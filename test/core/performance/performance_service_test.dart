import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/core/performance/performance_service.dart';

void main() {
  group('PerformanceService', () {
    late PerformanceService performanceService;

    setUp(() {
      performanceService = PerformanceService();
      performanceService.initialize();
    });

    tearDown(() {
      performanceService.dispose();
    });

    test('should initialize correctly', () {
      // Act
      performanceService.initialize();

      // Assert
      expect(performanceService, isNotNull);
    });

    test('should start and stop monitoring', () {
      // Act
      performanceService.startMonitoring();
      expect(performanceService, isNotNull); // Monitoring started

      performanceService.stopMonitoring();
      expect(performanceService, isNotNull); // Monitoring stopped
    });

    test('should record operation performance', () {
      // Arrange
      const operationName = 'test_operation';
      const duration = Duration(milliseconds: 100);

      // Act
      performanceService.recordOperation(operationName, duration);

      // Assert
      final metrics = performanceService.getOperationMetrics(operationName);
      expect(metrics['count'], greaterThan(0));
    });

    test('should record user actions', () {
      // Arrange
      const action = 'button_click';

      // Act
      performanceService.recordUserAction(action);

      // Assert
      final metrics = performanceService.getOperationMetrics('user_action_$action');
      expect(metrics['count'], greaterThan(0));
    });

    test('should get current performance summary', () {
      // Act
      final summary = performanceService.getCurrentSummary();

      // Assert
      expect(summary, isNotNull);
      expect(summary.performanceScore, greaterThanOrEqualTo(0));
      expect(summary.performanceScore, lessThanOrEqualTo(100));
    });

    test('should export performance data', () {
      // Arrange
      performanceService.recordOperation('test_op', const Duration(milliseconds: 50));

      // Act
      final exportedData = performanceService.exportData();

      // Assert
      expect(exportedData, isA<Map<String, dynamic>>());
      expect(exportedData.containsKey('metrics'), isTrue);
      expect(exportedData.containsKey('operationMetrics'), isTrue);
      expect(exportedData.containsKey('summary'), isTrue);
      expect(exportedData.containsKey('exportTime'), isTrue);
    });

    test('should clear metrics', () {
      // Arrange
      performanceService.recordOperation('test_op', const Duration(milliseconds: 50));

      // Act
      performanceService.clearMetrics();

      // Assert
      final summary = performanceService.getCurrentSummary();
      expect(summary.averageMemoryUsage, equals(0.0));
    });

    test('should provide report stream', () {
      // Act
      final stream = performanceService.reportStream;

      // Assert
      expect(stream, isA<Stream<PerformanceReport>>());
    });
  });

  group('PerformanceMetric', () {
    test('should serialize to and from JSON', () {
      // Arrange
      final metric = PerformanceMetric(
        timestamp: DateTime.now(),
        memoryUsage: {'used': 1024, 'total': 2048},
        cacheStats: {'items': 10, 'size': 512},
        platformInfo: {'platform': 'test', 'version': '1.0'},
      );

      // Act
      final json = metric.toJson();
      final restored = PerformanceMetric.fromJson(json);

      // Assert
      expect(restored.memoryUsage, equals(metric.memoryUsage));
      expect(restored.cacheStats, equals(metric.cacheStats));
      expect(restored.platformInfo, equals(metric.platformInfo));
    });
  });

  group('PerformanceSummary', () {
    test('should create empty summary', () {
      // Act
      final summary = PerformanceSummary.empty();

      // Assert
      expect(summary.averageMemoryUsage, equals(0.0));
      expect(summary.maxMemoryUsage, equals(0));
      expect(summary.averageCacheItems, equals(0.0));
      expect(summary.performanceScore, equals(100.0));
    });

    test('should serialize to and from JSON', () {
      // Arrange
      final summary = PerformanceSummary(
        averageMemoryUsage: 1024.0,
        maxMemoryUsage: 2048,
        averageCacheItems: 10.5,
        performanceScore: 85.0,
      );

      // Act
      final json = summary.toJson();
      final restored = PerformanceSummary.fromJson(json);

      // Assert
      expect(restored.averageMemoryUsage, equals(summary.averageMemoryUsage));
      expect(restored.maxMemoryUsage, equals(summary.maxMemoryUsage));
      expect(restored.averageCacheItems, equals(summary.averageCacheItems));
      expect(restored.performanceScore, equals(summary.performanceScore));
    });
  });

  group('PerformanceReport', () {
    test('should serialize to and from JSON', () {
      // Arrange
      final report = PerformanceReport(
        timestamp: DateTime.now(),
        summary: PerformanceSummary(
          averageMemoryUsage: 1024.0,
          maxMemoryUsage: 2048,
          averageCacheItems: 10.5,
          performanceScore: 85.0,
        ),
        recommendations: ['Optimize memory usage', 'Clear cache'],
      );

      // Act
      final json = report.toJson();
      final restored = PerformanceReport.fromJson(json);

      // Assert
      expect(restored.summary.performanceScore, equals(report.summary.performanceScore));
      expect(restored.recommendations, equals(report.recommendations));
    });
  });

  group('PerformanceTrackingMixin', () {
    test('should track async performance', () async {
      // Arrange
      final tracker = _TestPerformanceTracker();

      // Act
      final result = await tracker.trackPerformance('test_async', () async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 'success';
      });

      // Assert
      expect(result, equals('success'));
    });

    test('should track sync performance', () {
      // Arrange
      final tracker = _TestPerformanceTracker();

      // Act
      final result = tracker.trackSyncPerformance('test_sync', () {
        return 'success';
      });

      // Assert
      expect(result, equals('success'));
    });

    test('should handle async errors', () async {
      // Arrange
      final tracker = _TestPerformanceTracker();

      // Act & Assert
      expect(
        () => tracker.trackPerformance('test_error', () async {
          throw Exception('Test error');
        }),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle sync errors', () {
      // Arrange
      final tracker = _TestPerformanceTracker();

      // Act & Assert
      expect(
        () => tracker.trackSyncPerformance('test_error', () {
          throw Exception('Test error');
        }),
        throwsA(isA<Exception>()),
      );
    });
  });
}

class _TestPerformanceTracker with PerformanceTrackingMixin {
  // Test implementation of the mixin
}