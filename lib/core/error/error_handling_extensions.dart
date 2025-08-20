import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'global_error_handler.dart';
import 'exceptions.dart';
import 'failures.dart';
import '../feedback/feedback_service.dart';

/// Extension to add error handling capabilities to BLoC
extension ErrorHandlingBloc<Event, State> on Bloc<Event, State> {
  /// Handle an exception and optionally show user feedback
  void handleException(
    Exception exception, {
    String? context,
    StackTrace? stackTrace,
    bool showUserFeedback = true,
    bool logError = true,
  }) {
    if (logError) {
      GlobalErrorHandler().handleException(
        exception,
        context: context,
        stackTrace: stackTrace,
        shouldNotifyUser: showUserFeedback,
      );
    }

    if (showUserFeedback) {
      final appError = AppError.fromException(exception);
      _showFeedbackForError(appError);
    }
  }

  /// Handle a failure and optionally show user feedback
  void handleFailure(
    Failure failure, {
    String? context,
    StackTrace? stackTrace,
    bool showUserFeedback = true,
    bool logError = true,
  }) {
    if (logError) {
      GlobalErrorHandler().handleFailure(
        failure,
        context: context,
        stackTrace: stackTrace,
        shouldNotifyUser: showUserFeedback,
      );
    }

    if (showUserFeedback) {
      final appError = AppError.fromFailure(failure);
      _showFeedbackForError(appError);
    }
  }

  /// Handle an AppError directly
  void handleAppError(
    AppError error, {
    String? context,
    StackTrace? stackTrace,
    bool showUserFeedback = true,
    bool logError = true,
  }) {
    if (logError) {
      GlobalErrorHandler().handleError(
        error,
        context: context,
        stackTrace: stackTrace,
        shouldNotifyUser: showUserFeedback,
      );
    }

    if (showUserFeedback) {
      _showFeedbackForError(error);
    }
  }

  void _showFeedbackForError(AppError error) {
    final feedbackService = FeedbackService();
    
    switch (error.severity) {
      case ErrorSeverity.low:
        feedbackService.showInfo(error.message);
        break;
      case ErrorSeverity.medium:
        feedbackService.showWarning(error.message);
        break;
      case ErrorSeverity.high:
      case ErrorSeverity.critical:
        feedbackService.showError(error.message);
        break;
    }
  }
}

/// Extension to add error handling capabilities to Cubit
extension ErrorHandlingCubit<State> on Cubit<State> {
  /// Handle an exception and optionally show user feedback
  void handleException(
    Exception exception, {
    String? context,
    StackTrace? stackTrace,
    bool showUserFeedback = true,
    bool logError = true,
  }) {
    if (logError) {
      GlobalErrorHandler().handleException(
        exception,
        context: context,
        stackTrace: stackTrace,
        shouldNotifyUser: showUserFeedback,
      );
    }

    if (showUserFeedback) {
      final appError = AppError.fromException(exception);
      _showFeedbackForError(appError);
    }
  }

  /// Handle a failure and optionally show user feedback
  void handleFailure(
    Failure failure, {
    String? context,
    StackTrace? stackTrace,
    bool showUserFeedback = true,
    bool logError = true,
  }) {
    if (logError) {
      GlobalErrorHandler().handleFailure(
        failure,
        context: context,
        stackTrace: stackTrace,
        shouldNotifyUser: showUserFeedback,
      );
    }

    if (showUserFeedback) {
      final appError = AppError.fromFailure(failure);
      _showFeedbackForError(appError);
    }
  }

  /// Handle an AppError directly
  void handleAppError(
    AppError error, {
    String? context,
    StackTrace? stackTrace,
    bool showUserFeedback = true,
    bool logError = true,
  }) {
    if (logError) {
      GlobalErrorHandler().handleError(
        error,
        context: context,
        stackTrace: stackTrace,
        shouldNotifyUser: showUserFeedback,
      );
    }

    if (showUserFeedback) {
      _showFeedbackForError(error);
    }
  }

  void _showFeedbackForError(AppError error) {
    final feedbackService = FeedbackService();
    
    switch (error.severity) {
      case ErrorSeverity.low:
        feedbackService.showInfo(error.message);
        break;
      case ErrorSeverity.medium:
        feedbackService.showWarning(error.message);
        break;
      case ErrorSeverity.high:
      case ErrorSeverity.critical:
        feedbackService.showError(error.message);
        break;
    }
  }
}

/// Extension for easy success feedback
extension SuccessFeedback on Object {
  /// Show success feedback
  void showSuccess(String message, {String? title}) {
    FeedbackService().showSuccess(message, title: title);
  }

  /// Show loading feedback
  void showLoading(String message, {String? title}) {
    FeedbackService().showLoading(message, title: title);
  }

  /// Hide loading feedback
  void hideLoading() {
    FeedbackService().hideLoading();
  }

  /// Show info feedback
  void showInfo(String message, {String? title}) {
    FeedbackService().showInfo(message, title: title);
  }
}

/// Mixin for widgets that need error handling
mixin ErrorHandlingMixin {
  /// Handle an exception with user-friendly feedback
  void handleException(
    Exception exception, {
    String? context,
    bool showFeedback = true,
  }) {
    GlobalErrorHandler().handleException(
      exception,
      context: context,
      shouldNotifyUser: showFeedback,
    );
  }

  /// Handle a failure with user-friendly feedback
  void handleFailure(
    Failure failure, {
    String? context,
    bool showFeedback = true,
  }) {
    GlobalErrorHandler().handleFailure(
      failure,
      context: context,
      shouldNotifyUser: showFeedback,
    );
  }

  /// Show success message
  void showSuccess(String message, {String? title}) {
    FeedbackService().showSuccess(message, title: title);
  }

  /// Show error message
  void showError(String message, {String? title, VoidCallback? onRetry}) {
    FeedbackService().showError(message, title: title, onRetry: onRetry);
  }

  /// Show loading message
  void showLoading(String message, {String? title}) {
    FeedbackService().showLoading(message, title: title);
  }

  /// Hide loading message
  void hideLoading() {
    FeedbackService().hideLoading();
  }
}