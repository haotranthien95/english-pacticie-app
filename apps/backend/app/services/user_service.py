"""Service for user profile management."""
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import User, GameSession
from app.schemas.user import UpdateProfileRequest, UserProfileResponse
from app.core.exceptions import NotFoundError


class UserService:
    """Service for managing user profiles."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_profile(self, user: User, include_stats: bool = False) -> UserProfileResponse:
        """
        Get user profile with optional statistics.
        
        Args:
            user: Authenticated user
            include_stats: Whether to include session statistics
            
        Returns:
            User profile response
        """
        profile = UserProfileResponse(
            id=user.id,
            email=user.email,
            name=user.name,
            avatar_url=user.avatar_url,
            auth_provider=user.auth_provider.value,
            created_at=user.created_at.isoformat(),
            updated_at=user.updated_at.isoformat(),
        )
        
        if include_stats:
            # Calculate statistics
            stats = await self._get_user_statistics(user.id)
            profile.total_sessions = stats["total_sessions"]
            profile.total_speeches_practiced = stats["total_speeches"]
        
        return profile
    
    async def update_profile(
        self, user: User, request: UpdateProfileRequest
    ) -> UserProfileResponse:
        """
        Update user profile fields.
        
        Args:
            user: Authenticated user
            request: Profile update request
            
        Returns:
            Updated user profile
        """
        # Update fields if provided
        if request.name is not None:
            user.name = request.name
        
        if request.avatar_url is not None:
            user.avatar_url = request.avatar_url
        
        # Update timestamp
        user.updated_at = datetime.now(timezone.utc)
        
        await self.db.commit()
        await self.db.refresh(user)
        
        return await self.get_profile(user)
    
    async def delete_account(self, user: User) -> dict:
        """
        Delete user account and all associated data.
        
        Args:
            user: Authenticated user
            
        Returns:
            Deletion confirmation
            
        Note:
            Cascade delete will remove all game sessions and results.
        """
        deleted_at = datetime.now(timezone.utc)
        
        # Delete user (cascade will handle related records)
        await self.db.delete(user)
        await self.db.commit()
        
        return {
            "message": "Account successfully deleted",
            "deleted_at": deleted_at.isoformat(),
        }
    
    async def _get_user_statistics(self, user_id) -> dict:
        """
        Calculate user statistics from game sessions.
        
        Args:
            user_id: User UUID
            
        Returns:
            Dictionary with total_sessions and total_speeches
        """
        # Count completed sessions
        session_count_result = await self.db.execute(
            select(func.count(GameSession.id))
            .where(
                GameSession.user_id == user_id,
                GameSession.completed_at.isnot(None),
            )
        )
        total_sessions = session_count_result.scalar() or 0
        
        # Sum total speeches from all sessions
        speeches_count_result = await self.db.execute(
            select(func.sum(GameSession.total_speeches))
            .where(
                GameSession.user_id == user_id,
                GameSession.completed_at.isnot(None),
            )
        )
        total_speeches = speeches_count_result.scalar() or 0
        
        return {
            "total_sessions": total_sessions,
            "total_speeches": total_speeches,
        }
