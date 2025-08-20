import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/core/performance/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('should delay execution', () async {
      // Arrange
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
      bool executed = false;

      // Act
      debouncer.call(() {
        executed = true;
      });

      // Assert - should not execute immediately
      expect(executed, isFalse);
      expect(debouncer.isActive, isTrue);

      // Wait for delay
      await Future.delayed(const Duration(milliseconds: 150));
      expect(executed, isTrue);
      expect(debouncer.isActive, isFalse);

      debouncer.dispose();
    });

    test('should cancel previous execution when called again', () async {
      // Arrange
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
      int executionCount = 0;

      // Act
      debouncer.call(() {
        executionCount++;
      });

      await Future.delayed(const Duration(milliseconds: 50));

      debouncer.call(() {
        executionCount++;
      });

      // Wait for delay
      await Future.delayed(const Duration(milliseconds: 150));

      // Assert - should only execute once (the last call)
      expect(executionCount, equals(1));

      debouncer.dispose();
    });

    test('should execute immediately with callNow', () {
      // Arrange
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
      bool executed = false;

      // Act
      debouncer.callNow(() {
        executed = true;
      });

      // Assert
      expect(executed, isTrue);
      expect(debouncer.isActive, isFalse);

      debouncer.dispose();
    });

    test('should cancel pending execution', () async {
      // Arrange
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
      bool executed = false;

      // Act
      debouncer.call(() {
        executed = true;
      });

      debouncer.cancel();

      // Wait for original delay
      await Future.delayed(const Duration(milliseconds: 150));

      // Assert
      expect(executed, isFalse);
      expect(debouncer.isActive, isFalse);

      debouncer.dispose();
    });
  });

  group('Throttler', () {
    test('should execute immediately on first call', () {
      // Arrange
      final throttler = Throttler(interval: const Duration(milliseconds: 100));
      bool executed = false;

      // Act
      throttler.call(() {
        executed = true;
      });

      // Assert
      expect(executed, isTrue);

      throttler.dispose();
    });

    test('should throttle subsequent calls', () async {
      // Arrange
      final throttler = Throttler(interval: const Duration(milliseconds: 100));
      int executionCount = 0;

      // Act
      throttler.call(() {
        executionCount++;
      });

      throttler.call(() {
        executionCount++;
      });

      throttler.call(() {
        executionCount++;
      });

      // Assert - should only execute once immediately
      expect(executionCount, equals(1));

      // Wait for throttle interval
      await Future.delayed(const Duration(milliseconds: 150));

      // Should execute the last call
      expect(executionCount, equals(2));

      throttler.dispose();
    });

    test('should execute immediately with callNow', () {
      // Arrange
      final throttler = Throttler(interval: const Duration(milliseconds: 100));
      int executionCount = 0;

      // Act
      throttler.call(() {
        executionCount++;
      });

      throttler.callNow(() {
        executionCount++;
      });

      // Assert
      expect(executionCount, equals(2));

      throttler.dispose();
    });
  });

  group('BatchProcessor', () {
    test('should process batch when max size reached', () async {
      // Arrange
      final processedBatches = <List<int>>[];
      final batchProcessor = BatchProcessor<int>(
        batchInterval: const Duration(milliseconds: 100),
        maxBatchSize: 3,
        processor: (items) async {
          processedBatches.add(List.from(items));
        },
      );

      // Act
      batchProcessor.add(1);
      batchProcessor.add(2);
      batchProcessor.add(3); // Should trigger batch processing

      // Wait a bit for async processing
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(processedBatches.length, equals(1));
      expect(processedBatches[0], equals([1, 2, 3]));
      expect(batchProcessor.pendingCount, equals(0));

      batchProcessor.dispose();
    });

    test('should process batch after interval', () async {
      // Arrange
      final processedBatches = <List<int>>[];
      final batchProcessor = BatchProcessor<int>(
        batchInterval: const Duration(milliseconds: 50),
        maxBatchSize: 10,
        processor: (items) async {
          processedBatches.add(List.from(items));
        },
      );

      // Act
      batchProcessor.add(1);
      batchProcessor.add(2);

      // Wait for batch interval
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(processedBatches.length, equals(1));
      expect(processedBatches[0], equals([1, 2]));
      expect(batchProcessor.pendingCount, equals(0));

      batchProcessor.dispose();
    });

    test('should flush pending items immediately', () async {
      // Arrange
      final processedBatches = <List<int>>[];
      final batchProcessor = BatchProcessor<int>(
        batchInterval: const Duration(milliseconds: 1000),
        maxBatchSize: 10,
        processor: (items) async {
          processedBatches.add(List.from(items));
        },
      );

      // Act
      batchProcessor.add(1);
      batchProcessor.add(2);
      await batchProcessor.flush();

      // Assert
      expect(processedBatches.length, equals(1));
      expect(processedBatches[0], equals([1, 2]));
      expect(batchProcessor.pendingCount, equals(0));

      batchProcessor.dispose();
    });

    test('should handle addAll correctly', () async {
      // Arrange
      final processedBatches = <List<int>>[];
      final batchProcessor = BatchProcessor<int>(
        batchInterval: const Duration(milliseconds: 100),
        maxBatchSize: 5,
        processor: (items) async {
          processedBatches.add(List.from(items));
        },
      );

      // Act
      batchProcessor.addAll([1, 2, 3, 4, 5]); // Should trigger batch processing

      // Wait a bit for async processing
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert
      expect(processedBatches.length, equals(1));
      expect(processedBatches[0], equals([1, 2, 3, 4, 5]));

      batchProcessor.dispose();
    });
  });

  group('AsyncQueue', () {
    test('should limit concurrent operations', () async {
      // Arrange
      final asyncQueue = AsyncQueue(maxConcurrency: 2);
      int runningCount = 0;
      int maxConcurrentCount = 0;

      Future<void> operation() async {
        runningCount++;
        maxConcurrentCount = maxConcurrentCount > runningCount 
            ? maxConcurrentCount 
            : runningCount;
        
        await Future.delayed(const Duration(milliseconds: 50));
        runningCount--;
      }

      // Act
      final futures = List.generate(5, (_) => asyncQueue.add(operation));
      await Future.wait(futures);

      // Assert
      expect(maxConcurrentCount, lessThanOrEqualTo(2));
      expect(runningCount, equals(0));
    });

    test('should return results correctly', () async {
      // Arrange
      final asyncQueue = AsyncQueue(maxConcurrency: 2);

      Future<int> operation(int value) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return value * 2;
      }

      // Act
      final results = await Future.wait([
        asyncQueue.add(() => operation(1)),
        asyncQueue.add(() => operation(2)),
        asyncQueue.add(() => operation(3)),
      ]);

      // Assert
      expect(results, equals([2, 4, 6]));
    });

    test('should handle errors correctly', () async {
      // Arrange
      final asyncQueue = AsyncQueue(maxConcurrency: 1);

      Future<void> failingOperation() async {
        await Future.delayed(const Duration(milliseconds: 10));
        throw Exception('Test error');
      }

      // Act & Assert
      expect(
        () => asyncQueue.add(failingOperation),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('CachedDebouncer', () {
    test('should cache and return values', () async {
      // Arrange
      final cachedDebouncer = CachedDebouncer<String>(
        delay: const Duration(milliseconds: 50),
      );
      String? result;

      // Act
      cachedDebouncer.call(
        'test_key',
        () => 'test_value',
        (value) => result = value,
      );

      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(result, equals('test_value'));
      expect(cachedDebouncer.getCached('test_key'), equals('test_value'));

      cachedDebouncer.dispose();
    });

    test('should return cached value immediately', () {
      // Arrange
      final cachedDebouncer = CachedDebouncer<String>(
        delay: const Duration(milliseconds: 50),
      );

      // Act
      cachedDebouncer.callNow(
        'test_key',
        () => 'test_value',
        (value) {},
      );

      // Assert
      expect(cachedDebouncer.getCached('test_key'), equals('test_value'));

      cachedDebouncer.dispose();
    });

    test('should clear cache correctly', () {
      // Arrange
      final cachedDebouncer = CachedDebouncer<String>(
        delay: const Duration(milliseconds: 50),
      );

      cachedDebouncer.callNow(
        'test_key',
        () => 'test_value',
        (value) {},
      );

      // Act
      cachedDebouncer.clearCache('test_key');

      // Assert
      expect(cachedDebouncer.getCached('test_key'), isNull);

      cachedDebouncer.dispose();
    });
  });
}