"""
Speech model - Stores English practice sentences with audio
Associated with tags via many-to-many relationship
"""
from sqlalchemy import Column, String, DateTime, Enum, Index, Table, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
import uuid

from app.database import Base


class Level(str, enum.Enum):
    """CEFR proficiency levels"""
    A1 = "A1"  # Beginner
    A2 = "A2"  # Elementary
    B1 = "B1"  # Intermediate
    B2 = "B2"  # Upper Intermediate
    C1 = "C1"  # Advanced


class SpeechType(str, enum.Enum):
    """Speech content type"""
    QUESTION = "question"
    ANSWER = "answer"


# Association table for many-to-many Speech <-> Tag
speech_tags = Table(
    'speech_tags',
    Base.metadata,
    Column(
        'speech_id',
        UUID(as_uuid=True),
        ForeignKey('speeches.id', ondelete='CASCADE'),
        primary_key=True
    ),
    Column(
        'tag_id',
        UUID(as_uuid=True),
        ForeignKey('tags.id', ondelete='CASCADE'),
        primary_key=True
    ),
    Column('created_at', DateTime(timezone=True), server_default=func.now())
)


class Speech(Base):
    """
    Speech model for practice content
    
    Contains reference audio URL and text for pronunciation practice
    Categorized by level (CEFR), type, and tags
    
    Indexes:
    - Composite index on (level, type) for filtering
    - Full-text search on text (PostgreSQL GIN)
    """
    __tablename__ = "speeches"
    
    # Primary key
    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=func.gen_random_uuid()
    )
    
    # Content
    audio_url = Column(String(1024), nullable=False)  # MinIO URL
    text = Column(Text, nullable=False)
    
    # Classification
    level = Column(Enum(Level, native_enum=False), nullable=False, index=True)
    type = Column(
        Enum(SpeechType, native_enum=False),
        nullable=False,
        default=SpeechType.ANSWER
    )
    
    # Relationships
    tags = relationship(
        "Tag",
        secondary=speech_tags,
        backref="speeches",
        cascade="all, delete"
    )
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False
    )
    
    # Composite indexes
    __table_args__ = (
        Index('ix_speeches_level_type', 'level', 'type'),
        # Full-text search index (PostgreSQL specific)
        Index(
            'ix_speeches_text_fts',
            'text',
            postgresql_using='gin',
            postgresql_ops={'text': 'gin_trgm_ops'}
        ),
    )
    
    def __repr__(self):
        return f"<Speech(id={self.id}, level={self.level}, type={self.type}, text='{self.text[:50]}...')>"
