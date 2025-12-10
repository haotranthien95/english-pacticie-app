"""Speech scoring endpoint for pronunciation assessment."""
from typing import Annotated

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import CurrentUser
from app.core.exceptions import SpeechProcessingError
from app.services.speech_service import SpeechService
from app.services.speech_provider import get_speech_provider
from app.utils.audio_buffer import AudioBufferManager

router = APIRouter(prefix="/speech", tags=["Speech"])


class ScoringResponse:
    """Response schema for pronunciation scoring."""
    
    def __init__(
        self,
        recognized_text: str,
        pronunciation_score: float,
        accuracy_score: float,
        fluency_score: float,
        completeness_score: float,
        word_scores: list[dict],
    ):
        self.recognized_text = recognized_text
        self.pronunciation_score = pronunciation_score
        self.accuracy_score = accuracy_score
        self.fluency_score = fluency_score
        self.completeness_score = completeness_score
        self.word_scores = word_scores


@router.post(
    "/score",
    summary="Assess pronunciation from audio",
    responses={
        200: {"description": "Pronunciation assessed successfully"},
        400: {"description": "Invalid audio or processing error"},
        401: {"description": "Unauthorized"},
    },
)
async def score_pronunciation(
    audio: Annotated[UploadFile, File(description="Audio file (WAV, MP3)")],
    reference_text: Annotated[str, Form(description="Expected text to compare")],
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """
    Assess pronunciation quality from audio recording.
    
    **Request:**
    - `audio`: Audio file (multipart/form-data)
    - `reference_text`: Expected text for comparison
    
    **Returns:**
    - `recognized_text`: Transcribed text from audio
    - `pronunciation_score`: Overall score (0-100)
    - `accuracy_score`: Pronunciation accuracy (0-100)
    - `fluency_score`: Speaking fluency (0-100)
    - `completeness_score`: How complete the speech was (0-100)
    - `word_scores`: Word-level scores with error types
    
    **Note:** Audio is processed in-memory and never persisted to disk.
    """
    # Validate file type
    if not audio.content_type or not audio.content_type.startswith("audio/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="File must be an audio file",
        )
    
    # Read audio data with buffer manager for guaranteed cleanup
    try:
        audio_data = await audio.read()
        
        async with AudioBufferManager(audio_data) as buffer:
            # Get speech provider
            speech_provider = get_speech_provider()
            
            # Assess pronunciation (buffer contains audio bytes)
            result = await speech_provider.assess_pronunciation(
                audio_data=buffer.getvalue(),
                reference_text=reference_text,
                language="en-US",
            )
        
        # Buffer is automatically cleaned up here
        
        # Convert WordScore dataclasses to dicts for JSON response
        word_scores = [
            {
                "word": ws.word,
                "score": ws.score,
                "error_type": ws.error_type,
            }
            for ws in result.word_scores
        ]
        
        return {
            "recognized_text": result.recognized_text,
            "pronunciation_score": result.pronunciation_score,
            "accuracy_score": result.accuracy_score,
            "fluency_score": result.fluency_score,
            "completeness_score": result.completeness_score,
            "word_scores": word_scores,
        }
    
    except SpeechProcessingError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Speech processing failed: {e.message}",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Unexpected error: {str(e)}",
        )
