"""Factory for creating speech provider instances."""
from app.services.speech_provider.base import SpeechProviderBase
from app.services.speech_provider.azure_provider import AzureSpeechProvider


def get_speech_provider() -> SpeechProviderBase:
    """
    Get speech provider instance.
    
    For MVP, returns Azure Speech Provider.
    In future, could support multiple providers based on config.
    
    Returns:
        SpeechProviderBase implementation
    """
    return AzureSpeechProvider()
