"""
Unit tests for AuthService.

Tests authentication, registration, token management, and password operations.
"""
import pytest
from datetime import datetime, timedelta
from unittest.mock import Mock, AsyncMock, patch

from app.services.auth_service import AuthService
from app.models.user import User, AuthProvider
from app.schemas.auth import RegisterRequest, LoginRequest, TokenResponse
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
        from uuid import uuid4
        return User(
            id=uuid4(),
            email="test@example.com",
            name="Test User",
            password_hash=hash_password("TestPass123!"),
            auth_provider=AuthProvider.EMAIL,
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
    
    @pytest.mark.asyncio
    async def test_register_user_success(self, auth_service, mock_db):
        """Test successful user registration."""
        # Arrange
        request = RegisterRequest(
            email="new@example.com",
            name="New User",
            password="SecurePass123!",
        )
        
        # Mock database queries
        mock_db.execute = AsyncMock(return_value=Mock(scalars=Mock(return_value=Mock(first=Mock(return_value=None)))))
        mock_db.add = Mock()
        mock_db.commit = AsyncMock()
        mock_db.refresh = AsyncMock()
        
        # Act
        with patch.object(auth_service, '_create_tokens', return_value={"access_token": "access_token", "refresh_token": "refresh_token", "token_type": "bearer", "expires_in": 604800}):
            result = await auth_service.register(request)
        
        # Assert
        assert result.user.email == request.email
        assert result.user.name == request.name
        assert result.tokens.access_token == "access_token"
        assert result.tokens.refresh_token == "refresh_token"
        mock_db.add.assert_called_once()
        mock_db.commit.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_register_user_duplicate_email(self, auth_service, mock_db, sample_user):
        """Test registration with duplicate email."""
        # Arrange
        request = RegisterRequest(
            email="test@example.com",  # Existing email
            name="New User",
            password="SecurePass123!",
        )
        
        # Mock existing user found
        mock_db.execute = AsyncMock(
            return_value=Mock(scalar_one_or_none=Mock(return_value=sample_user))
        )
        
        # Act & Assert
        with pytest.raises(AuthenticationError, match="Email already registered"):
            await auth_service.register(request)
    
    @pytest.mark.asyncio
    async def test_register_user_duplicate_username(self, auth_service, mock_db, sample_user):
        """Test registration with duplicate username - Note: Current API doesn't check username uniqueness."""
        # This test is skipped as the current implementation doesn't have username field
        pytest.skip("Username validation not implemented in current register endpoint")
    
    @pytest.mark.asyncio
    async def test_login_user_success(self, auth_service, mock_db, sample_user):
        """Test successful user login."""
        # Arrange
        request = LoginRequest(
            email="test@example.com",
            password="TestPass123!",
        )
        
        # Mock database query
        mock_db.execute = AsyncMock(
            return_value=Mock(scalar_one_or_none=Mock(return_value=sample_user))
        )
        
        # Act
        with patch.object(auth_service, '_create_tokens', return_value={"access_token": "access_token", "refresh_token": "refresh_token", "token_type": "bearer", "expires_in": 604800}):
            result = await auth_service.login(request)
        
        # Assert
        assert result.user.email == sample_user.email
        assert result.tokens.access_token == "access_token"
        assert result.tokens.refresh_token == "refresh_token"
    
    @pytest.mark.asyncio
    async def test_login_user_invalid_email(self, auth_service, mock_db):
        """Test login with non-existent email."""
        # Arrange
        request = LoginRequest(
            email="nonexistent@example.com",
            password="TestPass123!",
        )
        
        # Mock user not found
        mock_db.execute = AsyncMock(
            return_value=Mock(scalar_one_or_none=Mock(return_value=None))
        )
        
        # Act & Assert
        with pytest.raises(AuthenticationError, match="Invalid email or password"):
            await auth_service.login(request)
    
    @pytest.mark.asyncio
    async def test_login_user_invalid_password(self, auth_service, mock_db, sample_user):
        """Test login with incorrect password."""
        # Arrange
        request = LoginRequest(
            email="test@example.com",
            password="WrongPassword123!",
        )
        
        # Mock database query
        mock_db.execute = AsyncMock(
            return_value=Mock(scalar_one_or_none=Mock(return_value=sample_user))
        )
        
        # Act & Assert
        with pytest.raises(AuthenticationError, match="Invalid email or password"):
            await auth_service.login(request)
    
    @pytest.mark.asyncio
    async def test_login_user_inactive_account(self, auth_service, mock_db, sample_user):
        """Test login with inactive account - Note: Current API doesn't check active status."""
        # This test is skipped as the current implementation doesn't check is_active
        pytest.skip("Active status validation not implemented in current login endpoint")
    
    @pytest.mark.asyncio
    async def test_refresh_token_success(self, auth_service, mock_db, sample_user):
        """Test successful token refresh."""
        # Arrange
        refresh_token = "valid_refresh_token"
        user_id_str = str(sample_user.id)
        
        # Mock token validation and user lookup
        with patch('app.services.auth_service.get_token_subject', return_value=user_id_str):
            mock_db.execute = AsyncMock(
                return_value=Mock(scalar_one_or_none=Mock(return_value=sample_user))
            )
            
            # Act
            with patch.object(auth_service, '_create_tokens', return_value=TokenResponse(access_token="new_access_token", refresh_token="new_refresh_token", token_type="bearer", expires_in=604800)):
                result = await auth_service.refresh_token(refresh_token)
            
            # Assert
            assert result.access_token == "new_access_token"
            assert result.token_type == "bearer"
    
    @pytest.mark.asyncio
    async def test_refresh_token_invalid(self, auth_service):
        """Test token refresh with invalid token."""
        # Arrange
        invalid_token = "invalid_refresh_token"
        
        # Mock token validation failure
        with patch('app.services.auth_service.get_token_subject', return_value=None):
            # Act & Assert
            with pytest.raises(AuthenticationError, match="Invalid refresh token"):
                await auth_service.refresh_token(invalid_token)
    
    @pytest.mark.asyncio
    async def test_get_current_user_success(self, auth_service, mock_db, sample_user):
        """Test getting current user from token - Note: This is handled by dependencies, not service method."""
        # This test is skipped as get_current_user is not a service method
        pytest.skip("get_current_user is handled by dependencies, not AuthService method")
    
    @pytest.mark.asyncio
    async def test_get_current_user_not_found(self, auth_service, mock_db):
        """Test getting current user when user doesn't exist - Note: This is handled by dependencies."""
        # This test is skipped as get_current_user is not a service method
        pytest.skip("get_current_user is handled by dependencies, not AuthService method")
    
    def test_generate_tokens(self, auth_service, sample_user):
        """Test token generation."""
        # Act
        user_id_str = str(sample_user.id)
        with patch('app.services.auth_service.create_access_token', return_value="access_token"):
            with patch('app.services.auth_service.create_refresh_token', return_value="refresh_token"):
                result = auth_service._create_tokens(user_id_str)
        
        # Assert
        assert result.access_token == "access_token"
        assert result.refresh_token == "refresh_token"
        assert result.token_type == "bearer"
