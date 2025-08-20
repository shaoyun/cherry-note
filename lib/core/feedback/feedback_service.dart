import 'dart:async';
import 'package:flutter/material.dart';

/// Service for managing user feedback (success, error, info messages)
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final StreamController<FeedbackMessage> _messageController = 
      StreamController<FeedbackMessage>.broadcast();

  /// Stream of feedback messages
  Stream<FeedbackMessage> get messageStream => _messageController.stream;

  /// Show success message
  void showSuccess(
    String message, {
    String? title,
    Duration? duration,
    VoidCallback? onTap,
  }) {
    _messageController.add(FeedbackMessage(
      type: FeedbackType.success,
      message: message,
      title: title,
      duration: duration ?? const Duration(seconds: 3),
      onTap: onTap,
    ));
  }

  /// Show error message
  void showError(
    String message, {
    String? title,
    Duration? duration,
    VoidCallback? onTap,
    VoidCallback? onRetry,
  }) {
    _messageController.add(FeedbackMessage(
      type: FeedbackType.error,
      message: message,
      title: title,
      duration: duration ?? const Duration(seconds: 5),
      onTap: onTap,
      onRetry: onRetry,
    ));
  }

  /// Show warning message
  void showWarning(
    String message, {
    String? title,
    Duration? duration,
    VoidCallback? onTap,
  }) {
    _messageController.add(FeedbackMessage(
      type: FeedbackType.warning,
      message: message,
      title: title,
      duration: duration ?? const Duration(seconds: 4),
      onTap: onTap,
    ));
  }

  /// Show info message
  void showInfo(
    String message, {
    String? title,
    Duration? duration,
    VoidCallback? onTap,
  }) {
    _messageController.add(FeedbackMessage(
      type: FeedbackType.info,
      message: message,
      title: title,
      duration: duration ?? const Duration(seconds: 3),
      onTap: onTap,
    ));
  }

  /// Show loading message
  void showLoading(
    String message, {
    String? title,
  }) {
    _messageController.add(FeedbackMessage(
      type: FeedbackType.loading,
      message: message,
      title: title,
      duration: null, // Loading messages don't auto-dismiss
    ));
  }

  /// Hide loading message
  void hideLoading() {
    _messageController.add(FeedbackMessage(
      type: FeedbackType.hideLoading,
      message: '',
    ));
  }

  /// Dispose resources
  void dispose() {
    _messageController.close();
  }
}

/// Represents a feedback message
class FeedbackMessage {
  final FeedbackType type;
  final String message;
  final String? title;
  final Duration? duration;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;
  final DateTime timestamp;

  FeedbackMessage({
    required this.type,
    required this.message,
    this.title,
    this.duration,
    this.onTap,
    this.onRetry,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'FeedbackMessage(type: $type, message: $message, title: $title)';
  }
}

/// Types of feedback messages
enum FeedbackType {
  success,
  error,
  warning,
  info,
  loading,
  hideLoading,
}

/// Extension to get display properties for feedback types
extension FeedbackTypeExtension on FeedbackType {
  IconData get icon {
    switch (this) {
      case FeedbackType.success:
        return Icons.check_circle;
      case FeedbackType.error:
        return Icons.error;
      case FeedbackType.warning:
        return Icons.warning;
      case FeedbackType.info:
        return Icons.info;
      case FeedbackType.loading:
        return Icons.hourglass_empty;
      case FeedbackType.hideLoading:
        return Icons.close;
    }
  }

  Color getColor(BuildContext context) {
    switch (this) {
      case FeedbackType.success:
        return Colors.green;
      case FeedbackType.error:
        return Colors.red;
      case FeedbackType.warning:
        return Colors.orange;
      case FeedbackType.info:
        return Theme.of(context).colorScheme.primary;
      case FeedbackType.loading:
        return Theme.of(context).colorScheme.primary;
      case FeedbackType.hideLoading:
        return Colors.grey;
    }
  }

  String get defaultTitle {
    switch (this) {
      case FeedbackType.success:
        return '成功';
      case FeedbackType.error:
        return '错误';
      case FeedbackType.warning:
        return '警告';
      case FeedbackType.info:
        return '提示';
      case FeedbackType.loading:
        return '加载中';
      case FeedbackType.hideLoading:
        return '';
    }
  }
}