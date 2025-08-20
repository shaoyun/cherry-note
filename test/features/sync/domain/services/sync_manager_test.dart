import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:cherry_note/features/sync/domain/services/sync_manager.dart';
import 'package:cherry_note/features/sync/domain/services/sync_service.dart';
import 'package:cherry_note/features/sync/domain/services/sync_queue_service.dart';
import 'package:cherry_note/features/sync/domain/entities/sync_operation.dart';

// 生成Mock类
@GenerateMocks([SyncService, SyncQueueService])
import 'sync_manager_test.mocks.dart';

void main() {
  late SyncManager syncManager;
  late MockSyncService mockSyncService;
  late MockSyncQueueService mockQueueService;

  setUp(() {
    mockSyncService = MockSyncService();
    mockQueueService = MockSyncQueueService();
    
    syncManager = SyncManager(
      syncService: mockSyncService,
      queueService: mockQueueService,
    );
  });

  tearDown(() {
    syncManager.dispose();
  });

  group('SyncManager', () {
    group('启动和停止', () {
      test('应该能够启动同步管理器', () async {
        // Arrange
        when(mockSyncService.enableAutoSync()).thenAnswer((_) async {});

        // Act
        await syncManager.start();

        // Assert
        verify(mockSyncService.enableAutoSync()).called(1);
      });

      test('应该能够停止同步管理器', () async {
        // Arrange
        when(mockSyncService.disableAutoSync()).thenAnswer((_) async {});

        // Act
        await syncManager.stop();

        // Assert
        verify(mockSyncService.disableAutoSync()).called(1);
      });
    });

    group('文件操作调度', () {
      test('应该能够调度文件上传', () async {
        // Arrange
        const filePath = '/test/file.md';
        when(mockQueueService.enqueue(any)).thenAnswer((_) async {});

        // Act
        await syncManager.scheduleFileUpload(filePath);

        // Assert
        verify(mockQueueService.enqueue(any)).called(1);
      });

      test('应该能够调度文件下载', () async {
        // Arrange
        const filePath = '/test/file.md';
        when(mockQueueService.enqueue(any)).thenAnswer((_) async {});

        // Act
        await syncManager.scheduleFileDownload(filePath);

        // Assert
        verify(mockQueueService.enqueue(any)).called(1);
      });

      test('应该能够调度文件删除', () async {
        // Arrange
        const filePath = '/test/file.md';
        when(mockQueueService.enqueue(any)).thenAnswer((_) async {});

        // Act
        await syncManager.scheduleFileDelete(filePath);

        // Assert
        verify(mockQueueService.enqueue(any)).called(1);
      });
    });

    group('立即同步', () {
      test('应该能够立即同步文件', () async {
        // Arrange
        const filePath = '/test/file.md';
        const expectedResult = SyncResult(success: true, syncedFiles: [filePath]);
        when(mockSyncService.syncFile(filePath)).thenAnswer((_) async => expectedResult);

        // Act
        final result = await syncManager.syncFileNow(filePath);

        // Assert
        expect(result.success, isTrue);
        expect(result.syncedFiles, contains(filePath));
        verify(mockSyncService.syncFile(filePath)).called(1);
      });

      test('应该能够执行完整同步', () async {
        // Arrange
        const expectedResult = SyncResult(success: true);
        when(mockSyncService.fullSync()).thenAnswer((_) async => expectedResult);

        // Act
        final result = await syncManager.performFullSync();

        // Assert
        expect(result.success, isTrue);
        verify(mockSyncService.fullSync()).called(1);
      });
    });

    group('状态查询', () {
      test('应该能够获取同步状态', () async {
        // Arrange
        const expectedInfo = SyncInfo(status: SyncStatus.idle);
        when(mockSyncService.getSyncInfo()).thenAnswer((_) async => expectedInfo);

        // Act
        final info = await syncManager.getSyncStatus();

        // Assert
        expect(info.status, equals(SyncStatus.idle));
        verify(mockSyncService.getSyncInfo()).called(1);
      });

      test('应该能够获取队列统计', () async {
        // Arrange
        const expectedStats = SyncQueueStats(
          totalOperations: 5,
          pendingOperations: 2,
          inProgressOperations: 1,
          completedOperations: 2,
          failedOperations: 0,
          cancelledOperations: 0,
        );
        when(mockQueueService.getQueueStats()).thenAnswer((_) async => expectedStats);

        // Act
        final stats = await syncManager.getQueueStats();

        // Assert
        expect(stats.totalOperations, equals(5));
        expect(stats.pendingOperations, equals(2));
        verify(mockQueueService.getQueueStats()).called(1);
      });

      test('应该能够检查是否有待处理操作', () async {
        // Arrange
        when(mockQueueService.hasPendingOperations()).thenAnswer((_) async => true);

        // Act
        final hasPending = await syncManager.hasPendingOperations();

        // Assert
        expect(hasPending, isTrue);
        verify(mockQueueService.hasPendingOperations()).called(1);
      });
    });

    group('冲突处理', () {
      test('应该能够获取冲突列表', () async {
        // Arrange
        final expectedConflicts = [
          FileConflict(
            filePath: '/test/file.md',
            localModified: DateTime.now(),
            remoteModified: DateTime.now().add(const Duration(minutes: 1)),
            localContent: 'Local content',
            remoteContent: 'Remote content',
          ),
        ];
        when(mockSyncService.getConflicts()).thenAnswer((_) async => expectedConflicts);

        // Act
        final conflicts = await syncManager.getConflicts();

        // Assert
        expect(conflicts.length, equals(1));
        expect(conflicts.first.filePath, equals('/test/file.md'));
        verify(mockSyncService.getConflicts()).called(1);
      });

      test('应该能够解决冲突', () async {
        // Arrange
        const filePath = '/test/file.md';
        const resolution = ConflictResolution.keepLocal;
        when(mockSyncService.handleConflict(filePath, resolution)).thenAnswer((_) async {});

        // Act
        await syncManager.resolveConflict(filePath, resolution);

        // Assert
        verify(mockSyncService.handleConflict(filePath, resolution)).called(1);
      });
    });

    group('同步控制', () {
      test('应该能够暂停同步', () async {
        // Arrange
        when(mockSyncService.pauseSync()).thenAnswer((_) async {});

        // Act
        await syncManager.pauseSync();

        // Assert
        verify(mockSyncService.pauseSync()).called(1);
      });

      test('应该能够恢复同步', () async {
        // Arrange
        when(mockSyncService.resumeSync()).thenAnswer((_) async {});

        // Act
        await syncManager.resumeSync();

        // Assert
        verify(mockSyncService.resumeSync()).called(1);
      });
    });

    group('维护操作', () {
      test('应该能够执行清理', () async {
        // Arrange
        when(mockSyncService.cleanup()).thenAnswer((_) async {});

        // Act
        await syncManager.cleanup();

        // Assert
        verify(mockSyncService.cleanup()).called(1);
      });

      test('应该能够重置同步', () async {
        // Arrange
        when(mockSyncService.resetSync()).thenAnswer((_) async {});
        when(mockQueueService.clearQueue()).thenAnswer((_) async {});

        // Act
        await syncManager.reset();

        // Assert
        verify(mockSyncService.resetSync()).called(1);
        verify(mockQueueService.clearQueue()).called(1);
      });
    });

    group('事件流', () {
      test('应该能够访问同步状态流', () {
        // Arrange
        final statusStream = Stream<SyncStatus>.fromIterable([SyncStatus.idle]);
        when(mockSyncService.syncStatusStream).thenAnswer((_) => statusStream);

        // Act
        final stream = syncManager.syncStatusStream;

        // Assert
        expect(stream, equals(statusStream));
      });

      test('应该能够访问队列事件流', () {
        // Arrange
        final queueStream = Stream<SyncQueueEvent>.fromIterable([]);
        when(mockQueueService.queueEvents).thenAnswer((_) => queueStream);

        // Act
        final stream = syncManager.queueEventStream;

        // Assert
        expect(stream, equals(queueStream));
      });
    });
  });
}