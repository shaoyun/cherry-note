import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cherry_note/core/services/android_background_sync_service.dart';
import 'package:cherry_note/features/sync/domain/services/sync_service.dart';
import 'package:cherry_note/features/sync/domain/entities/sync_operation.dart';
import 'package:cherry_note/core/di/injection.dart';

class MockSyncService extends Mock implements SyncService {}

void main() {
  group('AndroidBackgroundSyncService', () {
    late AndroidBackgroundSyncService service;
    late MockSyncService mockSyncService;
    late List<MethodCall> methodCalls;

    setUp(() {
      mockSyncService = MockSyncService();
      
      // Mock GetIt registration
      if (getIt.isRegistered<SyncService>()) {
        getIt.unregister<SyncService>();
      }
      getIt.registerSingleton<SyncService>(mockSyncService);
      
      service = AndroidBackgroundSyncService();
      methodCalls = [];
      
      // Mock the method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('cherry_note/background_sync'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          
          switch (methodCall.method) {
            case 'initialize':
              return null;
            case 'schedulePeriodicSync':
              return null;
            case 'cancelPeriodicSync':
              return null;
            case 'scheduleOneTimeSync':
              return null;
            case 'updateSyncNotification':
              return null;
            case 'showSyncNotification':
              return null;
            default:
              throw PlatformException(
                code: 'UNIMPLEMENTED',
                message: 'Method ${methodCall.method} not implemented',
              );
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('cherry_note/background_sync'),
        null,
      );
      
      if (getIt.isRegistered<SyncService>()) {
        getIt.unregister<SyncService>();
      }
    });

    test('initialize should call native method', () async {
      await service.initialize();
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('initialize'));
    });

    test('schedulePeriodicSync should call native method with correct parameters', () async {
      await service.schedulePeriodicSync(
        interval: const Duration(hours: 2),
        requiresCharging: true,
        requiresWifi: true,
      );
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('schedulePeriodicSync'));
      expect(methodCalls.first.arguments['intervalMinutes'], equals(120));
      expect(methodCalls.first.arguments['requiresCharging'], isTrue);
      expect(methodCalls.first.arguments['requiresWifi'], isTrue);
    });

    test('cancelPeriodicSync should call native method', () async {
      await service.cancelPeriodicSync();
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('cancelPeriodicSync'));
    });

    test('scheduleOneTimeSync should call native method with correct parameters', () async {
      await service.scheduleOneTimeSync(
        delay: const Duration(minutes: 30),
        requiresCharging: false,
        requiresWifi: true,
      );
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('scheduleOneTimeSync'));
      expect(methodCalls.first.arguments['delayMinutes'], equals(30));
      expect(methodCalls.first.arguments['requiresCharging'], isFalse);
      expect(methodCalls.first.arguments['requiresWifi'], isTrue);
    });

    test('should handle performBackgroundSync method call', () async {
      // Mock sync service response
      when(mockSyncService.fullSync()).thenAnswer((_) async => SyncResult(
        success: true,
        syncedFiles: ['file1.md', 'file2.md'],
        conflicts: [],
        error: null,
      ));

      // Simulate method call from native code
      final result = await service.handleMethodCall(
        const MethodCall('performBackgroundSync'),
      );
      
      expect(result, isTrue);
      verify(mockSyncService.fullSync()).called(1);
    });

    test('should handle sync progress updates', () async {
      await service.handleMethodCall(
        const MethodCall('onSyncProgress', {
          'progress': 0.5,
          'message': 'Syncing files...',
        }),
      );
      
      // Should update notification with progress
      expect(methodCalls.any((call) => call.method == 'updateSyncNotification'), isTrue);
    });

    test('should handle sync completion', () async {
      await service.handleMethodCall(
        const MethodCall('onSyncComplete', {
          'syncedFiles': 5,
        }),
      );
      
      // Should show completion notification
      expect(methodCalls.any((call) => call.method == 'showSyncNotification'), isTrue);
    });

    test('should handle sync errors', () async {
      await service.handleMethodCall(
        const MethodCall('onSyncError', {
          'error': 'Network error',
        }),
      );
      
      // Should show error notification
      expect(methodCalls.any((call) => call.method == 'showSyncNotification'), isTrue);
    });

    test('should handle platform exceptions gracefully', () async {
      // Mock a platform exception
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('cherry_note/background_sync'),
        (MethodCall methodCall) async {
          throw PlatformException(
            code: 'ERROR',
            message: 'Test error',
          );
        },
      );

      // Should not throw exception
      await expectLater(
        () => service.initialize(),
        returnsNormally,
      );
    });
  });
}