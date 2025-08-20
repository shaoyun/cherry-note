import 'package:cherry_note/features/sync/domain/services/sync_service.dart';
import 'package:cherry_note/features/sync/data/datasources/local_cache_service.dart';
import 'package:cherry_note/features/sync/domain/repositories/s3_storage_repository.dart';

/// 冲突检测类型
enum ConflictType {
  /// 内容冲突 - 本地和远程都有修改
  contentConflict,
  /// 时间戳冲突 - 时间戳不一致但内容可能相同
  timestampConflict,
  /// 删除冲突 - 一方删除，另一方修改
  deleteConflict,
  /// 创建冲突 - 同时创建同名文件
  createConflict,
}

/// 冲突严重程度
enum ConflictSeverity {
  /// 低 - 可以自动解决
  low,
  /// 中 - 需要用户选择策略
  medium,
  /// 高 - 需要用户手动处理
  high,
}

/// 冲突检测结果
class ConflictDetectionResult {
  final String filePath;
  final ConflictType type;
  final ConflictSeverity severity;
  final FileConflict? conflict;
  final String description;
  final List<ConflictResolution> suggestedResolutions;
  final ConflictResolution? autoResolution;

  ConflictDetectionResult({
    required this.filePath,
    required this.type,
    required this.severity,
    this.conflict,
    required this.description,
    this.suggestedResolutions = const [],
    this.autoResolution,
  });

  /// 是否可以自动解决
  bool get canAutoResolve => autoResolution != null;

  @override
  String toString() {
    return 'ConflictDetectionResult(filePath: $filePath, type: $type, '
        'severity: $severity, canAutoResolve: $canAutoResolve)';
  }
}

/// 冲突检测服务
abstract class ConflictDetectionService {
  /// 检测单个文件的冲突
  Future<ConflictDetectionResult?> detectFileConflict(String filePath);

  /// 批量检测冲突
  Future<List<ConflictDetectionResult>> detectConflicts(List<String> filePaths);

  /// 检测所有可能的冲突
  Future<List<ConflictDetectionResult>> detectAllConflicts();

  /// 分析冲突严重程度
  ConflictSeverity analyzeConflictSeverity(FileConflict conflict);

  /// 获取建议的解决方案
  List<ConflictResolution> getSuggestedResolutions(ConflictDetectionResult result);

  /// 检查是否可以自动解决
  ConflictResolution? getAutoResolution(ConflictDetectionResult result);

  /// 预览冲突解决结果
  Future<String> previewResolution(
    FileConflict conflict,
    ConflictResolution resolution,
  );
}

/// 冲突检测服务实现
class ConflictDetectionServiceImpl implements ConflictDetectionService {
  final LocalCacheService _cacheService;
  final S3StorageRepository _storageRepository;

  ConflictDetectionServiceImpl({
    required LocalCacheService cacheService,
    required S3StorageRepository storageRepository,
  })  : _cacheService = cacheService,
        _storageRepository = storageRepository;

