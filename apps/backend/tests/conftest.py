"""
Pytest configuration and shared fixtures for all tests.
"""
import pytest
import pytest_asyncio
from unittest.mock import AsyncMock, Mock
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import Session

from app.models.user import User
from app.models.speech import Speech
from app.models.tag import Tag
from app.core.security import hash_password


@pytest.fixture
def mock_db():
    """Mock synchronous database session."""
    session = Mock(spec=Session)
    session.add = Mock()
    session.commit = Mock()
    session.refresh = Mock()
    session.delete = Mock()
    session.rollback = Mock()
    session.close = Mock()
    return session


@pytest_asyncio.fixture
async def async_mock_db():
    """Mock asynchronous database session."""
    session = AsyncMock(spec=AsyncSession)
    session.add = Mock()
    session.commit = AsyncMock()
    session.refresh = AsyncMock()
    session.delete = Mock()
    session.rollback = AsyncMock()
    session.close = AsyncMock()
    return session


@pytest.fixture
def sample_user():
    """Sample user for testing."""
    return User(
        id=1,
        email="test@example.com",
        username="testuser",
        hashed_password=hash_password("TestPass123!"),
        is_active=True,
    )


@pytest.fixture
def sample_admin_user():
    """Sample admin user for testing."""
    return User(
        id=2,
        email="admin@example.com",
        username="admin",
        hashed_password=hash_password("AdminPass123!"),
        is_active=True,
        is_admin=True,
    )


@pytest.fixture
def sample_speech():
    """Sample speech for testing."""
    return Speech(
        id=1,
        text="Hello world",
        level="beginner",
        type="word",
        audio_url="https://example.com/audio.mp3",
        phonetic="həˈloʊ wɜrld",
        translation="Xin chào thế giới",
        is_active=True,
    )


@pytest.fixture
def sample_tag():
    """Sample tag for testing."""
    return Tag(
        id=1,
        name="greeting",
        category="topic",
        is_active=True,
    )


@pytest.fixture
def mock_redis():
    """Mock Redis client."""
    redis_mock = AsyncMock()
    redis_mock.get = AsyncMock(return_value=None)
    redis_mock.set = AsyncMock(return_value=True)
    redis_mock.delete = AsyncMock(return_value=1)
    redis_mock.keys = AsyncMock(return_value=[])
    redis_mock.info = AsyncMock(return_value={"keyspace_hits": "100", "keyspace_misses": "20"})
    return redis_mock


@pytest.fixture
def mock_storage():
    """Mock storage service."""
    storage_mock = AsyncMock()
    storage_mock.upload_file = AsyncMock(return_value="https://example.com/file.mp3")
    storage_mock.delete_file = AsyncMock(return_value=True)
    storage_mock.get_presigned_url = AsyncMock(return_value="https://example.com/presigned-url")
    return storage_mock


@pytest.fixture
def mock_speech_processor():
    """Mock speech processing service."""
    processor_mock = AsyncMock()
    processor_mock.assess_pronunciation = AsyncMock(
        return_value={
            "accuracy_score": 85,
            "fluency_score": 90,
            "completeness_score": 95,
            "overall_score": 90,
            "pronunciation_assessment": {
                "accuracy_score": 85,
                "fluency_score": 90,
                "completeness_score": 95,
            },
            "words": [
                {"word": "hello", "accuracy_score": 90, "error_type": "None"},
                {"word": "world", "accuracy_score": 80, "error_type": "Mispronunciation"},
            ],
        }
    )
    return processor_mock
