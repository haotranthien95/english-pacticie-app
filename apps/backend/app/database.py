"""
Database connection and session management using SQLAlchemy
Provides database session dependency for FastAPI endpoints
"""
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import declarative_base
from typing import AsyncGenerator

from app.config import settings

# Convert synchronous database URL to async (postgresql:// -> postgresql+asyncpg://)
async_database_url = settings.database_url.replace("postgresql://", "postgresql+asyncpg://")

# Create async SQLAlchemy engine
engine = create_async_engine(
    async_database_url,
    pool_pre_ping=True,  # Verify connections before using
    pool_size=5,
    max_overflow=10,
    echo=settings.debug,  # Log SQL in debug mode
)

# Async session factory
AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)

# Base class for ORM models
Base = declarative_base()


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    FastAPI dependency that provides an async database session
    
    Usage:
        @app.get("/users")
        async def get_users(db: AsyncSession = Depends(get_db)):
            result = await db.execute(select(User))
            return result.scalars().all()
    
    Ensures session is closed after request completes
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


async def init_db() -> None:
    """
    Initialize database tables
    Call this on application startup or use Alembic migrations
    """
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