  @override
  Future<ConflictDetectionResult?> detectFileConflict(String filePath) async {
    try {
      // 获取本地和远程文件信息
      final localContent = await _cacheService.getCachedFile(filePath);
      final localTimestamp = await _cacheService.getCacheTimestamp(filePath);

      String? remoteContent;
      DateTime? remoteTimestamp;

      try {
        remoteContent = await _storageRepository.downloadFile(filePath);
        // 这里需要S3StorageRepository支持获取文件元数据
        // 暂时使用当前时间作为占位符
        remoteTimestamp = DateTime.now();
      } catch (e) {
        // 远程文件不存在
        remoteContent = null;
        remoteTimestamp = null;
      }

      // 分析冲突类型
      final conflictType = _analyzeConflictType(
        localContent,
        remoteContent,
        localTimestamp,
        remoteTimestamp,
      );

      if (conflictType == null) {
        return null; // 没有冲突
      }

      // 创建冲突对象
      FileConflict? conflict;
      if (localContent != null && remoteContent != null && 
          localTimestamp != null && remoteTimestamp != null) {
        conflict = FileConflict(
          filePath: filePath,
          localModified: localTimestamp,
          remoteModified: remoteTimestamp,
          localContent: localContent,
          remoteContent: remoteContent,
        );
      }

      // 分析严重程度
      final severity = conflict != null 
          ? analyzeConflictSeverity(conflict)
          : ConflictSeverity.medium;

      // 生成描述
      final description = _generateConflictDescription(conflictType, filePath);

      // 获取建议的解决方案
      final result = ConflictDetectionResult(
        filePath: filePath,
        type: conflictType,
        severity: severity,
        conflict: conflict,
        description: description,
      );

      final suggestedResolutions = getSuggestedResolutions(result);
      final autoResolution = getAutoResolution(result);

      return ConflictDetectionResult(
        filePath: filePath,
        type: conflictType,
        severity: severity,
        conflict: conflict,
        description: description,
        suggestedResolutions: suggestedResolutions,
        autoResolution: autoResolution,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<ConflictDetectionResult>> detectConflicts(List<String> filePaths) async {
    final results = <ConflictDetectionResult>[];

    for (final filePath in filePaths) {
      final result = await detectFileConflict(filePath);
      if (result != null) {
        results.add(result);
      }
    }

    return results;
  }

  @override
  Future<List<ConflictDetectionResult>> detectAllConflicts() async {
    try {
      // 获取所有本地文件
      final localFiles = await _cacheService.getCachedFiles();
      
      // 获取所有远程文件
      final remoteFiles = await _storageRepository.listFiles('');

      // 合并文件列表
      final allFiles = <String>{...localFiles, ...remoteFiles}.toList();

      return await detectConflicts(allFiles);
    } catch (e) {
      return [];
    }
  }

  @override
  ConflictSeverity analyzeConflictSeverity(FileConflict conflict) {
    // 计算内容差异程度
    final contentSimilarity = _calculateContentSimilarity(
      conflict.localContent,
      conflict.remoteContent,
    );

    // 计算时间差
    final timeDifference = conflict.remoteModified
        .difference(conflict.localModified)
        .abs()
        .inMinutes;

    // 根据相似度和时间差判断严重程度
    if (contentSimilarity > 0.9) {
      return ConflictSeverity.low; // 内容几乎相同，可能只是格式差异
    } else if (contentSimilarity > 0.7 && timeDifference < 60) {
      return ConflictSeverity.medium; // 内容相似且时间接近
    } else {
      return ConflictSeverity.high; // 内容差异大或时间差异大
    }
  }

  @override
  List<ConflictResolution> getSuggestedResolutions(ConflictDetectionResult result) {
    switch (result.type) {
      case ConflictType.contentConflict:
        return [
          ConflictResolution.merge,
          ConflictResolution.keepLocal,
          ConflictResolution.keepRemote,
          ConflictResolution.createBoth,
        ];
      case ConflictType.timestampConflict:
        return [
          ConflictResolution.keepLocal,
          ConflictResolution.keepRemote,
        ];
      case ConflictType.deleteConflict:
        return [
          ConflictResolution.keepLocal,
          ConflictResolution.keepRemote,
        ];
      case ConflictType.createConflict:
        return [
          ConflictResolution.createBoth,
          ConflictResolution.keepLocal,
          ConflictResolution.keepRemote,
        ];
    }
  }

  @override
  ConflictResolution? getAutoResolution(ConflictDetectionResult result) {
    // 只有低严重程度的冲突才考虑自动解决
    if (result.severity != ConflictSeverity.low) {
      return null;
    }

    switch (result.type) {
      case ConflictType.timestampConflict:
        // 时间戳冲突且内容相似，保留较新的版本
        return ConflictResolution.keepRemote;
      case ConflictType.contentConflict:
        // 内容冲突但相似度很高，尝试合并
        if (result.conflict != null) {
          final similarity = _calculateContentSimilarity(
            result.conflict!.localContent,
            result.conflict!.remoteContent,
          );
          if (similarity > 0.95) {
            return ConflictResolution.merge;
          }
        }
        return null;
      default:
        return null;
    }
  }

  @override
  Future<String> previewResolution(
    FileConflict conflict,
    ConflictResolution resolution,
  ) async {
    switch (resolution) {
      case ConflictResolution.keepLocal:
        return conflict.localContent;
      case ConflictResolution.keepRemote:
        return conflict.remoteContent;
      case ConflictResolution.merge:
        return _mergeContent(conflict.localContent, conflict.remoteContent);
      case ConflictResolution.createBoth:
        return 'Local version: ${conflict.filePath}_local\n'
            'Remote version: ${conflict.filePath}_remote';
    }
  }

  /// 分析冲突类型
  ConflictType? _analyzeConflictType(
    String? localContent,
    String? remoteContent,
    DateTime? localTimestamp,
    DateTime? remoteTimestamp,
  ) {
    // 两者都不存在，没有冲突
    if (localContent == null && remoteContent == null) {
      return null;
    }

    // 删除冲突：一方存在，另一方不存在
    if (localContent == null || remoteContent == null) {
      return ConflictType.deleteConflict;
    }

    // 内容相同，没有冲突
    if (localContent == remoteContent) {
      return null;
    }

    // 内容不同，判断是内容冲突还是时间戳冲突
    final contentSimilarity = _calculateContentSimilarity(localContent, remoteContent);
    if (contentSimilarity > 0.9) {
      return ConflictType.timestampConflict;
    }

    // 默认为内容冲突
    return ConflictType.contentConflict;
  }

  /// 计算内容相似度
  double _calculateContentSimilarity(String content1, String content2) {
    if (content1 == content2) return 1.0;
    if (content1.isEmpty && content2.isEmpty) return 1.0;
    if (content1.isEmpty || content2.isEmpty) return 0.0;

    // 简单的相似度计算：基于字符级别的编辑距离
    final maxLength = content1.length > content2.length ? content1.length : content2.length;
    final editDistance = _calculateEditDistance(content1, content2);
    
    return 1.0 - (editDistance / maxLength);
  }

  /// 计算编辑距离（Levenshtein距离）
  int _calculateEditDistance(String s1, String s2) {
    final m = s1.length;
    final n = s2.length;

    // 创建DP表
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    // 初始化边界条件
    for (int i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= n; j++) {
      dp[0][j] = j;
    }

    // 填充DP表
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (s1[i - 1] == s2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 + [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]].reduce((a, b) => a < b ? a : b);
        }
      }
    }

    return dp[m][n];
  }

