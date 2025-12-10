"""Game API endpoints for speech selection and session management."""
from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import CurrentUser
from app.schemas.speech import RandomSpeechRequest, RandomSpeechResponse, SpeechResponse
from app.schemas.game import (
    CreateGameSessionRequest,
    CompleteGameSessionRequest,
    GameSessionResponse,
)
from app.services.speech_service import SpeechService
from app.services.game_service import GameService
from app.core.exceptions import NotFoundError, ValidationError

router = APIRouter(prefix="/game", tags=["Game"])


@router.post(
    "/speeches/random",
    response_model=RandomSpeechResponse,
    summary="Fetch random speeches with filters",
    responses={
        200: {"description": "Random speeches fetched successfully"},
        401: {"description": "Unauthorized"},
    },
)
async def get_random_speeches(
    request: RandomSpeechRequest,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> RandomSpeechResponse:
    """
    Fetch random speeches for game session.
    
    **Filters:**
    - `level`: CEFR level (A1, A2, B1, B2, C1)
    - `type`: Speech type (question, answer)
    - `tag_ids`: Tag IDs (AND logic - must match ALL tags)
    - `limit`: Max speeches to return (1-100, default 10)
    
    **Use case:** Client fetches speeches before starting a game session.
    """
    speech_service = SpeechService(db)
    speeches = await speech_service.get_random_speeches(request)
    
    return RandomSpeechResponse(
        speeches=speeches,
        total=len(speeches),
    )


@router.post(
    "/sessions",
    response_model=GameSessionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create new game session",
    responses={
        201: {"description": "Session created successfully"},
        401: {"description": "Unauthorized"},
    },
)
async def create_game_session(
    request: CreateGameSessionRequest,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> GameSessionResponse:
    """
    Create a new game session.
    
    **Flow:**
    1. Client creates session with mode/level/tags
    2. Client fetches speeches via `/speeches/random`
    3. User plays through speeches
    4. Client completes session via `PUT /sessions/{id}/complete`
    """
    game_service = GameService(db)
    return await game_service.create_session(user, request)


@router.put(
    "/sessions/{session_id}/complete",
    response_model=GameSessionResponse,
    summary="Complete game session with results",
    responses={
        200: {"description": "Session completed successfully"},
        400: {"description": "Validation error"},
        404: {"description": "Session not found"},
    },
)
async def complete_game_session(
    session_id: UUID,
    results: list,  # Will be validated by CompleteGameSessionRequest
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> GameSessionResponse:
    """
    Complete a game session by submitting all results in one transaction.
    
    **Request body:**
    ```json
    {
      "results": [
        {
          "speech_id": "uuid",
          "sequence_number": 1,
          "user_response": "correct",
          "pronunciation_score": 85.5,
          "word_scores": [{"word": "hello", "score": 90, "error_type": null}]
        }
      ]
    }
    ```
    
    **Calculates:**
    - Total speeches, correct/incorrect/skipped counts
    - Average pronunciation/accuracy/fluency scores
    - Marks session as completed
    """
    game_service = GameService(db)
    
    request = CompleteGameSessionRequest(session_id=session_id, results=results)
    
    try:
        return await game_service.complete_session(user, request)
    except NotFoundError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))
    except ValidationError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.get(
    "/sessions/{session_id}",
    response_model=GameSessionResponse,
    summary="Get game session details",
    responses={
        200: {"description": "Session retrieved"},
        404: {"description": "Session not found"},
    },
)
async def get_game_session(
    session_id: UUID,
    include_results: bool = False,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> GameSessionResponse:
    """
    Fetch game session by ID.
    
    **Query params:**
    - `include_results`: Include full game results (default: false)
    """
    game_service = GameService(db)
    session = await game_service.get_session_by_id(user, session_id, include_results)
    
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Game session not found",
        )
    
    return session


@router.get(
    "/sessions",
    response_model=list[GameSessionResponse],
    summary="Get user's game history",
    responses={
        200: {"description": "Sessions retrieved"},
    },
)
async def get_user_sessions(
    mode: str = None,
    level: str = None,
    limit: int = 20,
    offset: int = 0,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[GameSessionResponse]:
    """
    Fetch user's game session history with pagination.
    
    **Query params:**
    - `mode`: Filter by game mode (listen_only, listen_and_repeat)
    - `level`: Filter by CEFR level (A1, A2, B1, B2, C1)
    - `limit`: Max results (default: 20)
    - `offset`: Pagination offset (default: 0)
    
    **Order:** Most recent first
    """
    game_service = GameService(db)
    
    # Convert string params to enums if provided
    from app.models import GameMode, Level
    
    mode_enum = GameMode(mode) if mode else None
    level_enum = Level(level) if level else None
    
    return await game_service.get_user_sessions(
        user, mode=mode_enum, level=level_enum, limit=limit, offset=offset
    )
