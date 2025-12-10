"""
Application configuration using Pydantic Settings
Loads from environment variables with .env file support
"""
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="allow"
    )
    
    # Application
    environment: str = "development"
    debug: bool = True
    host: str = "0.0.0.0"
    port: int = 8000
    allowed_origins: str = "http://localhost:3000"
    
    # Database
    database_url: str
    
    # Redis
    redis_url: str = "redis://localhost:6379/0"
    
    # MinIO / S3 Storage
    s3_endpoint_url: str
    s3_access_key: str
    s3_secret_key: str
    s3_bucket_name: str = "english-practice-audio"
    s3_use_ssl: bool = False
    
    # Azure Speech Services
    azure_speech_key: str
    azure_speech_region: str = "eastus"
    speech_api_timeout: int = 10
    speech_provider: str = "azure"  # MVP: Azure only
    
    # JWT Authentication
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    jwt_expiration_minutes: int = 10080  # 7 days
    
    # OAuth Providers (for token validation)
    google_client_id: str = ""
    apple_client_id: str = ""
    facebook_app_id: str = ""
    facebook_app_secret: str = ""
    
    # SQLAdmin Panel
    admin_username: str = "admin"
    admin_password_hash: str
    
    @property
    def cors_origins(self) -> List[str]:
        """Parse CORS origins from comma-separated string"""
        return [origin.strip() for origin in self.allowed_origins.split(",")]


# Global settings instance
settings = Settings()
