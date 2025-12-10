"""Service for speech content management."""
from typing import Optional
from uuid import UUID

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import Speech, Tag, Level, SpeechType, speech_tags
from app.schemas.speech import SpeechResponse, RandomSpeechRequest


class SpeechService:
    """Service for fetching and managing speech content."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_random_speeches(
        self, filters: RandomSpeechRequest
    ) -> list[SpeechResponse]:
        """
        Fetch random speeches with filters.
        
        Args:
            filters: Request with level, type, tag_ids, limit
            
        Returns:
            List of random speeches matching filters
        """
        # Build query
        query = select(Speech).options(selectinload(Speech.tags))
        
        # Apply level filter
        if filters.level:
            query = query.where(Speech.level == filters.level)
        
        # Apply type filter
        if filters.type:
            query = query.where(Speech.type == filters.type)
        
        # Apply tag filters (AND logic - speech must have ALL specified tags)
        if filters.tag_ids:
            # Subquery to count matching tags per speech
            tag_count_subquery = (
                select(speech_tags.c.speech_id)
                .where(speech_tags.c.tag_id.in_(filters.tag_ids))
                .group_by(speech_tags.c.speech_id)
                .having(func.count(speech_tags.c.tag_id) == len(filters.tag_ids))
            )
            
            query = query.where(Speech.id.in_(tag_count_subquery))
        
        # Order randomly and limit
        query = query.order_by(func.random()).limit(filters.limit)
        
        # Execute query
        result = await self.db.execute(query)
        speeches = result.scalars().all()
        
        # Convert to response schemas
        return [self._speech_to_response(speech) for speech in speeches]
    
    async def get_speech_by_id(self, speech_id: UUID) -> Optional[Speech]:
        """
        Fetch speech by ID with tags loaded.
        
        Args:
            speech_id: Speech UUID
            
        Returns:
            Speech model or None if not found
        """
        result = await self.db.execute(
            select(Speech)
            .options(selectinload(Speech.tags))
            .where(Speech.id == speech_id)
        )
        return result.scalar_one_or_none()
    
    async def get_speeches_by_ids(self, speech_ids: list[UUID]) -> list[Speech]:
        """
        Fetch multiple speeches by IDs.
        
        Args:
            speech_ids: List of speech UUIDs
            
        Returns:
            List of Speech models
        """
        result = await self.db.execute(
            select(Speech)
            .options(selectinload(Speech.tags))
            .where(Speech.id.in_(speech_ids))
        )
        return list(result.scalars().all())
    
    async def search_speeches(
        self,
        query: str,
        level: Optional[Level] = None,
        limit: int = 20,
    ) -> list[SpeechResponse]:
        """
        Full-text search speeches by text content.
        
        Args:
            query: Search query string
            level: Optional level filter
            limit: Max results to return
            
        Returns:
            List of matching speeches
        """
        # Build query with full-text search
        # Using PostgreSQL tsvector for full-text search
        search_query = select(Speech).options(selectinload(Speech.tags))
        
        # Apply text search (simple ILIKE for MVP, use tsvector in production)
        search_query = search_query.where(Speech.text.ilike(f"%{query}%"))
        
        # Apply level filter if provided
        if level:
            search_query = search_query.where(Speech.level == level)
        
        # Limit results
        search_query = search_query.limit(limit)
        
        result = await self.db.execute(search_query)
        speeches = result.scalars().all()
        
        return [self._speech_to_response(speech) for speech in speeches]
    
    def _speech_to_response(self, speech: Speech) -> SpeechResponse:
        """Convert Speech model to SpeechResponse schema."""
        return SpeechResponse(
            id=speech.id,
            audio_url=speech.audio_url,
            text=speech.text,
            level=speech.level,
            type=speech.type,
            tags=[tag.name for tag in speech.tags],
            created_at=speech.created_at.isoformat(),
        )
