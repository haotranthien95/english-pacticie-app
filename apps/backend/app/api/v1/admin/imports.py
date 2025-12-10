"""
Admin API endpoints for bulk content import.

Two-step workflow:
1. POST /admin/import/audio - Upload audio files to temporary storage
2. POST /admin/import/csv - Import speeches from CSV, referencing uploaded audio
"""
from typing import Annotated, List

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.services.import_service import ImportService


router = APIRouter(prefix="/admin/import", tags=["Admin - Import"])


# ============================================================================
# Response Schemas
# ============================================================================


from pydantic import BaseModel, Field


class UploadedFileResponse(BaseModel):
    """Schema for a single uploaded audio file."""
    
    id: str = Field(..., description="Unique file ID")
    original_filename: str = Field(..., description="Original filename from upload")
    storage_url: str = Field(..., description="MinIO storage URL")
    size_bytes: int = Field(..., description="File size in bytes")
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "id": "file-uuid-1",
                "original_filename": "sentence_001.mp3",
                "storage_url": "https://minio.local:9000/english-practice-audio/uploads/session-uuid/sentence_001.mp3",
                "size_bytes": 45678,
            }
        }
    }


class AudioUploadResponse(BaseModel):
    """Schema for audio upload response."""
    
    upload_session_id: str = Field(..., description="Session ID for CSV import")
    uploaded_files: List[UploadedFileResponse] = Field(..., description="List of uploaded files")
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "upload_session_id": "session-uuid",
                "uploaded_files": [
                    {
                        "id": "file-uuid-1",
                        "original_filename": "sentence_001.mp3",
                        "storage_url": "https://minio.local:9000/english-practice-audio/uploads/session-uuid/sentence_001.mp3",
                        "size_bytes": 45678,
                    }
                ],
            }
        }
    }


class CreatedSpeechResponse(BaseModel):
    """Schema for a successfully created speech."""
    
    row: int = Field(..., description="CSV row number")
    speech_id: str = Field(..., description="Created speech UUID")
    text: str = Field(..., description="Speech text content")


class CSVValidationErrorResponse(BaseModel):
    """Schema for a CSV validation error."""
    
    row: int = Field(..., description="CSV row number with error")
    error: str = Field(..., description="Error message")


class CSVImportResponse(BaseModel):
    """Schema for CSV import response."""
    
    success_count: int = Field(..., description="Number of speeches created")
    error_count: int = Field(..., description="Number of validation errors")
    created_speeches: List[CreatedSpeechResponse] = Field(default=[], description="List of created speeches")
    errors: List[CSVValidationErrorResponse] = Field(default=[], description="List of validation errors")
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "success_count": 2,
                "error_count": 1,
                "created_speeches": [
                    {"row": 2, "speech_id": "uuid-1", "text": "What is your name?"},
                    {"row": 3, "speech_id": "uuid-2", "text": "My name is John."},
                ],
                "errors": [
                    {"row": 4, "error": "Audio file 'missing.mp3' not found in upload session"},
                ],
            }
        }
    }


# ============================================================================
# Import Endpoints
# ============================================================================


@router.post("/audio", response_model=AudioUploadResponse, status_code=status.HTTP_201_CREATED)
async def upload_audio_files(
    files: Annotated[List[UploadFile], File(..., description="Audio files to upload (MP3, WAV, M4A)")],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AudioUploadResponse:
    """
    Upload multiple audio files for later CSV import.
    
    **Workflow**:
    1. Upload audio files first (this endpoint)
    2. Use returned `upload_session_id` in CSV import
    
    **File Requirements**:
    - Allowed formats: MP3, WAV, M4A
    - Max size per file: 10MB
    - Duplicate filenames automatically get suffix (_1, _2, etc.)
    
    **Returns**:
    - Session ID for CSV import
    - List of uploaded files with storage URLs
    
    **Example**:
    ```bash
    curl -X POST http://localhost:8000/api/v1/admin/import/audio \\
      -F "files=@audio1.mp3" \\
      -F "files=@audio2.mp3" \\
      -F "files=@audio3.mp3"
    ```
    """
    if not files:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No files provided",
        )
    
    # Prepare files for service
    file_tuples = []
    for upload_file in files:
        # Read file content
        content = await upload_file.read()
        size = len(content)
        
        # Create file-like object
        import io
        file_data = io.BytesIO(content)
        
        file_tuples.append((upload_file.filename, file_data, size))
    
    # Upload files
    import_service = ImportService(db)
    
    try:
        session_id, uploaded_files = await import_service.upload_audio_files(file_tuples)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
    
    # Convert to response schema
    return AudioUploadResponse(
        upload_session_id=session_id,
        uploaded_files=[
            UploadedFileResponse(**uploaded_file.to_dict())
            for uploaded_file in uploaded_files
        ],
    )


@router.post("/csv", response_model=CSVImportResponse)
async def import_csv(
    file: Annotated[UploadFile, File(..., description="CSV file with speech data")],
    upload_session_id: Annotated[str, Form(..., description="Session ID from audio upload")],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> CSVImportResponse:
    """
    Import speeches from CSV file.
    
    **Workflow**:
    1. Upload audio files first (POST /admin/import/audio)
    2. Upload CSV with `upload_session_id` (this endpoint)
    
    **CSV Format**:
    ```csv
    audio_filename,text,level,type,tags
    sentence_001.mp3,"What is your name?",A1,question,"present_tense,basics"
    sentence_002.mp3,"My name is John.",A1,answer,"present_tense,basics"
    ```
    
    **CSV Columns**:
    - `audio_filename` (required): Must match uploaded filename
    - `text` (required): English sentence text
    - `level` (required): CEFR level (A1, A2, B1, B2, C1)
    - `type` (optional): question or answer (default: answer)
    - `tags` (optional): Comma-separated tag names (auto-created if missing)
    
    **Validation**:
    - All rows validated before creating any records (atomic)
    - Audio filenames must exist in upload session
    - No duplicate filenames within CSV
    - All required fields must be present
    - Level and type must be valid enum values
    
    **Returns**:
    - Success count: Number of speeches created
    - Error count: Number of validation errors
    - Created speeches: List of successfully created speeches
    - Errors: Detailed validation errors by row number
    
    **Notes**:
    - If ANY validation errors, NO speeches are created
    - Tags are auto-created with category "imported"
    - Upload session expires after 24 hours
    
    **Example**:
    ```bash
    curl -X POST http://localhost:8000/api/v1/admin/import/csv \\
      -F "file=@speeches.csv" \\
      -F "upload_session_id=session-uuid"
    ```
    """
    # Validate file type
    if not file.filename.endswith(".csv"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be a CSV file",
        )
    
    # Read CSV content
    content = await file.read()
    import io
    csv_data = io.BytesIO(content)
    
    # Import CSV
    import_service = ImportService(db)
    
    try:
        created_speeches, validation_errors = await import_service.import_csv(
            csv_data=csv_data,
            upload_session_id=upload_session_id,
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
    
    # Convert to response schema
    return CSVImportResponse(
        success_count=len(created_speeches),
        error_count=len(validation_errors),
        created_speeches=[
            CreatedSpeechResponse(**speech.to_dict())
            for speech in created_speeches
        ],
        errors=[
            CSVValidationErrorResponse(**error.to_dict())
            for error in validation_errors
        ],
    )
