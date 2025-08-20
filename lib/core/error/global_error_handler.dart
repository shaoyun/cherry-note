import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'exceptions.dart';
import 'failures.dart';

/// Global error handler service for managing application-wide errors
class GlobalErrorHandler {
  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();
  factory GlobalErrorHandler() => _instance;
  GlobalErrorHandler._internal();

  final StreamController<AppError> _errorController = StreamController<AppError>.broadcast();
  
  /// Stream of application errors
  Stream<AppError> get errorStream => _errorController.stream;

  /// Initialize global error handling
  static void initialize() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      GlobalErrorHandler().handleError(
        AppError.fromFlutterError(details),
        stackTrace: details.stack,
      );
    };

    // Handle errors outside of Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      GlobalErrorHandler().handleError(
        AppError.fromException(error),
        stackTrace: stack,
      );
      return true;
    };
  }

  /// Handle an error with optional context and stack trace
  void handleError(
    AppError error, {
    String? context,
    StackTrace? stackTrace,
    bool shouldNotifyUser = true,
  }) {
    // Log the error
    _logError(error, context: context, stackTrace: stackTrace);

    // Add to error stream for UI handling
    if (shouldNotifyUser) {
      _errorController.add(error);
    }

    // Report to crash analytics in release mode
    if (kReleaseMode) {
      _reportToCrashlytics(error, context: context, stackTrace: stackTrace);
    }
  }

  /// Handle exceptions and convert them to AppError
  void handleException(
    Exception exception, {
    String? context,
    StackTrace? stackTrace,
    bool shouldNotifyUser = true,
  }) {
    final appError = AppError.fromException(exception);
    handleError(
      appError,
      context: context,
      stackTrace: stackTrace,
      shouldNotifyUser: shouldNotifyUser,
    );
  }

  /// Handle failures and convert them to AppError
  void handleFailure(
    Failure failure, {
    String? context,
    StackTrace? stackTrace,
    bool shouldNotifyUser = true,
  }) {
    final appError = AppError.fromFailure(failure);
    handleError(
      appError,
      context: context,
      stackTrace: stackTrace,
      shouldNotifyUser: shouldNotifyUser,
    );
  }

  void _logError(
    AppError error, {
    String? context,
    StackTrace? stackTrace,
  }) {
    final contextInfo = context != null ? ' [Context: $context]' : '';
    final message = '${error.severity.name.toUpperCase()}: ${error.message}$contextInfo';
    
    switch (error.severity) {
      case ErrorSeverity.low:
        developer.log(message, name: 'AppError', level: 800);
        break;
      case ErrorSeverity.medium:
        developer.log(message, name: 'AppError', level: 900, stackTrace: stackTrace);
        break;
      case ErrorSeverity.high:
        developer.log(message, name: 'AppError', level: 1000, stackTrace: stackTrace);
        break;
      case ErrorSeverity.critical:
        developer.log(message, name: 'AppError', level: 1200, stackTrace: stackTrace);
        break;
    }
  }

  void _reportToCrashlytics(
    AppError error, {
    String? context,
    StackTrace? stackTrace,
  }) {
    // TODO: Implement crash analytics reporting
    // This would integrate with services like Firebase Crashlytics
    // or other error reporting services
  }

  /// Dispose resources
  void dispose() {
    _errorController.close();
  }
}

