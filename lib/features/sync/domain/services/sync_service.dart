import 'package:cherry_note/features/sync/domain/entities/sync_operation.dart';

/// 同步结果
class SyncResult {
  final bool success;
  final List<String> syncedFiles;
  final List<FileConflict> conflicts;
  final String? error;
  final int uploadedCount;
  final int downloadedCount;
  final int deletedCount;

  const SyncResult({
    required this.success,
    this.syncedFiles = const [],
    this.conflicts = const [],
    this.error,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    this.deletedCount = 0,
  });

  SyncResult copyWith({
    bool? success,
    List<String>? syncedFiles,
    List<FileConflict>? conflicts,
    String? error,
    int? uploadedCount,
    int? downloadedCount,
    int? deletedCount,
  }) {
    return SyncResult(
      success: success ?? this.success,
      syncedFiles: syncedFiles ?? this.syncedFiles,
      conflicts: conflicts ?? this.conflicts,
      error: error ?? this.error,
      uploadedCount: uploadedCount ?? this.uploadedCount,
      downloadedCount: downloadedCount ?? this.downloadedCount,
      deletedCount: deletedCount ?? this.deletedCount,
    );
  }

  @override
  String toString() {
    return 'SyncResult(success: $success, synced: ${syncedFiles.length}, '
        'conflicts: ${conflicts.length}, uploaded: $uploadedCount, '
        'downloaded: $downloadedCount, deleted: $deletedCount)';
  }
}

/// 文件冲突
class FileConflict {
  final String filePath;
  final DateTime localModified;
  final DateTime remoteModified;
  final String localContent;
  final String remoteContent;
  final String? localChecksum;
  final String? remoteChecksum;

  FileConflict({
    required this.filePath,
    required this.localModified,
    required this.remoteModified,
    required this.localContent,
    required this.remoteContent,
    this.localChecksum,
    this.remoteChecksum,
  });

  @override
  String toString() {
    return 'FileConflict(filePath: $filePath, localModified: $localModified, '
        'remoteModified: $remoteModified)';
  }
}

/// 冲突解决策略
enum ConflictResolution {
  keepLocal('keep_local'),
  keepRemote('keep_remote'),
  merge('merge'),
  createBoth('create_both');

  const ConflictResolution(this.value);
  final String value;

  static ConflictResolution fromString(String value) {
    return ConflictResolution.values.firstWhere(
      (resolution) => resolution.value == value,
      orElse: () => ConflictResolution.keepLocal,
    );
  }
}

/// 同步状态
enum SyncStatus {
  idle('idle'),
  syncing('syncing'),
  success('success'),
  error('error'),
  conflict('conflict'),
  offline('offline');

  const SyncStatus(this.value);
  final String value;

  static SyncStatus fromString(String value) {
    return SyncStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SyncStatus.idle,
    );
  }
}

/// 同步信息
class SyncInfo {
  final DateTime? lastSyncTime;
  final SyncStatus status;
  final int pendingOperations;
  final int totalFiles;
  final String? lastError;

  const SyncInfo({
    this.lastSyncTime,
    required this.status,
    this.pendingOperations = 0,
    this.totalFiles = 0,
    this.lastError,
  });

  @override
  String toString() {
    return 'SyncInfo(lastSync: $lastSyncTime, status: $status, '
        'pending: $pendingOperations, total: $totalFiles)';
  }
}

/// 同步服务接口
abstract class SyncService {
  /// 自动同步
  Future<void> enableAutoSync({Duration interval = const Duration(minutes: 5)});
  Future<void> disableAutoSync();
  bool get isAutoSyncEnabled;

  /// 手动同步
  Future<SyncResult> syncToRemote();
  Future<SyncResult> syncFromRemote();
  Future<SyncResult> fullSync();

  /// 单个文件同步
  Future<SyncResult> syncFile(String filePath);
  Future<SyncResult> uploadFile(String filePath);
  Future<SyncResult> downloadFile(String filePath);
  Future<SyncResult> deleteFile(String filePath);

  /// 冲突处理
  Future<void> handleConflict(String filePath, ConflictResolution resolution);
  Future<List<FileConflict>> getConflicts();
  Future<void> clearConflicts();

  /// 同步状态
  Stream<SyncStatus> get syncStatusStream;
  Future<SyncInfo> getSyncInfo();
  Future<void> updateSyncInfo(SyncInfo info);

  /// 文件变更检测
  Future<List<String>> getModifiedFiles();
  Future<List<String>> getLocalChanges();
  Future<List<String>> getRemoteChanges();
  Future<bool> hasLocalChanges();
  Future<bool> hasRemoteChanges();

  /// 时间戳比较
  Future<DateTime?> getLocalFileTimestamp(String filePath);
  Future<DateTime?> getRemoteFileTimestamp(String filePath);
  Future<bool> isLocalFileNewer(String filePath);
  Future<bool> isRemoteFileNewer(String filePath);

  /// 连接状态
  Future<bool> checkConnection();
  bool get isOnline;

  /// 同步控制
  Future<void> pauseSync();
  Future<void> resumeSync();
  bool get isSyncPaused;

  /// 清理和维护
  Future<void> cleanup();
  Future<void> resetSync();
}