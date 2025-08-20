import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cherry_note/features/sync/domain/services/sync_service.dart';
import 'package:cherry_note/features/sync/domain/services/sync_queue_service.dart';
import 'package:cherry_note/features/sync/domain/repositories/s3_storage_repository.dart';
import 'package:cherry_note/features/sync/data/datasources/local_cache_service.dart';
import 'package:cherry_note/features/sync/domain/entities/sync_operation.dart';
import 'package:cherry_note/features/sync/domain/entities/sync_operation_factory.dart';
import 'package:cherry_note/core/error/exceptions.dart';

/// 同步服务实现
class SyncServiceImpl implements SyncService {
  final S3StorageRepository _storageRepository;
  final LocalCacheService _cacheService;
  final SyncQueueService _queueService;

  Timer? _autoSyncTimer;
  bool _isAutoSyncEnabled = false;
  bool _isSyncPaused = false;
  bool _isOnline = true;

  final StreamController<SyncStatus> _statusController = StreamController.broadcast();

  SyncServiceImpl({
    required S3StorageRepository storageRepository,
    required LocalCacheService cacheService,
    required SyncQueueService queueService,
  })  : _storageRepository = storageRepository,
        _cacheService = cacheService,
        _queueService = queueService;

  @override
  Stream<SyncStatus> get syncStatusStream => _statusController.stream;

  @override
  bool get isAutoSyncEnabled => _isAutoSyncEnabled;

  @override
  bool get isSyncPaused => _isSyncPaused;

  @override
  bool get isOnline => _isOnline;

  // ========== 自动同步 ==========

  @override
  Future<void> enableAutoSync({Duration interval = const Duration(minutes: 5)}) async {
    if (_isAutoSyncEnabled) {
      await disableAutoSync();
    }

    _isAutoSyncEnabled = true;
    _autoSyncTimer = Timer.periodic(interval, (_) async {
      if (!_isSyncPaused && _isOnline) {
        try {
          await fullSync();
        } catch (e) {
          // 自动同步失败不抛出异常，只记录状态
          _statusController.add(SyncStatus.error);
        }
      }
    });

    await _cacheService.setSetting('auto_sync_enabled', 'true');
    await _cacheService.setSetting('auto_sync_interval', interval.inMinutes.toString());
  }

  @override
  Future<void> disableAutoSync() async {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    _isAutoSyncEnabled = false;

    await _cacheService.setSetting('auto_sync_enabled', 'false');
  }

  // ========== 手动同步 ==========

