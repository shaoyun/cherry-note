import 'package:equatable/equatable.dart';

class BatchOperationResult extends Equatable {
  final bool success;
  final int totalFiles;
  final int successfulFiles;
  final int failedFiles;
  final List<String> successfulKeys;
  final Map<String, String> errors;
  final Duration duration;

  const BatchOperationResult({
    required this.success,
    required this.totalFiles,
    required this.successfulFiles,
    required this.failedFiles,
    required this.successfulKeys,
    required this.errors,
    required this.duration,
  });

  /// Create a successful result
  factory BatchOperationResult.success({
    required int totalFiles,
    required List<String> successfulKeys,
    required Duration duration,
  }) {
    return BatchOperationResult(
      success: true,
      totalFiles: totalFiles,
      successfulFiles: totalFiles,
      failedFiles: 0,
      successfulKeys: successfulKeys,
      errors: {},
      duration: duration,
    );
  }

  /// Create a partial success result
  factory BatchOperationResult.partial({
    required int totalFiles,
    required List<String> successfulKeys,
    required Map<String, String> errors,
    required Duration duration,
  }) {
    return BatchOperationResult(
      success: false,
      totalFiles: totalFiles,
      successfulFiles: successfulKeys.length,
      failedFiles: errors.length,
      successfulKeys: successfulKeys,
      errors: errors,
      duration: duration,
    );
  }

  /// Create a failed result
  factory BatchOperationResult.failure({
    required int totalFiles,
    required Map<String, String> errors,
    required Duration duration,
  }) {
    return BatchOperationResult(
      success: false,
      totalFiles: totalFiles,
      successfulFiles: 0,
      failedFiles: errors.length,
      successfulKeys: [],
      errors: errors,
      duration: duration,
    );
  }

  /// Get success rate as percentage
  double get successRate {
    if (totalFiles == 0) return 0.0;
    return (successfulFiles / totalFiles) * 100;
  }

  /// Check if operation was completely successful
  bool get isCompleteSuccess => success && failedFiles == 0;

  /// Check if operation was partially successful
  bool get isPartialSuccess => !success && successfulFiles > 0;

  /// Check if operation completely failed
  bool get isCompleteFailure => !success && successfulFiles == 0;

  @override
  List<Object?> get props => [
        success,
        totalFiles,
        successfulFiles,
        failedFiles,
        successfulKeys,
        errors,
        duration,
      ];

  @override
  String toString() {
    return 'BatchOperationResult(success: $success, '
           'successful: $successfulFiles/$totalFiles, '
           'duration: ${duration.inMilliseconds}ms)';
  }
}

/// Progress information for batch operations
class BatchOperationProgress extends Equatable {
  final int totalFiles;
  final int processedFiles;
  final int successfulFiles;
  final int failedFiles;
  final String? currentFile;
  final Duration elapsed;

  const BatchOperationProgress({
    required this.totalFiles,
    required this.processedFiles,
    required this.successfulFiles,
    required this.failedFiles,
    this.currentFile,
    required this.elapsed,
  });

  /// Get progress as percentage (0.0 to 1.0)
  double get progress {
    if (totalFiles == 0) return 0.0;
    return processedFiles / totalFiles;
  }

  /// Get progress as percentage (0 to 100)
  int get progressPercent => (progress * 100).round();

  /// Get remaining files count
  int get remainingFiles => totalFiles - processedFiles;

  /// Estimate remaining time based on current progress
  Duration? get estimatedTimeRemaining {
    if (processedFiles == 0 || elapsed.inMilliseconds == 0) return null;
    
    final avgTimePerFile = elapsed.inMilliseconds / processedFiles;
    final remainingMs = (remainingFiles * avgTimePerFile).round();
    
    return Duration(milliseconds: remainingMs);
  }

  @override
  List<Object?> get props => [
        totalFiles,
        processedFiles,
        successfulFiles,
        failedFiles,
        currentFile,
        elapsed,
      ];

  @override
  String toString() {
    return 'BatchOperationProgress($processedFiles/$totalFiles, '
           '${progressPercent}%, current: $currentFile)';
  }
}