import 'dart:async';

import 'package:cherry_note/features/sync/domain/services/conflict_detection_service.dart';
import 'package:cherry_note/features/sync/domain/services/conflict_resolution_service.dart';
import 'package:cherry_note/features/sync/domain/services/sync_service.dart';
import 'package:cherry_note/features/sync/data/datasources/local_cache_service.dart';

/// 冲突管理器事件
abstract class ConflictManagerEvent {
  final DateTime timestamp;

  const ConflictManagerEvent({required this.timestamp});
}

/// 冲突检测事件
class ConflictDetectedEvent extends ConflictManagerEvent {
  final ConflictDetectionResult result;

  const ConflictDetectedEvent({
    required this.result,
    required DateTime timestamp,
  }) : super(timestamp: timestamp);
}

/// 冲突解决事件
class ConflictResolvedEvent extends ConflictManagerEvent {
  final ConflictResolutionResult result;

  const ConflictResolvedEvent({
    required this.result,
    required DateTime timestamp,
  }) : super(timestamp: timestamp);
}

/// 批量冲突解决事件
class BatchConflictResolvedEvent extends ConflictManagerEvent {
  final BatchConflictResolutionResult result;

  const BatchConflictResolvedEvent({
    required this.result,
    required DateTime timestamp,
  }) : super(timestamp: timestamp);
}

/// 冲突管理器统计信息
class ConflictManagerStats {
  final int totalConflicts;
  final int resolvedConflicts;
  final int pendingConflicts;
  final int autoResolvedConflicts;
  final int manuallyResolvedConflicts;
  final Map<ConflictType, int> conflictsByType;
  final Map<ConflictResolution, int> resolutionsByType;

  const ConflictManagerStats({
    required this.totalConflicts,
    required this.resolvedConflicts,
    required this.pendingConflicts,
    required this.autoResolvedConflicts,
    required this.manuallyResolvedConflicts,
    required this.conflictsByType,
    required this.resolutionsByType,
  });

  @override
  String toString() {
    return 'ConflictManagerStats(total: $totalConflicts, resolved: $resolvedConflicts, '
        'pending: $pendingConflicts, auto: $autoResolvedConflicts, manual: $manuallyResolvedConflicts)';
  }
}

/// 冲突管理器
/// 统一管理冲突检测、解决和监控
class ConflictManager {
  final ConflictDetectionService _detectionService;
  final ConflictResolutionService _resolutionService;
  final LocalCacheService _cacheService;

  final StreamController<ConflictManagerEvent> _eventController = StreamController.broadcast();
  
  Timer? _periodicDetectionTimer;
  bool _isAutoDetectionEnabled = false;

  // 统计信息
  int _totalConflictsDetected = 0;
  int _totalConflictsResolved = 0;
  int _autoResolvedCount = 0;
  int _manuallyResolvedCount = 0;
  final Map<ConflictType, int> _conflictsByType = {};
  final Map<ConflictResolution, int> _resolutionsByType = {};

  ConflictManager({
    required ConflictDetectionService detectionService,
    required ConflictResolutionService resolutionService,
    required LocalCacheService cacheService,
  })  : _detectionService = detectionService,
        _resolutionService = resolutionService,
        _cacheService = cacheService;

  /// 事件流
  Stream<ConflictManagerEvent> get eventStream => _eventController.stream;

  /// 是否启用自动检测
  bool get isAutoDetectionEnabled => _isAutoDetectionEnabled;

  // ========== 冲突检测 ==========

  /// 启用自动冲突检测
  Future<void> enableAutoDetection({Duration interval = const Duration(minutes: 10)}) async {
    if (_isAutoDetectionEnabled) {
      await disableAutoDetection();
    }

    _isAutoDetectionEnabled = true;
    _periodicDetectionTimer = Timer.periodic(interval, (_) async {
      await _performPeriodicDetection();
    });

    await _cacheService.setSetting('conflict_auto_detection', 'true');
    await _cacheService.setSetting('conflict_detection_interval', interval.inMinutes.toString());
  }

  /// 禁用自动冲突检测
  Future<void> disableAutoDetection() async {
    _periodicDetectionTimer?.cancel();
    _periodicDetectionTimer = null;
    _isAutoDetectionEnabled = false;

    await _cacheService.setSetting('conflict_auto_detection', 'false');
  }

  /// 检测单个文件的冲突
  Future<ConflictDetectionResult?> detectFileConflict(String filePath) async {
    final result = await _detectionService.detectFileConflict(filePath);
    
    if (result != null) {
      _totalConflictsDetected++;
      _conflictsByType[result.type] = (_conflictsByType[result.type] ?? 0) + 1;
      
      _eventController.add(ConflictDetectedEvent(
        result: result,
        timestamp: DateTime.now(),
      ));
    }

    return result;
  }

  /// 检测所有冲突
  Future<List<ConflictDetectionResult>> detectAllConflicts() async {
    final results = await _detectionService.detectAllConflicts();
    
    for (final result in results) {
      _totalConflictsDetected++;
      _conflictsByType[result.type] = (_conflictsByType[result.type] ?? 0) + 1;
      
      _eventController.add(ConflictDetectedEvent(
        result: result,
        timestamp: DateTime.now(),
      ));
    }

    return results;
  }

  /// 获取当前存在的冲突
  Future<List<ConflictDetectionResult>> getCurrentConflicts() async {
    return await _detectionService.detectAllConflicts();
  }

  // ========== 冲突解决 ==========

