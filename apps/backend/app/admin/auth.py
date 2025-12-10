"""
SQLAdmin authentication backend for admin panel.

Provides session-based authentication with bcrypt password verification.
Credentials stored in environment variables (ADMIN_USERNAME, ADMIN_PASSWORD_HASH).
"""
from typing import Optional

from fastapi import Request
from passlib.context import CryptContext
from sqladmin.authentication import AuthenticationBackend

from app.config import settings


# Password context for bcrypt verification
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class AdminAuth(AuthenticationBackend):
    """
    Authentication backend for SQLAdmin panel.
    
    Features:
    - Session-based authentication (separate from user JWT)
    - Bcrypt password verification
    - Admin credentials from environment variables
    - Simple single-admin setup for MVP
    
    Usage:
        admin = Admin(
            app, 
            engine, 
            authentication_backend=AdminAuth(secret_key=settings.JWT_SECRET_KEY)
        )
    
    Environment Variables:
        ADMIN_USERNAME: Admin login username (default: "admin")
        ADMIN_PASSWORD_HASH: Bcrypt hash of admin password
        
    Generate password hash:
        python -c "from passlib.context import CryptContext; print(CryptContext(schemes=['bcrypt']).hash('your_password'))"
    """
    
    def __init__(self, secret_key: str):
        """
        Initialize admin authentication backend.
        
        Args:
            secret_key: Secret key for session signing (use JWT_SECRET_KEY)
        """
        super().__init__(secret_key)
    
    async def login(self, request: Request) -> bool:
        """
        Authenticate admin user credentials.
        
        Args:
            request: FastAPI request with form data (username, password)
            
        Returns:
            True if authentication successful, False otherwise
        """
        form = await request.form()
        username = form.get("username")
        password = form.get("password")
        
        # Validate credentials exist
        if not username or not password:
            return False
        
        # Check username matches
        if username != settings.admin_username:
            return False
        
        # Verify password against bcrypt hash
        try:
            if pwd_context.verify(password, settings.admin_password_hash):
                # Store admin user in session
                request.session["admin_user"] = username
                return True
        except Exception:
            # Invalid hash format or verification error
            return False
        
        return False
    
    async def logout(self, request: Request) -> bool:
        """
        Logout admin user by clearing session.
        
        Args:
            request: FastAPI request
            
        Returns:
            True always (logout always succeeds)
        """
        request.session.clear()
        return True
    
    async def authenticate(self, request: Request) -> Optional[bool]:
        """
        Check if admin user is authenticated.
        
        Args:
            request: FastAPI request
            
        Returns:
            True if authenticated, False otherwise
        """
        # Check if admin_user exists in session
        return "admin_user" in request.session


# Helper function to generate password hash for .env file
def generate_password_hash(password: str) -> str:
    """
    Generate bcrypt hash for admin password.
    
    Usage:
        from app.admin.auth import generate_password_hash
        hash = generate_password_hash("my_secure_password")
        # Add to .env: ADMIN_PASSWORD_HASH=<hash>
    
    Args:
        password: Plain text password
        
    Returns:
        Bcrypt hash string (starts with $2b$)
    """
    return pwd_context.hash(password)
