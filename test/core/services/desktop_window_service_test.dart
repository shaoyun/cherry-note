import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/core/services/desktop_window_service.dart';

void main() {
  group('DesktopWindowService', () {
    late DesktopWindowService service;
    late List<MethodCall> methodCalls;

    setUp(() {
      service = DesktopWindowService();
      methodCalls = [];
      
      // Mock the method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('cherry_note/window'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          
          switch (methodCall.method) {
            case 'initialize':
              return null;
            case 'setTitle':
              return null;
            case 'setSize':
              return null;
            case 'setMinimumSize':
              return null;
            case 'setMaximumSize':
              return null;
            case 'center':
              return null;
            case 'maximize':
              return null;
            case 'minimize':
              return null;
            case 'restore':
              return null;
            case 'isMaximized':
              return false;
            case 'isMinimized':
              return false;
            case 'setPosition':
              return null;
            case 'getPosition':
              return {'x': 100.0, 'y': 100.0};
            case 'getSize':
              return {'width': 800.0, 'height': 600.0};
            case 'setResizable':
              return null;
            case 'setAlwaysOnTop':
              return null;
            case 'setFullscreen':
              return null;
            case 'isFullscreen':
              return false;
            case 'saveWindowState':
              return null;
            case 'restoreWindowState':
              return null;
            case 'setIcon':
              return null;
            case 'showInTaskbar':
              return null;
            case 'requestAttention':
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
        const MethodChannel('cherry_note/window'),
        null,
      );
    });

    test('initialize should call native method', () async {
      await service.initialize();
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('initialize'));
    });

    test('setTitle should call native method with correct parameter', () async {
      await service.setTitle('Test Title');
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('setTitle'));
      expect(methodCalls.first.arguments['title'], equals('Test Title'));
    });

    test('setSize should call native method with correct parameters', () async {
      await service.setSize(1024, 768);
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('setSize'));
      expect(methodCalls.first.arguments['width'], equals(1024.0));
      expect(methodCalls.first.arguments['height'], equals(768.0));
    });

    test('setMinimumSize should call native method', () async {
      await service.setMinimumSize(400, 300);
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('setMinimumSize'));
      expect(methodCalls.first.arguments['width'], equals(400.0));
      expect(methodCalls.first.arguments['height'], equals(300.0));
    });

    test('setMaximumSize should call native method', () async {
      await service.setMaximumSize(1920, 1080);
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('setMaximumSize'));
      expect(methodCalls.first.arguments['width'], equals(1920.0));
      expect(methodCalls.first.arguments['height'], equals(1080.0));
    });

    test('center should call native method', () async {
      await service.center();
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('center'));
    });

    test('maximize should call native method', () async {
      await service.maximize();
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('maximize'));
    });

    test('minimize should call native method', () async {
      await service.minimize();
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('minimize'));
    });

    test('restore should call native method', () async {
      await service.restore();
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('restore'));
    });

    test('isMaximized should call native method and return result', () async {
      final result = await service.isMaximized();
      
      expect(result, isFalse);
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('isMaximized'));
    });

    test('isMinimized should call native method and return result', () async {
      final result = await service.isMinimized();
      
      expect(result, isFalse);
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('isMinimized'));
    });

    test('setPosition should call native method with correct parameters', () async {
      await service.setPosition(200, 150);
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('setPosition'));
      expect(methodCalls.first.arguments['x'], equals(200.0));
      expect(methodCalls.first.arguments['y'], equals(150.0));
    });

    test('getPosition should call native method and return position', () async {
      final result = await service.getPosition();
      
      expect(result['x'], equals(100.0));
      expect(result['y'], equals(100.0));
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('getPosition'));
    });

    test('getSize should call native method and return size', () async {
      final result = await service.getSize();
      
      expect(result['width'], equals(800.0));
      expect(result['height'], equals(600.0));
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('getSize'));
    });

    test('setResizable should call native method', () async {
      await service.setResizable(false);
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('setResizable'));
      expect(methodCalls.first.arguments['resizable'], isFalse);
    });

    test('setAlwaysOnTop should call native method', () async {
      await service.setAlwaysOnTop(true);
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('setAlwaysOnTop'));
      expect(methodCalls.first.arguments['alwaysOnTop'], isTrue);
    });

    test('setFullscreen should call native method', () async {
      await service.setFullscreen(true);
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('setFullscreen'));
      expect(methodCalls.first.arguments['fullscreen'], isTrue);
    });

    test('isFullscreen should call native method and return result', () async {
      final result = await service.isFullscreen();
      
      expect(result, isFalse);
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('isFullscreen'));
    });

    test('saveWindowState should call multiple methods to get state', () async {
      await service.saveWindowState();
      
      // Should call getPosition, getSize, isMaximized, and saveWindowState
      expect(methodCalls.length, equals(4));
      expect(methodCalls.any((call) => call.method == 'getPosition'), isTrue);
      expect(methodCalls.any((call) => call.method == 'getSize'), isTrue);
      expect(methodCalls.any((call) => call.method == 'isMaximized'), isTrue);
      expect(methodCalls.any((call) => call.method == 'saveWindowState'), isTrue);
    });

    test('restoreWindowState should call native method', () async {
      await service.restoreWindowState();
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('restoreWindowState'));
    });

    test('setIcon should call native method', () async {
      await service.setIcon('/path/to/icon.ico');
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('setIcon'));
      expect(methodCalls.first.arguments['iconPath'], equals('/path/to/icon.ico'));
    });

    test('showInTaskbar should call native method', () async {
      await service.showInTaskbar(false);
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('showInTaskbar'));
      expect(methodCalls.first.arguments['show'], isFalse);
    });

    test('requestAttention should call native method', () async {
      await service.requestAttention();
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls.first.method, equals('requestAttention'));
    });

    test('should handle platform exceptions gracefully', () async {
      // Mock a platform exception
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('cherry_note/window'),
        (MethodCall methodCall) async {
          throw PlatformException(
            code: 'ERROR',
            message: 'Test error',
          );
        },
      );

      // Should not throw exception
      await expectLater(
        () => service.setTitle('Test'),
        returnsNormally,
      );
    });
  });
}