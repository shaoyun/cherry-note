import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/core/performance/memory_manager.dart';

void main() {
  group('MemoryManager', () {
    late MemoryManager memoryManager;

    setUp(() {
      memoryManager = MemoryManager();
      memoryManager.initialize();
    });

    tearDown(() {
      memoryManager.dispose();
    });

    test('should cache and retrieve data correctly', () {
      // Arrange
      const key = 'test_key';
      const data = 'test_data';

      // Act
      memoryManager.cache(key, data);
      final retrieved = memoryManager.getCached<String>(key);

      // Assert
      expect(retrieved, equals(data));
    });

    test('should return null for non-existent cache key', () {
      // Act
      final retrieved = memoryManager.getCached<String>('non_existent');

      // Assert
      expect(retrieved, isNull);
    });

    test('should remove cache correctly', () {
      // Arrange
      const key = 'test_key';
      const data = 'test_data';
      memoryManager.cache(key, data);

      // Act
      memoryManager.removeCache(key);
      final retrieved = memoryManager.getCached<String>(key);

      // Assert
      expect(retrieved, isNull);
    });

    test('should clear all cache', () {
      // Arrange
      memoryManager.cache('key1', 'data1');
      memoryManager.cache('key2', 'data2');

      // Act
      memoryManager.clearCache();

      // Assert
      expect(memoryManager.getCached<String>('key1'), isNull);
      expect(memoryManager.getCached<String>('key2'), isNull);
    });

    test('should track access count', () {
      // Arrange
      const key = 'test_key';
      const data = 'test_data';
      memoryManager.cache(key, data);

      // Act
      memoryManager.getCached<String>(key);
      memoryManager.getCached<String>(key);
      memoryManager.getCached<String>(key);

      // Assert
      final stats = memoryManager.getCacheStats();
      expect(stats['totalItems'], equals(1));
    });

    test('should provide cache statistics', () {
      // Arrange
      memoryManager.cache('key1', 'data1');
      memoryManager.cache('key2', 'data2');

      // Act
      final stats = memoryManager.getCacheStats();

      // Assert
      expect(stats['totalItems'], equals(2));
      expect(stats['memoryUsage'], isA<int>());
      expect(stats['memoryUsage'], greaterThan(0));
    });
  });

  group('ImageCacheManager', () {
    late ImageCacheManager imageCacheManager;

    setUp(() {
      imageCacheManager = ImageCacheManager();
    });

    test('should cache and retrieve images correctly', () {
      // Arrange
      const url = 'https://example.com/image.jpg';
      const imageData = 'mock_image_data';

      // Act
      imageCacheManager.cacheImage(url, imageData);
      final retrieved = imageCacheManager.getCachedImage(url);

      // Assert
      expect(retrieved, equals(imageData));
    });

    test('should return null for non-cached image', () {
      // Act
      final retrieved = imageCacheManager.getCachedImage('non_existent_url');

      // Assert
      expect(retrieved, isNull);
    });

    test('should clear image cache', () {
      // Arrange
      imageCacheManager.cacheImage('url1', 'data1');
      imageCacheManager.cacheImage('url2', 'data2');

      // Act
      imageCacheManager.clearImageCache();

      // Assert
      expect(imageCacheManager.getCachedImage('url1'), isNull);
      expect(imageCacheManager.getCachedImage('url2'), isNull);
      expect(imageCacheManager.imageCacheSize, equals(0));
    });
  });

  group('LRUMap', () {
    test('should maintain maximum size', () {
      // Arrange
      final lruMap = LRUMap<String, String>(2);

      // Act
      lruMap['key1'] = 'value1';
      lruMap['key2'] = 'value2';
      lruMap['key3'] = 'value3'; // Should evict key1

      // Assert
      expect(lruMap.length, equals(2));
      expect(lruMap['key1'], isNull);
      expect(lruMap['key2'], equals('value2'));
      expect(lruMap['key3'], equals('value3'));
    });

    test('should update access order', () {
      // Arrange
      final lruMap = LRUMap<String, String>(2);
      lruMap['key1'] = 'value1';
      lruMap['key2'] = 'value2';

      // Act
      final _ = lruMap['key1']; // Access key1 to make it most recent
      lruMap['key3'] = 'value3'; // Should evict key2, not key1

      // Assert
      expect(lruMap.length, equals(2));
      expect(lruMap['key1'], equals('value1'));
      expect(lruMap['key2'], isNull);
      expect(lruMap['key3'], equals('value3'));
    });
  });

  group('PerformanceMonitor', () {
    late PerformanceMonitor performanceMonitor;

    setUp(() {
      performanceMonitor = PerformanceMonitor();
    });

    test('should measure execution time', () async {
      // Arrange
      const timerName = 'test_operation';

      // Act
      performanceMonitor.startTimer(timerName);
      await Future.delayed(const Duration(milliseconds: 10));
      performanceMonitor.stopTimer(timerName);

      // Assert
      final metrics = performanceMonitor.getMetrics(timerName);
      expect(metrics['count'], equals(1));
      expect(metrics['average'], greaterThan(0));
      expect(metrics['min'], greaterThan(0));
      expect(metrics['max'], greaterThan(0));
    });

    test('should handle multiple measurements', () async {
      // Arrange
      const timerName = 'test_operation';

      // Act
      for (int i = 0; i < 3; i++) {
        performanceMonitor.startTimer(timerName);
        await Future.delayed(const Duration(milliseconds: 5));
        performanceMonitor.stopTimer(timerName);
      }

      // Assert
      final metrics = performanceMonitor.getMetrics(timerName);
      expect(metrics['count'], equals(3));
      expect(metrics['average'], greaterThan(0));
      expect(metrics['median'], greaterThan(0));
    });

    test('should clear metrics', () async {
      // Arrange
      const timerName = 'test_operation';
      performanceMonitor.startTimer(timerName);
      await Future.delayed(const Duration(milliseconds: 5));
      performanceMonitor.stopTimer(timerName);

      // Act
      performanceMonitor.clearMetrics(timerName);

      // Assert
      final metrics = performanceMonitor.getMetrics(timerName);
      expect(metrics['count'], equals(0));
    });

    test('should get all metrics', () async {
      // Arrange
      performanceMonitor.startTimer('operation1');
      await Future.delayed(const Duration(milliseconds: 5));
      performanceMonitor.stopTimer('operation1');

      performanceMonitor.startTimer('operation2');
      await Future.delayed(const Duration(milliseconds: 5));
      performanceMonitor.stopTimer('operation2');

      // Act
      final allMetrics = performanceMonitor.getAllMetrics();

      // Assert
      expect(allMetrics.keys, contains('operation1'));
      expect(allMetrics.keys, contains('operation2'));
      expect(allMetrics['operation1']!['count'], equals(1));
      expect(allMetrics['operation2']!['count'], equals(1));
    });
  });
}