  @override
  Future<SyncResult> syncToRemote() async {
    if (_isSyncPaused) {
      throw SyncException('Sync is paused');
    }

    _statusController.add(SyncStatus.syncing);

    try {
      final localChanges = await getLocalChanges();
      final conflicts = <FileConflict>[];
      final syncedFiles = <String>[];
      int uploadedCount = 0;
      int deletedCount = 0;

      for (final filePath in localChanges) {
        try {
          // 检查是否有冲突
          if (await _hasConflict(filePath)) {
            final conflict = await _createConflict(filePath);
            if (conflict != null) {
              conflicts.add(conflict);
              continue;
            }
          }

          // 检查文件是否存在于本地缓存
          final localContent = await _cacheService.getCachedFile(filePath);
          if (localContent != null) {
            // 上传文件
            await _storageRepository.uploadFile(filePath, localContent);
            syncedFiles.add(filePath);
            uploadedCount++;
          } else {
            // 文件已被删除，添加删除操作
            final deleteOp = SyncOperationFactory.createDeleteOperation(filePath: filePath);
            await _queueService.enqueue(deleteOp);
            deletedCount++;
          }
        } catch (e) {
          // 单个文件同步失败，继续处理其他文件
          continue;
        }
      }

      final result = SyncResult(
        success: conflicts.isEmpty,
        syncedFiles: syncedFiles,
        conflicts: conflicts,
        uploadedCount: uploadedCount,
        deletedCount: deletedCount,
      );

      _statusController.add(conflicts.isEmpty ? SyncStatus.success : SyncStatus.conflict);
      await _updateLastSyncTime();

      return result;
    } catch (e) {
      _statusController.add(SyncStatus.error);
      return SyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<SyncResult> syncFromRemote() async {
    if (_isSyncPaused) {
      throw SyncException('Sync is paused');
    }

    _statusController.add(SyncStatus.syncing);

    try {
      final remoteChanges = await getRemoteChanges();
      final conflicts = <FileConflict>[];
      final syncedFiles = <String>[];
      int downloadedCount = 0;

      for (final filePath in remoteChanges) {
        try {
          // 检查是否有冲突
          if (await _hasConflict(filePath)) {
            final conflict = await _createConflict(filePath);
            if (conflict != null) {
              conflicts.add(conflict);
              continue;
            }
          }

          // 下载文件
          final remoteContent = await _storageRepository.downloadFile(filePath);
          await _cacheService.cacheFile(filePath, remoteContent);
          syncedFiles.add(filePath);
          downloadedCount++;
        } catch (e) {
          // 单个文件同步失败，继续处理其他文件
          continue;
        }
      }

      final result = SyncResult(
        success: conflicts.isEmpty,
        syncedFiles: syncedFiles,
        conflicts: conflicts,
        downloadedCount: downloadedCount,
      );

      _statusController.add(conflicts.isEmpty ? SyncStatus.success : SyncStatus.conflict);
      await _updateLastSyncTime();

      return result;
    } catch (e) {
      _statusController.add(SyncStatus.error);
      return SyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<SyncResult> fullSync() async {
    if (_isSyncPaused) {
      throw SyncException('Sync is paused');
    }

    _statusController.add(SyncStatus.syncing);

    try {
      // 先检查连接
      _isOnline = await checkConnection();
      if (!_isOnline) {
        _statusController.add(SyncStatus.offline);
        return SyncResult(
          success: false,
          error: 'No internet connection',
        );
      }

      // 执行双向同步
      final uploadResult = await syncToRemote();
      final downloadResult = await syncFromRemote();

      // 合并结果
      final allSyncedFiles = <String>{
        ...uploadResult.syncedFiles,
        ...downloadResult.syncedFiles,
      }.toList();

      final allConflicts = <FileConflict>[
        ...uploadResult.conflicts,
        ...downloadResult.conflicts,
      ];

      final result = SyncResult(
        success: uploadResult.success && downloadResult.success,
        syncedFiles: allSyncedFiles,
        conflicts: allConflicts,
        uploadedCount: uploadResult.uploadedCount,
        downloadedCount: downloadResult.downloadedCount,
        deletedCount: uploadResult.deletedCount,
      );

      _statusController.add(allConflicts.isEmpty ? SyncStatus.success : SyncStatus.conflict);
      return result;
    } catch (e) {
      _statusController.add(SyncStatus.error);
      return SyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // ========== 单个文件同步 ==========

  @override
  Future<SyncResult> syncFile(String filePath) async {
    try {
      final isLocalNewer = await isLocalFileNewer(filePath);
      final isRemoteNewer = await isRemoteFileNewer(filePath);

      if (isLocalNewer && isRemoteNewer) {
        // 有冲突
        final conflict = await _createConflict(filePath);
        return SyncResult(
          success: false,
          conflicts: conflict != null ? [conflict] : [],
        );
      } else if (isLocalNewer) {
        return await uploadFile(filePath);
      } else if (isRemoteNewer) {
        return await downloadFile(filePath);
      } else {
        // 文件相同，无需同步
        return const SyncResult(success: true);
      }
    } catch (e) {
      return SyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<SyncResult> uploadFile(String filePath) async {
    try {
      final localContent = await _cacheService.getCachedFile(filePath);
      if (localContent == null) {
        throw SyncException('Local file not found: $filePath');
      }

      await _storageRepository.uploadFile(filePath, localContent);

      return SyncResult(
        success: true,
        syncedFiles: [filePath],
        uploadedCount: 1,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<SyncResult> downloadFile(String filePath) async {
    try {
      final remoteContent = await _storageRepository.downloadFile(filePath);
      await _cacheService.cacheFile(filePath, remoteContent);

      return SyncResult(
        success: true,
        syncedFiles: [filePath],
        downloadedCount: 1,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  @override
  Future<SyncResult> deleteFile(String filePath) async {
    try {
      await _storageRepository.deleteFile(filePath);
      await _cacheService.removeCachedFile(filePath);

      return SyncResult(
        success: true,
        syncedFiles: [filePath],
        deletedCount: 1,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // ========== 冲突处理 ==========

  @override
  Future<void> handleConflict(String filePath, ConflictResolution resolution) async {
    final conflict = await _getStoredConflict(filePath);
    if (conflict == null) return;

    try {
      switch (resolution) {
        case ConflictResolution.keepLocal:
          await _storageRepository.uploadFile(filePath, conflict.localContent);
          break;
        case ConflictResolution.keepRemote:
          await _cacheService.cacheFile(filePath, conflict.remoteContent);
          break;
        case ConflictResolution.merge:
          // 简单的合并策略：将两个版本合并
          final mergedContent = '${conflict.localContent}\n\n--- REMOTE VERSION ---\n\n${conflict.remoteContent}';
          await _cacheService.cacheFile(filePath, mergedContent);
          await _storageRepository.uploadFile(filePath, mergedContent);
          break;
        case ConflictResolution.createBoth:
          // 创建两个版本
          final localPath = '${filePath}_local';
          final remotePath = '${filePath}_remote';
          await _cacheService.cacheFile(localPath, conflict.localContent);
          await _cacheService.cacheFile(remotePath, conflict.remoteContent);
          await _storageRepository.uploadFile(localPath, conflict.localContent);
          await _storageRepository.uploadFile(remotePath, conflict.remoteContent);
          break;
      }

      // 移除冲突记录
      await _removeStoredConflict(filePath);
    } catch (e) {
      throw SyncException('Failed to handle conflict: $e');
    }
  }

  @override
  Future<List<FileConflict>> getConflicts() async {
    try {
      final conflictSettings = await _cacheService.getSettingsWithPrefix('conflict_');
      final conflicts = <FileConflict>[];

      for (final entry in conflictSettings.entries) {
        try {
          final conflictData = jsonDecode(entry.value) as Map<String, dynamic>;
          final conflict = FileConflict(
            filePath: conflictData['filePath'] as String,
            localModified: DateTime.parse(conflictData['localModified'] as String),
            remoteModified: DateTime.parse(conflictData['remoteModified'] as String),
            localContent: conflictData['localContent'] as String,
            remoteContent: conflictData['remoteContent'] as String,
            localChecksum: conflictData['localChecksum'] as String?,
            remoteChecksum: conflictData['remoteChecksum'] as String?,
          );
          conflicts.add(conflict);
        } catch (e) {
          // 忽略无法解析的冲突数据
          continue;
        }
      }

      return conflicts;
    } catch (e) {
      throw SyncException('Failed to get conflicts: $e');
    }
  }

  @override
  Future<void> clearConflicts() async {
    try {
      final conflictKeys = await _cacheService.getSettingKeys(prefix: 'conflict_');
      for (final key in conflictKeys) {
        await _cacheService.removeSetting(key);
      }
    } catch (e) {
      throw SyncException('Failed to clear conflicts: $e');
    }
  }

  // ========== 同步状态 ==========

  @override
  Future<SyncInfo> getSyncInfo() async {
    try {
      final lastSyncStr = await _cacheService.getSetting('last_sync_time');
      final statusStr = await _cacheService.getSetting('sync_status') ?? 'idle';
      final lastErrorStr = await _cacheService.getSetting('last_sync_error');

      final pendingOps = await _queueService.getPendingOperations();
      final cachedFiles = await _cacheService.getCachedFiles();

      return SyncInfo(
        lastSyncTime: lastSyncStr != null ? DateTime.parse(lastSyncStr) : null,
        status: SyncStatus.fromString(statusStr),
        pendingOperations: pendingOps.length,
        totalFiles: cachedFiles.length,
        lastError: lastErrorStr,
      );
    } catch (e) {
      throw SyncException('Failed to get sync info: $e');
    }
  }

  @override
  Future<void> updateSyncInfo(SyncInfo info) async {
    try {
      if (info.lastSyncTime != null) {
        await _cacheService.setSetting('last_sync_time', info.lastSyncTime!.toIso8601String());
      }
      await _cacheService.setSetting('sync_status', info.status.value);
      if (info.lastError != null) {
        await _cacheService.setSetting('last_sync_error', info.lastError!);
      } else {
        await _cacheService.removeSetting('last_sync_error');
      }
    } catch (e) {
      throw SyncException('Failed to update sync info: $e');
    }
  }

  // ========== 文件变更检测 ==========

  @override
  Future<List<String>> getModifiedFiles() async {
    try {
      final localChanges = await getLocalChanges();
      final remoteChanges = await getRemoteChanges();
      
      final allChanges = <String>{
        ...localChanges,
        ...remoteChanges,
      }.toList();
      
      return allChanges;
    } catch (e) {
      throw SyncException('Failed to get modified files: $e');
    }
  }

  @override
  Future<List<String>> getLocalChanges() async {
    try {
      final cachedFiles = await _cacheService.getCachedFiles();
      final changedFiles = <String>[];

      for (final filePath in cachedFiles) {
        final cacheTimestamp = await _cacheService.getCacheTimestamp(filePath);
        if (cacheTimestamp == null) continue;

        // 检查是否比上次同步时间新
        final lastSyncStr = await _cacheService.getSetting('last_sync_time');
        if (lastSyncStr != null) {
          final lastSyncTime = DateTime.parse(lastSyncStr);
          if (cacheTimestamp.isAfter(lastSyncTime)) {
            changedFiles.add(filePath);
          }
        } else {
          // 如果没有同步记录，认为所有文件都是新的
          changedFiles.add(filePath);
        }
      }

      return changedFiles;
    } catch (e) {
      throw SyncException('Failed to get local changes: $e');
    }
  }

  @override
  Future<List<String>> getRemoteChanges() async {
    try {
      // 获取远程文件列表
      final remoteFiles = await _storageRepository.listFiles('');
      final changedFiles = <String>[];

      for (final filePath in remoteFiles) {
        final remoteTimestamp = await getRemoteFileTimestamp(filePath);
        if (remoteTimestamp == null) continue;

        // 检查是否比本地版本新
        final localTimestamp = await getLocalFileTimestamp(filePath);
        if (localTimestamp == null || remoteTimestamp.isAfter(localTimestamp)) {
          changedFiles.add(filePath);
        }
      }

      return changedFiles;
    } catch (e) {
      throw SyncException('Failed to get remote changes: $e');
    }
  }

  @override
  Future<bool> hasLocalChanges() async {
    try {
      final localChanges = await getLocalChanges();
      return localChanges.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> hasRemoteChanges() async {
    try {
      final remoteChanges = await getRemoteChanges();
      return remoteChanges.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ========== 时间戳比较 ==========

  @override
  Future<DateTime?> getLocalFileTimestamp(String filePath) async {
    try {
      return await _cacheService.getCacheTimestamp(filePath);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<DateTime?> getRemoteFileTimestamp(String filePath) async {
    try {
      // 这里需要S3StorageRepository支持获取文件元数据
      // 暂时返回null，后续需要扩展S3StorageRepository接口
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isLocalFileNewer(String filePath) async {
    try {
      final localTimestamp = await getLocalFileTimestamp(filePath);
      final remoteTimestamp = await getRemoteFileTimestamp(filePath);

      if (localTimestamp == null) return false;
      if (remoteTimestamp == null) return true;

      return localTimestamp.isAfter(remoteTimestamp);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isRemoteFileNewer(String filePath) async {
    try {
      final localTimestamp = await getLocalFileTimestamp(filePath);
      final remoteTimestamp = await getRemoteFileTimestamp(filePath);

      if (remoteTimestamp == null) return false;
      if (localTimestamp == null) return true;

      return remoteTimestamp.isAfter(localTimestamp);
    } catch (e) {
      return false;
    }
  }

  // ========== 连接状态 ==========

  @override
  Future<bool> checkConnection() async {
    try {
      // 尝试列出根目录文件来检查连接
      await _storageRepository.listFiles('');
      _isOnline = true;
      return true;
    } catch (e) {
      _isOnline = false;
      return false;
    }
  }

  // ========== 同步控制 ==========

  @override
  Future<void> pauseSync() async {
    _isSyncPaused = true;
    await _cacheService.setSetting('sync_paused', 'true');
  }

  @override
  Future<void> resumeSync() async {
    _isSyncPaused = false;
    await _cacheService.setSetting('sync_paused', 'false');
  }

  // ========== 清理和维护 ==========

  @override
  Future<void> cleanup() async {
    try {
      // 清理旧的同步队列项
      await _queueService.cleanupCompletedOperations();
      
      // 清理旧的冲突记录
      await clearConflicts();
      
      // 执行数据库维护
      await _cacheService.vacuum();
    } catch (e) {
      throw SyncException('Failed to cleanup: $e');
    }
  }

  @override
  Future<void> resetSync() async {
    try {
      // 停止自动同步
      await disableAutoSync();
      
      // 清空同步队列
      await _queueService.clearQueue();
      
      // 清除同步状态
      await _cacheService.removeSetting('last_sync_time');
      await _cacheService.removeSetting('sync_status');
      await _cacheService.removeSetting('last_sync_error');
      
      // 清除冲突
      await clearConflicts();
      
      // 重置状态
      _isSyncPaused = false;
      _statusController.add(SyncStatus.idle);
    } catch (e) {
      throw SyncException('Failed to reset sync: $e');
    }
  }

  // ========== 私有辅助方法 ==========

  /// 检查文件是否有冲突
  Future<bool> _hasConflict(String filePath) async {
    try {
      final localTimestamp = await getLocalFileTimestamp(filePath);
      final remoteTimestamp = await getRemoteFileTimestamp(filePath);

      if (localTimestamp == null || remoteTimestamp == null) {
        return false;
      }

      // 如果本地和远程都有修改，且时间戳不同，则认为有冲突
      final lastSyncStr = await _cacheService.getSetting('last_sync_time');
      if (lastSyncStr != null) {
        final lastSyncTime = DateTime.parse(lastSyncStr);
        return localTimestamp.isAfter(lastSyncTime) && remoteTimestamp.isAfter(lastSyncTime);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// 创建冲突对象
  Future<FileConflict?> _createConflict(String filePath) async {
    try {
      final localContent = await _cacheService.getCachedFile(filePath);
      final remoteContent = await _storageRepository.downloadFile(filePath);
      final localTimestamp = await getLocalFileTimestamp(filePath);
      final remoteTimestamp = await getRemoteFileTimestamp(filePath);

      if (localContent == null || localTimestamp == null || remoteTimestamp == null) {
        return null;
      }

      final conflict = FileConflict(
        filePath: filePath,
        localModified: localTimestamp,
        remoteModified: remoteTimestamp,
        localContent: localContent,
        remoteContent: remoteContent,
      );

      // 存储冲突信息
      await _storeConflict(conflict);

      return conflict;
    } catch (e) {
      return null;
    }
  }

  /// 存储冲突信息
  Future<void> _storeConflict(FileConflict conflict) async {
    try {
      final conflictData = {
        'filePath': conflict.filePath,
        'localModified': conflict.localModified.toIso8601String(),
        'remoteModified': conflict.remoteModified.toIso8601String(),
        'localContent': conflict.localContent,
        'remoteContent': conflict.remoteContent,
        'localChecksum': conflict.localChecksum,
        'remoteChecksum': conflict.remoteChecksum,
      };

      await _cacheService.setSetting(
        'conflict_${conflict.filePath.replaceAll('/', '_')}',
        jsonEncode(conflictData),
      );
    } catch (e) {
      // 忽略存储冲突失败
    }
  }

  /// 获取存储的冲突信息
  Future<FileConflict?> _getStoredConflict(String filePath) async {
    try {
      final conflictKey = 'conflict_${filePath.replaceAll('/', '_')}';
      final conflictJson = await _cacheService.getSetting(conflictKey);
      
      if (conflictJson == null) return null;

      final conflictData = jsonDecode(conflictJson) as Map<String, dynamic>;
      return FileConflict(
        filePath: conflictData['filePath'] as String,
        localModified: DateTime.parse(conflictData['localModified'] as String),
        remoteModified: DateTime.parse(conflictData['remoteModified'] as String),
        localContent: conflictData['localContent'] as String,
        remoteContent: conflictData['remoteContent'] as String,
        localChecksum: conflictData['localChecksum'] as String?,
        remoteChecksum: conflictData['remoteChecksum'] as String?,
      );
    } catch (e) {
      return null;
    }
  }

  /// 移除存储的冲突信息
  Future<void> _removeStoredConflict(String filePath) async {
    try {
      final conflictKey = 'conflict_${filePath.replaceAll('/', '_')}';
      await _cacheService.removeSetting(conflictKey);
    } catch (e) {
      // 忽略移除冲突失败
    }
  }

  /// 更新最后同步时间
  Future<void> _updateLastSyncTime() async {
    try {
      await _cacheService.setSetting('last_sync_time', DateTime.now().toIso8601String());
    } catch (e) {
      // 忽略更新时间失败
    }
  }

  /// 释放资源
  void dispose() {
    _autoSyncTimer?.cancel();
    _statusController.close();
  }
}