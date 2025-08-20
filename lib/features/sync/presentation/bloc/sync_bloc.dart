import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cherry_note/features/sync/presentation/bloc/sync_event.dart';
import 'package:cherry_note/features/sync/presentation/bloc/sync_state.dart';
import 'package:cherry_note/features/sync/domain/services/sync_service.dart';
import 'package:cherry_note/features/sync/domain/services/auto_sync_service.dart';
import 'package:cherry_note/core/error/exceptions.dart';

/// 同步状态管理BLoC
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncService _syncService;
  final AutoSyncService _autoSyncService;

  StreamSubscription<SyncStatus>? _syncStatusSubscription;
  StreamSubscription<AutoSyncState>? _autoSyncStateSubscription;

  SyncBloc({
    required SyncService syncService,
    required AutoSyncService autoSyncService,
  })  : _syncService = syncService,
        _autoSyncService = autoSyncService,
        super(const SyncInitialState()) {
    // 注册事件处理器
    on<StartFullSyncEvent>(_onStartFullSync);
    on<StartUploadSyncEvent>(_onStartUploadSync);
    on<StartDownloadSyncEvent>(_onStartDownloadSync);
    on<SyncFileEvent>(_onSyncFile);
    on<CancelSyncEvent>(_onCancelSync);

    on<EnableAutoSyncEvent>(_onEnableAutoSync);
    on<DisableAutoSyncEvent>(_onDisableAutoSync);
    on<PauseSyncEvent>(_onPauseSync);
    on<ResumeSyncEvent>(_onResumeSync);

    on<HandleConflictEvent>(_onHandleConflict);
    on<LoadConflictsEvent>(_onLoadConflicts);
    on<ClearConflictsEvent>(_onClearConflicts);

    on<UpdateAutoSyncConfigEvent>(_onUpdateAutoSyncConfig);
    on<LoadSyncSettingsEvent>(_onLoadSyncSettings);
    on<ResetSyncSettingsEvent>(_onResetSyncSettings);

    on<LoadSyncInfoEvent>(_onLoadSyncInfo);
    on<RefreshSyncStatusEvent>(_onRefreshSyncStatus);
    on<CheckConnectionEvent>(_onCheckConnection);
    on<LoadModifiedFilesEvent>(_onLoadModifiedFiles);

    // Internal event handlers removed for simplicity

    // 监听同步状态变化
    _initializeStatusListeners();

    // 不自动加载，等待用户触发
  }

  /// 初始化状态监听器
  void _initializeStatusListeners() {
    // 监听同步状态变化
    _syncStatusSubscription = _syncService.syncStatusStream.listen(
      (status) => _handleSyncStatusUpdate(status),
    );

    // 监听自动同步状态变化
    _autoSyncStateSubscription = _autoSyncService.stateStream.listen(
      (autoSyncState) {
        // 当自动同步状态变化时，刷新设置
        add(const LoadSyncSettingsEvent());
      },
    );
  }

  // ========== 同步操作事件处理 ==========

  /// 处理开始完整同步事件
  Future<void> _onStartFullSync(
    StartFullSyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      emit(SyncInProgressState(
        syncStatus: SyncStatus.syncing,
        progress: const SyncProgress(current: 0, total: 1),
        operation: 'full',
      ));

      final result = await _syncService.fullSync();
      await _handleSyncCompleted(result);
    } catch (e) {
      await _handleSyncError(e.toString());
    }
  }

  /// 处理开始上传同步事件
  Future<void> _onStartUploadSync(
    StartUploadSyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      emit(SyncInProgressState(
        syncStatus: SyncStatus.syncing,
        progress: const SyncProgress(current: 0, total: 1),
        operation: 'upload',
      ));

      final result = await _syncService.syncToRemote();
      await _handleSyncCompleted(result);
    } catch (e) {
      await _handleSyncError(e.toString());
    }
  }  
