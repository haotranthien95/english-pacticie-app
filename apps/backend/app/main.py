"""
English Learning App - FastAPI Backend
Main application entry point with CORS, middleware, and exception handlers
"""
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from contextlib import asynccontextmanager
from starlette.middleware.sessions import SessionMiddleware
import logging

from app.config import settings
from app.database import engine, Base
from app.core.exceptions import (
    ApplicationError,
    AuthenticationError,
    AuthorizationError,
    NotFoundError,
    ValidationError as AppValidationError,
    SpeechProcessingError,
    StorageError,
)

# Configure logging
logging.basicConfig(
    level=logging.DEBUG if settings.debug else logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    # Startup
    logger.info("Starting up English Learning App API...")
    logger.info(f"Environment: {settings.environment}")
    logger.info(f"Debug mode: {settings.debug}")
    
    # Create database tables (for development only, use Alembic in production)
    if settings.debug:
        logger.info("Creating database tables...")
        Base.metadata.create_all(bind=engine)
    
    yield
    
    # Shutdown
    logger.info("Shutting down...")


# Create FastAPI application
app = FastAPI(
    title="English Learning App API",
    description="Backend API for English pronunciation practice application",
    version="1.0.0",
    docs_url="/docs" if settings.debug else None,  # Disable docs in production
    redoc_url="/redoc" if settings.debug else None,
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add session middleware for SQLAdmin authentication
app.add_middleware(
    SessionMiddleware,
    secret_key=settings.jwt_secret_key,
    session_cookie="admin_session",
    max_age=3600 * 24,  # 24 hours
)


# Global exception handlers
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle request validation errors"""
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "detail": "Validation error",
            "errors": exc.errors()
        }
    )


@app.exception_handler(AuthenticationError)
async def authentication_exception_handler(request: Request, exc: AuthenticationError):
    """Handle authentication errors"""
    return JSONResponse(
        status_code=status.HTTP_401_UNAUTHORIZED,
        content={"detail": exc.message, **exc.details}
    )


@app.exception_handler(AuthorizationError)
async def authorization_exception_handler(request: Request, exc: AuthorizationError):
    """Handle authorization errors"""
    return JSONResponse(
        status_code=status.HTTP_403_FORBIDDEN,
        content={"detail": exc.message, **exc.details}
    )


@app.exception_handler(NotFoundError)
async def not_found_exception_handler(request: Request, exc: NotFoundError):
    """Handle not found errors"""
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={"detail": exc.message, **exc.details}
    )


@app.exception_handler(AppValidationError)
async def app_validation_exception_handler(request: Request, exc: AppValidationError):
    """Handle application validation errors"""
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={"detail": exc.message, **exc.details}
    )


@app.exception_handler(SpeechProcessingError)
async def speech_processing_exception_handler(request: Request, exc: SpeechProcessingError):
    """Handle speech processing errors"""
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={"detail": exc.message, **exc.details}
    )


@app.exception_handler(StorageError)
async def storage_exception_handler(request: Request, exc: StorageError):
    """Handle storage errors"""
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": exc.message, **exc.details}
    )


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handle unexpected errors"""
    logger.error(f"Unexpected error: {exc}", exc_info=True)
    
    if settings.debug:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "detail": "Internal server error",
                "error": str(exc)
            }
        )
    
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Internal server error"}
    )


# Health check endpoint
@app.get("/health", tags=["Health"])
async def health_check():
    """
    Health check endpoint
    Returns OK if the service is running
    """
    return {
        "status": "ok",
        "environment": settings.environment,
        "version": "1.0.0"
    }


# Root endpoint
@app.get("/", tags=["Root"])
async def root():
    """
    Root endpoint
    Returns API information
    """
    return {
        "message": "English Learning App API",
        "version": "1.0.0",
        "docs": "/docs" if settings.debug else None
    }


# Import and include routers
from app.api.v1 import auth, game, speech, users
from app.api.v1.admin import speeches as admin_speeches, tags as admin_tags

# Mount API v1 routers
app.include_router(auth.router, prefix="/api/v1")
app.include_router(game.router, prefix="/api/v1")
app.include_router(speech.router, prefix="/api/v1")
app.include_router(users.router, prefix="/api/v1")

# Mount admin API routers
app.include_router(admin_speeches.router, prefix="/api/v1")
app.include_router(admin_tags.router, prefix="/api/v1")

# Mount SQLAdmin panel
from sqladmin import Admin
from app.admin.auth import AdminAuth
from app.admin.views import SpeechAdmin, TagAdmin, UserAdmin, GameSessionAdmin

admin = Admin(
    app,
    engine,
    authentication_backend=AdminAuth(secret_key=settings.jwt_secret_key),
    title="English Learning Admin",
    base_url="/admin",
)

# Add model views to admin panel
admin.add_view(SpeechAdmin)
admin.add_view(TagAdmin)
admin.add_view(UserAdmin)
admin.add_view(GameSessionAdmin)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug
    )
