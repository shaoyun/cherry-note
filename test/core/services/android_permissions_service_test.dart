import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/core/services/android_permissions_service.dart';

void main() {
  group('AndroidPermissionsService', () {
    late AndroidPermissionsService service;
    late List<MethodCall> methodCalls;

    setUp(() {
      service = AndroidPermissionsService();
      methodCalls = [];
      
      // Mock the method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('cherry_note/permissions'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          
          switch (methodCall.method) {
            case 'hasStoragePermissions':
              return true;
            case 'requestStoragePermissions':
              return true;
            case 'hasNotificationPermissions':
              return true;
            case 'requestNotificationPermissions':
              return true;
            case 'canRunInBackground':
              return true;
            case 'requestDisableBatteryOptimization':
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
        const MethodChannel('cherry_note/permissions'),
        null,
      );
    });

    test('hasStoragePermissions should call native method', () async {
      final result = await service.hasStoragePermissions();
      
      expect(result, isTrue);
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('hasStoragePermissions'));
    });

    test('requestStoragePermissions should call native method', () async {
      final result = await service.requestStoragePermissions();
      
      expect(result, isTrue);
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('requestStoragePermissions'));
    });

    test('hasNotificationPermissions should call native method', () async {
      final result = await service.hasNotificationPermissions();
      
      expect(result, isTrue);
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('hasNotificationPermissions'));
    });

    test('requestNotificationPermissions should call native method', () async {
      final result = await service.requestNotificationPermissions();
      
      expect(result, isTrue);
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('requestNotificationPermissions'));
    });

    test('canRunInBackground should call native method', () async {
      final result = await service.canRunInBackground();
      
      expect(result, isTrue);
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('canRunInBackground'));
    });

    test('requestDisableBatteryOptimization should call native method', () async {
      await service.requestDisableBatteryOptimization();
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('requestDisableBatteryOptimization'));
    });

    test('should handle platform exceptions gracefully', () async {
      // Mock a platform exception
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('cherry_note/permissions'),
        (MethodCall methodCall) async {
          throw PlatformException(
            code: 'ERROR',
            message: 'Test error',
          );
        },
      );

      final result = await service.hasStoragePermissions();
      expect(result, isFalse);
    });
  });
}