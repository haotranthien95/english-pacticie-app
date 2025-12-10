"""Base interface for speech recognition and pronunciation assessment providers."""
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Optional


@dataclass
class WordScore:
    """Word-level pronunciation score."""
    
    word: str
    score: float  # 0-100
    error_type: Optional[str] = None  # e.g., "Mispronunciation", "Omission"


@dataclass
class ScoringResult:
    """Pronunciation assessment result from speech provider."""
    
    recognized_text: str
    pronunciation_score: float  # 0-100
    accuracy_score: float  # 0-100
    fluency_score: float  # 0-100
    completeness_score: float  # 0-100
    word_scores: list[WordScore]


class SpeechProviderBase(ABC):
    """Abstract base class for speech recognition providers."""
    
    @abstractmethod
    async def assess_pronunciation(
        self,
        audio_data: bytes,
        reference_text: str,
        language: str = "en-US",
    ) -> ScoringResult:
        """
        Assess pronunciation quality against reference text.
        
        Args:
            audio_data: Audio file bytes (WAV, MP3, etc.)
            reference_text: Expected text to compare against
            language: Language code (default: en-US)
            
        Returns:
            ScoringResult with scores and transcription
            
        Raises:
            SpeechProcessingError: If assessment fails
        """
        pass
    
    @abstractmethod
    async def transcribe_audio(
        self, audio_data: bytes, language: str = "en-US"
    ) -> str:
        """
        Transcribe audio to text without assessment.
        
        Args:
            audio_data: Audio file bytes
            language: Language code
            
        Returns:
            Transcribed text
            
        Raises:
            SpeechProcessingError: If transcription fails
        """
        pass
