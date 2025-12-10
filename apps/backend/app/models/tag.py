"""
Tag model - Categorizes speeches by grammar concepts and topics
Used for filtering speeches in game configuration
"""
from sqlalchemy import Column, String, DateTime, Index
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func
import uuid

from app.database import Base


class Tag(Base):
    """
    Tag model for categorizing speeches
    
    Categories:
    - tense: Grammar tenses (present_simple, past_continuous, etc.)
    - topic: Subject areas (daily_life, business, travel, etc.)
    
    Indexes:
    - Unique index on name (prevents duplicates)
    - Index on category (for filtering)
    """
    __tablename__ = "tags"
    
    # Primary key
    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=func.gen_random_uuid()
    )
    
    # Tag fields
    name = Column(String(100), unique=True, nullable=False, index=True)
    category = Column(String(50), nullable=False, index=True)  # tense, topic
    
    # Timestamp
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    def __repr__(self):
        return f"<Tag(id={self.id}, name={self.name}, category={self.category})>"
