"""Azure Speech SDK provider for pronunciation assessment."""
import asyncio
from typing import Optional

import azure.cognitiveservices.speech as speechsdk

from app.config import settings
from app.core.exceptions import SpeechProcessingError
from app.services.speech_provider.base import (
    SpeechProviderBase,
    ScoringResult,
    WordScore,
)


class AzureSpeechProvider(SpeechProviderBase):
    """Azure Cognitive Services Speech SDK provider."""
    
    def __init__(self):
        """Initialize Azure Speech configuration."""
        self.speech_config = speechsdk.SpeechConfig(
            subscription=settings.azure_speech_key,
            region=settings.azure_speech_region,
        )
    
    async def assess_pronunciation(
        self,
        audio_data: bytes,
        reference_text: str,
        language: str = "en-US",
    ) -> ScoringResult:
        """
        Assess pronunciation using Azure Speech SDK.
        
        Args:
            audio_data: Audio bytes (WAV format recommended)
            reference_text: Reference text for comparison
            language: Language code
            
        Returns:
            ScoringResult with detailed scores
            
        Raises:
            SpeechProcessingError: If Azure API fails
        """
        try:
            # Configure speech recognition from audio data
            audio_config = speechsdk.audio.AudioConfig(
                stream=speechsdk.audio.PushAudioInputStream()
            )
            
            # Configure pronunciation assessment
            pronunciation_config = speechsdk.PronunciationAssessmentConfig(
                reference_text=reference_text,
                grading_system=speechsdk.PronunciationAssessmentGradingSystem.HundredMark,
                granularity=speechsdk.PronunciationAssessmentGranularity.Word,
                enable_miscue=True,
            )
            
            # Create speech recognizer
            speech_recognizer = speechsdk.SpeechRecognizer(
                speech_config=self.speech_config,
                audio_config=audio_config,
                language=language,
            )
            
            # Apply pronunciation assessment config
            pronunciation_config.apply_to(speech_recognizer)
            
            # Push audio data to stream
            audio_stream = speech_recognizer.audio_config.stream
            audio_stream.write(audio_data)
            audio_stream.close()
            
            # Run recognition in thread pool (Azure SDK is synchronous)
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None, speech_recognizer.recognize_once
            )
            
            # Check result
            if result.reason == speechsdk.ResultReason.RecognizedSpeech:
                return self._parse_pronunciation_result(result)
            elif result.reason == speechsdk.ResultReason.NoMatch:
                raise SpeechProcessingError(
                    "No speech detected in audio",
                    details={"no_match_details": result.no_match_details},
                )
            elif result.reason == speechsdk.ResultReason.Canceled:
                cancellation = result.cancellation_details
                raise SpeechProcessingError(
                    f"Speech recognition canceled: {cancellation.reason}",
                    details={
                        "error_code": cancellation.error_code,
                        "error_details": cancellation.error_details,
                    },
                )
            else:
                raise SpeechProcessingError(f"Unexpected result reason: {result.reason}")
        
        except SpeechProcessingError:
            raise
        except Exception as e:
            raise SpeechProcessingError(
                f"Azure Speech API error: {str(e)}",
                details={"exception_type": type(e).__name__},
            )
    
    async def transcribe_audio(
        self, audio_data: bytes, language: str = "en-US"
    ) -> str:
        """
        Transcribe audio without pronunciation assessment.
        
        Args:
            audio_data: Audio bytes
            language: Language code
            
        Returns:
            Transcribed text
            
        Raises:
            SpeechProcessingError: If transcription fails
        """
        try:
            # Configure audio stream
            audio_stream = speechsdk.audio.PushAudioInputStream()
            audio_config = speechsdk.audio.AudioConfig(stream=audio_stream)
            
            # Create speech recognizer
            speech_recognizer = speechsdk.SpeechRecognizer(
                speech_config=self.speech_config,
                audio_config=audio_config,
                language=language,
            )
            
            # Push audio data
            audio_stream.write(audio_data)
            audio_stream.close()
            
            # Run recognition
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None, speech_recognizer.recognize_once
            )
            
            if result.reason == speechsdk.ResultReason.RecognizedSpeech:
                return result.text
            elif result.reason == speechsdk.ResultReason.NoMatch:
                raise SpeechProcessingError("No speech detected in audio")
            else:
                raise SpeechProcessingError(f"Transcription failed: {result.reason}")
        
        except SpeechProcessingError:
            raise
        except Exception as e:
            raise SpeechProcessingError(f"Azure Speech API error: {str(e)}")
    
    def _parse_pronunciation_result(
        self, result: speechsdk.SpeechRecognitionResult
    ) -> ScoringResult:
        """
        Parse Azure pronunciation assessment result.
        
        Args:
            result: Azure speech recognition result
            
        Returns:
            ScoringResult with parsed scores
        """
        import json
        
        # Parse pronunciation assessment JSON
        pronunciation_result = json.loads(
            result.properties.get(
                speechsdk.PropertyId.SpeechServiceResponse_JsonResult
            )
        )
        
        # Extract overall scores
        nb_result = pronunciation_result.get("NBest", [{}])[0]
        pronunciation_assessment = nb_result.get("PronunciationAssessment", {})
        
        pronunciation_score = pronunciation_assessment.get("PronScore", 0.0)
        accuracy_score = pronunciation_assessment.get("AccuracyScore", 0.0)
        fluency_score = pronunciation_assessment.get("FluencyScore", 0.0)
        completeness_score = pronunciation_assessment.get("CompletenessScore", 0.0)
        
        # Extract word-level scores
        word_scores = []
        for word_data in nb_result.get("Words", []):
            word_assessment = word_data.get("PronunciationAssessment", {})
            word_scores.append(
                WordScore(
                    word=word_data.get("Word", ""),
                    score=word_assessment.get("AccuracyScore", 0.0),
                    error_type=word_assessment.get("ErrorType"),
                )
            )
        
        return ScoringResult(
            recognized_text=result.text,
            pronunciation_score=pronunciation_score,
            accuracy_score=accuracy_score,
            fluency_score=fluency_score,
            completeness_score=completeness_score,
            word_scores=word_scores,
        )
