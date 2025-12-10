"""
Admin API endpoints for tag management.

CRUD operations for tags with speech count and deletion protection.
Requires admin authentication (separate from user JWT).
"""
from typing import Annotated, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Tag, speech_tags


router = APIRouter(prefix="/admin/tags", tags=["Admin - Tags"])


# ============================================================================
# Request/Response Schemas
# ============================================================================


from pydantic import BaseModel, Field


class CreateTagRequest(BaseModel):
    """Schema for creating a new tag."""
    
    name: str = Field(..., description="Tag name (unique)", min_length=1, max_length=100)
    category: str = Field(..., description="Tag category (tense, topic, etc.)", min_length=1, max_length=50)
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "name": "present_perfect",
                "category": "tense",
            }
        }
    }


class UpdateTagRequest(BaseModel):
    """Schema for updating an existing tag."""
    
    name: Optional[str] = Field(None, description="Tag name (unique)", min_length=1, max_length=100)
    category: Optional[str] = Field(None, description="Tag category", min_length=1, max_length=50)
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "category": "grammar",
            }
        }
    }


class TagAdminResponse(BaseModel):
    """Schema for admin tag response with speech count."""
    
    id: UUID
    name: str
    category: str
    speech_count: int = Field(default=0, description="Number of speeches using this tag")
    created_at: str
    
    model_config = {"from_attributes": True}


class TagListResponse(BaseModel):
    """Schema for paginated tag list response."""
    
    tags: list[TagAdminResponse]
    total: int
    page: int
    page_size: int
    total_pages: int


class DeleteTagResponse(BaseModel):
    """Schema for tag deletion confirmation."""
    
    message: str
    deleted_id: UUID


# ============================================================================
# Helper Functions
# ============================================================================


async def get_tag_speech_count(db: AsyncSession, tag_id: UUID) -> int:
    """Get the number of speeches associated with a tag."""
    query = select(func.count()).select_from(speech_tags).where(speech_tags.c.tag_id == tag_id)
    result = await db.execute(query)
    return result.scalar() or 0


async def tag_to_admin_response(db: AsyncSession, tag: Tag) -> TagAdminResponse:
    """Convert Tag model to admin response schema with speech count."""
    speech_count = await get_tag_speech_count(db, tag.id)
    return TagAdminResponse(
        id=tag.id,
        name=tag.name,
        category=tag.category,
        speech_count=speech_count,
        created_at=tag.created_at.isoformat(),
    )


# ============================================================================
# Admin Tag Endpoints
# ============================================================================


@router.get("", response_model=TagListResponse)
async def list_tags(
    db: Annotated[AsyncSession, Depends(get_db)],
    page: int = Query(default=1, ge=1, description="Page number"),
    page_size: int = Query(default=50, ge=1, le=200, description="Items per page"),
    category: Optional[str] = Query(None, description="Filter by category"),
    search: Optional[str] = Query(None, description="Search by name (case-insensitive)"),
) -> TagListResponse:
    """
    List all tags with pagination and filters.
    
    Supports:
    - Pagination (page, page_size)
    - Filter by category
    - Search by name
    - Sorted by name ASC
    - Includes speech count for each tag
    """
    # Build base query
    query = select(Tag)
    
    # Apply filters
    if category:
        query = query.where(Tag.category == category)
    if search:
        query = query.where(Tag.name.ilike(f"%{search}%"))
    
    # Get total count
    count_query = select(func.count()).select_from(Tag)
    if category:
        count_query = count_query.where(Tag.category == category)
    if search:
        count_query = count_query.where(Tag.name.ilike(f"%{search}%"))
    
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0
    
    # Apply pagination and ordering
    query = query.order_by(Tag.name.asc())
    query = query.offset((page - 1) * page_size).limit(page_size)
    
    # Execute query
    result = await db.execute(query)
    tags = result.scalars().all()
    
    # Calculate total pages
    total_pages = (total + page_size - 1) // page_size if total > 0 else 0
    
    # Convert to response with speech counts
    tag_responses = []
    for tag in tags:
        tag_response = await tag_to_admin_response(db, tag)
        tag_responses.append(tag_response)
    
    return TagListResponse(
        tags=tag_responses,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )


