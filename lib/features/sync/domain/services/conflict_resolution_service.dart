import 'package:cherry_note/features/sync/domain/services/sync_service.dart';
import 'package:cherry_note/features/sync/domain/services/conflict_detection_service.dart';
import 'package:cherry_note/features/sync/data/datasources/local_cache_service.dart';
import 'package:cherry_note/features/sync/domain/repositories/s3_storage_repository.dart';
import 'package:cherry_note/core/error/exceptions.dart';

/// 冲突解决结果
class ConflictResolutionResult {
  final bool success;
  final String filePath;
  final ConflictResolution resolution;
  final String? resultContent;
  final List<String> createdFiles;
  final String? error;

  const ConflictResolutionResult({
    required this.success,
    required this.filePath,
    required this.resolution,
    this.resultContent,
    this.createdFiles = const [],
    this.error,
  });

  @override
  String toString() {
    return 'ConflictResolutionResult(success: $success, filePath: $filePath, '
        'resolution: $resolution, createdFiles: ${createdFiles.length})';
  }
}

/// 批量冲突解决结果
class BatchConflictResolutionResult {
  final List<ConflictResolutionResult> results;
  final int successCount;
  final int failureCount;
  final List<String> errors;

  BatchConflictResolutionResult(this.results)
      : successCount = results.where((r) => r.success).length,
        failureCount = results.where((r) => !r.success).length,
        errors = results.where((r) => !r.success).map((r) => r.error ?? 'Unknown error').toList();

  bool get allSuccessful => failureCount == 0;
  bool get hasFailures => failureCount > 0;

  @override
  String toString() {
    return 'BatchConflictResolutionResult(total: ${results.length}, '
        'success: $successCount, failures: $failureCount)';
  }
}

/// 冲突解决策略配置
class ConflictResolutionStrategy {
  final ConflictResolution defaultResolution;
  final Map<ConflictType, ConflictResolution> typeSpecificResolutions;
  final bool autoResolveWhenPossible;
  final bool createBackups;

  const ConflictResolutionStrategy({
    this.defaultResolution = ConflictResolution.keepLocal,
    this.typeSpecificResolutions = const {},
    this.autoResolveWhenPossible = true,
    this.createBackups = true,
  });

  /// 获取指定冲突类型的解决策略
  ConflictResolution getResolutionForType(ConflictType type) {
    return typeSpecificResolutions[type] ?? defaultResolution;
  }
}

/// 冲突解决服务
abstract class ConflictResolutionService {
  /// 解决单个冲突
  Future<ConflictResolutionResult> resolveConflict(
    FileConflict conflict,
    ConflictResolution resolution,
  );

  /// 批量解决冲突
  Future<BatchConflictResolutionResult> resolveConflicts(
    List<FileConflict> conflicts,
    ConflictResolutionStrategy strategy,
  );

  /// 自动解决可以自动处理的冲突
  Future<BatchConflictResolutionResult> autoResolveConflicts(
    List<ConflictDetectionResult> detectionResults,
  );

  /// 预览冲突解决结果
  Future<String> previewResolution(
    FileConflict conflict,
    ConflictResolution resolution,
  );

  /// 创建备份
  Future<String> createBackup(String filePath, String content);

  /// 恢复备份
  Future<void> restoreBackup(String backupPath, String originalPath);

  /// 清理备份文件
  Future<void> cleanupBackups({Duration? olderThan});
}

/// 冲突解决服务实现
class ConflictResolutionServiceImpl implements ConflictResolutionService {
  final LocalCacheService _cacheService;
  final S3StorageRepository _storageRepository;
  final ConflictDetectionService _detectionService;

  ConflictResolutionServiceImpl({
    required LocalCacheService cacheService,
    required S3StorageRepository storageRepository,
    required ConflictDetectionService detectionService,
  })  : _cacheService = cacheService,
        _storageRepository = storageRepository,
        _detectionService = detectionService;

