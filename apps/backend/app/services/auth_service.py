"""Authentication service for user registration, login, and OAuth validation."""
import httpx
from typing import Optional
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models import User, AuthProvider
from app.schemas.auth import (
    RegisterRequest,
    LoginRequest,
    SocialAuthRequest,
    TokenResponse,
    UserResponse,
    AuthResponse,
)
from app.utils.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
)


class AuthenticationError(Exception):
    """Raised when authentication fails."""
    pass


class AuthService:
    """Service for handling authentication operations."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def register(self, data: RegisterRequest) -> AuthResponse:
        """
        Register a new user with email and password.
        
        Args:
            data: Registration request with email, password, name
            
        Returns:
            AuthResponse with user info and tokens
            
        Raises:
            AuthenticationError: If email already exists
        """
        # Check if user already exists
        result = await self.db.execute(
            select(User).where(User.email == data.email)
        )
        existing_user = result.scalar_one_or_none()
        
        if existing_user:
            raise AuthenticationError("Email already registered")
        
        # Create new user
        hashed_password = hash_password(data.password)
        user = User(
            email=data.email,
            name=data.name,
            password_hash=hashed_password,
            auth_provider=AuthProvider.EMAIL,
        )
        
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        
        # Generate tokens
        tokens = self._create_tokens(str(user.id))
        user_response = self._user_to_response(user)
        
        return AuthResponse(user=user_response, tokens=tokens)
    
    async def login(self, data: LoginRequest) -> AuthResponse:
        """
        Authenticate user with email and password.
        
        Args:
            data: Login request with email and password
            
        Returns:
            AuthResponse with user info and tokens
            
        Raises:
            AuthenticationError: If credentials are invalid
        """
        # Find user by email
        result = await self.db.execute(
            select(User).where(User.email == data.email)
        )
        user = result.scalar_one_or_none()
        
        if not user:
            raise AuthenticationError("Invalid email or password")
        
        # Verify password
        if not user.password_hash:
            raise AuthenticationError("Cannot login with password for OAuth account")
        
        if not verify_password(data.password, user.password_hash):
            raise AuthenticationError("Invalid email or password")
        
        # Generate tokens
        tokens = self._create_tokens(str(user.id))
        user_response = self._user_to_response(user)
        
        return AuthResponse(user=user_response, tokens=tokens)
    
    async def social_auth(self, data: SocialAuthRequest) -> AuthResponse:
        """
        Authenticate user with OAuth token from social provider.
        
        Args:
            data: Social auth request with provider and token
            
        Returns:
            AuthResponse with user info and tokens
            
        Raises:
            AuthenticationError: If token validation fails
        """
        # Validate token and get user info from provider
        provider_user = await self._validate_social_token(data.provider, data.token)
        
        # Use email from request if provider doesn't return it
        email = provider_user.get("email") or data.email
        if not email:
            raise AuthenticationError("Email is required for social authentication")
        
        # Map provider string to enum
        provider_enum = {
            "google": AuthProvider.GOOGLE,
            "apple": AuthProvider.APPLE,
            "facebook": AuthProvider.FACEBOOK,
        }[data.provider]
        
        # Find or create user
        result = await self.db.execute(
            select(User).where(
                User.auth_provider == provider_enum,
                User.auth_provider_id == provider_user["id"],
            )
        )
        user = result.scalar_one_or_none()
        
        if not user:
            # Check if email exists with different provider
            result = await self.db.execute(
                select(User).where(User.email == email)
            )
            existing_user = result.scalar_one_or_none()
            
            if existing_user:
                raise AuthenticationError(
                    f"Email already registered with {existing_user.auth_provider.value} provider"
                )
            
            # Create new user
            user = User(
                email=email,
                name=provider_user.get("name") or data.name or email.split("@")[0],
                avatar_url=provider_user.get("picture"),
                auth_provider=provider_enum,
                auth_provider_id=provider_user["id"],
            )
            self.db.add(user)
            await self.db.commit()
            await self.db.refresh(user)
        
        # Generate tokens
        tokens = self._create_tokens(str(user.id))
        user_response = self._user_to_response(user)
        
        return AuthResponse(user=user_response, tokens=tokens)
    
    async def refresh_token(self, refresh_token: str) -> TokenResponse:
        """
        Generate new access token from refresh token.
        
        Args:
            refresh_token: JWT refresh token
            
        Returns:
            New token pair
            
        Raises:
            AuthenticationError: If refresh token is invalid
        """
        from app.utils.security import get_token_subject
        
        user_id = get_token_subject(refresh_token)
        if not user_id:
            raise AuthenticationError("Invalid refresh token")
        
        # Verify user still exists
        result = await self.db.execute(
            select(User).where(User.id == UUID(user_id))
        )
        user = result.scalar_one_or_none()
        
        if not user:
            raise AuthenticationError("User not found")
        
        # Generate new tokens
        return self._create_tokens(user_id)
    
    async def _validate_social_token(
        self, provider: str, token: str
    ) -> dict:
        """
        Validate OAuth token with provider and get user info.
        
        Args:
            provider: OAuth provider name
            token: OAuth access token
            
        Returns:
            Dictionary with user info (id, email, name, picture)
            
        Raises:
            AuthenticationError: If token validation fails
        """
        async with httpx.AsyncClient() as client:
            if provider == "google":
                response = await client.get(
                    "https://www.googleapis.com/oauth2/v3/userinfo",
                    headers={"Authorization": f"Bearer {token}"},
                    timeout=10.0,
                )
                
                if response.status_code != 200:
                    raise AuthenticationError("Invalid Google token")
                
                data = response.json()
                return {
                    "id": data["sub"],
                    "email": data.get("email"),
                    "name": data.get("name"),
                    "picture": data.get("picture"),
                }
            
            elif provider == "apple":
                # Apple uses JWT ID tokens - validate with Apple's public keys
                # For MVP, we trust the client to validate on their side
                # In production, implement proper JWT validation with Apple's keys
                response = await client.get(
                    "https://appleid.apple.com/auth/token",
                    params={"client_id": settings.apple_client_id, "code": token},
                    timeout=10.0,
                )
                
                if response.status_code != 200:
                    raise AuthenticationError("Invalid Apple token")
                
                # Extract user info from ID token
                # For MVP, require email from request
                return {
                    "id": token,  # Use token as temp ID for MVP
                    "email": None,  # Client should provide email
                    "name": None,
                }
            
            elif provider == "facebook":
                response = await client.get(
                    "https://graph.facebook.com/me",
                    params={
                        "fields": "id,email,name,picture",
                        "access_token": token,
                    },
                    timeout=10.0,
                )
                
                if response.status_code != 200:
                    raise AuthenticationError("Invalid Facebook token")
                
                data = response.json()
                return {
                    "id": data["id"],
                    "email": data.get("email"),
                    "name": data.get("name"),
                    "picture": data.get("picture", {}).get("data", {}).get("url"),
                }
            
            else:
                raise AuthenticationError(f"Unsupported provider: {provider}")
    
    def _create_tokens(self, user_id: str) -> TokenResponse:
        """Create access and refresh tokens for user."""
        access_token = create_access_token({"sub": user_id})
        refresh_token = create_refresh_token({"sub": user_id})
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            token_type="bearer",
            expires_in=settings.jwt_expiration_minutes * 60,
        )
    
    def _user_to_response(self, user: User) -> UserResponse:
        """Convert User model to UserResponse schema."""
        return UserResponse(
            id=user.id,
            email=user.email,
            name=user.name,
            avatar_url=user.avatar_url,
            auth_provider=user.auth_provider.value,
            created_at=user.created_at.isoformat(),
        )
