import 'package:equatable/equatable.dart';
import 'package:cherry_note/features/sync/domain/services/sync_service.dart';
import 'package:cherry_note/features/sync/domain/services/auto_sync_service.dart';

/// 同步事件基类
abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

// ========== 同步操作事件 ==========

/// 开始完整同步
class StartFullSyncEvent extends SyncEvent {
  const StartFullSyncEvent();
}

/// 开始上传同步
class StartUploadSyncEvent extends SyncEvent {
  const StartUploadSyncEvent();
}

/// 开始下载同步
class StartDownloadSyncEvent extends SyncEvent {
  const StartDownloadSyncEvent();
}

/// 同步单个文件
class SyncFileEvent extends SyncEvent {
  final String filePath;

  const SyncFileEvent({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

/// 取消同步
class CancelSyncEvent extends SyncEvent {
  const CancelSyncEvent();
}

// ========== 自动同步事件 ==========

/// 启用自动同步
class EnableAutoSyncEvent extends SyncEvent {
  final Duration interval;

  const EnableAutoSyncEvent({
    this.interval = const Duration(minutes: 5),
  });

  @override
  List<Object?> get props => [interval];
}

/// 禁用自动同步
class DisableAutoSyncEvent extends SyncEvent {
  const DisableAutoSyncEvent();
}

/// 暂停同步
class PauseSyncEvent extends SyncEvent {
  const PauseSyncEvent();
}

/// 恢复同步
class ResumeSyncEvent extends SyncEvent {
  const ResumeSyncEvent();
}

// ========== 冲突处理事件 ==========

/// 处理冲突
class HandleConflictEvent extends SyncEvent {
  final String filePath;
  final ConflictResolution resolution;

  const HandleConflictEvent({
    required this.filePath,
    required this.resolution,
  });

  @override
  List<Object?> get props => [filePath, resolution];
}

/// 获取冲突列表
class LoadConflictsEvent extends SyncEvent {
  const LoadConflictsEvent();
}

/// 清除所有冲突
class ClearConflictsEvent extends SyncEvent {
  const ClearConflictsEvent();
}

// ========== 同步设置事件 ==========

/// 更新自动同步配置
class UpdateAutoSyncConfigEvent extends SyncEvent {
  final AutoSyncConfig config;

  const UpdateAutoSyncConfigEvent({required this.config});

  @override
  List<Object?> get props => [config];
}

/// 加载同步设置
class LoadSyncSettingsEvent extends SyncEvent {
  const LoadSyncSettingsEvent();
}

/// 重置同步设置
class ResetSyncSettingsEvent extends SyncEvent {
  const ResetSyncSettingsEvent();
}

// ========== 同步状态事件 ==========

/// 加载同步信息
class LoadSyncInfoEvent extends SyncEvent {
  const LoadSyncInfoEvent();
}

/// 刷新同步状态
class RefreshSyncStatusEvent extends SyncEvent {
  const RefreshSyncStatusEvent();
}

/// 检查连接状态
class CheckConnectionEvent extends SyncEvent {
  const CheckConnectionEvent();
}

/// 获取修改的文件列表
class LoadModifiedFilesEvent extends SyncEvent {
  const LoadModifiedFilesEvent();
}