  /// 生成冲突描述
  String _generateConflictDescription(ConflictType type, String filePath) {
    switch (type) {
      case ConflictType.contentConflict:
        return 'File "$filePath" has been modified both locally and remotely with different content.';
      case ConflictType.timestampConflict:
        return 'File "$filePath" has timestamp conflicts but similar content.';
      case ConflictType.deleteConflict:
        return 'File "$filePath" has been deleted in one location but modified in another.';
      case ConflictType.createConflict:
        return 'File "$filePath" has been created simultaneously in both locations with different content.';
    }
  }

  /// 合并内容
  String _mergeContent(String localContent, String remoteContent) {
    // 简单的合并策略：将两个版本合并
    final lines1 = localContent.split('\n');
    final lines2 = remoteContent.split('\n');

    final mergedLines = <String>[];
    final maxLines = lines1.length > lines2.length ? lines1.length : lines2.length;

    for (int i = 0; i < maxLines; i++) {
      final line1 = i < lines1.length ? lines1[i] : '';
      final line2 = i < lines2.length ? lines2[i] : '';

      if (line1 == line2) {
        mergedLines.add(line1);
      } else if (line1.isEmpty) {
        mergedLines.add(line2);
      } else if (line2.isEmpty) {
        mergedLines.add(line1);
      } else {
        // 冲突行，保留两个版本
        mergedLines.add('<<<<<<< LOCAL');
        mergedLines.add(line1);
        mergedLines.add('=======');
        mergedLines.add(line2);
        mergedLines.add('>>>>>>> REMOTE');
      }
    }

    return mergedLines.join('\n');
  }
}