"""Service for game session management."""
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models import GameSession, GameResult, User, Speech, GameMode, Level, UserResponse
from app.schemas.game import (
    CreateGameSessionRequest,
    GameResultInput,
    CompleteGameSessionRequest,
    GameSessionResponse,
    GameResultResponse,
)
from app.core.exceptions import NotFoundError, ValidationError


class GameService:
    """Service for managing game sessions and results."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create_session(
        self, user: User, request: CreateGameSessionRequest
    ) -> GameSessionResponse:
        """
        Create a new game session for user.
        
        Args:
            user: Authenticated user
            request: Session creation request
            
        Returns:
            Created session response
        """
        session = GameSession(
            user_id=user.id,
            mode=request.mode,
            level=request.level,
            selected_tags=request.selected_tags,
            total_speeches=0,  # Will be updated when session completes
            correct_count=0,
            incorrect_count=0,
            skipped_count=0,
        )
        
        self.db.add(session)
        await self.db.commit()
        await self.db.refresh(session)
        
        return self._session_to_response(session)
    
    async def complete_session(
        self, user: User, request: CompleteGameSessionRequest
    ) -> GameSessionResponse:
        """
        Complete a game session with all results in a transaction.
        
        Args:
            user: Authenticated user
            request: Session completion request with results
            
        Returns:
            Completed session with statistics
            
        Raises:
            NotFoundError: If session not found or not owned by user
            ValidationError: If results are invalid
        """
        # Fetch session
        result = await self.db.execute(
            select(GameSession)
            .where(
                GameSession.id == request.session_id,
                GameSession.user_id == user.id,
            )
        )
        session = result.scalar_one_or_none()
        
        if not session:
            raise NotFoundError("Game session not found")
        
        if session.completed_at:
            raise ValidationError("Session already completed")
        
        # Validate speech IDs exist
        speech_ids = [r.speech_id for r in request.results]
        speech_result = await self.db.execute(
            select(Speech.id).where(Speech.id.in_(speech_ids))
        )
        existing_speech_ids = set(speech_result.scalars().all())
        
        missing_ids = set(speech_ids) - existing_speech_ids
        if missing_ids:
            raise ValidationError(f"Invalid speech IDs: {missing_ids}")
        
        # Create game results
        correct_count = 0
        incorrect_count = 0
        skipped_count = 0
        pronunciation_scores = []
        accuracy_scores = []
        fluency_scores = []
        
        for result_data in request.results:
            game_result = GameResult(
                session_id=session.id,
                speech_id=result_data.speech_id,
                sequence_number=result_data.sequence_number,
                user_response=result_data.user_response,
                recognized_text=result_data.recognized_text,
                pronunciation_score=result_data.pronunciation_score,
                accuracy_score=result_data.accuracy_score,
                fluency_score=result_data.fluency_score,
                completeness_score=result_data.completeness_score,
                word_scores=result_data.word_scores,
            )
            
            self.db.add(game_result)
            
            # Count responses
            if result_data.user_response == UserResponse.CORRECT:
                correct_count += 1
            elif result_data.user_response == UserResponse.INCORRECT:
                incorrect_count += 1
            elif result_data.user_response == UserResponse.SKIPPED:
                skipped_count += 1
            
            # Collect scores for listen_and_repeat mode
            if session.mode == GameMode.LISTEN_AND_REPEAT:
                if result_data.pronunciation_score is not None:
                    pronunciation_scores.append(result_data.pronunciation_score)
                if result_data.accuracy_score is not None:
                    accuracy_scores.append(result_data.accuracy_score)
                if result_data.fluency_score is not None:
                    fluency_scores.append(result_data.fluency_score)
        
        # Update session statistics
        session.total_speeches = len(request.results)
        session.correct_count = correct_count
        session.incorrect_count = incorrect_count
        session.skipped_count = skipped_count
        session.completed_at = datetime.now(timezone.utc)
        
        # Calculate average scores for listen_and_repeat mode
        if pronunciation_scores:
            session.avg_pronunciation_score = sum(pronunciation_scores) / len(
                pronunciation_scores
            )
        if accuracy_scores:
            session.avg_accuracy_score = sum(accuracy_scores) / len(accuracy_scores)
        if fluency_scores:
            session.avg_fluency_score = sum(fluency_scores) / len(fluency_scores)
        
        await self.db.commit()
        await self.db.refresh(session)
        
        # Load results for response
        result = await self.db.execute(
            select(GameSession)
            .options(selectinload(GameSession.results))
            .where(GameSession.id == session.id)
        )
        session_with_results = result.scalar_one()
        
        return self._session_to_response(session_with_results, include_results=True)
    
    async def get_session_by_id(
        self, user: User, session_id: UUID, include_results: bool = False
    ) -> Optional[GameSessionResponse]:
        """
        Fetch game session by ID.
        
        Args:
            user: Authenticated user
            session_id: Session UUID
            include_results: Whether to include game results
            
        Returns:
            Session response or None if not found
        """
        query = select(GameSession).where(
            GameSession.id == session_id, GameSession.user_id == user.id
        )
        
        if include_results:
            query = query.options(selectinload(GameSession.results))
        
        result = await self.db.execute(query)
        session = result.scalar_one_or_none()
        
        if not session:
            return None
        
        return self._session_to_response(session, include_results=include_results)
    
    async def get_user_sessions(
        self,
        user: User,
        mode: Optional[GameMode] = None,
        level: Optional[Level] = None,
        limit: int = 20,
        offset: int = 0,
    ) -> list[GameSessionResponse]:
        """
        Fetch user's game sessions with pagination and filters.
        
        Args:
            user: Authenticated user
            mode: Optional mode filter
            level: Optional level filter
            limit: Max results to return
            offset: Pagination offset
            
        Returns:
            List of session responses
        """
        query = select(GameSession).where(GameSession.user_id == user.id)
        
        if mode:
            query = query.where(GameSession.mode == mode)
        
        if level:
            query = query.where(GameSession.level == level)
        
        # Order by most recent first
        query = (
            query.order_by(GameSession.created_at.desc())
            .limit(limit)
            .offset(offset)
        )
        
        result = await self.db.execute(query)
        sessions = result.scalars().all()
        
        return [self._session_to_response(session) for session in sessions]
    
    def _session_to_response(
        self, session: GameSession, include_results: bool = False
    ) -> GameSessionResponse:
        """Convert GameSession model to response schema."""
        results = None
        if include_results and session.results:
            results = [
                GameResultResponse(
                    id=r.id,
                    speech_id=r.speech_id,
                    sequence_number=r.sequence_number,
                    user_response=r.user_response,
                    recognized_text=r.recognized_text,
                    pronunciation_score=r.pronunciation_score,
                    accuracy_score=r.accuracy_score,
                    fluency_score=r.fluency_score,
                    completeness_score=r.completeness_score,
                    word_scores=r.word_scores,
                )
                for r in sorted(session.results, key=lambda x: x.sequence_number)
            ]
        
        return GameSessionResponse(
            id=session.id,
            user_id=session.user_id,
            mode=session.mode,
            level=session.level,
            selected_tags=session.selected_tags or [],
            total_speeches=session.total_speeches,
            correct_count=session.correct_count,
            incorrect_count=session.incorrect_count,
            skipped_count=session.skipped_count,
            avg_pronunciation_score=session.avg_pronunciation_score,
            avg_accuracy_score=session.avg_accuracy_score,
            avg_fluency_score=session.avg_fluency_score,
            created_at=session.created_at.isoformat(),
            completed_at=session.completed_at.isoformat() if session.completed_at else None,
            results=results,
        )
