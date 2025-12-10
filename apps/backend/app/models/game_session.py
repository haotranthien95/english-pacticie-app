"""
GameSession model - Stores completed practice sessions
Contains summary statistics and selected configuration
"""
from sqlalchemy import Column, String, DateTime, Enum, Integer, Float, ForeignKey, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
import uuid

from app.database import Base


class GameMode(str, enum.Enum):
    """Game play modes"""
    LISTEN_ONLY = "listen_only"
    LISTEN_AND_REPEAT = "listen_and_repeat"


class GameSession(Base):
    """
    GameSession model for completed practice sessions
    
    Stores session configuration and summary statistics
    Individual sentence results stored in GameResult
    
    Indexes:
    - Composite index on (user_id, completed_at) for history queries
    - Composite index on (mode, level) for analytics
    """
    __tablename__ = "game_sessions"
    
    # Primary key
    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=func.gen_random_uuid()
    )
    
    # Foreign keys
    user_id = Column(
        UUID(as_uuid=True),
        ForeignKey('users.id', ondelete='CASCADE'),
        nullable=False,
        index=True
    )
    
    # Session configuration
    mode = Column(Enum(GameMode, native_enum=False), nullable=False)
    level = Column(String(10), nullable=False)  # A1, A2, B1, B2, C1
    selected_tags = Column(JSONB, nullable=False, default=[])  # Array of tag IDs
    
    # Summary statistics
    total_speeches = Column(Integer, nullable=False, default=0)
    correct_count = Column(Integer, nullable=False, default=0)
    incorrect_count = Column(Integer, nullable=False, default=0)
    skipped_count = Column(Integer, nullable=False, default=0)
    
    # Pronunciation scores (for listen_and_repeat mode)
    avg_pronunciation_score = Column(Float, nullable=True)  # 0-100
    avg_accuracy_score = Column(Float, nullable=True)
    avg_fluency_score = Column(Float, nullable=True)
    
    # Timestamps
    completed_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Relationships
    user = relationship("User", backref="game_sessions")
    results = relationship(
        "GameResult",
        back_populates="session",
        cascade="all, delete-orphan"
    )
    
    # Composite indexes
    __table_args__ = (
        Index('ix_game_sessions_user_completed', 'user_id', 'completed_at'),
        Index('ix_game_sessions_mode_level', 'mode', 'level'),
    )
    
    def __repr__(self):
        return f"<GameSession(id={self.id}, mode={self.mode}, level={self.level}, correct={self.correct_count}/{self.total_speeches})>"
