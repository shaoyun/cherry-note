import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:cherry_note/core/error/error_logger.dart';
import 'package:cherry_note/core/error/global_error_handler.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  group('ErrorLogger', () {
    late ErrorLogger errorLogger;
    late Directory tempDir;

    setUpAll(() {
      PathProviderPlatform.instance = MockPathProviderPlatform();
    });

    setUp(() async {
      errorLogger = ErrorLogger();
      tempDir = await Directory.systemTemp.createTemp('error_logger_test');
      await errorLogger.initialize();
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        // Arrange & Act
        await errorLogger.initialize();

        // Assert
        // No exception should be thrown
        expect(true, isTrue);
      });
    });

    group('Error Logging', () {
      test('should log error to file', () async {
        // Arrange
        final error = AppError(
          message: 'Test error message',
          technicalMessage: 'Technical details',
          code: 'TEST_ERROR',
          severity: ErrorSeverity.medium,
          category: ErrorCategory.unknown,
        );

        // Act
        await errorLogger.logError(error, context: 'Test context');

        // Assert
        final logs = await errorLogger.getRecentLogs();
        expect(logs, isNotEmpty);
        expect(logs.first, contains('Test error message'));
        expect(logs.first, contains('Technical details'));
        expect(logs.first, contains('TEST_ERROR'));
        expect(logs.first, contains('Test context'));
      });

      test('should handle logging when file is not initialized', () async {
        // Arrange
        final uninitializedLogger = ErrorLogger();
        final error = AppError(
          message: 'Test error',
          severity: ErrorSeverity.low,
          category: ErrorCategory.unknown,
        );

        // Act & Assert
        // Should not throw exception
        await uninitializedLogger.logError(error);
        expect(true, isTrue);
      });

      test('should log error with stack trace', () async {
        // Arrange
        final error = AppError(
          message: 'Test error with stack trace',
          severity: ErrorSeverity.high,
          category: ErrorCategory.unknown,
        );
        final stackTrace = StackTrace.current;

        // Act
        await errorLogger.logError(error, stackTrace: stackTrace);

        // Assert
        final logs = await errorLogger.getRecentLogs();
        expect(logs, isNotEmpty);
        expect(logs.first, contains('Test error with stack trace'));
        expect(logs.first, contains('stackTrace'));
      });
    });

    group('Log Management', () {
      test('should get recent logs', () async {
        // Arrange
        final errors = [
          AppError(
            message: 'Error 1',
            severity: ErrorSeverity.low,
            category: ErrorCategory.unknown,
          ),
          AppError(
            message: 'Error 2',
            severity: ErrorSeverity.medium,
            category: ErrorCategory.unknown,
          ),
          AppError(
            message: 'Error 3',
            severity: ErrorSeverity.high,
            category: ErrorCategory.unknown,
          ),
        ];

        // Act
        for (final error in errors) {
          await errorLogger.logError(error);
        }

        // Assert
        final logs = await errorLogger.getRecentLogs(maxEntries: 2);
        expect(logs.length, 2);
        expect(logs.first, contains('Error 3')); // Most recent first
        expect(logs.last, contains('Error 2'));
      });

      test('should clear logs', () async {
        // Arrange
        final error = AppError(
          message: 'Test error',
          severity: ErrorSeverity.low,
          category: ErrorCategory.unknown,
        );
        await errorLogger.logError(error);

        // Act
        await errorLogger.clearLogs();

        // Assert
        final logs = await errorLogger.getRecentLogs();
        expect(logs, isEmpty);
      });

      test('should get log statistics', () async {
        // Arrange
        final error = AppError(
          message: 'Test error for statistics',
          severity: ErrorSeverity.medium,
          category: ErrorCategory.unknown,
        );
        await errorLogger.logError(error);

        // Act
        final stats = await errorLogger.getLogStatistics();

        // Assert
        expect(stats.fileSize, greaterThan(0));
        expect(stats.entryCount, greaterThan(0));
        expect(stats.lastModified, isA<DateTime>());
      });

      test('should return empty statistics when no log file exists', () async {
        // Arrange
        final uninitializedLogger = ErrorLogger();

        // Act
        final stats = await uninitializedLogger.getLogStatistics();

        // Assert
        expect(stats.fileSize, 0);
        expect(stats.entryCount, 0);
        expect(stats.fileSizeFormatted, '0 B');
      });
    });

    group('Log Statistics', () {
      test('should format file size correctly', () {
        // Test bytes
        var stats = LogStatistics(
          fileSize: 512,
          entryCount: 1,
          lastModified: DateTime.now(),
        );
        expect(stats.fileSizeFormatted, '512 B');

        // Test kilobytes
        stats = LogStatistics(
          fileSize: 1536, // 1.5 KB
          entryCount: 1,
          lastModified: DateTime.now(),
        );
        expect(stats.fileSizeFormatted, '1.5 KB');

        // Test megabytes
        stats = LogStatistics(
          fileSize: 2097152, // 2 MB
          entryCount: 1,
          lastModified: DateTime.now(),
        );
        expect(stats.fileSizeFormatted, '2.0 MB');
      });

      test('should create empty statistics', () {
        // Act
        final stats = LogStatistics.empty();

        // Assert
        expect(stats.fileSize, 0);
        expect(stats.entryCount, 0);
        expect(stats.fileSizeFormatted, '0 B');
      });
    });

    group('Error Handling', () {
      test('should handle export when no log file exists', () async {
        // Arrange
        final uninitializedLogger = ErrorLogger();
        final exportPath = '${tempDir.path}/export.txt';

        // Act & Assert
        expect(
          () => uninitializedLogger.exportLogs(exportPath),
          throwsException,
        );
      });

      test('should export logs successfully', () async {
        // Arrange
        final error = AppError(
          message: 'Test error for export',
          severity: ErrorSeverity.medium,
          category: ErrorCategory.unknown,
        );
        await errorLogger.logError(error);
        final exportPath = '${tempDir.path}/export.txt';

        // Act
        await errorLogger.exportLogs(exportPath);

        // Assert
        final exportFile = File(exportPath);
        expect(exportFile.existsSync(), isTrue);
        final content = await exportFile.readAsString();
        expect(content, contains('Test error for export'));
      });
    });
  });
}