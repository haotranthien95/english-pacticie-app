"""
Import service for bulk speech content import via CSV and audio uploads.

Provides two-step workflow:
1. Upload audio files to temporary storage with session tracking
2. Upload CSV to create speech records, validating audio file references
"""
import csv
import io
import uuid
from datetime import datetime, timedelta
from typing import BinaryIO, Dict, List, Optional, Tuple

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Level, Speech, SpeechType, Tag
from app.services.storage_service import StorageService


# ============================================================================
# Data Classes
# ============================================================================


class UploadedFile:
    """Represents a single uploaded audio file in a session."""
    
    def __init__(
        self,
        file_id: str,
        original_filename: str,
        storage_url: str,
        size_bytes: int,
    ):
        self.id = file_id
        self.original_filename = original_filename
        self.storage_url = storage_url
        self.size_bytes = size_bytes
    
    def to_dict(self) -> dict:
        """Convert to dictionary for JSON response."""
        return {
            "id": self.id,
            "original_filename": self.original_filename,
            "storage_url": self.storage_url,
            "size_bytes": self.size_bytes,
        }


class UploadSession:
    """
    Tracks uploaded audio files in a session.
    
    In-memory storage for MVP. Future enhancement: Redis/database.
    """
    
    def __init__(self, session_id: str):
        self.session_id = session_id
        self.created_at = datetime.utcnow()
        self.files: Dict[str, UploadedFile] = {}  # filename -> UploadedFile
    
    def add_file(self, uploaded_file: UploadedFile) -> None:
        """Add uploaded file to session."""
        self.files[uploaded_file.original_filename] = uploaded_file
    
    def get_file(self, filename: str) -> Optional[UploadedFile]:
        """Get uploaded file by original filename."""
        return self.files.get(filename)
    
    def is_expired(self, max_age_hours: int = 24) -> bool:
        """Check if session has expired."""
        age = datetime.utcnow() - self.created_at
        return age > timedelta(hours=max_age_hours)


class CSVValidationError:
    """Represents a validation error in CSV import."""
    
    def __init__(self, row: int, error: str):
        self.row = row
        self.error = error
    
    def to_dict(self) -> dict:
        """Convert to dictionary for JSON response."""
        return {
            "row": self.row,
            "error": self.error,
        }


class CreatedSpeech:
    """Represents a successfully created speech from CSV."""
    
    def __init__(self, row: int, speech_id: str, text: str):
        self.row = row
        self.speech_id = speech_id
        self.text = text
    
    def to_dict(self) -> dict:
        """Convert to dictionary for JSON response."""
        return {
            "row": self.row,
            "speech_id": str(self.speech_id),
            "text": self.text,
        }


# ============================================================================
# Import Service
# ============================================================================


