"""
Structured logging configuration with structlog.

Provides JSON-formatted logging with request IDs, user context,
and structured fields for better log analysis and monitoring.
"""
import logging
import sys
from typing import Any, Dict

import structlog
from structlog.types import EventDict, WrappedLogger

from app.config import settings


def add_app_context(logger: WrappedLogger, method_name: str, event_dict: EventDict) -> EventDict:
    """
    Add application context to log events.
    
    Adds:
    - environment: development/production
    - app_name: English Learning App API
    """
    event_dict["environment"] = settings.environment
    event_dict["app_name"] = "english-learning-api"
    return event_dict


def configure_logging() -> None:
    """
    Configure structured logging with structlog.
    
    Call this function during application startup.
    
    Processors:
    - add_log_level: Add log level to output
    - add_timestamp: Add ISO timestamp
    - format_exc_info: Format exception tracebacks
    - add_app_context: Add application context
    - JSONRenderer: Render logs as JSON (production)
    - ConsoleRenderer: Pretty-print logs (development)
    """
    # Determine renderer based on environment
    if settings.environment == "production":
        renderer = structlog.processors.JSONRenderer()
    else:
        renderer = structlog.dev.ConsoleRenderer(colors=True)
    
    # Configure structlog
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            add_app_context,
            renderer,
        ],
        wrapper_class=structlog.stdlib.BoundLogger,
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )
    
    # Configure stdlib logging
    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=logging.DEBUG if settings.debug else logging.INFO,
    )


def get_logger(name: str = None) -> structlog.stdlib.BoundLogger:
    """
    Get structured logger instance.
    
    Args:
        name: Logger name (usually __name__)
        
    Returns:
        Structured logger with context support
        
    Example:
        logger = get_logger(__name__)
        logger.info("user_registered", user_id=user.id, email=user.email)
    """
    return structlog.get_logger(name)


def log_request(
    method: str,
    path: str,
    status_code: int,
    duration_ms: float,
    user_id: str = None,
) -> None:
    """
    Log HTTP request with structured fields.
    
    Args:
        method: HTTP method (GET, POST, etc.)
        path: Request path
        status_code: HTTP status code
        duration_ms: Request duration in milliseconds
        user_id: Optional user ID for authenticated requests
    """
    logger = get_logger("api.request")
    
    log_data = {
        "method": method,
        "path": path,
        "status_code": status_code,
        "duration_ms": duration_ms,
    }
    
    if user_id:
        log_data["user_id"] = user_id
    
    # Determine log level based on status code
    if status_code >= 500:
        logger.error("request_completed", **log_data)
    elif status_code >= 400:
        logger.warning("request_completed", **log_data)
    else:
        logger.info("request_completed", **log_data)


def log_database_query(
    query_type: str,
    table: str,
    duration_ms: float,
    rows_affected: int = None,
) -> None:
    """
    Log database query with structured fields.
    
    Args:
        query_type: Query type (SELECT, INSERT, UPDATE, DELETE)
        table: Table name
        duration_ms: Query duration in milliseconds
        rows_affected: Number of rows affected (for INSERT/UPDATE/DELETE)
    """
    logger = get_logger("database")
    
    log_data = {
        "query_type": query_type,
        "table": table,
        "duration_ms": duration_ms,
    }
    
    if rows_affected is not None:
        log_data["rows_affected"] = rows_affected
    
    logger.debug("database_query", **log_data)


def log_external_api_call(
    service: str,
    endpoint: str,
    method: str,
    status_code: int,
    duration_ms: float,
    error: str = None,
) -> None:
    """
    Log external API call with structured fields.
    
    Args:
        service: Service name (azure_speech, minio, etc.)
        endpoint: API endpoint
        method: HTTP method
        status_code: HTTP status code
        duration_ms: Request duration in milliseconds
        error: Error message if request failed
    """
    logger = get_logger("external_api")
    
    log_data = {
        "service": service,
        "endpoint": endpoint,
        "method": method,
        "status_code": status_code,
        "duration_ms": duration_ms,
    }
    
    if error:
        log_data["error"] = error
        logger.error("external_api_call", **log_data)
    else:
        logger.info("external_api_call", **log_data)


def log_business_event(
    event_type: str,
    user_id: str = None,
    **kwargs: Any,
) -> None:
    """
    Log business event with structured fields.
    
    Args:
        event_type: Event type (user_registered, game_completed, etc.)
        user_id: Optional user ID
        **kwargs: Additional event-specific fields
    """
    logger = get_logger("business")
    
    log_data = {"event_type": event_type}
    
    if user_id:
        log_data["user_id"] = user_id
    
    log_data.update(kwargs)
    
    logger.info("business_event", **log_data)


def log_security_event(
    event_type: str,
    ip_address: str = None,
    user_id: str = None,
    **kwargs: Any,
) -> None:
    """
    Log security event with structured fields.
    
    Args:
        event_type: Event type (login_failed, rate_limit_exceeded, etc.)
        ip_address: Client IP address
        user_id: Optional user ID
        **kwargs: Additional event-specific fields
    """
    logger = get_logger("security")
    
    log_data = {"event_type": event_type}
    
    if ip_address:
        log_data["ip_address"] = ip_address
    
    if user_id:
        log_data["user_id"] = user_id
    
    log_data.update(kwargs)
    
    logger.warning("security_event", **log_data)
