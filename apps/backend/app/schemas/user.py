"""Pydantic schemas for user profile management."""
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


class UpdateProfileRequest(BaseModel):
    """Schema for updating user profile."""
    
    name: Optional[str] = Field(None, min_length=1, max_length=100, description="User full name")
    avatar_url: Optional[str] = Field(None, max_length=1024, description="Avatar image URL")
    
    model_config = {
        "json_schema_extra": {
            "example": {
                "name": "John Doe Updated",
                "avatar_url": "https://example.com/new-avatar.jpg",
            }
        }
    }


class UserProfileResponse(BaseModel):
    """Schema for detailed user profile response."""
    
    id: UUID = Field(..., description="User unique identifier")
    email: EmailStr = Field(..., description="User email address")
    name: str = Field(..., description="User full name")
    avatar_url: Optional[str] = Field(None, description="User avatar URL")
    auth_provider: str = Field(..., description="Authentication provider")
    created_at: str = Field(..., description="Account creation timestamp")
    updated_at: str = Field(..., description="Last profile update timestamp")
    
    # Statistics (optional, can be added later)
    total_sessions: Optional[int] = Field(None, description="Total game sessions completed")
    total_speeches_practiced: Optional[int] = Field(None, description="Total speeches practiced")
    
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
                "updated_at": "2025-12-10T14:30:00Z",
                "total_sessions": 15,
                "total_speeches_practiced": 150,
            }
        },
    }


class DeleteAccountResponse(BaseModel):
    """Schema for account deletion response."""
    
    message: str = Field(..., description="Confirmation message")
    deleted_at: str = Field(..., description="Deletion timestamp")