class ImportService:
    """
    Service for bulk content import.
    
    Features:
    - Audio file upload with session tracking
    - CSV parsing and validation
    - Atomic speech creation (all or nothing)
    - Tag auto-creation
    - Duplicate filename handling
    """
    
    # In-memory session storage (MVP)
    # Future: Move to Redis for distributed systems
    _sessions: Dict[str, UploadSession] = {}
    
    # Allowed audio file extensions
    ALLOWED_EXTENSIONS = {".mp3", ".wav", ".m4a"}
    
    # Max file size (10MB)
    MAX_FILE_SIZE = 10 * 1024 * 1024
    
    def __init__(self, db: AsyncSession):
        """
        Initialize import service.
        
        Args:
            db: Database session for speech creation
        """
        self.db = db
        self.storage = StorageService()
    
    # ========================================================================
    # Audio Upload
    # ========================================================================
    
    async def upload_audio_files(
        self,
        files: List[Tuple[str, BinaryIO, int]],  # (filename, data, size)
    ) -> Tuple[str, List[UploadedFile]]:
        """
        Upload multiple audio files to MinIO.
        
        Args:
            files: List of tuples (filename, file_data, size_bytes)
            
        Returns:
            Tuple of (session_id, list of UploadedFile objects)
            
        Raises:
            ValueError: If file extension not allowed or file too large
        """
        # Create upload session
        session_id = str(uuid.uuid4())
        session = UploadSession(session_id)
        
        uploaded_files = []
        filename_counts: Dict[str, int] = {}  # Track duplicates
        
        for original_filename, file_data, size_bytes in files:
            # Validate file extension
            file_ext = self._get_file_extension(original_filename)
            if file_ext not in self.ALLOWED_EXTENSIONS:
                raise ValueError(
                    f"Invalid file extension '{file_ext}'. "
                    f"Allowed: {', '.join(self.ALLOWED_EXTENSIONS)}"
                )
            
            # Validate file size
            if size_bytes > self.MAX_FILE_SIZE:
                raise ValueError(
                    f"File '{original_filename}' exceeds max size of "
                    f"{self.MAX_FILE_SIZE / (1024 * 1024):.0f}MB"
                )
            
            # Handle duplicate filenames
            upload_filename = original_filename
            if original_filename in filename_counts:
                filename_counts[original_filename] += 1
                # Append suffix: filename_1.mp3, filename_2.mp3
                name_without_ext = original_filename.rsplit(".", 1)[0]
                upload_filename = f"{name_without_ext}_{filename_counts[original_filename]}{file_ext}"
            else:
                filename_counts[original_filename] = 0
            
            # Generate unique storage path
            storage_filename = f"uploads/{session_id}/{upload_filename}"
            
            # Upload to MinIO
            file_data.seek(0)  # Reset file pointer
            storage_url = self.storage.upload_audio(
                file_data=file_data,
                filename=storage_filename,
            )
            
            # Create uploaded file record
            uploaded_file = UploadedFile(
                file_id=str(uuid.uuid4()),
                original_filename=original_filename,
                storage_url=storage_url,
                size_bytes=size_bytes,
            )
            
            # Add to session
            session.add_file(uploaded_file)
            uploaded_files.append(uploaded_file)
        
        # Store session
        self._sessions[session_id] = session
        
        return session_id, uploaded_files
    
    # ========================================================================
    # CSV Import
    # ========================================================================
    
    async def import_csv(
        self,
        csv_data: BinaryIO,
        upload_session_id: str,
    ) -> Tuple[List[CreatedSpeech], List[CSVValidationError]]:
        """
        Import speeches from CSV file.
        
        Validates all rows before creating any records (atomic).
        Auto-creates tags if they don't exist.
        
        Args:
            csv_data: CSV file data stream
            upload_session_id: Session ID from audio upload
            
        Returns:
            Tuple of (created_speeches, validation_errors)
            
        Raises:
            ValueError: If session not found or expired
        """
        # Validate session exists
        session = self._sessions.get(upload_session_id)
        if not session:
            raise ValueError(f"Upload session '{upload_session_id}' not found")
        
        if session.is_expired():
            raise ValueError(f"Upload session '{upload_session_id}' has expired")
        
        # Parse CSV
        csv_data.seek(0)
        csv_text = csv_data.read().decode("utf-8")
        csv_reader = csv.DictReader(io.StringIO(csv_text))
        
        # Validate required columns
        required_columns = {"audio_filename", "text", "level"}
        if not required_columns.issubset(set(csv_reader.fieldnames or [])):
            raise ValueError(
                f"CSV missing required columns. Required: {required_columns}"
            )
        
        # Parse and validate all rows first
        rows = []
        validation_errors = []
        seen_filenames = set()
        
        for row_num, row in enumerate(csv_reader, start=2):  # Start at 2 (header is row 1)
            try:
                parsed_row = self._parse_csv_row(row, row_num, session, seen_filenames)
                rows.append(parsed_row)
                seen_filenames.add(row["audio_filename"])
            except ValueError as e:
                validation_errors.append(CSVValidationError(row_num, str(e)))
        
        # If any validation errors, return early (no records created)
        if validation_errors:
            return [], validation_errors
        
        # All rows valid - create speeches in transaction
        created_speeches = []
        
        try:
            for parsed_row in rows:
                # Get or create tags
                tag_objects = await self._get_or_create_tags(parsed_row["tag_names"])
                
                # Create speech
                speech = Speech(
                    audio_url=parsed_row["audio_url"],
                    text=parsed_row["text"],
                    level=parsed_row["level"],
                    type=parsed_row["type"],
                    tags=tag_objects,
                )
                
                self.db.add(speech)
                await self.db.flush()  # Get speech.id
                
                created_speeches.append(
                    CreatedSpeech(
                        row=parsed_row["row_num"],
                        speech_id=str(speech.id),
                        text=speech.text,
                    )
                )
            
            # Commit transaction
            await self.db.commit()
            
        except Exception as e:
            # Rollback on any error
            await self.db.rollback()
            raise ValueError(f"Failed to create speeches: {str(e)}")
        
        return created_speeches, []
    
    # ========================================================================
    # Helper Methods
    # ========================================================================
    
    def _get_file_extension(self, filename: str) -> str:
        """Get lowercase file extension including dot."""
        if "." not in filename:
            return ""
        return "." + filename.rsplit(".", 1)[1].lower()
    
    def _parse_csv_row(
        self,
        row: dict,
        row_num: int,
        session: UploadSession,
        seen_filenames: set,
    ) -> dict:
        """
        Parse and validate a single CSV row.
        
        Returns:
            Dictionary with parsed values
            
        Raises:
            ValueError: If validation fails
        """
        # Validate audio_filename exists
        audio_filename = row.get("audio_filename", "").strip()
        if not audio_filename:
            raise ValueError("Missing required field: audio_filename")
        
        # Check for duplicate within CSV
        if audio_filename in seen_filenames:
            raise ValueError(f"Duplicate audio_filename '{audio_filename}' in CSV")
        
        # Validate audio file exists in session
        uploaded_file = session.get_file(audio_filename)
        if not uploaded_file:
            raise ValueError(
                f"Audio file '{audio_filename}' not found in upload session"
            )
        
        # Validate text
        text = row.get("text", "").strip()
        if not text:
            raise ValueError("Missing required field: text")
        
        # Validate level
        level_str = row.get("level", "").strip().upper()
        if not level_str:
            raise ValueError("Missing required field: level")
        
        try:
            level = Level[level_str]
        except KeyError:
            valid_levels = ", ".join([l.value for l in Level])
            raise ValueError(
                f"Invalid level '{level_str}'. Must be one of: {valid_levels}"
            )
        
        # Parse type (optional, defaults to answer)
        type_str = row.get("type", "answer").strip().lower()
        try:
            speech_type = SpeechType[type_str.upper()] if type_str else SpeechType.ANSWER
        except KeyError:
            valid_types = ", ".join([t.value for t in SpeechType])
            raise ValueError(
                f"Invalid type '{type_str}'. Must be one of: {valid_types}"
            )
        
        # Parse tags (optional, comma-separated)
        tags_str = row.get("tags", "").strip()
        tag_names = []
        if tags_str:
            tag_names = [t.strip() for t in tags_str.split(",") if t.strip()]
        
        return {
            "row_num": row_num,
            "audio_url": uploaded_file.storage_url,
            "text": text,
            "level": level,
            "type": speech_type,
            "tag_names": tag_names,
        }
    
    async def _get_or_create_tags(self, tag_names: List[str]) -> List[Tag]:
        """
        Get existing tags or create new ones.
        
        Args:
            tag_names: List of tag names
            
        Returns:
            List of Tag objects
        """
        if not tag_names:
            return []
        
        tag_objects = []
        
        for tag_name in tag_names:
            # Check if tag exists
            query = select(Tag).where(Tag.name == tag_name)
            result = await self.db.execute(query)
            tag = result.scalar_one_or_none()
            
            if tag:
                tag_objects.append(tag)
            else:
                # Create new tag with default category "imported"
                new_tag = Tag(name=tag_name, category="imported")
                self.db.add(new_tag)
                await self.db.flush()  # Get tag.id
                tag_objects.append(new_tag)
        
        return tag_objects
    
    @classmethod
    def cleanup_expired_sessions(cls, max_age_hours: int = 24) -> int:
        """
        Remove expired upload sessions.
        
        Args:
            max_age_hours: Maximum session age in hours
            
        Returns:
            Number of sessions removed
        """
        expired_sessions = [
            session_id
            for session_id, session in cls._sessions.items()
            if session.is_expired(max_age_hours)
        ]
        
        for session_id in expired_sessions:
            del cls._sessions[session_id]
        
        return len(expired_sessions)
