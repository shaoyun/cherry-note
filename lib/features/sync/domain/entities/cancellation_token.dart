import 'dart:async';

/// Token that can be used to cancel long-running operations
class CancellationToken {
  final Completer<void> _completer = Completer<void>();
  bool _isCancelled = false;
  String? _reason;

  /// Create a new cancellation token
  CancellationToken();

  /// Create a token that is already cancelled
  CancellationToken.cancelled([String? reason]) {
    _cancel(reason);
  }

  /// Check if cancellation has been requested
  bool get isCancelled => _isCancelled;

  /// Get the cancellation reason
  String? get reason => _reason;

  /// Future that completes when cancellation is requested
  Future<void> get future => _completer.future;

  /// Request cancellation
  void cancel([String? reason]) {
    if (!_isCancelled) {
      _cancel(reason);
    }
  }

  /// Throw if cancellation has been requested
  void throwIfCancelled() {
    if (_isCancelled) {
      throw OperationCancelledException(_reason ?? 'Operation was cancelled');
    }
  }

  void _cancel(String? reason) {
    _isCancelled = true;
    _reason = reason ?? 'Operation was cancelled';
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }
}

/// Exception thrown when an operation is cancelled
class OperationCancelledException implements Exception {
  final String message;

  const OperationCancelledException(this.message);

  @override
  String toString() => 'OperationCancelledException: $message';
}

/// Utility class for creating cancellation tokens
class CancellationTokenSource {
  final CancellationToken _token = CancellationToken();

  /// Get the cancellation token
  CancellationToken get token => _token;

  /// Cancel the token
  void cancel([String? reason]) {
    _token.cancel(reason);
  }

  /// Create a token that will be cancelled after a timeout
  static CancellationToken timeout(Duration timeout, [String? reason]) {
    final token = CancellationToken();
    Timer(timeout, () {
      token.cancel(reason ?? 'Operation timed out after ${timeout.inMilliseconds}ms');
    });
    return token;
  }

  /// Combine multiple tokens - cancels when any of them is cancelled
  static CancellationToken combine(List<CancellationToken> tokens) {
    final combinedToken = CancellationToken();
    
    for (final token in tokens) {
      if (token.isCancelled) {
        combinedToken.cancel(token.reason);
        break;
      } else {
        token.future.then((_) {
          if (!combinedToken.isCancelled) {
            combinedToken.cancel(token.reason);
          }
        });
      }
    }
    
    return combinedToken;
  }
}