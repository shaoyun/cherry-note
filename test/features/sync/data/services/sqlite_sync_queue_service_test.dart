import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cherry_note/features/sync/data/services/sqlite_sync_queue_service.dart';
import 'package:cherry_note/features/sync/data/datasources/sqlite_cache_service.dart';
import 'package:cherry_note/features/sync/domain/entities/sync_operation.dart';
import 'package:cherry_note/features/sync/domain/entities/sync_operation_factory.dart';
import 'package:cherry_note/features/sync/domain/services/sync_queue_service.dart';
import 'package:cherry_note/core/error/exceptions.dart';

void main() {
  late SqliteSyncQueueService queueService;
  late SqliteCacheService cacheService;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    cacheService = SqliteCacheService(databasePath: ':memory:');
    await cacheService.initialize();
    queueService = SqliteSyncQueueService(cacheService);
  });

  tearDown(() async {
    queueService.dispose();
    await cacheService.close();
  });

  group('SqliteSyncQueueService', () {
    group('enqueue', () {
      test('应该能够添加操作到队列', () async {
        // Arrange
        final operation = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
        );

        // Act
        await queueService.enqueue(operation);

        // Assert
        final pendingOps = await queueService.getPendingOperations();
        expect(pendingOps.length, equals(1));
        expect(pendingOps.first.id, equals(operation.id));
        expect(pendingOps.first.filePath, equals('/test/file.md'));
        expect(pendingOps.first.type, equals(SyncOperationType.upload));
      });

      test('应该避免重复的操作', () async {
        // Arrange
        final operation1 = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
        );
        final operation2 = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
        );

        // Act
        await queueService.enqueue(operation1);
        await queueService.enqueue(operation2);

        // Assert
        final pendingOps = await queueService.getPendingOperations();
        expect(pendingOps.length, equals(1));
      });

      test('应该允许不同类型的操作对同一文件', () async {
        // Arrange
        final uploadOp = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
        );
        final deleteOp = SyncOperationFactory.createDeleteOperation(
          filePath: '/test/file.md',
        );

        // Act
        await queueService.enqueue(uploadOp);
        await queueService.enqueue(deleteOp);

        // Assert
        final pendingOps = await queueService.getPendingOperations();
        expect(pendingOps.length, equals(2));
      });

      test('应该发送入队事件', () async {
        // Arrange
        final operation = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
        );

        // Act & Assert
        expectLater(
          queueService.queueEvents,
          emits(isA<OperationEnqueuedEvent>()),
        );

        await queueService.enqueue(operation);
      });
    });

    group('enqueueAll', () {
      test('应该能够批量添加操作', () async {
        // Arrange
        final operations = [
          SyncOperationFactory.createUploadOperation(filePath: '/test/file1.md'),
          SyncOperationFactory.createUploadOperation(filePath: '/test/file2.md'),
          SyncOperationFactory.createDeleteOperation(filePath: '/test/file3.md'),
        ];

        // Act
        await queueService.enqueueAll(operations);

        // Assert
        final pendingOps = await queueService.getPendingOperations();
        expect(pendingOps.length, equals(3));
      });
    });

    group('dequeue', () {
      test('空队列应该返回null', () async {
        // Act
        final operation = await queueService.dequeue();

        // Assert
        expect(operation, isNull);
      });

      test('应该按优先级返回操作', () async {
        // Arrange - 添加不同优先级的操作
        final uploadOp = SyncOperationFactory.createUploadOperation(
          filePath: '/test/upload.md',
        );
        final deleteOp = SyncOperationFactory.createDeleteOperation(
          filePath: '/test/delete.md',
        );
        final downloadOp = SyncOperationFactory.createDownloadOperation(
          filePath: '/test/download.md',
        );

        await queueService.enqueue(uploadOp);
        await queueService.enqueue(deleteOp);
        await queueService.enqueue(downloadOp);

        // Act
        final firstOp = await queueService.dequeue();

        // Assert - 删除操作应该有最高优先级
        expect(firstOp?.type, equals(SyncOperationType.delete));
        expect(firstOp?.status, equals(SyncOperationStatus.inProgress));
      });

      test('应该标记操作为进行中', () async {
        // Arrange
        final operation = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
        );
        await queueService.enqueue(operation);

        // Act
        final dequeuedOp = await queueService.dequeue();

        // Assert
        expect(dequeuedOp?.status, equals(SyncOperationStatus.inProgress));
      });
    });

    group('getPendingOperations', () {
      test('应该只返回待执行的操作', () async {
        // Arrange
        final pendingOp = SyncOperationFactory.createUploadOperation(
          filePath: '/test/pending.md',
        );
        final completedOp = SyncOperationFactory.createUploadOperation(
          filePath: '/test/completed.md',
        ).copyWith(status: SyncOperationStatus.completed);

        await queueService.enqueue(pendingOp);
        await queueService.enqueue(completedOp);

        // Act
        final pendingOps = await queueService.getPendingOperations();

        // Assert
        expect(pendingOps.length, equals(1));
        expect(pendingOps.first.status, equals(SyncOperationStatus.pending));
      });
    });

    group('getOperationsForFile', () {
      test('应该返回指定文件的所有操作', () async {
        // Arrange
        final targetFile = '/test/target.md';
        final otherFile = '/test/other.md';

        final op1 = SyncOperationFactory.createUploadOperation(filePath: targetFile);
        final op2 = SyncOperationFactory.createDeleteOperation(filePath: targetFile);
        final op3 = SyncOperationFactory.createUploadOperation(filePath: otherFile);

        await queueService.enqueue(op1);
        await queueService.enqueue(op2);
        await queueService.enqueue(op3);

        // Act
        final fileOps = await queueService.getOperationsForFile(targetFile);

        // Assert
        expect(fileOps.length, equals(2));
        expect(fileOps.every((op) => op.filePath == targetFile), isTrue);
      });
    });

    group('updateOperation', () {
      test('应该更新操作状态', () async {
        // Arrange
        final operation = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
        );
        await queueService.enqueue(operation);

        // Act
        final updatedOp = operation.copyWith(
          status: SyncOperationStatus.completed,
          completedAt: DateTime.now(),
        );
        await queueService.updateOperation(updatedOp);

        // Assert
        final fileOps = await queueService.getOperationsForFile('/test/file.md');
        expect(fileOps.first.status, equals(SyncOperationStatus.completed));
        expect(fileOps.first.completedAt, isNotNull);
      });

      test('应该发送更新事件', () async {
        // Arrange
        final operation = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
        );
        await queueService.enqueue(operation);

        // Act & Assert
        expectLater(
          queueService.queueEvents,
          emits(isA<OperationUpdatedEvent>()),
        );

        final updatedOp = operation.copyWith(status: SyncOperationStatus.completed);
        await queueService.updateOperation(updatedOp);
      });
    });

    group('markAsCompleted', () {
      test('应该标记操作为完成', () async {
        // Arrange
        final operation = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
        );
        await queueService.enqueue(operation);

        // Act
        await queueService.markAsCompleted(operation.id);

        // Assert
        final fileOps = await queueService.getOperationsForFile('/test/file.md');
        expect(fileOps.first.status, equals(SyncOperationStatus.completed));
        expect(fileOps.first.completedAt, isNotNull);
      });

      test('应该发送完成事件', () async {
        // Arrange
        final operation = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
        );
        await queueService.enqueue(operation);

        // Act & Assert
        expectLater(
          queueService.queueEvents,
          emitsInOrder([
            isA<OperationUpdatedEvent>(),
            isA<OperationCompletedEvent>(),
          ]),
        );

        await queueService.markAsCompleted(operation.id);
      });
    });

    group('markAsFailed', () {
      test('应该标记操作为失败并增加重试次数', () async {
        // Arrange
        final operation = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
        );
        await queueService.enqueue(operation);

        // Act
        await queueService.markAsFailed(operation.id, 'Test error');

        // Assert
        final fileOps = await queueService.getOperationsForFile('/test/file.md');
        expect(fileOps.first.status, equals(SyncOperationStatus.failed));
        expect(fileOps.first.retryCount, equals(1));
        expect(fileOps.first.errorMessage, equals('Test error'));
      });

      test('应该发送失败事件', () async {
        // Arrange
        final operation = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
        );
        await queueService.enqueue(operation);

        // Act & Assert
        expectLater(
          queueService.queueEvents,
          emitsInOrder([
            isA<OperationUpdatedEvent>(),
            isA<OperationFailedEvent>(),
          ]),
        );

        await queueService.markAsFailed(operation.id, 'Test error');
      });
    });

    group('cancelOperation', () {
      test('应该取消操作', () async {
        // Arrange
        final operation = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
        );
        await queueService.enqueue(operation);

        // Act
        await queueService.cancelOperation(operation.id);

        // Assert
        final fileOps = await queueService.getOperationsForFile('/test/file.md');
        expect(fileOps.first.status, equals(SyncOperationStatus.cancelled));
        expect(fileOps.first.completedAt, isNotNull);
      });
    });

    group('removeOperation', () {
      test('应该删除操作', () async {
        // Arrange
        final operation = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
        );
        await queueService.enqueue(operation);

        // Act
        await queueService.removeOperation(operation.id);

        // Assert
        final fileOps = await queueService.getOperationsForFile('/test/file.md');
        expect(fileOps, isEmpty);
      });
    });

    group('clearQueue', () {
      test('应该清空所有操作', () async {
        // Arrange
        final operations = [
          SyncOperationFactory.createUploadOperation(filePath: '/test/file1.md'),
          SyncOperationFactory.createUploadOperation(filePath: '/test/file2.md'),
          SyncOperationFactory.createDeleteOperation(filePath: '/test/file3.md'),
        ];
        await queueService.enqueueAll(operations);

        // Act
        await queueService.clearQueue();

        // Assert
        final pendingOps = await queueService.getPendingOperations();
        expect(pendingOps, isEmpty);
      });
    });

    group('getQueueStats', () {
      test('应该返回正确的统计信息', () async {
        // Arrange
        final pendingOp = SyncOperationFactory.createUploadOperation(
          filePath: '/test/pending.md',
        );
        final completedOp = SyncOperationFactory.createUploadOperation(
          filePath: '/test/completed.md',
        ).copyWith(status: SyncOperationStatus.completed);
        final failedOp = SyncOperationFactory.createUploadOperation(
          filePath: '/test/failed.md',
        ).copyWith(status: SyncOperationStatus.failed);

        await queueService.enqueue(pendingOp);
        await queueService.enqueue(completedOp);
        await queueService.enqueue(failedOp);

        // Act
        final stats = await queueService.getQueueStats();

        // Assert
        expect(stats.totalOperations, equals(3));
        expect(stats.pendingOperations, equals(1));
        expect(stats.completedOperations, equals(1));
        expect(stats.failedOperations, equals(1));
        expect(stats.inProgressOperations, equals(0));
        expect(stats.cancelledOperations, equals(0));
      });
    });

    group('hasPendingOperations', () {
      test('有待执行操作时应该返回true', () async {
        // Arrange
        final operation = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
        );
        await queueService.enqueue(operation);

        // Act
        final hasPending = await queueService.hasPendingOperations();

        // Assert
        expect(hasPending, isTrue);
      });

      test('没有待执行操作时应该返回false', () async {
        // Act
        final hasPending = await queueService.hasPendingOperations();

        // Assert
        expect(hasPending, isFalse);
      });
    });

    group('getFailedOperations', () {
      test('应该返回所有失败的操作', () async {
        // Arrange
        final pendingOp = SyncOperationFactory.createUploadOperation(
          filePath: '/test/pending.md',
        );
        final failedOp1 = SyncOperationFactory.createUploadOperation(
          filePath: '/test/failed1.md',
        ).copyWith(status: SyncOperationStatus.failed);
        final failedOp2 = SyncOperationFactory.createUploadOperation(
          filePath: '/test/failed2.md',
        ).copyWith(status: SyncOperationStatus.failed);

        await queueService.enqueue(pendingOp);
        await queueService.enqueue(failedOp1);
        await queueService.enqueue(failedOp2);

        // Act
        final failedOps = await queueService.getFailedOperations();

        // Assert
        expect(failedOps.length, equals(2));
        expect(failedOps.every((op) => op.status == SyncOperationStatus.failed), isTrue);
      });
    });

    group('retryFailedOperations', () {
      test('应该重置可重试的失败操作', () async {
        // Arrange
        final retryableOp = SyncOperationFactory.createUploadOperation(
          filePath: '/test/retryable.md',
        ).copyWith(
          status: SyncOperationStatus.failed,
          retryCount: 1,
          maxRetries: 3,
        );
        final nonRetryableOp = SyncOperationFactory.createUploadOperation(
          filePath: '/test/non-retryable.md',
        ).copyWith(
          status: SyncOperationStatus.failed,
          retryCount: 3,
          maxRetries: 3,
        );

        await queueService.enqueue(retryableOp);
        await queueService.enqueue(nonRetryableOp);

        // Act
        await queueService.retryFailedOperations();

        // Assert
        final retryableFileOps = await queueService.getOperationsForFile('/test/retryable.md');
        final nonRetryableFileOps = await queueService.getOperationsForFile('/test/non-retryable.md');

        expect(retryableFileOps.first.status, equals(SyncOperationStatus.pending));
        expect(nonRetryableFileOps.first.status, equals(SyncOperationStatus.failed));
      });
    });

    group('cleanupCompletedOperations', () {
      test('应该清理旧的已完成操作', () async {
        // Arrange
        final oldDate = DateTime.now().subtract(const Duration(days: 10));
        final recentDate = DateTime.now().subtract(const Duration(hours: 1));

        final oldCompletedOp = SyncOperationFactory.createUploadOperation(
          filePath: '/test/old.md',
        ).copyWith(
          status: SyncOperationStatus.completed,
          createdAt: oldDate,
        );
        final recentCompletedOp = SyncOperationFactory.createUploadOperation(
          filePath: '/test/recent.md',
        ).copyWith(
          status: SyncOperationStatus.completed,
          createdAt: recentDate,
        );

        await queueService.enqueue(oldCompletedOp);
        await queueService.enqueue(recentCompletedOp);

        // Act
        await queueService.cleanupCompletedOperations(
          olderThan: const Duration(days: 7),
        );

        // Assert
        final oldFileOps = await queueService.getOperationsForFile('/test/old.md');
        final recentFileOps = await queueService.getOperationsForFile('/test/recent.md');

        expect(oldFileOps, isEmpty);
        expect(recentFileOps.length, equals(1));
      });
    });
  });
}