  @override
  Future<ConflictResolutionResult> resolveConflict(
    FileConflict conflict,
    ConflictResolution resolution,
  ) async {
    try {
      switch (resolution) {
        case ConflictResolution.keepLocal:
          return await _resolveKeepLocal(conflict);
        case ConflictResolution.keepRemote:
          return await _resolveKeepRemote(conflict);
        case ConflictResolution.merge:
          return await _resolveMerge(conflict);
        case ConflictResolution.createBoth:
          return await _resolveCreateBoth(conflict);
      }
    } catch (e) {
      return ConflictResolutionResult(
        success: false,
        filePath: conflict.filePath,
        resolution: resolution,
        error: e.toString(),
      );
    }
  }

  @override
  Future<BatchConflictResolutionResult> resolveConflicts(
    List<FileConflict> conflicts,
    ConflictResolutionStrategy strategy,
  ) async {
    final results = <ConflictResolutionResult>[];

    for (final conflict in conflicts) {
      // 创建备份（如果启用）
      if (strategy.createBackups) {
        try {
          await createBackup(conflict.filePath, conflict.localContent);
        } catch (e) {
          // 备份失败不影响解决冲突
        }
      }

      // 确定解决策略
      ConflictResolution resolution;
      if (strategy.autoResolveWhenPossible) {
        final detectionResult = await _detectionService.detectFileConflict(conflict.filePath);
        resolution = detectionResult?.autoResolution ?? strategy.defaultResolution;
      } else {
        resolution = strategy.defaultResolution;
      }

      // 解决冲突
      final result = await resolveConflict(conflict, resolution);
      results.add(result);
    }

    return BatchConflictResolutionResult(results);
  }

  @override
  Future<BatchConflictResolutionResult> autoResolveConflicts(
    List<ConflictDetectionResult> detectionResults,
  ) async {
    final results = <ConflictResolutionResult>[];

    for (final detectionResult in detectionResults) {
      if (detectionResult.canAutoResolve && detectionResult.conflict != null) {
        final result = await resolveConflict(
          detectionResult.conflict!,
          detectionResult.autoResolution!,
        );
        results.add(result);
      }
    }

    return BatchConflictResolutionResult(results);
  }

  @override
  Future<String> previewResolution(
    FileConflict conflict,
    ConflictResolution resolution,
  ) async {
    return await _detectionService.previewResolution(conflict, resolution);
  }

  @override
  Future<String> createBackup(String filePath, String content) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = '${filePath}.backup.$timestamp';
      
      await _cacheService.cacheFile(backupPath, content);
      
      // 记录备份信息
      await _cacheService.setSetting(
        'backup_${filePath.replaceAll('/', '_')}',
        backupPath,
      );

