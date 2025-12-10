"""
English Learning App - FastAPI Backend
Main application entry point with CORS, middleware, and exception handlers
"""
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, Response
from fastapi.exceptions import RequestValidationError
from contextlib import asynccontextmanager
from starlette.middleware.sessions import SessionMiddleware
import time

from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

from app.config import settings
from app.database import engine, Base
from app.utils.logging import configure_logging, get_logger
from app.utils.cache import close_redis
from app.core.exceptions import (
    ApplicationError,
    AuthenticationError,
    AuthorizationError,
    NotFoundError,
    ValidationError as AppValidationError,
    SpeechProcessingError,
    StorageError,
)

# Configure structured logging
configure_logging()
logger = get_logger(__name__)

# Initialize rate limiter with Redis backend
limiter = Limiter(
    key_func=get_remote_address,
    default_limits=["100/minute"],
    storage_uri=settings.redis_url,
)

# Prometheus metrics
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
)

REQUEST_DURATION = Histogram(
    "http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["method", "endpoint"],
)

DATABASE_OPERATIONS = Counter(
    "database_operations_total",
    "Total database operations",
    ["operation", "table"],
)

BUSINESS_EVENTS = Counter(
    "business_events_total",
    "Total business events",
    ["event_type"],
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    # Startup
    logger.info("startup", environment=settings.environment, debug=settings.debug)
    
    # Create database tables (for development only, use Alembic in production)
    if settings.debug:
        logger.info("creating_database_tables")
        Base.metadata.create_all(bind=engine)
    
    yield
    
    # Shutdown
    logger.info("shutting_down")
    await close_redis()

# Create FastAPI application
app = FastAPI(
    title="English Learning App API",
    description="Backend API for English pronunciation practice application",
    version="1.0.0",
    docs_url="/docs" if settings.debug else None,  # Disable docs in production
    redoc_url="/redoc" if settings.debug else None,
    lifespan=lifespan
)

# Attach rate limiter to app state
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Add rate limiting middleware
app.add_middleware(SlowAPIMiddleware)

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


# Request logging and metrics middleware
@app.middleware("http")
async def log_requests_and_metrics(request: Request, call_next):
    """Log all requests and record Prometheus metrics."""
    start_time = time.time()
    
    # Process request
    response = await call_next(request)
    
    # Calculate duration
    duration = time.time() - start_time
    
    # Record Prometheus metrics
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code,
    ).inc()
    
    REQUEST_DURATION.labels(
        method=request.method,
        endpoint=request.url.path,
    ).observe(duration)
    
    # Log request with structured logging
    logger.info(
        "request_completed",
        method=request.method,
        path=str(request.url.path),
        status_code=response.status_code,
        duration_ms=round(duration * 1000, 2),
    )
    
    return response

# Metrics endpoint for Prometheus
@app.get("/metrics", tags=["Monitoring"])
async def metrics():
    """
    Prometheus metrics endpoint.
    
    Returns metrics in Prometheus format for scraping by monitoring tools.
    """
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)


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
    logger.error(
        "unexpected_error",
        error=str(exc),
        path=str(request.url.path),
        method=request.method,
        exc_info=exc,
    )
    
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
from app.api.v1.admin import speeches as admin_speeches, tags as admin_tags, imports as admin_imports

# Mount API v1 routers
app.include_router(auth.router, prefix="/api/v1")
app.include_router(game.router, prefix="/api/v1")
app.include_router(speech.router, prefix="/api/v1")
app.include_router(users.router, prefix="/api/v1")

# Mount admin API routers
app.include_router(admin_speeches.router, prefix="/api/v1")
app.include_router(admin_tags.router, prefix="/api/v1")
app.include_router(admin_imports.router, prefix="/api/v1")

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