/// 处理开始下载同步事件
  Future<void> _onStartDownloadSync(
    StartDownloadSyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      emit(SyncInProgressState(
        syncStatus: SyncStatus.syncing,
        progress: const SyncProgress(current: 0, total: 1),
        operation: 'download',
      ));

      final result = await _syncService.syncFromRemote();
      await _handleSyncCompleted(result);
    } catch (e) {
      await _handleSyncError(e.toString());
    }
  }

  /// 处理同步单个文件事件
  Future<void> _onSyncFile(
    SyncFileEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      emit(SyncInProgressState(
        syncStatus: SyncStatus.syncing,
        progress: SyncProgress(
          current: 0,
          total: 1,
          currentFile: event.filePath,
        ),
        operation: 'file',
      ));

      final result = await _syncService.syncFile(event.filePath);
      await _handleSyncCompleted(result);
    } catch (e) {
      await _handleSyncError(e.toString());
    }
  }

  /// 处理取消同步事件
  Future<void> _onCancelSync(
    CancelSyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      // 暂停同步服务
      await _syncService.pauseSync();
      
      // 重新加载状态
      add(const LoadSyncInfoEvent());
    } catch (e) {
      await _handleSyncError(e.toString());
    }
  }

  // ========== 自动同步事件处理 ==========

  /// 处理启用自动同步事件
  Future<void> _onEnableAutoSync(
    EnableAutoSyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      await _syncService.enableAutoSync(interval: event.interval);
      await _autoSyncService.enable();
      
      add(const LoadSyncSettingsEvent());
    } catch (e) {
      emit(SyncSettingsErrorState(error: e.toString()));
    }
  }

  /// 处理禁用自动同步事件
  Future<void> _onDisableAutoSync(
    DisableAutoSyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      await _syncService.disableAutoSync();
      await _autoSyncService.disable();
      
      add(const LoadSyncSettingsEvent());
    } catch (e) {
      emit(SyncSettingsErrorState(error: e.toString()));
    }
  }

  /// 处理暂停同步事件
  Future<void> _onPauseSync(
    PauseSyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      await _syncService.pauseSync();
      await _autoSyncService.pause();
      
      add(const LoadSyncSettingsEvent());
    } catch (e) {
      emit(SyncSettingsErrorState(error: e.toString()));
    }
  }

  /// 处理恢复同步事件
  Future<void> _onResumeSync(
    ResumeSyncEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      await _syncService.resumeSync();
      await _autoSyncService.resume();
      
      add(const LoadSyncSettingsEvent());
    } catch (e) {
      emit(SyncSettingsErrorState(error: e.toString()));
    }
  }

  // ========== 冲突处理事件处理 ==========

  /// 处理冲突解决事件
  Future<void> _onHandleConflict(
    HandleConflictEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      await _syncService.handleConflict(event.filePath, event.resolution);
      
      // 重新加载冲突列表
      add(const LoadConflictsEvent());
      add(const LoadSyncInfoEvent());
    } catch (e) {
      await _handleSyncError(e.toString());
    }
  }

  /// 处理加载冲突列表事件
  Future<void> _onLoadConflicts(
    LoadConflictsEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      final conflicts = await _syncService.getConflicts();
      
      if (state is SyncReadyState) {
        final currentState = state as SyncReadyState;
        emit(currentState.copyWith(conflicts: conflicts));
      }
    } catch (e) {
      await _handleSyncError(e.toString());
    }
  }

  /// 处理清除所有冲突事件
  Future<void> _onClearConflicts(
    ClearConflictsEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      await _syncService.clearConflicts();
      
      // 重新加载状态
      add(const LoadConflictsEvent());
      add(const LoadSyncInfoEvent());
    } catch (e) {
      await _handleSyncError(e.toString());
    }
  }

  // ========== 同步设置事件处理 ==========

  /// 处理更新自动同步配置事件
  Future<void> _onUpdateAutoSyncConfig(
    UpdateAutoSyncConfigEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      await _autoSyncService.configure(event.config);
      
      add(const LoadSyncSettingsEvent());
    } catch (e) {
      emit(SyncSettingsErrorState(error: e.toString()));
    }
  }

  /// 处理加载同步设置事件
  Future<void> _onLoadSyncSettings(
    LoadSyncSettingsEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      final autoSyncConfig = await _autoSyncService.getConfig();
      final isAutoSyncEnabled = _syncService.isAutoSyncEnabled;
      final isSyncPaused = _syncService.isSyncPaused;

      final settings = SyncSettings(
        autoSyncEnabled: isAutoSyncEnabled,
        autoSyncInterval: autoSyncConfig.syncInterval,
        autoSyncConfig: autoSyncConfig,
        syncPaused: isSyncPaused,
      );

      if (state is SyncReadyState) {
        final currentState = state as SyncReadyState;
        emit(currentState.copyWith(settings: settings));
      } else if (state is SyncInitialState || state is SyncLoadingState) {
        // 如果还在初始化，等待同步信息加载完成
        emit(SyncSettingsUpdatedState(settings: settings));
      }
    } catch (e) {
      emit(SyncSettingsErrorState(error: e.toString()));
    }
  }

  /// 处理重置同步设置事件
  Future<void> _onResetSyncSettings(
    ResetSyncSettingsEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      // 重置同步服务
      await _syncService.resetSync();
      
      // 重置自动同步服务
      await _autoSyncService.disable();
      
      // 重新加载设置
      add(const LoadSyncSettingsEvent());
      add(const LoadSyncInfoEvent());
    } catch (e) {
      emit(SyncSettingsErrorState(error: e.toString()));
    }
  }

  // ========== 同步状态事件处理 ==========

  /// 处理加载同步信息事件
  Future<void> _onLoadSyncInfo(
    LoadSyncInfoEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      if (state is SyncInitialState) {
        emit(const SyncLoadingState());
      }

      final syncInfo = await _syncService.getSyncInfo();
      final conflicts = await _syncService.getConflicts();
      final modifiedFiles = await _syncService.getModifiedFiles();
      final isOnline = await _syncService.checkConnection();

      // 获取当前设置
      SyncSettings? currentSettings;
      if (state is SyncReadyState) {
        currentSettings = (state as SyncReadyState).settings;
      } else if (state is SyncSettingsUpdatedState) {
        currentSettings = (state as SyncSettingsUpdatedState).settings;
      }

      // 如果没有设置，使用默认设置
      currentSettings ??= SyncSettings(
        autoSyncEnabled: _syncService.isAutoSyncEnabled,
        autoSyncInterval: const Duration(minutes: 5),
        autoSyncConfig: const AutoSyncConfig(),
        syncPaused: _syncService.isSyncPaused,
      );

      emit(SyncReadyState(
        syncInfo: syncInfo,
        settings: currentSettings,
        conflicts: conflicts,
        modifiedFiles: modifiedFiles,
        isOnline: isOnline,
      ));
    } catch (e) {
      emit(SyncErrorState(error: e.toString()));
    }
  }

  /// 处理刷新同步状态事件
  Future<void> _onRefreshSyncStatus(
    RefreshSyncStatusEvent event,
    Emitter<SyncState> emit,
  ) async {
    // 重新加载所有信息
    add(const LoadSyncInfoEvent());
    add(const LoadConflictsEvent());
    add(const LoadModifiedFilesEvent());
    add(const CheckConnectionEvent());
  }

  /// 处理检查连接状态事件
  Future<void> _onCheckConnection(
    CheckConnectionEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      final isOnline = await _syncService.checkConnection();
      
      if (state is SyncReadyState) {
        final currentState = state as SyncReadyState;
        emit(currentState.copyWith(isOnline: isOnline));
      }
    } catch (e) {
      // 连接检查失败，认为离线
      if (state is SyncReadyState) {
        final currentState = state as SyncReadyState;
        emit(currentState.copyWith(isOnline: false));
      }
    }
  }

  /// 处理加载修改文件列表事件
  Future<void> _onLoadModifiedFiles(
    LoadModifiedFilesEvent event,
    Emitter<SyncState> emit,
  ) async {
    try {
      final modifiedFiles = await _syncService.getModifiedFiles();
      
      if (state is SyncReadyState) {
        final currentState = state as SyncReadyState;
        emit(currentState.copyWith(modifiedFiles: modifiedFiles));
      }
    } catch (e) {
      // 忽略加载修改文件失败的错误
    }
  }

  // ========== 内部辅助方法 ==========

  /// 处理同步状态更新
  void _handleSyncStatusUpdate(SyncStatus status) async {
    switch (status) {
      case SyncStatus.idle:
        // 同步完成，重新加载信息
        add(const LoadSyncInfoEvent());
        break;
      case SyncStatus.syncing:
        // 如果当前不是同步中状态，切换到同步中
        if (state is! SyncInProgressState) {
          emit(SyncInProgressState(
            syncStatus: status,
            progress: const SyncProgress(current: 0, total: 1),
          ));
        }
        break;
      case SyncStatus.offline:
        // 切换到离线状态
        final syncInfo = await _syncService.getSyncInfo();
        final settings = state is SyncReadyState 
            ? (state as SyncReadyState).settings
            : SyncSettings(
                autoSyncEnabled: _syncService.isAutoSyncEnabled,
                autoSyncInterval: const Duration(minutes: 5),
                autoSyncConfig: const AutoSyncConfig(),
                syncPaused: _syncService.isSyncPaused,
              );
        
        emit(SyncOfflineState(
          syncInfo: syncInfo,
          settings: settings,
          pendingFiles: await _syncService.getModifiedFiles(),
        ));
        break;
      case SyncStatus.error:
      case SyncStatus.success:
      case SyncStatus.conflict:
        // 这些状态由其他事件处理
        break;
    }
  }

  /// 处理同步进度更新
  void _handleSyncProgressUpdate(int current, int total, String? currentFile) {
    if (state is SyncInProgressState) {
      final currentState = state as SyncInProgressState;
      emit(currentState.copyWith(
        progress: SyncProgress(
          current: current,
          total: total,
          currentFile: currentFile,
        ),
      ));
    }
  }

  /// 处理同步完成
  Future<void> _handleSyncCompleted(SyncResult result) async {
    final syncInfo = await _syncService.getSyncInfo();
    final settings = state is SyncReadyState 
        ? (state as SyncReadyState).settings
        : SyncSettings(
            autoSyncEnabled: _syncService.isAutoSyncEnabled,
            autoSyncInterval: const Duration(minutes: 5),
            autoSyncConfig: const AutoSyncConfig(),
            syncPaused: _syncService.isSyncPaused,
          );

    if (result.success) {
      if (result.conflicts.isNotEmpty) {
        // 有冲突
        emit(SyncConflictState(
          conflicts: result.conflicts,
          partialResult: result,
          syncInfo: syncInfo,
          settings: settings,
        ));
      } else {
        // 成功
        emit(SyncSuccessState(
          result: result,
          syncInfo: syncInfo,
          settings: settings,
        ));
        
        // 不自动切换回就绪状态，让UI决定何时刷新
      }
    } else {
      // 失败
      emit(SyncErrorState(
        error: result.error ?? 'Unknown sync error',
        syncInfo: syncInfo,
        settings: settings,
      ));
    }
  }

  /// 处理同步错误
  Future<void> _handleSyncError(String error) async {
    try {
      final syncInfo = await _syncService.getSyncInfo();
      final settings = state is SyncReadyState 
          ? (state as SyncReadyState).settings
          : null;

      emit(SyncErrorState(
        error: error,
        syncInfo: syncInfo,
        settings: settings,
      ));
    } catch (e) {
      emit(SyncErrorState(error: error));
    }
  }

  @override
  Future<void> close() {
    _syncStatusSubscription?.cancel();
    _autoSyncStateSubscription?.cancel();
    return super.close();
  }
}