@router.get("/{tag_id}", response_model=TagAdminResponse)
async def get_tag(
    tag_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TagAdminResponse:
    """
    Get a specific tag by ID.
    
    Returns full details including speech count.
    """
    query = select(Tag).where(Tag.id == tag_id)
    result = await db.execute(query)
    tag = result.scalar_one_or_none()
    
    if not tag:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tag with ID {tag_id} not found",
        )
    
    return await tag_to_admin_response(db, tag)


@router.post("", response_model=TagAdminResponse, status_code=status.HTTP_201_CREATED)
async def create_tag(
    request: CreateTagRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TagAdminResponse:
    """
    Create a new tag.
    
    Tag name must be unique (case-sensitive).
    """
    # Check if tag name already exists
    existing_query = select(Tag).where(Tag.name == request.name)
    existing_result = await db.execute(existing_query)
    existing_tag = existing_result.scalar_one_or_none()
    
    if existing_tag:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Tag with name '{request.name}' already exists",
        )
    
    # Create tag
    tag = Tag(
        name=request.name,
        category=request.category,
    )
    
    db.add(tag)
    await db.commit()
    await db.refresh(tag)
    
    return await tag_to_admin_response(db, tag)


@router.put("/{tag_id}", response_model=TagAdminResponse)
async def update_tag(
    tag_id: UUID,
    request: UpdateTagRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TagAdminResponse:
    """
    Update an existing tag.
    
    Only provided fields are updated.
    Tag name must remain unique if changed.
    """
    # Fetch existing tag
    query = select(Tag).where(Tag.id == tag_id)
    result = await db.execute(query)
    tag = result.scalar_one_or_none()
    
    if not tag:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tag with ID {tag_id} not found",
        )
    
    # Update fields
    if request.name is not None:
        # Check if new name conflicts with existing tag
        if request.name != tag.name:
            existing_query = select(Tag).where(Tag.name == request.name)
            existing_result = await db.execute(existing_query)
            existing_tag = existing_result.scalar_one_or_none()
            
            if existing_tag:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail=f"Tag with name '{request.name}' already exists",
                )
        
        tag.name = request.name
    
    if request.category is not None:
        tag.category = request.category
    
    await db.commit()
    await db.refresh(tag)
    
    return await tag_to_admin_response(db, tag)


@router.delete("/{tag_id}", response_model=DeleteTagResponse)
async def delete_tag(
    tag_id: UUID,
    db: Annotated[AsyncSession, Depends(get_db)],
    force: bool = Query(default=False, description="Force deletion even if speeches exist"),
) -> DeleteTagResponse:
    """
    Delete a tag by ID.
    
    Protection:
    - By default, prevents deletion if tag is associated with speeches
    - Use force=true to delete tag and remove associations (keeps speeches)
    
    Cascade behavior:
    - Removes tag-speech associations in speech_tags table
    - Does NOT delete speeches (only removes the association)
    """
    query = select(Tag).where(Tag.id == tag_id)
    result = await db.execute(query)
    tag = result.scalar_one_or_none()
    
    if not tag:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Tag with ID {tag_id} not found",
        )
    
    # Check speech associations
    speech_count = await get_tag_speech_count(db, tag_id)
    
    if speech_count > 0 and not force:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Tag is associated with {speech_count} speech(es). Use force=true to delete.",
        )
    
    # Delete tag (cascade will remove speech_tags associations)
    await db.delete(tag)
    await db.commit()
    
    return DeleteTagResponse(
        message=f"Tag deleted successfully (removed from {speech_count} speech(es))" if speech_count > 0 else "Tag deleted successfully",
        deleted_id=tag_id,
    )
