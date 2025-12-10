"""
GameResult model - Stores individual sentence results within a session
One result per speech in the session, ordered by sequence_number
"""
from sqlalchemy import Column, String, DateTime, Enum, Integer, Float, ForeignKey, Index, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
import uuid

from app.database import Base


class UserResponse(str, enum.Enum):
    """User's response evaluation"""
    CORRECT = "correct"
    INCORRECT = "incorrect"
    SKIPPED = "skipped"


class GameResult(Base):
    """
    GameResult model for individual speech results
    
    Stores per-sentence outcome and pronunciation scores
    Linked to session and speech for detailed analysis
    
    Indexes:
    - Composite index on (session_id, sequence_number) for ordered retrieval
    - Index on speech_id for speech analytics
    """
    __tablename__ = "game_results"
    
    # Primary key
    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=func.gen_random_uuid()
    )
    
    # Foreign keys
    session_id = Column(
        UUID(as_uuid=True),
        ForeignKey('game_sessions.id', ondelete='CASCADE'),
        nullable=False,
        index=True
    )
    speech_id = Column(
        UUID(as_uuid=True),
        ForeignKey('speeches.id', ondelete='CASCADE'),
        nullable=False,
        index=True
    )
    
    # Result data
    sequence_number = Column(Integer, nullable=False)  # Order in session (1-based)
    user_response = Column(Enum(UserResponse, native_enum=False), nullable=False)
    
    # Pronunciation assessment (for listen_and_repeat mode)
    recognized_text = Column(Text, nullable=True)  # What user actually said
    pronunciation_score = Column(Float, nullable=True)  # 0-100
    accuracy_score = Column(Float, nullable=True)
    fluency_score = Column(Float, nullable=True)
    completeness_score = Column(Float, nullable=True)
    word_scores = Column(JSONB, nullable=True)  # Array of {word, score, error_type}
    
    # Timestamp
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    
    # Relationships
    session = relationship("GameSession", back_populates="results")
    speech = relationship("Speech", backref="results")
    
    # Composite indexes
    __table_args__ = (
        Index('ix_game_results_session_sequence', 'session_id', 'sequence_number'),
    )
    
    def __repr__(self):
        return f"<GameResult(id={self.id}, session={self.session_id}, seq={self.sequence_number}, response={self.user_response})>"
