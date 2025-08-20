import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'memory_manager.dart';

/// 性能监控服务 - 监控应用性能指标
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final MemoryManager _memoryManager = MemoryManager();
  
  Timer? _monitoringTimer;
  final List<PerformanceMetric> _metrics = [];
  final StreamController<PerformanceReport> _reportController = 
      StreamController<PerformanceReport>.broadcast();

  bool _isInitialized = false;
  bool _isMonitoring = false;

  /// 初始化性能服务
  void initialize() {
    if (_isInitialized) return;
    
    _memoryManager.initialize();
    _isInitialized = true;
    
    developer.log('PerformanceService initialized', name: 'Performance');
  }

  /// 开始性能监控
  void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(interval, (_) {
      _collectMetrics();
    });
    
    developer.log('Performance monitoring started', name: 'Performance');
  }

  /// 停止性能监控
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _isMonitoring = false;
    
    developer.log('Performance monitoring stopped', name: 'Performance');
  }

  /// 收集性能指标
  void _collectMetrics() {
    final metric = PerformanceMetric(
      timestamp: DateTime.now(),
      memoryUsage: _getMemoryUsage(),
      cacheStats: _memoryManager.getCacheStats(),
      platformInfo: _getPlatformInfo(),
    );
    
    _metrics.add(metric);
    
    // 保持最近100个指标
    if (_metrics.length > 100) {
      _metrics.removeAt(0);
    }
    
    // 发送报告
    final report = _generateReport();
    _reportController.add(report);
  }

  /// 获取内存使用情况
  Map<String, dynamic> _getMemoryUsage() {
    // 在实际应用中，这里会获取真实的内存使用数据
    // 目前返回模拟数据
    return {
      'used': 50 * 1024 * 1024, // 50MB
      'available': 200 * 1024 * 1024, // 200MB
      'total': 250 * 1024 * 1024, // 250MB
    };
  }

  /// 获取平台信息
  Map<String, dynamic> _getPlatformInfo() {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'isDebug': kDebugMode,
      'isProfile': kProfileMode,
      'isRelease': kReleaseMode,
    };
  }

  /// 生成性能报告
  PerformanceReport _generateReport() {
    if (_metrics.isEmpty) {
      return PerformanceReport(
        timestamp: DateTime.now(),
        summary: PerformanceSummary.empty(),
        recommendations: [],
      );
    }

    final recentMetrics = _metrics.take(10).toList();
    final summary = _calculateSummary(recentMetrics);
    final recommendations = _generateRecommendations(summary);

    return PerformanceReport(
      timestamp: DateTime.now(),
      summary: summary,
      recommendations: recommendations,
    );
  }

  /// 计算性能摘要
  PerformanceSummary _calculateSummary(List<PerformanceMetric> metrics) {
    if (metrics.isEmpty) return PerformanceSummary.empty();

    final memoryUsages = metrics.map((m) => m.memoryUsage['used'] as int).toList();
    final avgMemoryUsage = memoryUsages.reduce((a, b) => a + b) / memoryUsages.length;
    final maxMemoryUsage = memoryUsages.reduce((a, b) => a > b ? a : b);

    final cacheItems = metrics.map((m) => m.cacheStats['totalItems'] as int).toList();
    final avgCacheItems = cacheItems.reduce((a, b) => a + b) / cacheItems.length;

    return PerformanceSummary(
      averageMemoryUsage: avgMemoryUsage,
      maxMemoryUsage: maxMemoryUsage,
      averageCacheItems: avgCacheItems,
      performanceScore: _calculatePerformanceScore(avgMemoryUsage, maxMemoryUsage, avgCacheItems),
    );
  }

  /// 计算性能评分
  double _calculatePerformanceScore(double avgMemory, int maxMemory, double avgCache) {
    // 简单的性能评分算法
    double score = 100.0;
    
    // 内存使用评分
    final memoryMB = avgMemory / (1024 * 1024);
    if (memoryMB > 100) score -= 20;
    else if (memoryMB > 50) score -= 10;
    
    // 缓存使用评分
    if (avgCache > 80) score -= 10;
    else if (avgCache > 50) score -= 5;
    
    return score.clamp(0.0, 100.0);
  }

  /// 生成性能建议
  List<String> _generateRecommendations(PerformanceSummary summary) {
    final recommendations = <String>[];
    
    if (summary.averageMemoryUsage > 100 * 1024 * 1024) {
      recommendations.add('内存使用过高，建议清理缓存或优化数据结构');
    }
    
    if (summary.averageCacheItems > 80) {
      recommendations.add('缓存项目过多，建议调整缓存策略');
    }
    
    if (summary.performanceScore < 70) {
      recommendations.add('整体性能较低，建议进行性能优化');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('性能表现良好');
    }
    
    return recommendations;
  }

  /// 记录操作性能
  void recordOperation(String operationName, Duration duration) {
    _performanceMonitor.startTimer(operationName);
    Timer(duration, () {
      _performanceMonitor.stopTimer(operationName);
    });
  }

  /// 记录用户操作
  void recordUserAction(String action) {
    _performanceMonitor.startTimer('user_action_$action');
    // 用户操作通常很快完成
    Timer(const Duration(milliseconds: 1), () {
      _performanceMonitor.stopTimer('user_action_$action');
    });
  }

  /// 获取操作性能指标
  Map<String, dynamic> getOperationMetrics(String operationName) {
    return _performanceMonitor.getMetrics(operationName);
  }

  /// 获取所有性能指标
  Map<String, Map<String, dynamic>> getAllOperationMetrics() {
    return _performanceMonitor.getAllMetrics();
  }

  /// 获取性能报告流
  Stream<PerformanceReport> get reportStream => _reportController.stream;

  /// 获取当前性能摘要
  PerformanceSummary getCurrentSummary() {
    if (_metrics.isEmpty) return PerformanceSummary.empty();
    return _calculateSummary(_metrics.take(10).toList());
  }

  /// 清理性能数据
  void clearMetrics() {
    _metrics.clear();
    _performanceMonitor.clearMetrics();
    developer.log('Performance metrics cleared', name: 'Performance');
  }

  /// 导出性能数据
  Map<String, dynamic> exportData() {
    return {
      'metrics': _metrics.map((m) => m.toJson()).toList(),
      'operationMetrics': getAllOperationMetrics(),
      'summary': getCurrentSummary().toJson(),
      'exportTime': DateTime.now().toIso8601String(),
    };
  }

  /// 销毁性能服务
  void dispose() {
    stopMonitoring();
    _reportController.close();
    _memoryManager.dispose();
    _metrics.clear();
    _isInitialized = false;
    
    developer.log('PerformanceService disposed', name: 'Performance');
  }
}

