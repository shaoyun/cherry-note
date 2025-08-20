import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/features/sync/domain/entities/sync_operation.dart';
import 'package:cherry_note/features/sync/domain/entities/sync_operation_factory.dart';

void main() {
  group('SyncOperationFactory', () {
    group('createUploadOperation', () {
      test('应该创建上传操作', () {
        // Act
        final operation = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
        );

        // Assert
        expect(operation.id, isNotEmpty);
        expect(operation.filePath, equals('/test/file.md'));
        expect(operation.type, equals(SyncOperationType.upload));
        expect(operation.status, equals(SyncOperationStatus.pending));
        expect(operation.retryCount, equals(0));
        expect(operation.maxRetries, equals(3));
        expect(operation.createdAt, isNotNull);
      });

      test('应该支持自定义参数', () {
        // Arrange
        final metadata = {'key': 'value'};

        // Act
        final operation = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
          metadata: metadata,
          maxRetries: 5,
        );

        // Assert
        expect(operation.metadata, equals(metadata));
        expect(operation.maxRetries, equals(5));
      });
    });

    group('createDownloadOperation', () {
      test('应该创建下载操作', () {
        // Act
        final operation = SyncOperationFactory.createDownloadOperation(
          filePath: '/test/file.md',
        );

        // Assert
        expect(operation.id, isNotEmpty);
        expect(operation.filePath, equals('/test/file.md'));
        expect(operation.type, equals(SyncOperationType.download));
        expect(operation.status, equals(SyncOperationStatus.pending));
        expect(operation.retryCount, equals(0));
        expect(operation.maxRetries, equals(3));
        expect(operation.createdAt, isNotNull);
      });
    });

    group('createDeleteOperation', () {
      test('应该创建删除操作', () {
        // Act
        final operation = SyncOperationFactory.createDeleteOperation(
          filePath: '/test/file.md',
        );

        // Assert
        expect(operation.id, isNotEmpty);
        expect(operation.filePath, equals('/test/file.md'));
        expect(operation.type, equals(SyncOperationType.delete));
        expect(operation.status, equals(SyncOperationStatus.pending));
        expect(operation.retryCount, equals(0));
        expect(operation.maxRetries, equals(3));
        expect(operation.createdAt, isNotNull);
      });
    });

    group('createScheduledOperation', () {
      test('应该创建延迟执行的操作', () {
        // Arrange
        final scheduledTime = DateTime.now().add(const Duration(hours: 1));

        // Act
        final operation = SyncOperationFactory.createScheduledOperation(
          filePath: '/test/file.md',
          type: SyncOperationType.upload,
          scheduledAt: scheduledTime,
        );

        // Assert
        expect(operation.id, isNotEmpty);
        expect(operation.filePath, equals('/test/file.md'));
        expect(operation.type, equals(SyncOperationType.upload));
        expect(operation.status, equals(SyncOperationStatus.pending));
        expect(operation.scheduledAt, equals(scheduledTime));
        expect(operation.retryCount, equals(0));
        expect(operation.maxRetries, equals(3));
        expect(operation.createdAt, isNotNull);
      });
    });

    group('createRetryOperation', () {
      test('应该从现有操作创建重试操作', () {
        // Arrange
        final originalOperation = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
          metadata: {'original': 'data'},
        ).copyWith(
          status: SyncOperationStatus.failed,
          retryCount: 2,
          errorMessage: 'Original error',
          completedAt: DateTime.now(),
        );

        // Act
        final retryOperation = SyncOperationFactory.createRetryOperation(originalOperation);

        // Assert
        expect(retryOperation.id, isNot(equals(originalOperation.id)));
        expect(retryOperation.filePath, equals(originalOperation.filePath));
        expect(retryOperation.type, equals(originalOperation.type));
        expect(retryOperation.status, equals(SyncOperationStatus.pending));
        expect(retryOperation.retryCount, equals(0));
        expect(retryOperation.errorMessage, isNull);
        expect(retryOperation.scheduledAt, isNull);
        expect(retryOperation.completedAt, isNull);
        expect(retryOperation.metadata, equals(originalOperation.metadata));
        expect(retryOperation.maxRetries, equals(originalOperation.maxRetries));
      });
    });

    group('唯一性', () {
      test('每次创建的操作应该有唯一的ID', () {
        // Act
        final op1 = SyncOperationFactory.createUploadOperation(filePath: '/test/file.md');
        final op2 = SyncOperationFactory.createUploadOperation(filePath: '/test/file.md');

        // Assert
        expect(op1.id, isNot(equals(op2.id)));
      });

      test('重试操作应该有新的唯一ID', () {
        // Arrange
        final originalOp = SyncOperationFactory.createUploadOperation(filePath: '/test/file.md');

        // Act
        final retryOp1 = SyncOperationFactory.createRetryOperation(originalOp);
        final retryOp2 = SyncOperationFactory.createRetryOperation(originalOp);

        // Assert
        expect(retryOp1.id, isNot(equals(originalOp.id)));
        expect(retryOp2.id, isNot(equals(originalOp.id)));
        expect(retryOp1.id, isNot(equals(retryOp2.id)));
      });
    });

    group('默认值', () {
      test('所有工厂方法应该使用正确的默认值', () {
        // Act
        final uploadOp = SyncOperationFactory.createUploadOperation(filePath: '/test/file.md');
        final downloadOp = SyncOperationFactory.createDownloadOperation(filePath: '/test/file.md');
        final deleteOp = SyncOperationFactory.createDeleteOperation(filePath: '/test/file.md');

        // Assert
        final operations = [uploadOp, downloadOp, deleteOp];
        for (final op in operations) {
          expect(op.status, equals(SyncOperationStatus.pending));
          expect(op.retryCount, equals(0));
          expect(op.maxRetries, equals(3));
          expect(op.scheduledAt, isNull);
          expect(op.completedAt, isNull);
          expect(op.errorMessage, isNull);
          expect(op.createdAt.difference(DateTime.now()).abs().inSeconds, lessThan(1));
        }
      });
    });
  });
}