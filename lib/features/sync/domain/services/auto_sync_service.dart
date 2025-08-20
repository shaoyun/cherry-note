import 'dart:async';

import 'package:cherry_note/features/sync/domain/services/sync_service.dart';
import 'package:cherry_note/features/sync/domain/services/sync_manager.dart';
import 'package:cherry_note/features/sync/data/datasources/local_cache_service.dart';

/// 自动同步配置
class AutoSyncConfig {
  final Duration syncInterval;
  final Duration debounceDelay;
  final bool syncOnFileChange;
  final bool syncOnAppStart;
  final bool syncOnAppResume;
  final int maxRetries;
  final Duration retryDelay;
  final List<String> excludePatterns;

  const AutoSyncConfig({
    this.syncInterval = const Duration(minutes: 5),
    this.debounceDelay = const Duration(seconds: 30),
    this.syncOnFileChange = true,
    this.syncOnAppStart = true,
    this.syncOnAppResume = true,
    this.maxRetries = 3,
    this.retryDelay = const Duration(minutes: 1),
    this.excludePatterns = const [],
  });

  AutoSyncConfig copyWith({
    Duration? syncInterval,
    Duration? debounceDelay,
    bool? syncOnFileChange,
    bool? syncOnAppStart,
    bool? syncOnAppResume,
    int? maxRetries,
    Duration? retryDelay,
    List<String>? excludePatterns,
  }) {
    return AutoSyncConfig(
      syncInterval: syncInterval ?? this.syncInterval,
      debounceDelay: debounceDelay ?? this.debounceDelay,
      syncOnFileChange: syncOnFileChange ?? this.syncOnFileChange,
      syncOnAppStart: syncOnAppStart ?? this.syncOnAppStart,
      syncOnAppResume: syncOnAppResume ?? this.syncOnAppResume,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      excludePatterns: excludePatterns ?? this.excludePatterns,
    );
  }

  @override
  String toString() {
    return 'AutoSyncConfig(interval: $syncInterval, debounce: $debounceDelay, '
        'onFileChange: $syncOnFileChange, onAppStart: $syncOnAppStart)';
  }
}

/// 自动同步事件
abstract class AutoSyncEvent {
  final DateTime timestamp;

  const AutoSyncEvent({required this.timestamp});
}

/// 定时同步事件
class PeriodicSyncEvent extends AutoSyncEvent {
  const PeriodicSyncEvent({required DateTime timestamp}) : super(timestamp: timestamp);
}

/// 文件变更触发的同步事件
class FileChangeSyncEvent extends AutoSyncEvent {
  final String filePath;
  final String changeType; // 'created', 'modified', 'deleted'

  const FileChangeSyncEvent({
    required this.filePath,
    required this.changeType,
    required DateTime timestamp,
  }) : super(timestamp: timestamp);
}

/// 应用启动同步事件
class AppStartSyncEvent extends AutoSyncEvent {
  const AppStartSyncEvent({required DateTime timestamp}) : super(timestamp: timestamp);
}

/// 应用恢复同步事件
class AppResumeSyncEvent extends AutoSyncEvent {
  const AppResumeSyncEvent({required DateTime timestamp}) : super(timestamp: timestamp);
}

/// 自动同步状态
enum AutoSyncState {
  disabled,
  enabled,
  paused,
  syncing,
  waiting,
  error,
}

/// 自动同步统计信息
class AutoSyncStats {
  final int totalSyncs;
  final int successfulSyncs;
  final int failedSyncs;
  final int periodicSyncs;
  final int fileChangeSyncs;
  final int appStartSyncs;
  final DateTime? lastSyncTime;
  final DateTime? lastSuccessfulSyncTime;
  final String? lastError;

  const AutoSyncStats({
    required this.totalSyncs,
    required this.successfulSyncs,
    required this.failedSyncs,
    required this.periodicSyncs,
    required this.fileChangeSyncs,
    required this.appStartSyncs,
    this.lastSyncTime,
    this.lastSuccessfulSyncTime,
    this.lastError,
  });

  double get successRate => totalSyncs > 0 ? successfulSyncs / totalSyncs : 0.0;

  @override
  String toString() {
    return 'AutoSyncStats(total: $totalSyncs, success: $successfulSyncs, '
        'failed: $failedSyncs, successRate: ${(successRate * 100).toStringAsFixed(1)}%)';
  }
}

/// 自动同步服务
abstract class AutoSyncService {
  /// 配置和控制
  Future<void> configure(AutoSyncConfig config);
  Future<AutoSyncConfig> getConfig();
  Future<void> enable();
  Future<void> disable();
  Future<void> pause();
  Future<void> resume();

  /// 状态查询
  AutoSyncState get state;
  bool get isEnabled;
  bool get isPaused;
  bool get isSyncing;

  /// 手动触发
  Future<void> triggerSync({String? reason});
  Future<void> triggerFileSync(String filePath);

  /// 文件变更监听
  void onFileCreated(String filePath);
  void onFileModified(String filePath);
  void onFileDeleted(String filePath);

  /// 应用生命周期
  Future<void> onAppStart();
  Future<void> onAppResume();
  Future<void> onAppPause();

  /// 统计和监控
  Future<AutoSyncStats> getStats();
  Future<void> resetStats();

  /// 事件流
  Stream<AutoSyncEvent> get eventStream;
  Stream<AutoSyncState> get stateStream;

  /// 清理和维护
  Future<void> cleanup();
}