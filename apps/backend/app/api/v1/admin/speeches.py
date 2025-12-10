"""
Admin API endpoints for speech content management.

CRUD operations for speeches with pagination, filtering, and full-text search.
Requires admin authentication (separate from user JWT).
"""
from typing import Annotated, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.models import Level, Speech, SpeechType, Tag, speech_tags


router = APIRouter(prefix="/admin/speeches", tags=["Admin - Speeches"])


# ============================================================================
# Request/Response Schemas
# ============================================================================


from pydantic import BaseModel, Field


class CreateSpeechRequest(BaseModel):
    """Schema for creating a new speech."""
    
    audio_url: str = Field(..., description="MinIO URL to audio file", min_length=1, max_length=1024)
    text: str = Field(..., description="Speech text content", min_length=1, max_length=5000)
    level: Level = Field(..., description="CEFR level")
    type: SpeechType = Field(default=SpeechType.ANSWER, description="Speech type")
    tag_ids: list[UUID] = Field(default=[], description="Tag UUIDs to associate")
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "audio_url": "https://minio.local:9000/english-practice-audio/b1-business-042.mp3",
                "text": "Can you please provide more details about the project timeline?",
                "level": "B1",
                "type": "question",
                "tag_ids": ["uuid-1", "uuid-2"],
            }
        }
    }


class UpdateSpeechRequest(BaseModel):
    """Schema for updating an existing speech."""
    
    audio_url: Optional[str] = Field(None, description="MinIO URL to audio file", min_length=1, max_length=1024)
    text: Optional[str] = Field(None, description="Speech text content", min_length=1, max_length=5000)
    level: Optional[Level] = Field(None, description="CEFR level")
    type: Optional[SpeechType] = Field(None, description="Speech type")
    tag_ids: Optional[list[UUID]] = Field(None, description="Tag UUIDs to associate (replaces existing)")
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "text": "Could you please provide more details about the project timeline?",
                "level": "B2",
            }
        }
    }


class SpeechAdminResponse(BaseModel):
    """Schema for admin speech response with full details."""
    
    id: UUID
    audio_url: str
    text: str
    level: Level
    type: SpeechType
    tags: list[dict] = Field(default=[], description="Tag objects with id, name, category")
    created_at: str
    updated_at: str
    
    model_config = {"from_attributes": True}


class SpeechListResponse(BaseModel):
    """Schema for paginated speech list response."""
    
    speeches: list[SpeechAdminResponse]
    total: int
    page: int
    page_size: int
    total_pages: int


class DeleteSpeechResponse(BaseModel):
    """Schema for speech deletion confirmation."""
    
    message: str
    deleted_id: UUID


# ============================================================================
# Helper Functions
# ============================================================================


def speech_to_admin_response(speech: Speech) -> SpeechAdminResponse:
    """Convert Speech model to admin response schema."""
    return SpeechAdminResponse(
        id=speech.id,
        audio_url=speech.audio_url,
        text=speech.text,
        level=speech.level,
        type=speech.type,
        tags=[{"id": str(tag.id), "name": tag.name, "category": tag.category} for tag in speech.tags],
        created_at=speech.created_at.isoformat(),
        updated_at=speech.updated_at.isoformat(),
    )


# ============================================================================
# Admin Speech Endpoints
# ============================================================================


@router.get("", response_model=SpeechListResponse)
async def list_speeches(
    db: Annotated[AsyncSession, Depends(get_db)],
    page: int = Query(default=1, ge=1, description="Page number"),
    page_size: int = Query(default=20, ge=1, le=200, description="Items per page"),
    level: Optional[Level] = Query(None, description="Filter by CEFR level"),
    type: Optional[SpeechType] = Query(None, description="Filter by speech type"),
    tag_id: Optional[UUID] = Query(None, description="Filter by tag ID"),
    search: Optional[str] = Query(None, description="Full-text search on text field"),
) -> SpeechListResponse:
    """
    List all speeches with pagination and filters.
    
    Supports:
    - Pagination (page, page_size)
    - Filter by level, type, tag
    - Full-text search on text field
    - Sorted by created_at DESC
    """
    # Build base query
    query = select(Speech).options(selectinload(Speech.tags))
    
    # Apply filters
    filters = []
    if level:
        filters.append(Speech.level == level)
    if type:
        filters.append(Speech.type == type)
    if tag_id:
        # Filter speeches that have this tag
        subquery = select(speech_tags.c.speech_id).where(speech_tags.c.tag_id == tag_id)
        filters.append(Speech.id.in_(subquery))
    if search:
        # Full-text search (case-insensitive)
        filters.append(Speech.text.ilike(f"%{search}%"))
    
    if filters:
        query = query.where(and_(*filters))
    
    # Get total count
    count_query = select(func.count()).select_from(Speech)
    if filters:
        count_query = count_query.where(and_(*filters))
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0
    
    # Apply pagination and ordering
    query = query.order_by(Speech.created_at.desc())
    query = query.offset((page - 1) * page_size).limit(page_size)
    
    # Execute query
    result = await db.execute(query)
    speeches = result.scalars().all()
    
    # Calculate total pages
    total_pages = (total + page_size - 1) // page_size if total > 0 else 0
    
    return SpeechListResponse(
        speeches=[speech_to_admin_response(speech) for speech in speeches],
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )


