"""Pydantic schemas for authentication endpoints."""
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, field_validator


class RegisterRequest(BaseModel):
    """Schema for email/password registration."""
    
    email: EmailStr = Field(..., description="User email address")
    password: str = Field(
        ..., min_length=8, max_length=100, description="User password (min 8 characters)"
    )
    name: str = Field(..., min_length=1, max_length=100, description="User full name")
    
    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        """Validate password contains at least one uppercase, lowercase, and digit."""
        if not any(c.isupper() for c in v):
            raise ValueError("Password must contain at least one uppercase letter")
        if not any(c.islower() for c in v):
            raise ValueError("Password must contain at least one lowercase letter")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain at least one digit")
        return v


class LoginRequest(BaseModel):
    """Schema for email/password login."""
    
    email: EmailStr = Field(..., description="User email address")
    password: str = Field(..., description="User password")


class SocialAuthRequest(BaseModel):
    """Schema for social OAuth authentication."""
    
    provider: str = Field(..., description="OAuth provider (google, apple, facebook)")
    token: str = Field(..., description="OAuth access token from provider")
    name: Optional[str] = Field(None, description="User name from OAuth profile")
    email: Optional[EmailStr] = Field(None, description="User email from OAuth profile")
    
    @field_validator("provider")
    @classmethod
    def validate_provider(cls, v: str) -> str:
        """Validate provider is one of the supported OAuth providers."""
        allowed_providers = ["google", "apple", "facebook"]
        if v.lower() not in allowed_providers:
            raise ValueError(
                f"Provider must be one of {allowed_providers}, got '{v}'"
            )
        return v.lower()


class RefreshTokenRequest(BaseModel):
    """Schema for refresh token request."""
    
    refresh_token: str = Field(..., description="JWT refresh token")


class TokenResponse(BaseModel):
    """Schema for token response (login, register, refresh)."""
    
    access_token: str = Field(..., description="JWT access token")
    refresh_token: str = Field(..., description="JWT refresh token")
    token_type: str = Field(default="bearer", description="Token type")
    expires_in: int = Field(..., description="Access token expiration in seconds")
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "token_type": "bearer",
                "expires_in": 604800,
            }
        }
    }


class UserResponse(BaseModel):
    """Schema for user profile response."""
    
    id: UUID = Field(..., description="User unique identifier")
    email: str = Field(..., description="User email address")
    name: str = Field(..., description="User full name")
    avatar_url: Optional[str] = Field(None, description="User avatar URL")
    auth_provider: str = Field(..., description="Authentication provider")
    created_at: str = Field(..., description="Account creation timestamp")
    
    model_config = {
        "from_attributes": True,
        "json_schema_extra": {
            "example": {
                "id": "123e4567-e89b-12d3-a456-426614174000",
                "email": "john.doe@example.com",
                "name": "John Doe",
                "avatar_url": "https://example.com/avatar.jpg",
                "auth_provider": "email",
                "created_at": "2025-12-10T12:00:00Z",
            }
        },
    }


class AuthResponse(BaseModel):
    """Schema for authentication response with user info and tokens."""
    
    user: UserResponse = Field(..., description="User profile information")
    tokens: TokenResponse = Field(..., description="JWT tokens")
