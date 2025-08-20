import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

/// 内存管理器 - 优化应用内存使用
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  final Map<String, dynamic> _cache = <String, dynamic>{};
  final Map<String, DateTime> _cacheTimestamps = <String, DateTime>{};
  final Map<String, int> _cacheAccessCount = <String, int>{};
  
  Timer? _cleanupTimer;
  static const Duration _cleanupInterval = Duration(minutes: 5);
  static const Duration _maxCacheAge = Duration(minutes: 30);
  static const int _maxCacheSize = 100;

  /// 初始化内存管理器
  void initialize() {
    _startCleanupTimer();
    developer.log('MemoryManager initialized', name: 'Performance');
  }

  /// 销毁内存管理器
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
    _cacheTimestamps.clear();
    _cacheAccessCount.clear();
    developer.log('MemoryManager disposed', name: 'Performance');
  }

  /// 启动定期清理定时器
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _performCleanup();
    });
  }

  /// 执行内存清理
  void _performCleanup() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    // 清理过期缓存
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _maxCacheAge) {
        keysToRemove.add(entry.key);
      }
    }

    // 如果缓存过多，清理最少使用的项
    if (_cache.length > _maxCacheSize) {
      final sortedEntries = _cacheAccessCount.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      final itemsToRemove = _cache.length - _maxCacheSize + keysToRemove.length;
      for (int i = 0; i < itemsToRemove && i < sortedEntries.length; i++) {
        keysToRemove.add(sortedEntries[i].key);
      }
    }

    // 移除标记的缓存项
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      _cacheAccessCount.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      developer.log('Cleaned up ${keysToRemove.length} cache items', name: 'Performance');
    }
  }

  /// 缓存数据
  void cache<T>(String key, T data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    _cacheAccessCount[key] = 0;
  }

  /// 获取缓存数据
  T? getCached<T>(String key) {
    if (_cache.containsKey(key)) {
      _cacheAccessCount[key] = (_cacheAccessCount[key] ?? 0) + 1;
      return _cache[key] as T?;
    }
    return null;
  }

  /// 移除缓存
  void removeCache(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    _cacheAccessCount.remove(key);
  }

  /// 清空所有缓存
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
    _cacheAccessCount.clear();
    developer.log('All cache cleared', name: 'Performance');
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return {
      'totalItems': _cache.length,
      'memoryUsage': _estimateMemoryUsage(),
      'oldestItem': _getOldestCacheTime(),
      'mostAccessedItem': _getMostAccessedItem(),
    };
  }

  /// 估算内存使用量（简单估算）
  int _estimateMemoryUsage() {
    int totalSize = 0;
    for (final value in _cache.values) {
      if (value is String) {
        totalSize += value.length * 2; // UTF-16 encoding
      } else if (value is List) {
        totalSize += value.length * 8; // Rough estimate
      } else {
        totalSize += 64; // Default object size estimate
      }
    }
    return totalSize;
  }

  /// 获取最旧的缓存时间
  DateTime? _getOldestCacheTime() {
    if (_cacheTimestamps.isEmpty) return null;
    return _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// 获取访问次数最多的缓存项
  String? _getMostAccessedItem() {
    if (_cacheAccessCount.isEmpty) return null;
    return _cacheAccessCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}

/// 图片缓存管理器
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  final LRUMap<String, dynamic> _imageCache = LRUMap<String, dynamic>(100);
  
  /// 缓存图片数据
  void cacheImage(String url, dynamic imageData) {
    _imageCache[url] = imageData;
  }

  /// 获取缓存的图片
  dynamic getCachedImage(String url) {
    return _imageCache[url];
  }

  /// 清理图片缓存
  void clearImageCache() {
    _imageCache.clear();
    developer.log('Image cache cleared', name: 'Performance');
  }

  /// 获取图片缓存大小
  int get imageCacheSize => _imageCache.length;
}

/// LRU (Least Recently Used) 缓存实现
class LRUMap<K, V> {
  final int _maxSize;
  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();

  LRUMap(this._maxSize);

  V? operator [](K key) {
    final value = _map.remove(key);
    if (value != null) {
      _map[key] = value;
    }
    return value;
  }

  void operator []=(K key, V value) {
    _map.remove(key);
    _map[key] = value;
    
    if (_map.length > _maxSize) {
      _map.remove(_map.keys.first);
    }
  }

  void clear() {
    _map.clear();
  }

  int get length => _map.length;
  
  bool containsKey(K key) => _map.containsKey(key);
  
  V? remove(K key) => _map.remove(key);
}

/// 性能监控器
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, Stopwatch> _timers = <String, Stopwatch>{};
  final Map<String, List<int>> _metrics = <String, List<int>>{};

  /// 开始性能计时
  void startTimer(String name) {
    _timers[name] = Stopwatch()..start();
  }

  /// 停止性能计时并记录
  void stopTimer(String name) {
    final timer = _timers[name];
    if (timer != null) {
      timer.stop();
      final elapsed = timer.elapsedMilliseconds;
      
      _metrics.putIfAbsent(name, () => <int>[]).add(elapsed);
      _timers.remove(name);
      
      developer.log('$name took ${elapsed}ms', name: 'Performance');
    }
  }

  /// 获取性能指标
  Map<String, dynamic> getMetrics(String name) {
    final values = _metrics[name];
    if (values == null || values.isEmpty) {
      return {'count': 0};
    }

    values.sort();
    final count = values.length;
    final sum = values.reduce((a, b) => a + b);
    final avg = sum / count;
    final median = count % 2 == 0
        ? (values[count ~/ 2 - 1] + values[count ~/ 2]) / 2
        : values[count ~/ 2].toDouble();

    return {
      'count': count,
      'average': avg,
      'median': median,
      'min': values.first,
      'max': values.last,
      'total': sum,
    };
  }

  /// 清理性能指标
  void clearMetrics([String? name]) {
    if (name != null) {
      _metrics.remove(name);
    } else {
      _metrics.clear();
    }
  }

  /// 获取所有性能指标
  Map<String, Map<String, dynamic>> getAllMetrics() {
    final result = <String, Map<String, dynamic>>{};
    for (final name in _metrics.keys) {
      result[name] = getMetrics(name);
    }
    return result;
  }
}