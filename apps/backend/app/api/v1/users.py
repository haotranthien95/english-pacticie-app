"""User profile API endpoints."""
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import CurrentUser
from app.schemas.user import UpdateProfileRequest, UserProfileResponse, DeleteAccountResponse
from app.services.user_service import UserService

router = APIRouter(prefix="/users", tags=["Users"])


@router.get(
    "/me",
    response_model=UserProfileResponse,
    summary="Get current user profile",
    responses={
        200: {"description": "User profile retrieved"},
        401: {"description": "Unauthorized"},
    },
)
async def get_my_profile(
    include_stats: Annotated[bool, Query(description="Include session statistics")] = False,
    user: CurrentUser = None,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> UserProfileResponse:
    """
    Get the profile of the currently authenticated user.
    
    **Query params:**
    - `include_stats`: Include statistics (total sessions, speeches practiced)
    
    **Returns:**
    - Basic profile info (id, email, name, avatar_url, auth_provider)
    - Timestamps (created_at, updated_at)
    - Optional statistics if `include_stats=true`
    """
    user_service = UserService(db)
    return await user_service.get_profile(user, include_stats=include_stats)


@router.put(
    "/me",
    response_model=UserProfileResponse,
    summary="Update current user profile",
    responses={
        200: {"description": "Profile updated successfully"},
        401: {"description": "Unauthorized"},
        400: {"description": "Validation error"},
    },
)
async def update_my_profile(
    request: UpdateProfileRequest,
    user: CurrentUser = None,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> UserProfileResponse:
    """
    Update the profile of the currently authenticated user.
    
    **Updatable fields:**
    - `name`: User's full name (1-100 characters)
    - `avatar_url`: Profile picture URL (max 1024 characters)
    
    **Note:** Email and auth_provider cannot be changed.
    
    **Returns:** Updated user profile
    """
    user_service = UserService(db)
    return await user_service.update_profile(user, request)


@router.delete(
    "/me",
    response_model=DeleteAccountResponse,
    summary="Delete current user account",
    responses={
        200: {"description": "Account deleted successfully"},
        401: {"description": "Unauthorized"},
    },
)
async def delete_my_account(
    user: CurrentUser = None,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
) -> DeleteAccountResponse:
    """
    Delete the currently authenticated user account.
    
    **Warning:** This action is irreversible!
    
    **Cascade deletions:**
    - All game sessions
    - All game results
    - User profile data
    
    **Returns:** Confirmation message with deletion timestamp
    """
    user_service = UserService(db)
    result = await user_service.delete_account(user)
    
    return DeleteAccountResponse(
        message=result["message"],
        deleted_at=result["deleted_at"],
    )