      return backupPath;
    } catch (e) {
      throw SyncException('Failed to create backup: $e');
    }
  }

  @override
  Future<void> restoreBackup(String backupPath, String originalPath) async {
    try {
      final backupContent = await _cacheService.getCachedFile(backupPath);
      if (backupContent == null) {
        throw SyncException('Backup file not found: $backupPath');
      }

      await _cacheService.cacheFile(originalPath, backupContent);
      await _storageRepository.uploadFile(originalPath, backupContent);

      // 清理备份记录
      await _cacheService.removeSetting('backup_${originalPath.replaceAll('/', '_')}');
      await _cacheService.removeCachedFile(backupPath);
    } catch (e) {
      throw SyncException('Failed to restore backup: $e');
    }
  }

  @override
  Future<void> cleanupBackups({Duration? olderThan}) async {
    try {
      final cutoffTime = DateTime.now().subtract(olderThan ?? const Duration(days: 7));
      final backupKeys = await _cacheService.getSettingKeys(prefix: 'backup_');

      for (final key in backupKeys) {
        final backupPath = await _cacheService.getSetting(key);
        if (backupPath == null) continue;

        // 从备份路径中提取时间戳
        final timestampMatch = RegExp(r'\.backup\.(\d+)$').firstMatch(backupPath);
        if (timestampMatch != null) {
          final timestamp = int.tryParse(timestampMatch.group(1)!);
          if (timestamp != null) {
            final backupTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
            if (backupTime.isBefore(cutoffTime)) {
              await _cacheService.removeCachedFile(backupPath);
              await _cacheService.removeSetting(key);
            }
          }
        }
      }
    } catch (e) {
      throw SyncException('Failed to cleanup backups: $e');
    }
  }

  /// 解决冲突：保留本地版本
  Future<ConflictResolutionResult> _resolveKeepLocal(FileConflict conflict) async {
    try {
      // 上传本地版本到远程
      await _storageRepository.uploadFile(conflict.filePath, conflict.localContent);

      return ConflictResolutionResult(
        success: true,
        filePath: conflict.filePath,
        resolution: ConflictResolution.keepLocal,
        resultContent: conflict.localContent,
      );
    } catch (e) {
      throw SyncException('Failed to keep local version: $e');
    }
  }

  /// 解决冲突：保留远程版本
  Future<ConflictResolutionResult> _resolveKeepRemote(FileConflict conflict) async {
    try {
      // 更新本地缓存为远程版本
      await _cacheService.cacheFile(conflict.filePath, conflict.remoteContent);

      return ConflictResolutionResult(
        success: true,
        filePath: conflict.filePath,
        resolution: ConflictResolution.keepRemote,
        resultContent: conflict.remoteContent,
      );
    } catch (e) {
      throw SyncException('Failed to keep remote version: $e');
    }
  }

  /// 解决冲突：合并版本
  Future<ConflictResolutionResult> _resolveMerge(FileConflict conflict) async {
    try {
      final mergedContent = await _mergeContent(conflict.localContent, conflict.remoteContent);

      // 保存合并后的内容
      await _cacheService.cacheFile(conflict.filePath, mergedContent);
      await _storageRepository.uploadFile(conflict.filePath, mergedContent);

      return ConflictResolutionResult(
        success: true,
        filePath: conflict.filePath,
        resolution: ConflictResolution.merge,
        resultContent: mergedContent,
      );
    } catch (e) {
      throw SyncException('Failed to merge versions: $e');
    }
  }

  /// 解决冲突：创建两个版本
  Future<ConflictResolutionResult> _resolveCreateBoth(FileConflict conflict) async {
    try {
      final localPath = '${conflict.filePath}_local';
      final remotePath = '${conflict.filePath}_remote';

      // 保存两个版本
      await _cacheService.cacheFile(localPath, conflict.localContent);
      await _cacheService.cacheFile(remotePath, conflict.remoteContent);
      await _storageRepository.uploadFile(localPath, conflict.localContent);
      await _storageRepository.uploadFile(remotePath, conflict.remoteContent);

      // 删除原始文件
      await _cacheService.removeCachedFile(conflict.filePath);
      await _storageRepository.deleteFile(conflict.filePath);

      return ConflictResolutionResult(
        success: true,
        filePath: conflict.filePath,
        resolution: ConflictResolution.createBoth,
        createdFiles: [localPath, remotePath],
      );
    } catch (e) {
      throw SyncException('Failed to create both versions: $e');
    }
  }

  /// 智能合并内容
  Future<String> _mergeContent(String localContent, String remoteContent) async {
    // 如果内容相同，直接返回
    if (localContent == remoteContent) {
      return localContent;
    }

    // 按行分割内容
    final localLines = localContent.split('\n');
    final remoteLines = remoteContent.split('\n');

    // 使用三路合并算法
    final mergedLines = <String>[];
    final maxLines = localLines.length > remoteLines.length 
        ? localLines.length 
        : remoteLines.length;

    for (int i = 0; i < maxLines; i++) {
      final localLine = i < localLines.length ? localLines[i] : '';
      final remoteLine = i < remoteLines.length ? remoteLines[i] : '';

      if (localLine == remoteLine) {
        // 行相同，直接添加
        mergedLines.add(localLine);
      } else if (localLine.isEmpty) {
        // 本地为空，使用远程
        mergedLines.add(remoteLine);
      } else if (remoteLine.isEmpty) {
        // 远程为空，使用本地
        mergedLines.add(localLine);
      } else {
        // 行不同，标记冲突
        mergedLines.add('<<<<<<< LOCAL');
        mergedLines.add(localLine);
        mergedLines.add('=======');
        mergedLines.add(remoteLine);
        mergedLines.add('>>>>>>> REMOTE');
      }
    }

    return mergedLines.join('\n');
  }
}