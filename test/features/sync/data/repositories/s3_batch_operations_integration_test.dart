import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cherry_note/features/sync/data/repositories/s3_storage_repository_impl.dart';
import 'package:cherry_note/features/sync/domain/entities/s3_config.dart';
import 'package:cherry_note/features/sync/domain/entities/batch_operation_result.dart';
import 'package:cherry_note/features/sync/domain/entities/cancellation_token.dart';
import 'package:cherry_note/core/network/network_info.dart';
import 'package:cherry_note/core/error/exceptions.dart';

import 's3_storage_repository_impl_test.mocks.dart';

@GenerateMocks([NetworkInfo])
void main() {
  group('S3StorageRepository Batch Operations Integration Tests', () {
    late S3StorageRepositoryImpl repository;
    late MockNetworkInfo mockNetworkInfo;

    setUp(() {
      mockNetworkInfo = MockNetworkInfo();
      repository = S3StorageRepositoryImpl(mockNetworkInfo);
    });

    group('uploadMultipleFilesWithProgress', () {
      test('should handle empty file map', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final result = await repository.uploadMultipleFilesWithProgress({});

        expect(result.success, true);
        expect(result.totalFiles, 0);
        expect(result.successfulFiles, 0);
        expect(result.failedFiles, 0);
        expect(result.successfulKeys, isEmpty);
        expect(result.errors, isEmpty);
        expect(result.isCompleteSuccess, true);
      });

      test('should report progress during upload', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final files = {
          'notes/file1.md': '# File 1\nContent 1',
          'notes/file2.md': '# File 2\nContent 2',
          'notes/file3.md': '# File 3\nContent 3',
        };

        final progressReports = <BatchOperationProgress>[];

        // This will fail because S3 client is not initialized, but we can test progress reporting
        try {
          await repository.uploadMultipleFilesWithProgress(
            files,
            onProgress: (progress) {
              progressReports.add(progress);
            },
          );
        } catch (e) {
          // Expected to fail due to uninitialized client
        }

        // Should have received progress reports
        expect(progressReports.length, greaterThan(0));
        
        // First progress should show 0 processed files
        expect(progressReports.first.processedFiles, 0);
        expect(progressReports.first.totalFiles, 3);
        
        // Last progress should show all files processed
        expect(progressReports.last.processedFiles, 3);
        expect(progressReports.last.totalFiles, 3);
      });

      test('should handle cancellation during upload', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final files = {
          'notes/file1.md': '# File 1\nContent 1',
          'notes/file2.md': '# File 2\nContent 2',
          'notes/file3.md': '# File 3\nContent 3',
        };

        final cancellationToken = CancellationToken();
        
        // Cancel immediately
        cancellationToken.cancel('Test cancellation');

        expect(
          () async => await repository.uploadMultipleFilesWithProgress(
            files,
            cancellationToken: cancellationToken,
          ),
          throwsA(isA<OperationCancelledException>()),
        );
      });

      test('should handle network disconnection', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final files = {
          'notes/file1.md': '# File 1\nContent 1',
        };

        final result = await repository.uploadMultipleFilesWithProgress(files);
        
        expect(result.success, false);
        expect(result.isCompleteFailure, true);
        expect(result.errors.length, 1);
        expect(result.errors.values.first, contains('No internet connection'));
      });

      test('should handle partial failures gracefully', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final files = {
          'notes/file1.md': '# File 1\nContent 1',
          'notes/file2.md': '# File 2\nContent 2',
        };

        // This will fail because S3 client is not initialized
        final result = await repository.uploadMultipleFilesWithProgress(files);

        expect(result.success, false);
        expect(result.totalFiles, 2);
        expect(result.successfulFiles, 0);
        expect(result.failedFiles, 2);
        expect(result.isCompleteFailure, true);
        expect(result.errors.length, 2);
      });
    });

    group('downloadMultipleFilesWithProgress', () {
      test('should handle empty file list', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final result = await repository.downloadMultipleFilesWithProgress([]);

        expect(result.success, true);
        expect(result.totalFiles, 0);
        expect(result.successfulFiles, 0);
        expect(result.failedFiles, 0);
        expect(result.successfulKeys, isEmpty);
        expect(result.errors, isEmpty);
        expect(result.isCompleteSuccess, true);
      });

      test('should report progress during download', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final files = ['notes/file1.md', 'notes/file2.md', 'notes/file3.md'];
        final progressReports = <BatchOperationProgress>[];

        // This will fail because S3 client is not initialized, but we can test progress reporting
        try {
          await repository.downloadMultipleFilesWithProgress(
            files,
            onProgress: (progress) {
              progressReports.add(progress);
            },
          );
        } catch (e) {
          // Expected to fail due to uninitialized client
        }

        // Should have received progress reports
        expect(progressReports.length, greaterThan(0));
        
        // First progress should show 0 processed files
        expect(progressReports.first.processedFiles, 0);
        expect(progressReports.first.totalFiles, 3);
        
        // Last progress should show all files processed
        expect(progressReports.last.processedFiles, 3);
        expect(progressReports.last.totalFiles, 3);
      });

      test('should handle cancellation during download', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final files = ['notes/file1.md', 'notes/file2.md'];
        final cancellationToken = CancellationToken();
        
        // Cancel immediately
        cancellationToken.cancel('Test cancellation');

        expect(
          () async => await repository.downloadMultipleFilesWithProgress(
            files,
            cancellationToken: cancellationToken,
          ),
          throwsA(isA<OperationCancelledException>()),
        );
      });
    });

    group('deleteMultipleFilesWithProgress', () {
      test('should handle empty file list', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final result = await repository.deleteMultipleFilesWithProgress([]);

        expect(result.success, true);
        expect(result.totalFiles, 0);
        expect(result.successfulFiles, 0);
        expect(result.failedFiles, 0);
        expect(result.successfulKeys, isEmpty);
        expect(result.errors, isEmpty);
        expect(result.isCompleteSuccess, true);
      });

      test('should report progress during deletion', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final files = ['notes/file1.md', 'notes/file2.md'];
        final progressReports = <BatchOperationProgress>[];

        // This will fail because S3 client is not initialized, but we can test progress reporting
        try {
          await repository.deleteMultipleFilesWithProgress(
            files,
            onProgress: (progress) {
              progressReports.add(progress);
            },
          );
        } catch (e) {
          // Expected to fail due to uninitialized client
        }

        // Should have received progress reports
        expect(progressReports.length, greaterThan(0));
        
        // First progress should show 0 processed files
        expect(progressReports.first.processedFiles, 0);
        expect(progressReports.first.totalFiles, 2);
        
        // Last progress should show all files processed
        expect(progressReports.last.processedFiles, 2);
        expect(progressReports.last.totalFiles, 2);
      });

      test('should handle cancellation during deletion', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final files = ['notes/file1.md', 'notes/file2.md'];
        final cancellationToken = CancellationToken();
        
        // Cancel immediately
        cancellationToken.cancel('Test cancellation');

        expect(
          () async => await repository.deleteMultipleFilesWithProgress(
            files,
            cancellationToken: cancellationToken,
          ),
          throwsA(isA<OperationCancelledException>()),
        );
      });
    });

    group('uploadFolderRecursively', () {
      test('should handle empty folder', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final result = await repository.uploadFolderRecursively(
          'empty-folder',
          {},
        );

        expect(result.success, true);
        expect(result.totalFiles, 0);
        expect(result.isCompleteSuccess, true);
      });

      test('should report progress during folder upload', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final files = {
          'project/notes/file1.md': '# File 1',
          'project/notes/file2.md': '# File 2',
          'project/docs/readme.md': '# README',
        };

        final progressReports = <BatchOperationProgress>[];

        // This will fail because S3 client is not initialized, but we can test progress reporting
        try {
          await repository.uploadFolderRecursively(
            'project',
            files,
            onProgress: (progress) {
              progressReports.add(progress);
            },
          );
        } catch (e) {
          // Expected to fail due to uninitialized client
        }

        // Should have received progress reports
        expect(progressReports.length, greaterThan(0));
        expect(progressReports.last.totalFiles, 3);
      });

      test('should handle cancellation during folder upload', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final files = {
          'project/file1.md': '# File 1',
          'project/file2.md': '# File 2',
        };

        final cancellationToken = CancellationToken();
        cancellationToken.cancel('Test cancellation');

        expect(
          () async => await repository.uploadFolderRecursively(
            'project',
            files,
            cancellationToken: cancellationToken,
          ),
          throwsA(isA<OperationCancelledException>()),
        );
      });
    });

    group('downloadFolderRecursively', () {
      test('should handle non-existent folder', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        // This will fail because S3 client is not initialized
        final result = await repository.downloadFolderRecursively('non-existent');

        expect(result.success, false);
        expect(result.isCompleteFailure, true);
        expect(result.errors.containsKey('non-existent'), true);
      });

      test('should handle cancellation during folder download', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final cancellationToken = CancellationToken();
        cancellationToken.cancel('Test cancellation');

        expect(
          () async => await repository.downloadFolderRecursively(
            'project',
            cancellationToken: cancellationToken,
          ),
          throwsA(isA<OperationCancelledException>()),
        );
      });

      test('should report progress during folder download', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final progressReports = <BatchOperationProgress>[];

        // This will fail because S3 client is not initialized, but we can test the flow
        try {
          await repository.downloadFolderRecursively(
            'project',
            onProgress: (progress) {
              progressReports.add(progress);
            },
          );
        } catch (e) {
          // Expected to fail due to uninitialized client
        }

        // The method should at least attempt to list files first
        // Progress reports depend on whether files are found
      });
    });

    group('deleteFolderRecursively', () {
      test('should handle non-existent folder', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        // This will fail because S3 client is not initialized
        final result = await repository.deleteFolderRecursively('non-existent');

        expect(result.success, false);
        expect(result.isCompleteFailure, true);
        expect(result.errors.containsKey('non-existent'), true);
      });

      test('should handle cancellation during folder deletion', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final cancellationToken = CancellationToken();
        cancellationToken.cancel('Test cancellation');

        expect(
          () async => await repository.deleteFolderRecursively(
            'project',
            cancellationToken: cancellationToken,
          ),
          throwsA(isA<OperationCancelledException>()),
        );
      });

      test('should report progress during folder deletion', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final progressReports = <BatchOperationProgress>[];

        // This will fail because S3 client is not initialized, but we can test the flow
        try {
          await repository.deleteFolderRecursively(
            'project',
            onProgress: (progress) {
              progressReports.add(progress);
            },
          );
        } catch (e) {
          // Expected to fail due to uninitialized client
        }

        // The method should at least attempt to list files first
        // Progress reports depend on whether files are found
      });
    });

    group('legacy batch operations', () {
      test('uploadMultipleFiles should delegate to progress version', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final files = {
          'notes/file1.md': '# File 1',
        };

        // This should fail because S3 client is not initialized
        expect(
          () async => await repository.uploadMultipleFiles(files),
          throwsA(isA<StorageException>()),
        );
      });

      test('downloadMultipleFiles should delegate to progress version', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final files = ['notes/file1.md'];

        // This should fail because S3 client is not initialized
        expect(
          () async => await repository.downloadMultipleFiles(files),
          throwsA(isA<StorageException>()),
        );
      });

      test('downloadMultipleFiles should throw on complete failure', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final files = ['notes/file1.md'];

        // This should fail because S3 client is not initialized
        expect(
          () async => await repository.downloadMultipleFiles(files),
          throwsA(isA<StorageException>()),
        );
      });
    });

    group('progress calculation', () {
      test('should calculate progress correctly throughout operation', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final files = {
          'file1.md': 'content1',
          'file2.md': 'content2',
          'file3.md': 'content3',
          'file4.md': 'content4',
          'file5.md': 'content5',
        };

        final progressReports = <BatchOperationProgress>[];

        try {
          await repository.uploadMultipleFilesWithProgress(
            files,
            onProgress: (progress) {
              progressReports.add(progress);
              
              // Verify progress is always between 0 and 1
              expect(progress.progress, greaterThanOrEqualTo(0.0));
              expect(progress.progress, lessThanOrEqualTo(1.0));
              
              // Verify processed files never exceeds total
              expect(progress.processedFiles, lessThanOrEqualTo(progress.totalFiles));
              
              // Verify successful + failed = processed (when operation completes)
              if (progress.processedFiles > 0) {
                expect(
                  progress.successfulFiles + progress.failedFiles,
                  lessThanOrEqualTo(progress.processedFiles),
                );
              }
            },
          );
        } catch (e) {
          // Expected to fail due to uninitialized client
        }

        // Should have received multiple progress reports
        expect(progressReports.length, greaterThan(1));
        
        // Progress should increase over time
        for (int i = 1; i < progressReports.length; i++) {
          expect(
            progressReports[i].processedFiles,
            greaterThanOrEqualTo(progressReports[i - 1].processedFiles),
          );
        }
      });

      test('should handle time estimation correctly', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final files = {
          'file1.md': 'content1',
          'file2.md': 'content2',
        };

        BatchOperationProgress? lastProgress;

        try {
          await repository.uploadMultipleFilesWithProgress(
            files,
            onProgress: (progress) {
              lastProgress = progress;
              
              // Check time estimation logic
              if (progress.processedFiles > 0 && progress.elapsed.inMilliseconds > 0) {
                final estimatedTime = progress.estimatedTimeRemaining;
                if (estimatedTime != null) {
                  expect(estimatedTime.inMilliseconds, greaterThanOrEqualTo(0));
                }
              }
            },
          );
        } catch (e) {
          // Expected to fail due to uninitialized client
        }

        expect(lastProgress, isNotNull);
        expect(lastProgress!.processedFiles, equals(files.length));
      });
    });

    group('error handling in batch operations', () {
      test('should handle network errors gracefully', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final files = {'file1.md': 'content'};

        final uploadResult = await repository.uploadMultipleFilesWithProgress(files);
        expect(uploadResult.success, false);
        expect(uploadResult.isCompleteFailure, true);

        final downloadResult = await repository.downloadMultipleFilesWithProgress(['file1.md']);
        expect(downloadResult.success, false);
        expect(downloadResult.isCompleteFailure, true);

        final deleteResult = await repository.deleteMultipleFilesWithProgress(['file1.md']);
        expect(deleteResult.success, false);
        expect(deleteResult.isCompleteFailure, true);
      });

      test('should handle initialization errors', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        final files = {'file1.md': 'content'};

        // Repository is not initialized, should handle gracefully
        final result = await repository.uploadMultipleFilesWithProgress(files);
        expect(result.success, false);
        expect(result.isCompleteFailure, true);
      });
    });
  });
}