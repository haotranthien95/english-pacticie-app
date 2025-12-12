"""Speech provider abstraction layer"""
from app.services.speech_provider.factory import get_speech_provider
from app.services.speech_provider.base import SpeechProviderBase
from app.services.speech_provider.azure_provider import AzureSpeechProvider

__all__ = [
    "get_speech_provider",
    "SpeechProviderBase", 
    "AzureSpeechProvider",
]
