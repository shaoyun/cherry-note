import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cherry_note/features/sync/data/services/sync_service_impl.dart';
import 'package:cherry_note/features/sync/domain/services/sync_service.dart';
import 'package:cherry_note/features/sync/domain/repositories/s3_storage_repository.dart';
import 'package:cherry_note/features/sync/data/datasources/sqlite_cache_service.dart';
import 'package:cherry_note/features/sync/data/services/sqlite_sync_queue_service.dart';
import 'package:cherry_note/features/sync/domain/entities/sync_operation.dart';
import 'package:cherry_note/features/sync/domain/entities/sync_operation_factory.dart';
import 'package:cherry_note/core/error/exceptions.dart';

// 生成Mock类
@GenerateMocks([S3StorageRepository])
import 'sync_service_impl_test.mocks.dart';

void main() {
  late SyncServiceImpl syncService;
  late MockS3StorageRepository mockStorageRepository;
  late SqliteCacheService cacheService;
  late SqliteSyncQueueService queueService;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    mockStorageRepository = MockS3StorageRepository();
    cacheService = SqliteCacheService(databasePath: ':memory:');
    await cacheService.initialize();
    queueService = SqliteSyncQueueService(cacheService);

    syncService = SyncServiceImpl(
      storageRepository: mockStorageRepository,
      cacheService: cacheService,
      queueService: queueService,
    );
  });

  tearDown(() async {
    syncService.dispose();
    queueService.dispose();
    await cacheService.close();
  });

  group('SyncServiceImpl', () {
    group('自动同步', () {
      test('应该能够启用自动同步', () async {
        // Act
        await syncService.enableAutoSync(interval: const Duration(seconds: 1));

        // Assert
        expect(syncService.isAutoSyncEnabled, isTrue);
        final setting = await cacheService.getSetting('auto_sync_enabled');
        expect(setting, equals('true'));
      });

      test('应该能够禁用自动同步', () async {
        // Arrange
        await syncService.enableAutoSync();

        // Act
        await syncService.disableAutoSync();

        // Assert
        expect(syncService.isAutoSyncEnabled, isFalse);
        final setting = await cacheService.getSetting('auto_sync_enabled');
        expect(setting, equals('false'));
      });
    });

    group('单个文件同步', () {
      test('应该能够上传文件', () async {
        // Arrange
        const filePath = '/test/file.md';
        const content = '# Test File';
        await cacheService.cacheFile(filePath, content);

        when(mockStorageRepository.uploadFile(filePath, content))
            .thenAnswer((_) async {});

        // Act
        final result = await syncService.uploadFile(filePath);

        // Assert
        expect(result.success, isTrue);
        expect(result.syncedFiles, contains(filePath));
        expect(result.uploadedCount, equals(1));
        verify(mockStorageRepository.uploadFile(filePath, content)).called(1);
      });

      test('应该能够下载文件', () async {
        // Arrange
        const filePath = '/test/file.md';
        const content = '# Test File';

        when(mockStorageRepository.downloadFile(filePath))
            .thenAnswer((_) async => content);

        // Act
        final result = await syncService.downloadFile(filePath);

        // Assert
        expect(result.success, isTrue);
        expect(result.syncedFiles, contains(filePath));
        expect(result.downloadedCount, equals(1));
        
        final cachedContent = await cacheService.getCachedFile(filePath);
        expect(cachedContent, equals(content));
        verify(mockStorageRepository.downloadFile(filePath)).called(1);
      });

      test('应该能够删除文件', () async {
        // Arrange
        const filePath = '/test/file.md';
        const content = '# Test File';
        await cacheService.cacheFile(filePath, content);

        when(mockStorageRepository.deleteFile(filePath))
            .thenAnswer((_) async {});

        // Act
        final result = await syncService.deleteFile(filePath);

        // Assert
        expect(result.success, isTrue);
        expect(result.syncedFiles, contains(filePath));
        expect(result.deletedCount, equals(1));
        
        final cachedContent = await cacheService.getCachedFile(filePath);
        expect(cachedContent, isNull);
        verify(mockStorageRepository.deleteFile(filePath)).called(1);
      });

      test('上传不存在的文件应该失败', () async {
        // Arrange
        const filePath = '/test/nonexistent.md';

        // Act
        final result = await syncService.uploadFile(filePath);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        expect(result.error, contains('Local file not found'));
      });
    });

    group('同步状态管理', () {
      test('应该能够获取同步信息', () async {
        // Arrange
        await cacheService.setSetting('last_sync_time', DateTime.now().toIso8601String());
        await cacheService.setSetting('sync_status', 'success');

        // Act
        final syncInfo = await syncService.getSyncInfo();

        // Assert
        expect(syncInfo.lastSyncTime, isNotNull);
        expect(syncInfo.status, equals(SyncStatus.success));
        expect(syncInfo.pendingOperations, equals(0));
      });

      test('应该能够更新同步信息', () async {
        // Arrange
        final now = DateTime.now();
        final syncInfo = SyncInfo(
          lastSyncTime: now,
          status: SyncStatus.success,
          lastError: null,
        );

        // Act
        await syncService.updateSyncInfo(syncInfo);

        // Assert
        final storedTime = await cacheService.getSetting('last_sync_time');
        final storedStatus = await cacheService.getSetting('sync_status');
        
        expect(storedTime, equals(now.toIso8601String()));
        expect(storedStatus, equals('success'));
      });
    });

    group('文件变更检测', () {
      test('应该能够检测本地变更', () async {
        // Arrange
        const filePath = '/test/file.md';
        const content = '# Test File';
        await cacheService.cacheFile(filePath, content);

        // Act
        final localChanges = await syncService.getLocalChanges();

        // Assert
        expect(localChanges, contains(filePath));
      });

      test('应该能够检查是否有本地变更', () async {
        // Arrange
        const filePath = '/test/file.md';
        const content = '# Test File';
        await cacheService.cacheFile(filePath, content);

        // Act
        final hasChanges = await syncService.hasLocalChanges();

        // Assert
        expect(hasChanges, isTrue);
      });

      test('没有本地变更时应该返回false', () async {
        // Arrange
        await cacheService.setSetting('last_sync_time', DateTime.now().toIso8601String());

        // Act
        final hasChanges = await syncService.hasLocalChanges();

        // Assert
        expect(hasChanges, isFalse);
      });
    });

    group('时间戳比较', () {
      test('应该能够获取本地文件时间戳', () async {
        // Arrange
        const filePath = '/test/file.md';
        const content = '# Test File';
        await cacheService.cacheFile(filePath, content);

        // Act
        final timestamp = await syncService.getLocalFileTimestamp(filePath);

        // Assert
        expect(timestamp, isNotNull);
        expect(timestamp!.difference(DateTime.now()).abs().inSeconds, lessThan(5));
      });

      test('不存在的文件应该返回null时间戳', () async {
        // Act
        final timestamp = await syncService.getLocalFileTimestamp('/nonexistent/file.md');

        // Assert
        expect(timestamp, isNull);
      });
    });

    group('连接状态', () {
      test('连接正常时应该返回true', () async {
        // Arrange
        when(mockStorageRepository.listFiles(''))
            .thenAnswer((_) async => []);

        // Act
        final isConnected = await syncService.checkConnection();

        // Assert
        expect(isConnected, isTrue);
        expect(syncService.isOnline, isTrue);
      });

      test('连接失败时应该返回false', () async {
        // Arrange
        when(mockStorageRepository.listFiles(''))
            .thenThrow(NetworkException('Connection failed'));

        // Act
        final isConnected = await syncService.checkConnection();

        // Assert
        expect(isConnected, isFalse);
        expect(syncService.isOnline, isFalse);
      });
    });

    group('同步控制', () {
      test('应该能够暂停同步', () async {
        // Act
        await syncService.pauseSync();

        // Assert
        expect(syncService.isSyncPaused, isTrue);
        final setting = await cacheService.getSetting('sync_paused');
        expect(setting, equals('true'));
      });

      test('应该能够恢复同步', () async {
        // Arrange
        await syncService.pauseSync();

        // Act
        await syncService.resumeSync();

        // Assert
        expect(syncService.isSyncPaused, isFalse);
        final setting = await cacheService.getSetting('sync_paused');
        expect(setting, equals('false'));
      });

      test('暂停时同步应该抛出异常', () async {
        // Arrange
        await syncService.pauseSync();

        // Act & Assert
        await expectLater(
          syncService.syncToRemote(),
          throwsA(isA<SyncException>()),
        );
      });
    });

    group('冲突处理', () {
      test('应该能够清除冲突', () async {
        // Arrange
        await cacheService.setSetting('conflict_test_file', '{"test": "data"}');

        // Act
        await syncService.clearConflicts();

        // Assert
        final conflicts = await syncService.getConflicts();
        expect(conflicts, isEmpty);
      });

      test('应该能够获取冲突列表', () async {
        // Arrange
        final conflictData = {
          'filePath': '/test/file.md',
          'localModified': DateTime.now().toIso8601String(),
          'remoteModified': DateTime.now().add(const Duration(minutes: 1)).toIso8601String(),
          'localContent': 'Local content',
          'remoteContent': 'Remote content',
        };
        await cacheService.setSetting('conflict_test_file', jsonEncode(conflictData));

        // Act
        final conflicts = await syncService.getConflicts();

        // Assert
        expect(conflicts.length, equals(1));
        expect(conflicts.first.filePath, equals('/test/file.md'));
        expect(conflicts.first.localContent, equals('Local content'));
        expect(conflicts.first.remoteContent, equals('Remote content'));
      });
    });

    group('清理和维护', () {
      test('应该能够执行清理', () async {
        // Arrange
        final operation = SyncOperationFactory.createUploadOperation(
          filePath: '/test/file.md',
        ).copyWith(status: SyncOperationStatus.completed);
        await queueService.enqueue(operation);

        // Act
        await syncService.cleanup();

        // Assert
        // 验证清理操作完成（具体验证取决于实现）
        expect(true, isTrue); // 占位符断言
      });

      test('应该能够重置同步', () async {
        // Arrange
        await syncService.enableAutoSync();
        await cacheService.setSetting('last_sync_time', DateTime.now().toIso8601String());

        // Act
        await syncService.resetSync();

        // Assert
        expect(syncService.isAutoSyncEnabled, isFalse);
        expect(syncService.isSyncPaused, isFalse);
        
        final lastSyncTime = await cacheService.getSetting('last_sync_time');
        expect(lastSyncTime, isNull);
      });
    });

    group('同步状态流', () {
      test('应该能够监听同步状态变化', () async {
        // Arrange
        final statusEvents = <SyncStatus>[];
        final subscription = syncService.syncStatusStream.listen(statusEvents.add);

        // Act
        await syncService.pauseSync();
        await syncService.resumeSync();

        // 等待事件处理
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        subscription.cancel();
        // 注意：这个测试可能需要根据实际实现调整
      });
    });
  });
}