/// 性能指标数据类
class PerformanceMetric {
  final DateTime timestamp;
  final Map<String, dynamic> memoryUsage;
  final Map<String, dynamic> cacheStats;
  final Map<String, dynamic> platformInfo;

  PerformanceMetric({
    required this.timestamp,
    required this.memoryUsage,
    required this.cacheStats,
    required this.platformInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'memoryUsage': memoryUsage,
      'cacheStats': cacheStats,
      'platformInfo': platformInfo,
    };
  }

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) {
    return PerformanceMetric(
      timestamp: DateTime.parse(json['timestamp']),
      memoryUsage: json['memoryUsage'],
      cacheStats: json['cacheStats'],
      platformInfo: json['platformInfo'],
    );
  }
}

/// 性能摘要数据类
class PerformanceSummary {
  final double averageMemoryUsage;
  final int maxMemoryUsage;
  final double averageCacheItems;
  final double performanceScore;

  PerformanceSummary({
    required this.averageMemoryUsage,
    required this.maxMemoryUsage,
    required this.averageCacheItems,
    required this.performanceScore,
  });

  factory PerformanceSummary.empty() {
    return PerformanceSummary(
      averageMemoryUsage: 0.0,
      maxMemoryUsage: 0,
      averageCacheItems: 0.0,
      performanceScore: 100.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageMemoryUsage': averageMemoryUsage,
      'maxMemoryUsage': maxMemoryUsage,
      'averageCacheItems': averageCacheItems,
      'performanceScore': performanceScore,
    };
  }

  factory PerformanceSummary.fromJson(Map<String, dynamic> json) {
    return PerformanceSummary(
      averageMemoryUsage: json['averageMemoryUsage'],
      maxMemoryUsage: json['maxMemoryUsage'],
      averageCacheItems: json['averageCacheItems'],
      performanceScore: json['performanceScore'],
    );
  }
}

/// 性能报告数据类
class PerformanceReport {
  final DateTime timestamp;
  final PerformanceSummary summary;
  final List<String> recommendations;

  PerformanceReport({
    required this.timestamp,
    required this.summary,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'summary': summary.toJson(),
      'recommendations': recommendations,
    };
  }

  factory PerformanceReport.fromJson(Map<String, dynamic> json) {
    return PerformanceReport(
      timestamp: DateTime.parse(json['timestamp']),
      summary: PerformanceSummary.fromJson(json['summary']),
      recommendations: List<String>.from(json['recommendations']),
    );
  }
}

/// 性能监控混入类
mixin PerformanceTrackingMixin {
  final PerformanceService _performanceService = PerformanceService();

  /// 跟踪方法执行时间
  Future<T> trackPerformance<T>(String operationName, Future<T> Function() operation) async {
    _performanceService.recordUserAction(operationName);
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      _performanceService.recordOperation(operationName, stopwatch.elapsed);
      return result;
    } catch (e) {
      stopwatch.stop();
      _performanceService.recordOperation('${operationName}_error', stopwatch.elapsed);
      rethrow;
    }
  }

  /// 跟踪同步方法执行时间
  T trackSyncPerformance<T>(String operationName, T Function() operation) {
    _performanceService.recordUserAction(operationName);
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = operation();
      stopwatch.stop();
      _performanceService.recordOperation(operationName, stopwatch.elapsed);
      return result;
    } catch (e) {
      stopwatch.stop();
      _performanceService.recordOperation('${operationName}_error', stopwatch.elapsed);
      rethrow;
    }
  }
}