@router.get("/{speech_id}", response_model=SpeechAdminResponse)
async def get_speech(
    speech_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SpeechAdminResponse:
    """
    Get a specific speech by ID.
    
    Returns full details including tags.
    """
    query = select(Speech).options(selectinload(Speech.tags)).where(Speech.id == speech_id)
    result = await db.execute(query)
    speech = result.scalar_one_or_none()
    
    if not speech:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Speech with ID {speech_id} not found",
        )
    
    return speech_to_admin_response(speech)


@router.post("", response_model=SpeechAdminResponse, status_code=status.HTTP_201_CREATED)
async def create_speech(
    request: CreateSpeechRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SpeechAdminResponse:
    """
    Create a new speech.
    
    Validates that all tag_ids exist before creating.
    Associates speech with specified tags.
    """
    # Validate tags exist
    if request.tag_ids:
        tag_query = select(Tag).where(Tag.id.in_(request.tag_ids))
        tag_result = await db.execute(tag_query)
        tags = list(tag_result.scalars().all())
        
        if len(tags) != len(request.tag_ids):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="One or more tag IDs are invalid",
            )
    else:
        tags = []
    
    # Create speech
    speech = Speech(
        audio_url=request.audio_url,
        text=request.text,
        level=request.level,
        type=request.type,
        tags=tags,
    )
    
    db.add(speech)
    await db.commit()
    await db.refresh(speech, ["tags"])
    
    return speech_to_admin_response(speech)


@router.put("/{speech_id}", response_model=SpeechAdminResponse)
async def update_speech(
    speech_id: UUID,
    request: UpdateSpeechRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> SpeechAdminResponse:
    """
    Update an existing speech.
    
    Only provided fields are updated.
    If tag_ids provided, replaces existing tag associations.
    """
    # Fetch existing speech
    query = select(Speech).options(selectinload(Speech.tags)).where(Speech.id == speech_id)
    result = await db.execute(query)
    speech = result.scalar_one_or_none()
    
    if not speech:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Speech with ID {speech_id} not found",
        )
    
    # Update fields
    if request.audio_url is not None:
        speech.audio_url = request.audio_url
    if request.text is not None:
        speech.text = request.text
    if request.level is not None:
        speech.level = request.level
    if request.type is not None:
        speech.type = request.type
    
    # Update tags if provided
    if request.tag_ids is not None:
        if request.tag_ids:
            # Validate tags exist
            tag_query = select(Tag).where(Tag.id.in_(request.tag_ids))
            tag_result = await db.execute(tag_query)
            tags = list(tag_result.scalars().all())
            
            if len(tags) != len(request.tag_ids):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="One or more tag IDs are invalid",
                )
            
            speech.tags = tags
        else:
            # Clear all tags
            speech.tags = []
    
    await db.commit()
    await db.refresh(speech, ["tags"])
    
    return speech_to_admin_response(speech)


@router.delete("/{speech_id}", response_model=DeleteSpeechResponse)
async def delete_speech(
    speech_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> DeleteSpeechResponse:
    """
    Delete a speech by ID.
    
    Cascade deletes:
    - Speech-tag associations (speech_tags)
    - Game results referencing this speech
    """
    query = select(Speech).where(Speech.id == speech_id)
    result = await db.execute(query)
    speech = result.scalar_one_or_none()
    
    if not speech:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Speech with ID {speech_id} not found",
        )
    
    await db.delete(speech)
    await db.commit()
    
    return DeleteSpeechResponse(
        message="Speech deleted successfully",
        deleted_id=speech_id,
    )
