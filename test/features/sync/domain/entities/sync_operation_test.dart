import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/features/sync/domain/entities/sync_operation.dart';

void main() {
  group('SyncOperation', () {
    late SyncOperation operation;

    setUp(() {
      operation = SyncOperation(
        id: 'test-id',
        filePath: '/test/file.md',
        type: SyncOperationType.upload,
        createdAt: DateTime.now(),
      );
    });

    group('构造函数', () {
      test('应该创建有效的同步操作', () {
        expect(operation.id, equals('test-id'));
        expect(operation.filePath, equals('/test/file.md'));
        expect(operation.type, equals(SyncOperationType.upload));
        expect(operation.status, equals(SyncOperationStatus.pending));
        expect(operation.retryCount, equals(0));
        expect(operation.maxRetries, equals(3));
      });

      test('应该支持自定义参数', () {
        final customOp = SyncOperation(
          id: 'custom-id',
          filePath: '/custom/file.md',
          type: SyncOperationType.download,
          status: SyncOperationStatus.inProgress,
          createdAt: DateTime.now(),
          retryCount: 2,
          maxRetries: 5,
          errorMessage: 'Test error',
          metadata: {'key': 'value'},
        );

        expect(customOp.status, equals(SyncOperationStatus.inProgress));
        expect(customOp.retryCount, equals(2));
        expect(customOp.maxRetries, equals(5));
        expect(customOp.errorMessage, equals('Test error'));
        expect(customOp.metadata, equals({'key': 'value'}));
      });
    });

    group('copyWith', () {
      test('应该创建修改后的副本', () {
        final updatedOp = operation.copyWith(
          status: SyncOperationStatus.completed,
          retryCount: 1,
        );

        expect(updatedOp.id, equals(operation.id));
        expect(updatedOp.filePath, equals(operation.filePath));
        expect(updatedOp.status, equals(SyncOperationStatus.completed));
        expect(updatedOp.retryCount, equals(1));
      });

      test('应该保持未修改的属性不变', () {
        final updatedOp = operation.copyWith(status: SyncOperationStatus.failed);

        expect(updatedOp.type, equals(operation.type));
        expect(updatedOp.createdAt, equals(operation.createdAt));
        expect(updatedOp.maxRetries, equals(operation.maxRetries));
      });
    });

    group('canRetry', () {
      test('失败且未达到最大重试次数时应该返回true', () {
        final failedOp = operation.copyWith(
          status: SyncOperationStatus.failed,
          retryCount: 2,
          maxRetries: 3,
        );

        expect(failedOp.canRetry, isTrue);
      });

      test('失败但已达到最大重试次数时应该返回false', () {
        final failedOp = operation.copyWith(
          status: SyncOperationStatus.failed,
          retryCount: 3,
          maxRetries: 3,
        );

        expect(failedOp.canRetry, isFalse);
      });

      test('非失败状态时应该返回false', () {
        final completedOp = operation.copyWith(status: SyncOperationStatus.completed);
        expect(completedOp.canRetry, isFalse);

        final pendingOp = operation.copyWith(status: SyncOperationStatus.pending);
        expect(pendingOp.canRetry, isFalse);
      });
    });

    group('isFinished', () {
      test('已完成状态应该返回true', () {
        final completedOp = operation.copyWith(status: SyncOperationStatus.completed);
        expect(completedOp.isFinished, isTrue);
      });

      test('已取消状态应该返回true', () {
        final cancelledOp = operation.copyWith(status: SyncOperationStatus.cancelled);
        expect(cancelledOp.isFinished, isTrue);
      });

      test('失败且不能重试时应该返回true', () {
        final failedOp = operation.copyWith(
          status: SyncOperationStatus.failed,
          retryCount: 3,
          maxRetries: 3,
        );
        expect(failedOp.isFinished, isTrue);
      });

      test('失败但可以重试时应该返回false', () {
        final failedOp = operation.copyWith(
          status: SyncOperationStatus.failed,
          retryCount: 1,
          maxRetries: 3,
        );
        expect(failedOp.isFinished, isFalse);
      });

      test('待执行状态应该返回false', () {
        final pendingOp = operation.copyWith(status: SyncOperationStatus.pending);
        expect(pendingOp.isFinished, isFalse);
      });
    });

    group('needsExecution', () {
      test('待执行状态应该返回true', () {
        final pendingOp = operation.copyWith(status: SyncOperationStatus.pending);
        expect(pendingOp.needsExecution, isTrue);
      });

      test('失败但可以重试时应该返回true', () {
        final failedOp = operation.copyWith(
          status: SyncOperationStatus.failed,
          retryCount: 1,
          maxRetries: 3,
        );
        expect(failedOp.needsExecution, isTrue);
      });

      test('已完成状态应该返回false', () {
        final completedOp = operation.copyWith(status: SyncOperationStatus.completed);
        expect(completedOp.needsExecution, isFalse);
      });

      test('进行中状态应该返回false', () {
        final inProgressOp = operation.copyWith(status: SyncOperationStatus.inProgress);
        expect(inProgressOp.needsExecution, isFalse);
      });

      test('失败且不能重试时应该返回false', () {
        final failedOp = operation.copyWith(
          status: SyncOperationStatus.failed,
          retryCount: 3,
          maxRetries: 3,
        );
        expect(failedOp.needsExecution, isFalse);
      });
    });

    group('相等性', () {
      test('相同属性的操作应该相等', () {
        final op1 = SyncOperation(
          id: 'test-id',
          filePath: '/test/file.md',
          type: SyncOperationType.upload,
          createdAt: DateTime(2024, 1, 1),
        );

        final op2 = SyncOperation(
          id: 'test-id',
          filePath: '/test/file.md',
          type: SyncOperationType.upload,
          createdAt: DateTime(2024, 1, 1),
        );

        expect(op1, equals(op2));
        expect(op1.hashCode, equals(op2.hashCode));
      });

      test('不同属性的操作应该不相等', () {
        final op1 = SyncOperation(
          id: 'test-id-1',
          filePath: '/test/file.md',
          type: SyncOperationType.upload,
          createdAt: DateTime.now(),
        );

        final op2 = SyncOperation(
          id: 'test-id-2',
          filePath: '/test/file.md',
          type: SyncOperationType.upload,
          createdAt: DateTime.now(),
        );

        expect(op1, isNot(equals(op2)));
      });
    });

    group('toString', () {
      test('应该返回有意义的字符串表示', () {
        final op = SyncOperation(
          id: 'test-id',
          filePath: '/test/file.md',
          type: SyncOperationType.upload,
          status: SyncOperationStatus.pending,
          createdAt: DateTime.now(),
          retryCount: 1,
          maxRetries: 3,
        );

        final str = op.toString();
        expect(str, contains('test-id'));
        expect(str, contains('/test/file.md'));
        expect(str, contains('upload'));
        expect(str, contains('pending'));
        expect(str, contains('1/3'));
      });
    });
  });

  group('SyncOperationType', () {
    test('应该正确转换字符串', () {
      expect(SyncOperationType.upload.value, equals('upload'));
      expect(SyncOperationType.download.value, equals('download'));
      expect(SyncOperationType.delete.value, equals('delete'));
    });

    test('应该从字符串创建枚举', () {
      expect(SyncOperationType.fromString('upload'), equals(SyncOperationType.upload));
      expect(SyncOperationType.fromString('download'), equals(SyncOperationType.download));
      expect(SyncOperationType.fromString('delete'), equals(SyncOperationType.delete));
    });

    test('无效字符串应该返回默认值', () {
      expect(SyncOperationType.fromString('invalid'), equals(SyncOperationType.upload));
    });
  });

  group('SyncOperationStatus', () {
    test('应该正确转换字符串', () {
      expect(SyncOperationStatus.pending.value, equals('pending'));
      expect(SyncOperationStatus.inProgress.value, equals('in_progress'));
      expect(SyncOperationStatus.completed.value, equals('completed'));
      expect(SyncOperationStatus.failed.value, equals('failed'));
      expect(SyncOperationStatus.cancelled.value, equals('cancelled'));
    });

    test('应该从字符串创建枚举', () {
      expect(SyncOperationStatus.fromString('pending'), equals(SyncOperationStatus.pending));
      expect(SyncOperationStatus.fromString('in_progress'), equals(SyncOperationStatus.inProgress));
      expect(SyncOperationStatus.fromString('completed'), equals(SyncOperationStatus.completed));
      expect(SyncOperationStatus.fromString('failed'), equals(SyncOperationStatus.failed));
      expect(SyncOperationStatus.fromString('cancelled'), equals(SyncOperationStatus.cancelled));
    });

    test('无效字符串应该返回默认值', () {
      expect(SyncOperationStatus.fromString('invalid'), equals(SyncOperationStatus.pending));
    });
  });
}