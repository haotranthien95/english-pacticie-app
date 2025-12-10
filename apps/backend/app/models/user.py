"""
User model - Stores user accounts with authentication information
Supports email/password and OAuth providers (Google, Apple, Facebook)
"""
from sqlalchemy import Column, String, DateTime, Enum, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import enum
import uuid

from app.database import Base


class AuthProvider(str, enum.Enum):
    """Authentication provider types"""
    EMAIL = "email"
    GOOGLE = "google"
    APPLE = "apple"
    FACEBOOK = "facebook"


class User(Base):
    """
    User model for authentication and profile
    
    Indexes:
    - Unique index on email
    - Composite index on (auth_provider, auth_provider_id) for OAuth lookup
    """
    __tablename__ = "users"
    
    # Primary key
    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=func.gen_random_uuid()
    )
    
    # Profile fields
    email = Column(String(255), unique=True, nullable=False, index=True)
    name = Column(String(255), nullable=False)
    avatar_url = Column(String(1024), nullable=True)
    
    # Authentication
    password_hash = Column(String(255), nullable=True)  # Null for OAuth users
    auth_provider = Column(
        Enum(AuthProvider, native_enum=False),
        nullable=False,
        default=AuthProvider.EMAIL
    )
    auth_provider_id = Column(String(255), nullable=True)  # OAuth provider user ID
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False
    )
    
    # Composite index for OAuth lookup
    __table_args__ = (
        Index('ix_users_auth_provider_id', 'auth_provider', 'auth_provider_id'),
    )
    
    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, provider={self.auth_provider})>"
