"""Authentication API endpoints."""
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.auth import (
    RegisterRequest,
    LoginRequest,
    SocialAuthRequest,
    RefreshTokenRequest,
    AuthResponse,
    TokenResponse,
    UserResponse,
)
from app.services.auth_service import AuthService, AuthenticationError
from app.dependencies import CurrentUser

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post(
    "/register",
    response_model=AuthResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register new user with email and password",
    responses={
        201: {"description": "User registered successfully"},
        400: {"description": "Email already registered or invalid data"},
    },
)
async def register(
    data: RegisterRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AuthResponse:
    """
    Register a new user account with email and password.
    
    **Password Requirements:**
    - Minimum 8 characters
    - At least one uppercase letter
    - At least one lowercase letter
    - At least one digit
    
    Returns user profile and JWT tokens (access + refresh).
    """
    auth_service = AuthService(db)
    
    try:
        return await auth_service.register(data)
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )


@router.post(
    "/login",
    response_model=AuthResponse,
    summary="Login with email and password",
    responses={
        200: {"description": "Login successful"},
        401: {"description": "Invalid credentials"},
    },
)
async def login(
    data: LoginRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AuthResponse:
    """
    Authenticate user with email and password.
    
    Returns user profile and JWT tokens (access + refresh).
    """
    auth_service = AuthService(db)
    
    try:
        return await auth_service.login(data)
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
        )


@router.post(
    "/social",
    response_model=AuthResponse,
    summary="Login with social OAuth provider",
    responses={
        200: {"description": "Social authentication successful"},
        401: {"description": "Invalid OAuth token"},
    },
)
async def social_auth(
    data: SocialAuthRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AuthResponse:
    """
    Authenticate user with OAuth token from social provider.
    
    **Supported Providers:**
    - `google`: Google Sign-In (OAuth 2.0)
    - `apple`: Sign in with Apple (OAuth 2.0)
    - `facebook`: Facebook Login (OAuth 2.0)
    
    The token should be the access token obtained from the OAuth flow on the client side.
    
    **First-time users:** Account will be created automatically.
    
    **Returning users:** Matched by `(provider, provider_user_id)`.
    """
    auth_service = AuthService(db)
    
    try:
        return await auth_service.social_auth(data)
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
        )


@router.post(
    "/refresh",
    response_model=TokenResponse,
    summary="Refresh access token",
    responses={
        200: {"description": "Token refreshed successfully"},
        401: {"description": "Invalid refresh token"},
    },
)
async def refresh_token(
    data: RefreshTokenRequest,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> TokenResponse:
    """
    Generate new access token using refresh token.
    
    **Use case:** When access token expires (after 7 days by default),
    use the refresh token to get a new access token without requiring
    the user to login again.
    
    Refresh tokens are valid for 30 days.
    """
    auth_service = AuthService(db)
    
    try:
        return await auth_service.refresh_token(data.refresh_token)
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
        )


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Get current user profile",
    responses={
        200: {"description": "User profile retrieved"},
        401: {"description": "Unauthorized - invalid or missing token"},
    },
)
async def get_me(user: CurrentUser) -> UserResponse:
    """
    Get the profile of the currently authenticated user.
    
    **Requires:** Valid JWT access token in Authorization header.
    
    **Header format:** `Authorization: Bearer <access_token>`
    """
    return UserResponse(
        id=user.id,
        email=user.email,
        name=user.name,
        avatar_url=user.avatar_url,
        auth_provider=user.auth_provider.value,
        created_at=user.created_at.isoformat(),
    )
