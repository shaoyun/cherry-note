import 'package:equatable/equatable.dart';
import 'package:cherry_note/features/sync/domain/services/sync_service.dart';
import 'package:cherry_note/features/sync/domain/services/auto_sync_service.dart';

/// 同步进度信息
class SyncProgress extends Equatable {
  final int current;
  final int total;
  final String? currentFile;
  final double percentage;

  const SyncProgress({
    required this.current,
    required this.total,
    this.currentFile,
  }) : percentage = total > 0 ? current / total : 0.0;

  SyncProgress copyWith({
    int? current,
    int? total,
    String? currentFile,
  }) {
    return SyncProgress(
      current: current ?? this.current,
      total: total ?? this.total,
      currentFile: currentFile ?? this.currentFile,
    );
  }

  @override
  List<Object?> get props => [current, total, currentFile];

  @override
  String toString() {
    return 'SyncProgress(current: $current, total: $total, '
        'percentage: ${(percentage * 100).toStringAsFixed(1)}%, '
        'currentFile: $currentFile)';
  }
}

/// 同步设置
class SyncSettings extends Equatable {
  final bool autoSyncEnabled;
  final Duration autoSyncInterval;
  final AutoSyncConfig autoSyncConfig;
  final bool syncPaused;

  const SyncSettings({
    required this.autoSyncEnabled,
    required this.autoSyncInterval,
    required this.autoSyncConfig,
    required this.syncPaused,
  });

  SyncSettings copyWith({
    bool? autoSyncEnabled,
    Duration? autoSyncInterval,
    AutoSyncConfig? autoSyncConfig,
    bool? syncPaused,
  }) {
    return SyncSettings(
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      autoSyncInterval: autoSyncInterval ?? this.autoSyncInterval,
      autoSyncConfig: autoSyncConfig ?? this.autoSyncConfig,
      syncPaused: syncPaused ?? this.syncPaused,
    );
  }

  @override
  List<Object?> get props => [
        autoSyncEnabled,
        autoSyncInterval,
        autoSyncConfig,
        syncPaused,
      ];
}

/// 同步状态基类
abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

// ========== 基础状态 ==========

/// 初始状态
class SyncInitialState extends SyncState {
  const SyncInitialState();
}

/// 加载中状态
class SyncLoadingState extends SyncState {
  const SyncLoadingState();
}

/// 就绪状态
class SyncReadyState extends SyncState {
  final SyncInfo syncInfo;
  final SyncSettings settings;
  final List<FileConflict> conflicts;
  final List<String> modifiedFiles;
  final bool isOnline;

  const SyncReadyState({
    required this.syncInfo,
    required this.settings,
    this.conflicts = const [],
    this.modifiedFiles = const [],
    required this.isOnline,
  });

  SyncReadyState copyWith({
    SyncInfo? syncInfo,
    SyncSettings? settings,
    List<FileConflict>? conflicts,
    List<String>? modifiedFiles,
    bool? isOnline,
  }) {
    return SyncReadyState(
      syncInfo: syncInfo ?? this.syncInfo,
      settings: settings ?? this.settings,
      conflicts: conflicts ?? this.conflicts,
      modifiedFiles: modifiedFiles ?? this.modifiedFiles,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [
        syncInfo,
        settings,
        conflicts,
        modifiedFiles,
        isOnline,
      ];
}

// ========== 同步进行中状态 ==========

/// 同步进行中状态
class SyncInProgressState extends SyncState {
  final SyncStatus syncStatus;
  final SyncProgress progress;
  final String? operation; // 'upload', 'download', 'full'

  const SyncInProgressState({
    required this.syncStatus,
    required this.progress,
    this.operation,
  });

  SyncInProgressState copyWith({
    SyncStatus? syncStatus,
    SyncProgress? progress,
    String? operation,
  }) {
    return SyncInProgressState(
      syncStatus: syncStatus ?? this.syncStatus,
      progress: progress ?? this.progress,
      operation: operation ?? this.operation,
    );
  }

  @override
  List<Object?> get props => [syncStatus, progress, operation];
}

// ========== 同步完成状态 ==========

/// 同步成功状态
class SyncSuccessState extends SyncState {
  final SyncResult result;
  final SyncInfo syncInfo;
  final SyncSettings settings;

  const SyncSuccessState({
    required this.result,
    required this.syncInfo,
    required this.settings,
  });

  @override
  List<Object?> get props => [result, syncInfo, settings];
}

/// 同步失败状态
class SyncErrorState extends SyncState {
  final String error;
  final SyncInfo? syncInfo;
  final SyncSettings? settings;

  const SyncErrorState({
    required this.error,
    this.syncInfo,
    this.settings,
  });

  @override
  List<Object?> get props => [error, syncInfo, settings];
}

/// 同步冲突状态
class SyncConflictState extends SyncState {
  final List<FileConflict> conflicts;
  final SyncResult? partialResult;
  final SyncInfo syncInfo;
  final SyncSettings settings;

  const SyncConflictState({
    required this.conflicts,
    this.partialResult,
    required this.syncInfo,
    required this.settings,
  });

  @override
  List<Object?> get props => [conflicts, partialResult, syncInfo, settings];
}

// ========== 离线状态 ==========

/// 离线状态
class SyncOfflineState extends SyncState {
  final SyncInfo syncInfo;
  final SyncSettings settings;
  final List<String> pendingFiles;

  const SyncOfflineState({
    required this.syncInfo,
    required this.settings,
    this.pendingFiles = const [],
  });

  @override
  List<Object?> get props => [syncInfo, settings, pendingFiles];
}

// ========== 设置状态 ==========

/// 设置更新成功状态
class SyncSettingsUpdatedState extends SyncState {
  final SyncSettings settings;

  const SyncSettingsUpdatedState({required this.settings});

  @override
  List<Object?> get props => [settings];
}

/// 设置更新失败状态
class SyncSettingsErrorState extends SyncState {
  final String error;
  final SyncSettings? previousSettings;

  const SyncSettingsErrorState({
    required this.error,
    this.previousSettings,
  });

  @override
  List<Object?> get props => [error, previousSettings];
}