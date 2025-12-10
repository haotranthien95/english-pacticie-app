"""
Redis caching utilities for FastAPI endpoints.

Provides decorators and utilities for caching function results in Redis
to reduce database load and improve API response times.
"""
import functools
import hashlib
import json
from typing import Any, Callable, Optional

import redis.asyncio as redis
from redis.asyncio import Redis

from app.config import settings


# Global Redis client instance
_redis_client: Optional[Redis] = None


async def get_redis() -> Redis:
    """
    Get Redis client instance (singleton).
    
    Returns:
        Redis client for caching operations
    """
    global _redis_client
    
    if _redis_client is None:
        _redis_client = redis.from_url(
            settings.redis_url,
            encoding="utf-8",
            decode_responses=True,
        )
    
    return _redis_client


async def close_redis() -> None:
    """Close Redis connection."""
    global _redis_client
    
    if _redis_client:
        await _redis_client.close()
        _redis_client = None


def cache_key(*args, **kwargs) -> str:
    """
    Generate cache key from function arguments.
    
    Args:
        *args: Positional arguments
        **kwargs: Keyword arguments
        
    Returns:
        MD5 hash of serialized arguments
    """
    # Serialize arguments
    key_data = {
        "args": args,
        "kwargs": kwargs,
    }
    
    key_str = json.dumps(key_data, sort_keys=True, default=str)
    return hashlib.md5(key_str.encode(), usedforsecurity=False).hexdigest()  # nosec B324 - Cache key only, not cryptographic


def cached(
    prefix: str,
    ttl: int = 300,
    key_builder: Optional[Callable] = None,
) -> Callable:
    """
    Decorator to cache async function results in Redis.
    
    Args:
        prefix: Cache key prefix (e.g., "speeches", "tags")
        ttl: Time-to-live in seconds (default: 5 minutes)
        key_builder: Optional custom key builder function
        
    Returns:
        Decorated function with caching
        
    Example:
        @cached(prefix="tag_list", ttl=3600)
        async def get_all_tags(db: AsyncSession):
            # This result will be cached for 1 hour
            return await db.execute(select(Tag))
    """
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        async def wrapper(*args, **kwargs) -> Any:
            # Get Redis client
            redis_client = await get_redis()
            
            # Build cache key
            if key_builder:
                suffix = key_builder(*args, **kwargs)
            else:
                suffix = cache_key(*args, **kwargs)
            
            cache_key_str = f"{prefix}:{suffix}"
            
            # Try to get from cache
            try:
                cached_value = await redis_client.get(cache_key_str)
                if cached_value:
                    # Cache hit
                    return json.loads(cached_value)
            except Exception:
                # Cache miss or error - continue to function call
                pass
            
            # Cache miss - call function
            result = await func(*args, **kwargs)
            
            # Store in cache
            try:
                await redis_client.setex(
                    cache_key_str,
                    ttl,
                    json.dumps(result, default=str),
                )
            except Exception:
                # Cache write error - log but don't fail
                pass
            
            return result
        
        return wrapper
    return decorator


async def invalidate_cache(prefix: str, pattern: Optional[str] = None) -> int:
    """
    Invalidate cache keys by prefix and optional pattern.
    
    Args:
        prefix: Cache key prefix to invalidate
        pattern: Optional glob pattern (e.g., "*", "user:*")
        
    Returns:
        Number of keys deleted
        
    Example:
        # Invalidate all tag caches
        await invalidate_cache("tags")
        
        # Invalidate specific user cache
        await invalidate_cache("user", "123")
    """
    redis_client = await get_redis()
    
    # Build search pattern
    if pattern:
        search_pattern = f"{prefix}:{pattern}"
    else:
        search_pattern = f"{prefix}:*"
    
    # Find matching keys
    deleted_count = 0
    async for key in redis_client.scan_iter(match=search_pattern, count=100):
        await redis_client.delete(key)
        deleted_count += 1
    
    return deleted_count


async def invalidate_all_cache() -> int:
    """
    Invalidate all cache keys.
    
    Warning: Use with caution! This clears the entire cache.
    
    Returns:
        Number of keys deleted
    """
    redis_client = await get_redis()
    
    deleted_count = 0
    async for key in redis_client.scan_iter(match="*", count=100):
        await redis_client.delete(key)
        deleted_count += 1
    
    return deleted_count


async def get_cache_stats() -> dict:
    """
    Get Redis cache statistics.
    
    Returns:
        Dictionary with cache statistics
    """
    redis_client = await get_redis()
    
    # Get info from Redis
    info = await redis_client.info("stats")
    
    return {
        "hits": info.get("keyspace_hits", 0),
        "misses": info.get("keyspace_misses", 0),
        "hit_rate": (
            info.get("keyspace_hits", 0) /
            (info.get("keyspace_hits", 0) + info.get("keyspace_misses", 1))
        ) * 100,
        "keys_total": await redis_client.dbsize(),
    }


# Cache key builders for common patterns


def user_cache_key(user_id: str) -> str:
    """Build cache key for user data."""
    return f"user:{user_id}"


def speech_list_cache_key(level: Optional[str] = None, type: Optional[str] = None, tags: Optional[str] = None) -> str:
    """Build cache key for speech list queries."""
    parts = []
    if level:
        parts.append(f"level:{level}")
    if type:
        parts.append(f"type:{type}")
    if tags:
        parts.append(f"tags:{tags}")
    
    return ":".join(parts) if parts else "all"


def tag_list_cache_key(category: Optional[str] = None) -> str:
    """Build cache key for tag list queries."""
    return f"category:{category}" if category else "all"
