import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cherry_note/features/sync/data/services/auto_sync_service_impl.dart';
import 'package:cherry_note/features/sync/domain/services/auto_sync_service.dart';
import 'package:cherry_note/features/sync/domain/services/sync_manager.dart';
import 'package:cherry_note/features/sync/data/datasources/sqlite_cache_service.dart';

// 生成Mock类
@GenerateMocks([SyncManager])
import 'auto_sync_service_impl_test.mocks.dart';

void main() {
  late AutoSyncServiceImpl autoSyncService;
  late MockSyncManager mockSyncManager;
  late SqliteCacheService cacheService;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    mockSyncManager = MockSyncManager();
    cacheService = SqliteCacheService(databasePath: ':memory:');
    await cacheService.initialize();

    autoSyncService = AutoSyncServiceImpl(
      syncManager: mockSyncManager,
      cacheService: cacheService,
    );
  });

  tearDown(() async {
    autoSyncService.dispose();
    await cacheService.close();
  });

  group('AutoSyncServiceImpl', () {
    group('配置管理', () {
      test('应该能够设置和获取配置', () async {
        // Arrange
        const config = AutoSyncConfig(
          syncInterval: Duration(minutes: 10),
          syncOnFileChange: false,
          syncOnAppStart: false,
        );

        // Act
        await autoSyncService.configure(config);
        final retrievedConfig = await autoSyncService.getConfig();

        // Assert
        expect(retrievedConfig.syncInterval, equals(const Duration(minutes: 10)));
        expect(retrievedConfig.syncOnFileChange, isFalse);
        expect(retrievedConfig.syncOnAppStart, isFalse);
      });

      test('应该能够持久化配置', () async {
        // Arrange
        const config = AutoSyncConfig(
          syncInterval: Duration(minutes: 15),
          debounceDelay: Duration(seconds: 60),
        );

        // Act
        await autoSyncService.configure(config);

        // 创建新的服务实例来测试持久化
        final newService = AutoSyncServiceImpl(
          syncManager: mockSyncManager,
          cacheService: cacheService,
        );
        final loadedConfig = await newService.getConfig();

        // Assert
        expect(loadedConfig.syncInterval, equals(const Duration(minutes: 15)));
        expect(loadedConfig.debounceDelay, equals(const Duration(seconds: 60)));

        newService.dispose();
      });
    });

    group('启用和禁用', () {
      test('应该能够启用自动同步', () async {
        // Arrange
        expect(autoSyncService.isEnabled, isFalse);
        expect(autoSyncService.state, equals(AutoSyncState.disabled));

        // Act
        await autoSyncService.enable();

        // Assert
        expect(autoSyncService.isEnabled, isTrue);
        expect(autoSyncService.state, equals(AutoSyncState.enabled));
      });

      test('应该能够禁用自动同步', () async {
        // Arrange
        await autoSyncService.enable();
        expect(autoSyncService.isEnabled, isTrue);

        // Act
        await autoSyncService.disable();

        // Assert
        expect(autoSyncService.isEnabled, isFalse);
        expect(autoSyncService.state, equals(AutoSyncState.disabled));
      });

      test('应该能够暂停和恢复自动同步', () async {
        // Arrange
        await autoSyncService.enable();
        expect(autoSyncService.state, equals(AutoSyncState.enabled));

        // Act - 暂停
        await autoSyncService.pause();

        // Assert
        expect(autoSyncService.isPaused, isTrue);
        expect(autoSyncService.state, equals(AutoSyncState.paused));

        // Act - 恢复
        await autoSyncService.resume();

        // Assert
        expect(autoSyncService.isPaused, isFalse);
        expect(autoSyncService.state, equals(AutoSyncState.enabled));
      });
    });

    group('手动触发同步', () {
      test('应该能够手动触发同步', () async {
        // Arrange
        await autoSyncService.enable();
        
        when(mockSyncManager.performFullSync())
            .thenAnswer((_) async => SyncResult(
              success: true,
              syncedFiles: ['file1.md'],
              conflicts: [],
            ));

        // Act
        await autoSyncService.triggerSync(reason: 'manual');

        // Assert
        verify(mockSyncManager.performFullSync()).called(1);
        final stats = await autoSyncService.getStats();
        expect(stats.totalSyncs, equals(1));
        expect(stats.successfulSyncs, equals(1));
      });

      test('应该能够触发单个文件同步', () async {
        // Arrange
        await autoSyncService.enable();
        const filePath = '/test/file.md';
        
        when(mockSyncManager.syncFileNow(filePath))
            .thenAnswer((_) async => {});

        // Act
        await autoSyncService.triggerFileSync(filePath);

        // Assert
        verify(mockSyncManager.syncFileNow(filePath)).called(1);
      });

      test('禁用时不应该触发同步', () async {
        // Arrange
        expect(autoSyncService.isEnabled, isFalse);

        // Act
        await autoSyncService.triggerSync();

        // Assert
        verifyNever(mockSyncManager.performFullSync());
      });
    });

    group('文件变更监听', () {
      test('应该能够监听文件创建', () async {
        // Arrange
        await autoSyncService.enable();
        await autoSyncService.configure(const AutoSyncConfig(
          syncOnFileChange: true,
          debounceDelay: Duration(milliseconds: 100),
        ));

        when(mockSyncManager.syncFileNow(any))
            .thenAnswer((_) async => {});

        // Act
        autoSyncService.onFileCreated('/test/new_file.md');

        // 等待防抖动延迟
        await Future.delayed(const Duration(milliseconds: 150));

        // Assert
        verify(mockSyncManager.syncFileNow('/test/new_file.md')).called(1);
      });

      test('应该能够监听文件修改', () async {
        // Arrange
        await autoSyncService.enable();
        await autoSyncService.configure(const AutoSyncConfig(
          syncOnFileChange: true,
          debounceDelay: Duration(milliseconds: 100),
        ));

        when(mockSyncManager.syncFileNow(any))
            .thenAnswer((_) async => {});

        // Act
        autoSyncService.onFileModified('/test/modified_file.md');

        // 等待防抖动延迟
        await Future.delayed(const Duration(milliseconds: 150));

        // Assert
        verify(mockSyncManager.syncFileNow('/test/modified_file.md')).called(1);
      });

      test('应该能够监听文件删除', () async {
        // Arrange
        await autoSyncService.enable();
        await autoSyncService.configure(const AutoSyncConfig(
          syncOnFileChange: true,
          debounceDelay: Duration(milliseconds: 100),
        ));

        when(mockSyncManager.syncFileNow(any))
            .thenAnswer((_) async => {});

        // Act
        autoSyncService.onFileDeleted('/test/deleted_file.md');

        // 等待防抖动延迟
        await Future.delayed(const Duration(milliseconds: 150));

        // Assert
        verify(mockSyncManager.syncFileNow('/test/deleted_file.md')).called(1);
      });

      test('禁用文件变更同步时不应该触发', () async {
        // Arrange
        await autoSyncService.enable();
        await autoSyncService.configure(const AutoSyncConfig(
          syncOnFileChange: false,
        ));

        // Act
        autoSyncService.onFileModified('/test/file.md');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verifyNever(mockSyncManager.syncFileNow(any));
      });

      test('应该正确处理排除模式', () async {
        // Arrange
        await autoSyncService.enable();
        await autoSyncService.configure(const AutoSyncConfig(
          syncOnFileChange: true,
          excludePatterns: ['.tmp', '.backup'],
          debounceDelay: Duration(milliseconds: 100),
        ));

        // Act
        autoSyncService.onFileModified('/test/file.tmp');
        autoSyncService.onFileModified('/test/file.backup');
        autoSyncService.onFileModified('/test/file.md');

        await Future.delayed(const Duration(milliseconds: 150));

        // Assert
        verify(mockSyncManager.syncFileNow('/test/file.md')).called(1);
        verifyNever(mockSyncManager.syncFileNow('/test/file.tmp'));
        verifyNever(mockSyncManager.syncFileNow('/test/file.backup'));
      });
    });

    group('应用生命周期', () {
      test('应用启动时应该触发同步', () async {
        // Arrange
        await autoSyncService.configure(const AutoSyncConfig(
          syncOnAppStart: true,
        ));
        await autoSyncService.enable();

        when(mockSyncManager.performFullSync())
            .thenAnswer((_) async => SyncResult(
              success: true,
              syncedFiles: [],
              conflicts: [],
            ));

        // Act
        await autoSyncService.onAppStart();

        // Assert
        verify(mockSyncManager.performFullSync()).called(1);
        final stats = await autoSyncService.getStats();
        expect(stats.appStartSyncs, equals(1));
      });

      test('应用恢复时应该触发同步', () async {
        // Arrange
        await autoSyncService.enable();
        await autoSyncService.configure(const AutoSyncConfig(
          syncOnAppResume: true,
        ));

        when(mockSyncManager.performFullSync())
            .thenAnswer((_) async => SyncResult(
              success: true,
              syncedFiles: [],
              conflicts: [],
            ));

        // Act
        await autoSyncService.onAppResume();

        // Assert
        verify(mockSyncManager.performFullSync()).called(1);
      });

      test('禁用应用启动同步时不应该触发', () async {
        // Arrange
        await autoSyncService.configure(const AutoSyncConfig(
          syncOnAppStart: false,
        ));
        await autoSyncService.enable();

        // Act
        await autoSyncService.onAppStart();

        // Assert
        verifyNever(mockSyncManager.performFullSync());
      });
    });

    group('定时同步', () {
      test('启用后应该开始定时同步', () async {
        // Arrange
        await autoSyncService.configure(const AutoSyncConfig(
          syncInterval: Duration(milliseconds: 200),
        ));

        when(mockSyncManager.performFullSync())
            .thenAnswer((_) async => SyncResult(
              success: true,
              syncedFiles: [],
              conflicts: [],
            ));

        // Act
        await autoSyncService.enable();

        // 等待至少一次定时同步
        await Future.delayed(const Duration(milliseconds: 250));

        // Assert
        verify(mockSyncManager.performFullSync()).called(greaterThan(0));
        final stats = await autoSyncService.getStats();
        expect(stats.periodicSyncs, greaterThan(0));
      });

      test('暂停时应该停止定时同步', () async {
        // Arrange
        await autoSyncService.configure(const AutoSyncConfig(
          syncInterval: Duration(milliseconds: 100),
        ));
        await autoSyncService.enable();

        when(mockSyncManager.performFullSync())
            .thenAnswer((_) async => SyncResult(
              success: true,
              syncedFiles: [],
              conflicts: [],
            ));

        // 等待一次同步
        await Future.delayed(const Duration(milliseconds: 150));
        final statsBeforePause = await autoSyncService.getStats();

        // Act
        await autoSyncService.pause();
        await Future.delayed(const Duration(milliseconds: 150));
        final statsAfterPause = await autoSyncService.getStats();

        // Assert
        expect(statsAfterPause.periodicSyncs, equals(statsBeforePause.periodicSyncs));
      });
    });

    group('事件流', () {
      test('应该发出状态变更事件', () async {
        // Arrange
        final stateEvents = <AutoSyncState>[];
        final subscription = autoSyncService.stateStream.listen(stateEvents.add);

        // Act
        await autoSyncService.enable();
        await autoSyncService.pause();
        await autoSyncService.resume();
        await autoSyncService.disable();

        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(stateEvents, contains(AutoSyncState.enabled));
        expect(stateEvents, contains(AutoSyncState.paused));
        expect(stateEvents, contains(AutoSyncState.disabled));

        await subscription.cancel();
      });

      test('应该发出同步事件', () async {
        // Arrange
        final events = <AutoSyncEvent>[];
        final subscription = autoSyncService.eventStream.listen(events.add);

        await autoSyncService.enable();

        // Act
        autoSyncService.onFileCreated('/test/file.md');
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.whereType<FileChangeSyncEvent>().length, equals(1));
        final fileEvent = events.whereType<FileChangeSyncEvent>().first;
        expect(fileEvent.filePath, equals('/test/file.md'));
        expect(fileEvent.changeType, equals('created'));

        await subscription.cancel();
      });
    });

    group('统计信息', () {
      test('应该正确记录统计信息', () async {
        // Arrange
        await autoSyncService.enable();

        when(mockSyncManager.performFullSync())
            .thenAnswer((_) async => SyncResult(
              success: true,
              syncedFiles: ['file1.md'],
              conflicts: [],
            ));

        // Act
        await autoSyncService.triggerSync(reason: 'test');
        final stats = await autoSyncService.getStats();

        // Assert
        expect(stats.totalSyncs, equals(1));
        expect(stats.successfulSyncs, equals(1));
        expect(stats.failedSyncs, equals(0));
        expect(stats.successRate, equals(1.0));
        expect(stats.lastSyncTime, isNotNull);
        expect(stats.lastSuccessfulSyncTime, isNotNull);
      });

      test('应该记录失败的同步', () async {
        // Arrange
        await autoSyncService.enable();

        when(mockSyncManager.performFullSync())
            .thenThrow(Exception('Sync failed'));

        // Act
        await autoSyncService.triggerSync(reason: 'test');
        final stats = await autoSyncService.getStats();

        // Assert
        expect(stats.totalSyncs, equals(1));
        expect(stats.successfulSyncs, equals(0));
        expect(stats.failedSyncs, equals(1));
        expect(stats.successRate, equals(0.0));
        expect(stats.lastError, isNotNull);
        expect(autoSyncService.state, equals(AutoSyncState.error));
      });

      test('应该能够重置统计信息', () async {
        // Arrange
        await autoSyncService.enable();

        when(mockSyncManager.performFullSync())
            .thenAnswer((_) async => SyncResult(
              success: true,
              syncedFiles: [],
              conflicts: [],
            ));

        await autoSyncService.triggerSync();
        final statsBefore = await autoSyncService.getStats();
        expect(statsBefore.totalSyncs, equals(1));

        // Act
        await autoSyncService.resetStats();
        final statsAfter = await autoSyncService.getStats();

        // Assert
        expect(statsAfter.totalSyncs, equals(0));
        expect(statsAfter.successfulSyncs, equals(0));
        expect(statsAfter.failedSyncs, equals(0));
      });

      test('应该持久化统计信息', () async {
        // Arrange
        await autoSyncService.enable();

        when(mockSyncManager.performFullSync())
            .thenAnswer((_) async => SyncResult(
              success: true,
              syncedFiles: [],
              conflicts: [],
            ));

        await autoSyncService.triggerSync();
        await autoSyncService.cleanup();

        // Act - 创建新实例
        final newService = AutoSyncServiceImpl(
          syncManager: mockSyncManager,
          cacheService: cacheService,
        );
        await newService.enable();
        final stats = await newService.getStats();

        // Assert
        expect(stats.totalSyncs, equals(1));
        expect(stats.successfulSyncs, equals(1));

        newService.dispose();
      });
    });

    group('清理和维护', () {
      test('应该能够正确清理资源', () async {
        // Arrange
        await autoSyncService.enable();

        // Act
        await autoSyncService.cleanup();

        // Assert
        expect(autoSyncService.state, equals(AutoSyncState.disabled));
      });
    });
  });
}