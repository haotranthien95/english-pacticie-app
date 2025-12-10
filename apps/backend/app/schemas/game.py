"""Pydantic schemas for game sessions."""
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field

from app.models import GameMode, Level, UserResponse


class CreateGameSessionRequest(BaseModel):
    """Schema for creating a new game session."""
    
    mode: GameMode = Field(..., description="Game mode (listen_only/listen_and_repeat)")
    level: Level = Field(..., description="CEFR level for speech selection")
    selected_tags: list[UUID] = Field(
        default=[], description="Tag IDs to filter speeches (empty = all tags)"
    )
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "mode": "listen_and_repeat",
                "level": "B1",
                "selected_tags": ["tag-uuid-1", "tag-uuid-2"],
            }
        }
    }


class GameResultInput(BaseModel):
    """Schema for submitting a single game result."""
    
    speech_id: UUID = Field(..., description="Speech ID that was played")
    sequence_number: int = Field(..., ge=1, description="Order in session (1-based)")
    user_response: UserResponse = Field(..., description="User's response")
    recognized_text: Optional[str] = Field(None, description="Transcribed text from Azure")
    pronunciation_score: Optional[float] = Field(
        None, ge=0, le=100, description="Overall pronunciation score (0-100)"
    )
    accuracy_score: Optional[float] = Field(
        None, ge=0, le=100, description="Accuracy score (0-100)"
    )
    fluency_score: Optional[float] = Field(
        None, ge=0, le=100, description="Fluency score (0-100)"
    )
    completeness_score: Optional[float] = Field(
        None, ge=0, le=100, description="Completeness score (0-100)"
    )
    word_scores: Optional[list[dict]] = Field(
        None, description="Word-level scores [{word, score, error_type}]"
    )


class CompleteGameSessionRequest(BaseModel):
    """Schema for completing a game session with all results."""
    
    session_id: UUID = Field(..., description="Game session ID")
    results: list[GameResultInput] = Field(..., description="List of game results")
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "session_id": "session-uuid",
                "results": [
                    {
                        "speech_id": "speech-uuid-1",
                        "sequence_number": 1,
                        "user_response": "correct",
                        "pronunciation_score": 85.5,
                        "word_scores": [{"word": "hello", "score": 90, "error_type": None}],
                    }
                ],
            }
        }
    }


class GameResultResponse(BaseModel):
    """Schema for game result response."""
    
    id: UUID
    speech_id: UUID
    sequence_number: int
    user_response: UserResponse
    recognized_text: Optional[str] = None
    pronunciation_score: Optional[float] = None
    accuracy_score: Optional[float] = None
    fluency_score: Optional[float] = None
    completeness_score: Optional[float] = None
    word_scores: Optional[list[dict]] = None
    
    model_config = {"from_attributes": True}


class GameSessionResponse(BaseModel):
    """Schema for game session response."""
    
    id: UUID
    user_id: UUID
    mode: GameMode
    level: Level
    selected_tags: list[UUID]
    total_speeches: int
    correct_count: int
    incorrect_count: int
    skipped_count: int
    avg_pronunciation_score: Optional[float] = None
    avg_accuracy_score: Optional[float] = None
    avg_fluency_score: Optional[float] = None
    created_at: str
    completed_at: Optional[str] = None
    results: Optional[list[GameResultResponse]] = None
    
    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "id": "session-uuid",
                "user_id": "user-uuid",
                "mode": "listen_and_repeat",
                "level": "B1",
                "selected_tags": [],
                "total_speeches": 10,
                "correct_count": 8,
                "incorrect_count": 1,
                "skipped_count": 1,
                "avg_pronunciation_score": 82.5,
                "created_at": "2025-12-10T12:00:00Z",
                "completed_at": "2025-12-10T12:15:00Z",
            }
        },
    }
