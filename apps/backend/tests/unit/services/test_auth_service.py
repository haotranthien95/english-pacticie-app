"""
Unit tests for AuthService.

Tests authentication, registration, token management, and password operations.
"""
import pytest
from datetime import datetime, timedelta
from unittest.mock import Mock, AsyncMock, patch

from app.services.auth_service import AuthService
from app.models.user import User
from app.schemas.auth import UserRegisterRequest, UserLoginRequest
from app.core.exceptions import AuthenticationError, ValidationError
from app.core.security import hash_password


class TestAuthService:
    """Test suite for AuthService."""
    
    @pytest.fixture
    def mock_db(self):
        """Mock database session."""
        return AsyncMock()
    
    @pytest.fixture
    def auth_service(self, mock_db):
        """AuthService instance with mocked dependencies."""
        return AuthService(mock_db)
    
    @pytest.fixture
    def sample_user(self):
        """Sample user for testing."""
        return User(
            id=1,
            email="test@example.com",
            username="testuser",
            hashed_password=hash_password("TestPass123!"),
            is_active=True,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
    
    @pytest.mark.asyncio
    async def test_register_user_success(self, auth_service, mock_db):
        """Test successful user registration."""
        # Arrange
        request = UserRegisterRequest(
            email="new@example.com",
            username="newuser",
            password="SecurePass123!",
        )
        
        # Mock database queries
        mock_db.execute = AsyncMock(return_value=Mock(scalars=Mock(return_value=Mock(first=Mock(return_value=None)))))
        mock_db.add = Mock()
        mock_db.commit = AsyncMock()
        mock_db.refresh = AsyncMock()
        
        # Act
        with patch.object(auth_service, '_generate_tokens', return_value=("access_token", "refresh_token")):
            result = await auth_service.register_user(request)
        
        # Assert
        assert result["user"]["email"] == request.email
        assert result["user"]["username"] == request.username
        assert "access_token" in result
        assert "refresh_token" in result
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_register_user_duplicate_email(self, auth_service, mock_db, sample_user):
        """Test registration with duplicate email."""
        # Arrange
        request = UserRegisterRequest(
            email="test@example.com",  # Existing email
            username="newuser",
            password="SecurePass123!",
        )
        
        # Mock existing user found
        mock_db.execute = AsyncMock(
            return_value=Mock(scalars=Mock(return_value=Mock(first=Mock(return_value=sample_user))))
        )
        
        # Act & Assert
        with pytest.raises(ValidationError, match="Email already registered"):
            await auth_service.register_user(request)
    
    @pytest.mark.asyncio
    async def test_register_user_duplicate_username(self, auth_service, mock_db, sample_user):
        """Test registration with duplicate username."""
        # Arrange
        request = UserRegisterRequest(
            email="new@example.com",
            username="testuser",  # Existing username
            password="SecurePass123!",
        )
        
        # Mock existing user found (first call returns None for email, second returns user for username)
        mock_db.execute = AsyncMock(
            side_effect=[
                Mock(scalars=Mock(return_value=Mock(first=Mock(return_value=None)))),  # Email check
                Mock(scalars=Mock(return_value=Mock(first=Mock(return_value=sample_user)))),  # Username check
            ]
        )
        
        # Act & Assert
        with pytest.raises(ValidationError, match="Username already taken"):
            await auth_service.register_user(request)
    
    @pytest.mark.asyncio
    async def test_login_user_success(self, auth_service, mock_db, sample_user):
        """Test successful user login."""
        # Arrange
        request = UserLoginRequest(
            email="test@example.com",
            password="TestPass123!",
        )
        
        # Mock database query
        mock_db.execute = AsyncMock(
            return_value=Mock(scalars=Mock(return_value=Mock(first=Mock(return_value=sample_user))))
        )
        
        # Act
        with patch.object(auth_service, '_generate_tokens', return_value=("access_token", "refresh_token")):
            result = await auth_service.login_user(request)
        
        # Assert
        assert result["user"]["email"] == sample_user.email
        assert result["user"]["username"] == sample_user.username
        assert "access_token" in result
        assert "refresh_token" in result
    
    @pytest.mark.asyncio
    async def test_login_user_invalid_email(self, auth_service, mock_db):
        """Test login with non-existent email."""
        # Arrange
        request = UserLoginRequest(
            email="nonexistent@example.com",
            password="TestPass123!",
        )
        
        # Mock user not found
        mock_db.execute = AsyncMock(
            return_value=Mock(scalars=Mock(return_value=Mock(first=Mock(return_value=None))))
        )
        
        # Act & Assert
        with pytest.raises(AuthenticationError, match="Invalid credentials"):
            await auth_service.login_user(request)
    
    @pytest.mark.asyncio
    async def test_login_user_invalid_password(self, auth_service, mock_db, sample_user):
        """Test login with incorrect password."""
        # Arrange
        request = UserLoginRequest(
            email="test@example.com",
            password="WrongPassword123!",
        )
        
        # Mock database query
        mock_db.execute = AsyncMock(
            return_value=Mock(scalars=Mock(return_value=Mock(first=Mock(return_value=sample_user))))
        )
        
        # Act & Assert
        with pytest.raises(AuthenticationError, match="Invalid credentials"):
            await auth_service.login_user(request)
    
    @pytest.mark.asyncio
    async def test_login_user_inactive_account(self, auth_service, mock_db, sample_user):
        """Test login with inactive account."""
        # Arrange
        sample_user.is_active = False
        request = UserLoginRequest(
            email="test@example.com",
            password="TestPass123!",
        )
        
        # Mock database query
        mock_db.execute = AsyncMock(
            return_value=Mock(scalars=Mock(return_value=Mock(first=Mock(return_value=sample_user))))
        )
        
        # Act & Assert
        with pytest.raises(AuthenticationError, match="Account is inactive"):
            await auth_service.login_user(request)
    
    @pytest.mark.asyncio
    async def test_refresh_token_success(self, auth_service, mock_db, sample_user):
        """Test successful token refresh."""
        # Arrange
        refresh_token = "valid_refresh_token"
        
        # Mock token validation and user lookup
        with patch('app.services.auth_service.verify_token', return_value={"user_id": 1}):
            mock_db.execute = AsyncMock(
                return_value=Mock(scalars=Mock(return_value=Mock(first=Mock(return_value=sample_user))))
            )
            
            # Act
            with patch.object(auth_service, '_generate_access_token', return_value="new_access_token"):
                result = await auth_service.refresh_access_token(refresh_token)
            
            # Assert
            assert result["access_token"] == "new_access_token"
            assert result["token_type"] == "bearer"
    
    @pytest.mark.asyncio
    async def test_refresh_token_invalid(self, auth_service):
        """Test token refresh with invalid token."""
        # Arrange
        invalid_token = "invalid_refresh_token"
        
        # Mock token validation failure
        with patch('app.services.auth_service.verify_token', side_effect=AuthenticationError("Invalid token")):
            # Act & Assert
            with pytest.raises(AuthenticationError, match="Invalid token"):
                await auth_service.refresh_access_token(invalid_token)
    
    @pytest.mark.asyncio
    async def test_get_current_user_success(self, auth_service, mock_db, sample_user):
        """Test getting current user from token."""
        # Arrange
        access_token = "valid_access_token"
        
        # Mock token validation and user lookup
        with patch('app.services.auth_service.verify_token', return_value={"user_id": 1}):
            mock_db.execute = AsyncMock(
                return_value=Mock(scalars=Mock(return_value=Mock(first=Mock(return_value=sample_user))))
            )
            
            # Act
            result = await auth_service.get_current_user(access_token)
            
            # Assert
            assert result.id == sample_user.id
            assert result.email == sample_user.email
    
    @pytest.mark.asyncio
    async def test_get_current_user_not_found(self, auth_service, mock_db):
        """Test getting current user when user doesn't exist."""
        # Arrange
        access_token = "valid_access_token"
        
        # Mock token validation but user not found
        with patch('app.services.auth_service.verify_token', return_value={"user_id": 999}):
            mock_db.execute = AsyncMock(
                return_value=Mock(scalars=Mock(return_value=Mock(first=Mock(return_value=None))))
            )
            
            # Act & Assert
            with pytest.raises(AuthenticationError, match="User not found"):
                await auth_service.get_current_user(access_token)
    
    def test_generate_tokens(self, auth_service, sample_user):
        """Test token generation."""
        # Act
        with patch('app.services.auth_service.create_access_token', return_value="access_token"):
            with patch('app.services.auth_service.create_refresh_token', return_value="refresh_token"):
                access_token, refresh_token = auth_service._generate_tokens(sample_user)
        
        # Assert
        assert access_token == "access_token"
        assert refresh_token == "refresh_token"
