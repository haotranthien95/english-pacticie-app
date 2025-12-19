import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Application-wide logger utility
/// Provides structured logging with different levels and proper formatting
class AppLogger {
  static Logger? _logger;

  /// Initialize the logger with custom configuration
  static void initialize({
    Level level = Level.debug,
    bool printTime = true,
    bool printEmojis = true,
    int methodCount = 0,
    int errorMethodCount = 8,
    int lineLength = 120,
  }) {
    _logger = Logger(
      filter: _CustomLogFilter(),
      printer: PrettyPrinter(
        methodCount: methodCount,
        errorMethodCount: errorMethodCount,
        lineLength: lineLength,
        colors: true,
        printEmojis: printEmojis,
        printTime: printTime,
      ),
      level: level,
    );

    info('Logger initialized at level: ${level.name}');
  }

  /// Get logger instance, creating default if not initialized
  static Logger get instance {
    _logger ??= Logger(
      filter: _CustomLogFilter(),
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );
    return _logger!;
  }

  /// Log debug message
  /// Use for detailed diagnostic information
  static void debug(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    DateTime? time,
  }) {
    instance.d(
      message,
      error: error,
      stackTrace: stackTrace,
      time: time,
    );
  }

  /// Log info message
  /// Use for general informational messages
  static void info(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    DateTime? time,
  }) {
    instance.i(
      message,
      error: error,
      stackTrace: stackTrace,
      time: time,
    );
  }

  /// Log warning message
  /// Use for potentially harmful situations
  static void warning(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    DateTime? time,
  }) {
    instance.w(
      message,
      error: error,
      stackTrace: stackTrace,
      time: time,
    );
  }

  /// Log error message
  /// Use for error events that might still allow the app to continue
  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    DateTime? time,
  }) {
    instance.e(
      message,
      error: error,
      stackTrace: stackTrace,
      time: time,
    );
  }

  /// Log fatal/wtf message
  /// Use for severe errors that will prevent normal app execution
  static void fatal(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    DateTime? time,
  }) {
    instance.f(
      message,
      error: error,
      stackTrace: stackTrace,
      time: time,
    );
  }

  /// Log trace message
  /// Use for very detailed diagnostic information
  static void trace(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    DateTime? time,
  }) {
    instance.t(
      message,
      error: error,
      stackTrace: stackTrace,
      time: time,
    );
  }

  /// Close and cleanup the logger
  static void close() {
    _logger?.close();
    _logger = null;
  }
}

/// Custom log filter that respects debug/release mode
class _CustomLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In release mode, only log warnings and above
    if (kReleaseMode) {
      return event.level.index >= Level.warning.index;
    }
    // In debug mode, log everything
    return true;
  }
}

/// Extension for logging with context
extension LoggerContext on AppLogger {
  /// Log with a specific tag/context
  static void logWithTag(
    String tag,
    String message, {
    Level level = Level.info,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    final taggedMessage = '[$tag] $message';

    switch (level) {
      case Level.trace:
        AppLogger.trace(taggedMessage, error: error, stackTrace: stackTrace);
        break;
      case Level.debug:
        AppLogger.debug(taggedMessage, error: error, stackTrace: stackTrace);
        break;
      case Level.info:
        AppLogger.info(taggedMessage, error: error, stackTrace: stackTrace);
        break;
      case Level.warning:
        AppLogger.warning(taggedMessage, error: error, stackTrace: stackTrace);
        break;
      case Level.error:
        AppLogger.error(taggedMessage, error: error, stackTrace: stackTrace);
        break;
      case Level.fatal:
        AppLogger.fatal(taggedMessage, error: error, stackTrace: stackTrace);
        break;
      default:
        AppLogger.info(taggedMessage, error: error, stackTrace: stackTrace);
    }
  }
}
