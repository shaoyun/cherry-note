import 'dart:async';

/// 防抖动器 - 防止频繁触发操作
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  /// 执行防抖动操作
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// 立即执行并取消等待中的操作
  void callNow(void Function() action) {
    _timer?.cancel();
    action();
  }

  /// 取消等待中的操作
  void cancel() {
    _timer?.cancel();
  }

  /// 检查是否有等待中的操作
  bool get isActive => _timer?.isActive ?? false;

  /// 销毁防抖动器
  void dispose() {
    _timer?.cancel();
  }
}

/// 节流器 - 限制操作执行频率
class Throttler {
  final Duration interval;
  DateTime? _lastExecution;
  Timer? _timer;

  Throttler({required this.interval});

  /// 执行节流操作
  void call(void Function() action) {
    final now = DateTime.now();
    
    if (_lastExecution == null || 
        now.difference(_lastExecution!) >= interval) {
      _lastExecution = now;
      action();
    } else if (_timer == null || !_timer!.isActive) {
      final remaining = interval - now.difference(_lastExecution!);
      _timer = Timer(remaining, () {
        _lastExecution = DateTime.now();
        action();
      });
    }
  }

  /// 立即执行并重置计时器
  void callNow(void Function() action) {
    _timer?.cancel();
    _lastExecution = DateTime.now();
    action();
  }

  /// 取消等待中的操作
  void cancel() {
    _timer?.cancel();
  }

  /// 检查是否有等待中的操作
  bool get isActive => _timer?.isActive ?? false;

  /// 销毁节流器
  void dispose() {
    _timer?.cancel();
  }
}

/// 批处理器 - 批量处理操作以提高性能
class BatchProcessor<T> {
  final Duration batchInterval;
  final int maxBatchSize;
  final Future<void> Function(List<T> items) processor;
  
  final List<T> _pendingItems = [];
  Timer? _batchTimer;

  BatchProcessor({
    required this.batchInterval,
    required this.maxBatchSize,
    required this.processor,
  });

  /// 添加项目到批处理队列
  void add(T item) {
    _pendingItems.add(item);
    
    if (_pendingItems.length >= maxBatchSize) {
      _processBatch();
    } else if (_batchTimer == null || !_batchTimer!.isActive) {
      _batchTimer = Timer(batchInterval, _processBatch);
    }
  }

  /// 添加多个项目到批处理队列
  void addAll(List<T> items) {
    _pendingItems.addAll(items);
    
    if (_pendingItems.length >= maxBatchSize) {
      _processBatch();
    } else if (_batchTimer == null || !_batchTimer!.isActive) {
      _batchTimer = Timer(batchInterval, _processBatch);
    }
  }

  /// 立即处理当前批次
  Future<void> flush() async {
    _batchTimer?.cancel();
    await _processBatch();
  }

  /// 处理批次
  Future<void> _processBatch() async {
    if (_pendingItems.isEmpty) return;
    
    final batch = List<T>.from(_pendingItems);
    _pendingItems.clear();
    _batchTimer?.cancel();
    
    try {
      await processor(batch);
    } catch (e) {
      // 处理失败时可以选择重新加入队列或记录错误
      rethrow;
    }
  }

  /// 获取待处理项目数量
  int get pendingCount => _pendingItems.length;

  /// 检查是否有待处理的批次
  bool get hasPending => _pendingItems.isNotEmpty;

  /// 销毁批处理器
  void dispose() {
    _batchTimer?.cancel();
    _pendingItems.clear();
  }
}

/// 异步操作队列 - 控制并发异步操作数量
class AsyncQueue {
  final int maxConcurrency;
  final List<Future<void> Function()> _queue = [];
  int _running = 0;

  AsyncQueue({this.maxConcurrency = 3});

  /// 添加异步操作到队列
  Future<T> add<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    
    _queue.add(() async {
      try {
        final result = await operation();
        completer.complete(result);
      } catch (error) {
        completer.completeError(error);
      }
    });
    
    _processQueue();
    return completer.future;
  }

  /// 处理队列中的操作
  void _processQueue() {
    while (_running < maxConcurrency && _queue.isNotEmpty) {
      final operation = _queue.removeAt(0);
      _running++;
      
      operation().whenComplete(() {
        _running--;
        _processQueue();
      });
    }
  }

  /// 获取队列长度
  int get queueLength => _queue.length;

  /// 获取正在运行的操作数量
  int get runningCount => _running;

  /// 清空队列
  void clear() {
    _queue.clear();
  }
}

/// 缓存防抖动器 - 带缓存的防抖动操作
class CachedDebouncer<T> {
  final Duration delay;
  final Map<String, Timer> _timers = {};
  final Map<String, T?> _cache = {};

  CachedDebouncer({required this.delay});

  /// 执行带缓存的防抖动操作
  void call(String key, T? Function() getter, void Function(T?) callback) {
    _timers[key]?.cancel();
    
    _timers[key] = Timer(delay, () {
      final value = getter();
      _cache[key] = value;
      callback(value);
      _timers.remove(key);
    });
  }

  /// 获取缓存值
  T? getCached(String key) => _cache[key];

  /// 立即执行并缓存结果
  void callNow(String key, T? Function() getter, void Function(T?) callback) {
    _timers[key]?.cancel();
    final value = getter();
    _cache[key] = value;
    callback(value);
    _timers.remove(key);
  }

  /// 取消指定键的操作
  void cancel(String key) {
    _timers[key]?.cancel();
    _timers.remove(key);
  }

  /// 清除缓存
  void clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
    } else {
      _cache.clear();
    }
  }

  /// 销毁防抖动器
  void dispose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _cache.clear();
  }
}