"""Audio buffer manager for guaranteed cleanup of memory buffers."""
import io
from typing import Optional


class AudioBufferManager:
    """
    Context manager for audio buffer lifecycle management.
    
    Ensures audio buffers are always cleaned up, even on exceptions.
    Critical for preventing memory leaks with user audio uploads.
    """
    
    def __init__(self, audio_data: Optional[bytes] = None):
        """
        Initialize audio buffer manager.
        
        Args:
            audio_data: Optional initial audio bytes
        """
        self.buffer: Optional[io.BytesIO] = None
        self._initial_data = audio_data
    
    def __enter__(self) -> io.BytesIO:
        """
        Enter context and create buffer.
        
        Returns:
            BytesIO buffer for audio data
        """
        self.buffer = io.BytesIO(self._initial_data) if self._initial_data else io.BytesIO()
        return self.buffer
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """
        Exit context and cleanup buffer.
        
        Guaranteed to run even if exception occurs.
        """
        if self.buffer:
            self.buffer.close()
            self.buffer = None
        
        # Don't suppress exceptions
        return False
    
    async def __aenter__(self) -> io.BytesIO:
        """Async context manager entry."""
        return self.__enter__()
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """Async context manager exit."""
        return self.__exit__(exc_type, exc_val, exc_tb)
