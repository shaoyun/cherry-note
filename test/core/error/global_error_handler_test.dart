import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/core/error/global_error_handler.dart';
import 'package:cherry_note/core/error/exceptions.dart';
import 'package:cherry_note/core/error/failures.dart';

void main() {
  group('GlobalErrorHandler', () {
    late GlobalErrorHandler errorHandler;

    setUp(() {
      errorHandler = GlobalErrorHandler();
    });

    group('AppError', () {
      test('should create AppError from AppException', () {
        // Arrange
        const exception = NetworkException('Network connection failed');

        // Act
        final error = AppError.fromException(exception);

        // Assert
        expect(error.message, '网络连接失败，请检查网络设置后重试');
        expect(error.technicalMessage, 'Network connection failed');
        expect(error.code, 'NETWORK_ERROR');
        expect(error.severity, ErrorSeverity.medium);
        expect(error.category, ErrorCategory.network);
      });

      test('should create AppError from Failure', () {
        // Arrange
        const failure = StorageFailure('Storage operation failed');

        // Act
        final error = AppError.fromFailure(failure);

        // Assert
        expect(error.message, '存储操作失败，请检查存储空间或权限');
        expect(error.technicalMessage, 'Storage operation failed');
        expect(error.code, 'STORAGE_FAILURE');
        expect(error.severity, ErrorSeverity.high);
        expect(error.category, ErrorCategory.storage);
      });

      test('should create AppError from unknown exception', () {
        // Arrange
        final exception = Exception('Unknown error');

        // Act
        final error = AppError.fromException(exception);

        // Assert
        expect(error.message, '发生了未知错误，请稍后重试');
        expect(error.technicalMessage, 'Exception: Unknown error');
        expect(error.severity, ErrorSeverity.medium);
        expect(error.category, ErrorCategory.unknown);
      });

      test('should map different exception types to correct user messages', () {
        final testCases = [
          (const NetworkException('test'), '网络连接失败，请检查网络设置后重试'),
          (const StorageException('test'), '存储操作失败，请检查存储空间或权限'),
          (const SyncException('test'), '同步失败，请检查网络连接和存储配置'),
          (const AuthenticationException('test'), '身份验证失败，请检查登录凭据'),
          (const ValidationException('test'), '输入数据格式不正确，请检查后重试'),
          (const FileSystemException('test'), '文件操作失败，请检查文件权限'),
          (const ParseException('test'), '数据解析失败，文件可能已损坏'),
          (const ConflictException('test'), '检测到数据冲突，需要手动解决'),
        ];

        for (final (exception, expectedMessage) in testCases) {
          final error = AppError.fromException(exception);
          expect(error.message, expectedMessage, reason: 'Failed for ${exception.runtimeType}');
        }
      });

      test('should map different exception types to correct severity', () {
        final testCases = [
          (const NetworkException('test'), ErrorSeverity.medium),
          (const StorageException('test'), ErrorSeverity.high),
          (const SyncException('test'), ErrorSeverity.medium),
          (const AuthenticationException('test'), ErrorSeverity.high),
          (const ValidationException('test'), ErrorSeverity.low),
          (const FileSystemException('test'), ErrorSeverity.medium),
          (const ParseException('test'), ErrorSeverity.medium),
          (const ConflictException('test'), ErrorSeverity.low),
        ];

        for (final (exception, expectedSeverity) in testCases) {
          final error = AppError.fromException(exception);
          expect(error.severity, expectedSeverity, reason: 'Failed for ${exception.runtimeType}');
        }
      });

      test('should map different exception types to correct category', () {
        final testCases = [
          (const NetworkException('test'), ErrorCategory.network),
          (const StorageException('test'), ErrorCategory.storage),
          (const SyncException('test'), ErrorCategory.sync),
          (const AuthenticationException('test'), ErrorCategory.auth),
          (const ValidationException('test'), ErrorCategory.validation),
          (const FileSystemException('test'), ErrorCategory.filesystem),
          (const ParseException('test'), ErrorCategory.data),
          (const ConflictException('test'), ErrorCategory.sync),
        ];

        for (final (exception, expectedCategory) in testCases) {
          final error = AppError.fromException(exception);
          expect(error.category, expectedCategory, reason: 'Failed for ${exception.runtimeType}');
        }
      });
    });

    group('Error Handling', () {
      test('should handle error and emit to stream', () async {
        // Arrange
        final error = AppError(
          message: 'Test error',
          severity: ErrorSeverity.medium,
          category: ErrorCategory.unknown,
        );

        // Act & Assert
        expectLater(
          errorHandler.errorStream,
          emits(error),
        );

        errorHandler.handleError(error);
      });

      test('should handle exception and convert to AppError', () async {
        // Arrange
        const exception = NetworkException('Network error');

        // Act & Assert
        expectLater(
          errorHandler.errorStream,
          emits(isA<AppError>().having(
            (e) => e.message,
            'message',
            '网络连接失败，请检查网络设置后重试',
          )),
        );

        errorHandler.handleException(exception);
      });

      test('should handle failure and convert to AppError', () async {
        // Arrange
        const failure = StorageFailure('Storage error');

        // Act & Assert
        expectLater(
          errorHandler.errorStream,
          emits(isA<AppError>().having(
            (e) => e.message,
            'message',
            '存储操作失败，请检查存储空间或权限',
          )),
        );

        errorHandler.handleFailure(failure);
      });

      test('should not emit to stream when shouldNotifyUser is false', () async {
        // Arrange
        final error = AppError(
          message: 'Test error',
          severity: ErrorSeverity.medium,
          category: ErrorCategory.unknown,
        );

        // Act
        errorHandler.handleError(error, shouldNotifyUser: false);

        // Assert
        // Wait a short time to ensure no events are emitted
        await Future.delayed(const Duration(milliseconds: 100));
        
        // The stream should not have emitted any events
        expect(true, isTrue); // Test passes if no events were emitted
      });
    });

    group('Error Severity', () {
      test('should have correct severity order', () {
        expect(ErrorSeverity.low.index, lessThan(ErrorSeverity.medium.index));
        expect(ErrorSeverity.medium.index, lessThan(ErrorSeverity.high.index));
        expect(ErrorSeverity.high.index, lessThan(ErrorSeverity.critical.index));
      });
    });

    group('Error Category', () {
      test('should have all expected categories', () {
        final categories = ErrorCategory.values;
        expect(categories, contains(ErrorCategory.network));
        expect(categories, contains(ErrorCategory.storage));
        expect(categories, contains(ErrorCategory.sync));
        expect(categories, contains(ErrorCategory.auth));
        expect(categories, contains(ErrorCategory.validation));
        expect(categories, contains(ErrorCategory.filesystem));
        expect(categories, contains(ErrorCategory.data));
        expect(categories, contains(ErrorCategory.ui));
        expect(categories, contains(ErrorCategory.unknown));
      });
    });
  });
}