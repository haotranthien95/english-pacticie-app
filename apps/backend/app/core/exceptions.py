"""Custom exception classes for typed error handling."""


class ApplicationError(Exception):
    """Base exception for all application errors."""
    
    def __init__(self, message: str, details: dict = None):
        self.message = message
        self.details = details or {}
        super().__init__(self.message)


class AuthenticationError(ApplicationError):
    """Raised when authentication fails."""
    pass


class AuthorizationError(ApplicationError):
    """Raised when user lacks permission for action."""
    pass


class NotFoundError(ApplicationError):
    """Raised when requested resource is not found."""
    pass


class ValidationError(ApplicationError):
    """Raised when input validation fails."""
    pass


class SpeechProcessingError(ApplicationError):
    """Raised when speech processing fails (Azure API, etc)."""
    pass


class StorageError(ApplicationError):
    """Raised when storage operations fail (MinIO, etc)."""
    pass


class DatabaseError(ApplicationError):
    """Raised when database operations fail."""
    pass


class ExternalServiceError(ApplicationError):
    """Raised when external service calls fail."""
    pass
