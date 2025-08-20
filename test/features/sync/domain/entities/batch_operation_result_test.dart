import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/features/sync/domain/entities/batch_operation_result.dart';

void main() {
  group('BatchOperationResult', () {
    test('should create successful result', () {
      final result = BatchOperationResult.success(
        totalFiles: 5,
        successfulKeys: ['file1.md', 'file2.md', 'file3.md', 'file4.md', 'file5.md'],
        duration: const Duration(seconds: 10),
      );

      expect(result.success, true);
      expect(result.totalFiles, 5);
      expect(result.successfulFiles, 5);
      expect(result.failedFiles, 0);
      expect(result.successfulKeys.length, 5);
      expect(result.errors.isEmpty, true);
      expect(result.isCompleteSuccess, true);
      expect(result.isPartialSuccess, false);
      expect(result.isCompleteFailure, false);
      expect(result.successRate, 100.0);
    });

    test('should create partial success result', () {
      final result = BatchOperationResult.partial(
        totalFiles: 5,
        successfulKeys: ['file1.md', 'file2.md', 'file3.md'],
        errors: {
          'file4.md': 'Network error',
          'file5.md': 'Access denied',
        },
        duration: const Duration(seconds: 15),
      );

      expect(result.success, false);
      expect(result.totalFiles, 5);
      expect(result.successfulFiles, 3);
      expect(result.failedFiles, 2);
      expect(result.successfulKeys.length, 3);
      expect(result.errors.length, 2);
      expect(result.isCompleteSuccess, false);
      expect(result.isPartialSuccess, true);
      expect(result.isCompleteFailure, false);
      expect(result.successRate, 60.0);
    });

    test('should create failure result', () {
      final result = BatchOperationResult.failure(
        totalFiles: 3,
        errors: {
          'file1.md': 'Network error',
          'file2.md': 'Access denied',
          'file3.md': 'File not found',
        },
        duration: const Duration(seconds: 5),
      );

      expect(result.success, false);
      expect(result.totalFiles, 3);
      expect(result.successfulFiles, 0);
      expect(result.failedFiles, 3);
      expect(result.successfulKeys.isEmpty, true);
      expect(result.errors.length, 3);
      expect(result.isCompleteSuccess, false);
      expect(result.isPartialSuccess, false);
      expect(result.isCompleteFailure, true);
      expect(result.successRate, 0.0);
    });

    test('should handle empty operation', () {
      final result = BatchOperationResult.success(
        totalFiles: 0,
        successfulKeys: [],
        duration: const Duration(milliseconds: 100),
      );

      expect(result.successRate, 0.0);
      expect(result.isCompleteSuccess, true);
    });

    test('should have correct string representation', () {
      final result = BatchOperationResult.partial(
        totalFiles: 10,
        successfulKeys: ['file1.md', 'file2.md'],
        errors: {'file3.md': 'Error'},
        duration: const Duration(milliseconds: 1500),
      );

      final str = result.toString();
      expect(str, contains('success: false'));
      expect(str, contains('successful: 2/10'));
      expect(str, contains('duration: 1500ms'));
    });
  });

  group('BatchOperationProgress', () {
    test('should calculate progress correctly', () {
      final progress = BatchOperationProgress(
        totalFiles: 10,
        processedFiles: 3,
        successfulFiles: 2,
        failedFiles: 1,
        currentFile: 'file4.md',
        elapsed: const Duration(seconds: 30),
      );

      expect(progress.progress, 0.3);
      expect(progress.progressPercent, 30);
      expect(progress.remainingFiles, 7);
    });

    test('should estimate remaining time', () {
      final progress = BatchOperationProgress(
        totalFiles: 10,
        processedFiles: 2,
        successfulFiles: 2,
        failedFiles: 0,
        elapsed: const Duration(seconds: 20), // 10 seconds per file
      );

      final estimatedTime = progress.estimatedTimeRemaining;
      expect(estimatedTime, isNotNull);
      expect(estimatedTime!.inSeconds, 80); // 8 remaining files * 10 seconds each
    });

    test('should handle zero progress', () {
      final progress = BatchOperationProgress(
        totalFiles: 10,
        processedFiles: 0,
        successfulFiles: 0,
        failedFiles: 0,
        elapsed: Duration.zero,
      );

      expect(progress.progress, 0.0);
      expect(progress.progressPercent, 0);
      expect(progress.estimatedTimeRemaining, null);
    });

    test('should handle empty operation', () {
      final progress = BatchOperationProgress(
        totalFiles: 0,
        processedFiles: 0,
        successfulFiles: 0,
        failedFiles: 0,
        elapsed: const Duration(seconds: 1),
      );

      expect(progress.progress, 0.0);
      expect(progress.progressPercent, 0);
      expect(progress.remainingFiles, 0);
    });

    test('should have correct string representation', () {
      final progress = BatchOperationProgress(
        totalFiles: 10,
        processedFiles: 3,
        successfulFiles: 2,
        failedFiles: 1,
        currentFile: 'test.md',
        elapsed: const Duration(seconds: 30),
      );

      final str = progress.toString();
      expect(str, contains('3/10'));
      expect(str, contains('30%'));
      expect(str, contains('current: test.md'));
    });
  });
}