/// Represents an application error with severity and user-friendly message
class AppError {
  final String message;
  final String? technicalMessage;
  final String? code;
  final ErrorSeverity severity;
  final ErrorCategory category;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  AppError({
    required this.message,
    this.technicalMessage,
    this.code,
    required this.severity,
    required this.category,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create AppError from Exception
  factory AppError.fromException(Object exception) {
    if (exception is AppException) {
      return AppError(
        message: _getUserFriendlyMessage(exception),
        technicalMessage: exception.message,
        code: exception.code,
        severity: _getSeverityFromException(exception),
        category: _getCategoryFromException(exception),
      );
    }

    return AppError(
      message: '发生了未知错误，请稍后重试',
      technicalMessage: exception.toString(),
      severity: ErrorSeverity.medium,
      category: ErrorCategory.unknown,
    );
  }

  /// Create AppError from Failure
  factory AppError.fromFailure(Failure failure) {
    return AppError(
      message: _getUserFriendlyMessage(failure),
      technicalMessage: failure.message,
      code: failure.code,
      severity: _getSeverityFromFailure(failure),
      category: _getCategoryFromFailure(failure),
    );
  }

  /// Create AppError from FlutterErrorDetails
  factory AppError.fromFlutterError(FlutterErrorDetails details) {
    return AppError(
      message: '界面显示出现问题，请重启应用',
      technicalMessage: details.toString(),
      severity: ErrorSeverity.high,
      category: ErrorCategory.ui,
      metadata: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );
  }

  static String _getUserFriendlyMessage(Object error) {
    if (error is NetworkException || error is NetworkFailure) {
      return '网络连接失败，请检查网络设置后重试';
    } else if (error is StorageException || error is StorageFailure) {
      return '存储操作失败，请检查存储空间或权限';
    } else if (error is SyncException || error is SyncFailure) {
      return '同步失败，请检查网络连接和存储配置';
    } else if (error is AuthenticationException || error is AuthenticationFailure) {
      return '身份验证失败，请检查登录凭据';
    } else if (error is ValidationException || error is ValidationFailure) {
      return '输入数据格式不正确，请检查后重试';
    } else if (error is FileSystemException || error is FileSystemFailure) {
      return '文件操作失败，请检查文件权限';
    } else if (error is ParseException || error is ParseFailure) {
      return '数据解析失败，文件可能已损坏';
    } else if (error is ConflictException || error is ConflictFailure) {
      return '检测到数据冲突，需要手动解决';
    }
    
    return '操作失败，请稍后重试';
  }

  static ErrorSeverity _getSeverityFromException(AppException exception) {
    if (exception is NetworkException) return ErrorSeverity.medium;
    if (exception is StorageException) return ErrorSeverity.high;
    if (exception is SyncException) return ErrorSeverity.medium;
    if (exception is AuthenticationException) return ErrorSeverity.high;
    if (exception is ValidationException) return ErrorSeverity.low;
    if (exception is FileSystemException) return ErrorSeverity.medium;
    if (exception is ParseException) return ErrorSeverity.medium;
    if (exception is ConflictException) return ErrorSeverity.low;
    return ErrorSeverity.medium;
  }

  static ErrorSeverity _getSeverityFromFailure(Failure failure) {
    if (failure is NetworkFailure) return ErrorSeverity.medium;
    if (failure is StorageFailure) return ErrorSeverity.high;
    if (failure is SyncFailure) return ErrorSeverity.medium;
    if (failure is AuthenticationFailure) return ErrorSeverity.high;
    if (failure is ValidationFailure) return ErrorSeverity.low;
    if (failure is FileSystemFailure) return ErrorSeverity.medium;
    if (failure is ParseFailure) return ErrorSeverity.medium;
    if (failure is ConflictFailure) return ErrorSeverity.low;
    return ErrorSeverity.medium;
  }

  static ErrorCategory _getCategoryFromException(AppException exception) {
    if (exception is NetworkException) return ErrorCategory.network;
    if (exception is StorageException) return ErrorCategory.storage;
    if (exception is SyncException) return ErrorCategory.sync;
    if (exception is AuthenticationException) return ErrorCategory.auth;
    if (exception is ValidationException) return ErrorCategory.validation;
    if (exception is FileSystemException) return ErrorCategory.filesystem;
    if (exception is ParseException) return ErrorCategory.data;
    if (exception is ConflictException) return ErrorCategory.sync;
    return ErrorCategory.unknown;
  }

  static ErrorCategory _getCategoryFromFailure(Failure failure) {
    if (failure is NetworkFailure) return ErrorCategory.network;
    if (failure is StorageFailure) return ErrorCategory.storage;
    if (failure is SyncFailure) return ErrorCategory.sync;
    if (failure is AuthenticationFailure) return ErrorCategory.auth;
    if (failure is ValidationFailure) return ErrorCategory.validation;
    if (failure is FileSystemFailure) return ErrorCategory.filesystem;
    if (failure is ParseFailure) return ErrorCategory.data;
    if (failure is ConflictFailure) return ErrorCategory.sync;
    return ErrorCategory.unknown;
  }

  @override
  String toString() {
    return 'AppError(message: $message, code: $code, severity: $severity, category: $category)';
  }
}

/// Error severity levels
enum ErrorSeverity {
  low,      // Minor issues that don't affect core functionality
  medium,   // Issues that affect some functionality but app remains usable
  high,     // Serious issues that significantly impact functionality
  critical, // Critical issues that may crash the app or corrupt data
}

/// Error categories for better organization and handling
enum ErrorCategory {
  network,     // Network-related errors
  storage,     // Storage and file system errors
  sync,        // Synchronization errors
  auth,        // Authentication and authorization errors
  validation,  // Data validation errors
  filesystem,  // File system operations
  data,        // Data parsing and processing errors
  ui,          // User interface errors
  unknown,     // Unknown or uncategorized errors
}