  /// 解决单个冲突
  Future<ConflictResolutionResult> resolveConflict(
    FileConflict conflict,
    ConflictResolution resolution,
  ) async {
    final result = await _resolutionService.resolveConflict(conflict, resolution);
    
    if (result.success) {
      _totalConflictsResolved++;
      _manuallyResolvedCount++;
      _resolutionsByType[resolution] = (_resolutionsByType[resolution] ?? 0) + 1;
    }

    _eventController.add(ConflictResolvedEvent(
      result: result,
      timestamp: DateTime.now(),
    ));

    return result;
  }

  /// 批量解决冲突
  Future<BatchConflictResolutionResult> resolveConflicts(
    List<FileConflict> conflicts,
    ConflictResolutionStrategy strategy,
  ) async {
    final result = await _resolutionService.resolveConflicts(conflicts, strategy);
    
    _totalConflictsResolved += result.successCount;
    _manuallyResolvedCount += result.successCount;

    for (final resolutionResult in result.results) {
      if (resolutionResult.success) {
        _resolutionsByType[resolutionResult.resolution] = 
            (_resolutionsByType[resolutionResult.resolution] ?? 0) + 1;
      }
    }

    _eventController.add(BatchConflictResolvedEvent(
      result: result,
      timestamp: DateTime.now(),
    ));

    return result;
  }

  /// 自动解决可以自动处理的冲突
  Future<BatchConflictResolutionResult> autoResolveConflicts() async {
    final detectionResults = await detectAllConflicts();
    final result = await _resolutionService.autoResolveConflicts(detectionResults);
    
    _totalConflictsResolved += result.successCount;
    _autoResolvedCount += result.successCount;

    for (final resolutionResult in result.results) {
      if (resolutionResult.success) {
        _resolutionsByType[resolutionResult.resolution] = 
            (_resolutionsByType[resolutionResult.resolution] ?? 0) + 1;
      }
    }

    _eventController.add(BatchConflictResolvedEvent(
      result: result,
      timestamp: DateTime.now(),
    ));

    return result;
  }

  /// 预览冲突解决结果
  Future<String> previewResolution(
    FileConflict conflict,
    ConflictResolution resolution,
  ) async {
    return await _resolutionService.previewResolution(conflict, resolution);
  }

  // ========== 备份管理 ==========

  /// 创建备份
  Future<String> createBackup(String filePath, String content) async {
    return await _resolutionService.createBackup(filePath, content);
  }

  /// 恢复备份
  Future<void> restoreBackup(String backupPath, String originalPath) async {
    await _resolutionService.restoreBackup(backupPath, originalPath);
  }

  /// 清理旧备份
  Future<void> cleanupBackups({Duration? olderThan}) async {
    await _resolutionService.cleanupBackups(olderThan: olderThan);
  }

  // ========== 统计和监控 ==========

  /// 获取统计信息
  Future<ConflictManagerStats> getStats() async {
    final currentConflicts = await getCurrentConflicts();
    
    return ConflictManagerStats(
      totalConflicts: _totalConflictsDetected,
      resolvedConflicts: _totalConflictsResolved,
      pendingConflicts: currentConflicts.length,
      autoResolvedConflicts: _autoResolvedCount,
      manuallyResolvedConflicts: _manuallyResolvedCount,
      conflictsByType: Map.from(_conflictsByType),
      resolutionsByType: Map.from(_resolutionsByType),
    );
  }

  /// 重置统计信息
  Future<void> resetStats() async {
    _totalConflictsDetected = 0;
    _totalConflictsResolved = 0;
    _autoResolvedCount = 0;
    _manuallyResolvedCount = 0;
    _conflictsByType.clear();
    _resolutionsByType.clear();

    // 清除持久化的统计信息
    final statKeys = await _cacheService.getSettingKeys(prefix: 'conflict_stat_');
    for (final key in statKeys) {
      await _cacheService.removeSetting(key);
    }
  }

  /// 导出冲突报告
  Future<String> exportConflictReport() async {
    final stats = await getStats();
    final currentConflicts = await getCurrentConflicts();
    
    final report = StringBuffer();
    report.writeln('# Conflict Management Report');
    report.writeln('Generated: ${DateTime.now().toIso8601String()}');
    report.writeln();
    
    report.writeln('## Statistics');
    report.writeln('- Total Conflicts Detected: ${stats.totalConflicts}');
    report.writeln('- Resolved Conflicts: ${stats.resolvedConflicts}');
    report.writeln('- Pending Conflicts: ${stats.pendingConflicts}');
    report.writeln('- Auto Resolved: ${stats.autoResolvedConflicts}');
    report.writeln('- Manually Resolved: ${stats.manuallyResolvedConflicts}');
    report.writeln();
    
    report.writeln('## Conflicts by Type');
    for (final entry in stats.conflictsByType.entries) {
      report.writeln('- ${entry.key.name}: ${entry.value}');
    }
    report.writeln();
    
    report.writeln('## Resolutions by Type');
    for (final entry in stats.resolutionsByType.entries) {
      report.writeln('- ${entry.key.name}: ${entry.value}');
    }
    report.writeln();
    
    if (currentConflicts.isNotEmpty) {
      report.writeln('## Current Conflicts');
      for (final conflict in currentConflicts) {
        report.writeln('- ${conflict.filePath}: ${conflict.type.name} (${conflict.severity.name})');
        report.writeln('  ${conflict.description}');
      }
    }
    
    return report.toString();
  }

  // ========== 私有方法 ==========

  /// 执行周期性冲突检测
  Future<void> _performPeriodicDetection() async {
    try {
      await detectAllConflicts();
    } catch (e) {
      // 周期性检测失败不抛出异常
    }
  }

  /// 释放资源
  void dispose() {
    _periodicDetectionTimer?.cancel();
    _eventController.close();
  }
}