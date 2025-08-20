import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:cherry_note/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:cherry_note/features/sync/presentation/bloc/sync_event.dart';
import 'package:cherry_note/features/sync/presentation/bloc/sync_state.dart';
import 'package:cherry_note/features/sync/domain/services/sync_service.dart';
import 'package:cherry_note/features/sync/domain/services/auto_sync_service.dart';

import 'sync_bloc_test.mocks.dart';

@GenerateMocks([SyncService, AutoSyncService])
void main() {
  group('SyncBloc', () {
    late MockSyncService mockSyncService;
    late MockAutoSyncService mockAutoSyncService;
    late SyncBloc syncBloc;
    late StreamController<SyncStatus> syncStatusController;
    late StreamController<AutoSyncState> autoSyncStateController;

    setUp(() {
      mockSyncService = MockSyncService();
      mockAutoSyncService = MockAutoSyncService();
      
      // 创建流控制器
      syncStatusController = StreamController<SyncStatus>.broadcast();
      autoSyncStateController = StreamController<AutoSyncState>.broadcast();
      
      // 设置默认的流
      when(mockSyncService.syncStatusStream)
          .thenAnswer((_) => syncStatusController.stream);
      when(mockAutoSyncService.stateStream)
          .thenAnswer((_) => autoSyncStateController.stream);
      
      // 设置默认返回值
      when(mockSyncService.isAutoSyncEnabled).thenReturn(false);
      when(mockSyncService.isSyncPaused).thenReturn(false);
      when(mockSyncService.getSyncInfo()).thenAnswer((_) async => const SyncInfo(
        status: SyncStatus.idle,
        pendingOperations: 0,
        totalFiles: 0,
      ));
      when(mockSyncService.getConflicts()).thenAnswer((_) async => []);
      when(mockSyncService.getModifiedFiles()).thenAnswer((_) async => []);
      when(mockSyncService.checkConnection()).thenAnswer((_) async => true);
      when(mockAutoSyncService.getConfig()).thenAnswer((_) async => const AutoSyncConfig());
      
      syncBloc = SyncBloc(
        syncService: mockSyncService,
        autoSyncService: mockAutoSyncService,
      );
    });

    tearDown(() {
      syncStatusController.close();
      autoSyncStateController.close();
      syncBloc.close();
    });

    test('initial state is SyncInitialState', () {
      expect(syncBloc.state, equals(const SyncInitialState()));
    });

    group('LoadSyncInfoEvent', () {
      blocTest<SyncBloc, SyncState>(
        'emits [SyncLoadingState, SyncReadyState] when loading sync info successfully',
        build: () => syncBloc,
        act: (bloc) => bloc.add(const LoadSyncInfoEvent()),
        expect: () => [
          const SyncLoadingState(),
          isA<SyncReadyState>()
              .having((state) => state.syncInfo.status, 'status', SyncStatus.idle)
              .having((state) => state.isOnline, 'isOnline', true),
        ],
        verify: (_) {
          verify(mockSyncService.getSyncInfo()).called(1);
          verify(mockSyncService.getConflicts()).called(1);
          verify(mockSyncService.getModifiedFiles()).called(1);
          verify(mockSyncService.checkConnection()).called(1);
        },
      );

      blocTest<SyncBloc, SyncState>(
        'emits [SyncLoadingState, SyncErrorState] when loading sync info fails',
        build: () {
          when(mockSyncService.getSyncInfo())
              .thenThrow(Exception('Failed to load sync info'));
          return syncBloc;
        },
        act: (bloc) => bloc.add(const LoadSyncInfoEvent()),
        expect: () => [
          const SyncLoadingState(),
          isA<SyncErrorState>()
              .having((state) => state.error, 'error', contains('Failed to load sync info')),
        ],
      );
    });    
group('StartFullSyncEvent', () {
      blocTest<SyncBloc, SyncState>(
        'emits [SyncInProgressState, SyncSuccessState] when full sync succeeds',
        build: () {
          when(mockSyncService.fullSync()).thenAnswer((_) async => const SyncResult(
            success: true,
            syncedFiles: ['file1.md', 'file2.md'],
            uploadedCount: 1,
            downloadedCount: 1,
          ));
          return syncBloc;
        },
        act: (bloc) => bloc.add(const StartFullSyncEvent()),
        expect: () => [
          isA<SyncInProgressState>()
              .having((state) => state.operation, 'operation', 'full')
              .having((state) => state.syncStatus, 'syncStatus', SyncStatus.syncing),
          isA<SyncSuccessState>()
              .having((state) => state.result.success, 'success', true)
              .having((state) => state.result.syncedFiles.length, 'syncedFiles', 2),
        ],
        verify: (_) {
          verify(mockSyncService.fullSync()).called(1);
        },
      );

      blocTest<SyncBloc, SyncState>(
        'emits [SyncInProgressState, SyncConflictState] when full sync has conflicts',
        build: () {
          final conflicts = [
            FileConflict(
              filePath: 'conflict.md',
              localModified: DateTime.now(),
              remoteModified: DateTime.now().add(const Duration(minutes: 1)),
              localContent: 'local content',
              remoteContent: 'remote content',
            ),
          ];
          when(mockSyncService.fullSync()).thenAnswer((_) async => SyncResult(
            success: true,
            conflicts: conflicts,
          ));
          return syncBloc;
        },
        act: (bloc) => bloc.add(const StartFullSyncEvent()),
        expect: () => [
          isA<SyncInProgressState>(),
          isA<SyncConflictState>()
              .having((state) => state.conflicts.length, 'conflicts', 1)
              .having((state) => state.conflicts.first.filePath, 'filePath', 'conflict.md'),
        ],
      );
    });

    group('EnableAutoSyncEvent', () {
      blocTest<SyncBloc, SyncState>(
        'calls enableAutoSync on both services when enabled',
        build: () {
          when(mockSyncService.enableAutoSync(interval: anyNamed('interval')))
              .thenAnswer((_) async {});
          when(mockAutoSyncService.enable()).thenAnswer((_) async {});
          return syncBloc;
        },
        act: (bloc) => bloc.add(const EnableAutoSyncEvent(
          interval: Duration(minutes: 10),
        )),
        verify: (_) {
          verify(mockSyncService.enableAutoSync(
            interval: const Duration(minutes: 10),
          )).called(1);
          verify(mockAutoSyncService.enable()).called(1);
        },
      );
    });

    group('DisableAutoSyncEvent', () {
      blocTest<SyncBloc, SyncState>(
        'calls disableAutoSync on both services when disabled',
        build: () {
          when(mockSyncService.disableAutoSync()).thenAnswer((_) async {});
          when(mockAutoSyncService.disable()).thenAnswer((_) async {});
          return syncBloc;
        },
        act: (bloc) => bloc.add(const DisableAutoSyncEvent()),
        verify: (_) {
          verify(mockSyncService.disableAutoSync()).called(1);
          verify(mockAutoSyncService.disable()).called(1);
        },
      );
    });

    group('HandleConflictEvent', () {
      blocTest<SyncBloc, SyncState>(
        'handles conflict resolution and reloads conflicts',
        build: () {
          when(mockSyncService.handleConflict('conflict.md', ConflictResolution.keepLocal))
              .thenAnswer((_) async {});
          when(mockSyncService.getConflicts()).thenAnswer((_) async => []);
          return syncBloc;
        },
        act: (bloc) => bloc.add(const HandleConflictEvent(
          filePath: 'conflict.md',
          resolution: ConflictResolution.keepLocal,
        )),
        verify: (_) {
          verify(mockSyncService.handleConflict(
            'conflict.md',
            ConflictResolution.keepLocal,
          )).called(1);
          verify(mockSyncService.getConflicts()).called(2); // Called by both LoadConflictsEvent and LoadSyncInfoEvent
        },
      );
    });

    group('LoadSyncSettingsEvent', () {
      blocTest<SyncBloc, SyncState>(
        'loads sync settings successfully',
        build: () {
          const config = AutoSyncConfig(syncInterval: Duration(minutes: 10));
          when(mockAutoSyncService.getConfig()).thenAnswer((_) async => config);
          when(mockSyncService.isAutoSyncEnabled).thenReturn(true);
          when(mockSyncService.isSyncPaused).thenReturn(false);
          return syncBloc;
        },
        act: (bloc) => bloc.add(const LoadSyncSettingsEvent()),
        expect: () => [
          isA<SyncSettingsUpdatedState>()
              .having((state) => state.settings.autoSyncEnabled, 'autoSyncEnabled', true)
              .having((state) => state.settings.autoSyncInterval, 'interval', const Duration(minutes: 10)),
        ],
        verify: (_) {
          verify(mockAutoSyncService.getConfig()).called(1);
          verify(mockSyncService.isAutoSyncEnabled).called(1);
          verify(mockSyncService.isSyncPaused).called(1);
        },
      );
    });

    group('Error handling', () {
      blocTest<SyncBloc, SyncState>(
        'emits SyncErrorState when sync operation fails',
        build: () {
          when(mockSyncService.fullSync())
              .thenThrow(Exception('Sync failed'));
          return syncBloc;
        },
        act: (bloc) => bloc.add(const StartFullSyncEvent()),
        expect: () => [
          isA<SyncInProgressState>(),
          isA<SyncErrorState>()
              .having((state) => state.error, 'error', contains('Sync failed')),
        ],
      );

      blocTest<SyncBloc, SyncState>(
        'emits SyncSettingsErrorState when settings operation fails',
        build: () {
          when(mockAutoSyncService.getConfig())
              .thenThrow(Exception('Settings failed'));
          return syncBloc;
        },
        act: (bloc) => bloc.add(const LoadSyncSettingsEvent()),
        expect: () => [
          isA<SyncSettingsErrorState>()
              .having((state) => state.error, 'error', contains('Settings failed')),
        ],
      );
    });
  });
}