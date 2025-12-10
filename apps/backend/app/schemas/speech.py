"""Pydantic schemas for speech content."""
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field

from app.models import Level, SpeechType


class SpeechResponse(BaseModel):
    """Schema for speech content response."""
    
    id: UUID = Field(..., description="Speech unique identifier")
    audio_url: str = Field(..., description="Audio file URL")
    text: str = Field(..., description="Speech text content")
    level: Level = Field(..., description="CEFR level (A1-C1)")
    type: SpeechType = Field(..., description="Speech type (question/answer)")
    tags: list[str] = Field(default=[], description="Associated tag names")
    created_at: str = Field(..., description="Creation timestamp")
    
    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "id": "123e4567-e89b-12d3-a456-426614174000",
                "audio_url": "https://minio.local:9000/english-practice-audio/a1-daily-001.mp3",
                "text": "Hello, my name is John. I live in London.",
                "level": "A1",
                "type": "answer",
                "tags": ["present_simple", "daily_life"],
                "created_at": "2025-12-10T12:00:00Z",
            }
        },
    }


class RandomSpeechRequest(BaseModel):
    """Schema for fetching random speeches with filters."""
    
    level: Optional[Level] = Field(None, description="Filter by CEFR level")
    type: Optional[SpeechType] = Field(None, description="Filter by speech type")
    tag_ids: list[UUID] = Field(default=[], description="Filter by tag IDs (AND logic)")
    limit: int = Field(default=10, ge=1, le=100, description="Number of speeches to return")
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "level": "B1",
                "type": "answer",
                "tag_ids": ["tag-uuid-1", "tag-uuid-2"],
                "limit": 10,
            }
        }
    }


class RandomSpeechResponse(BaseModel):
    """Schema for random speeches response."""
    
    speeches: list[SpeechResponse] = Field(..., description="List of random speeches")
    total: int = Field(..., description="Total number of speeches returned")
