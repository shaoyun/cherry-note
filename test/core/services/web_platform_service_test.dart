import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import '../../../lib/core/services/web_platform_service.dart';

void main() {
  group('WebPlatformService', () {
    test('should detect web environment correctly', () {
      // This test will pass differently in web vs non-web environments
      expect(WebPlatformService.isWeb, equals(kIsWeb));
    });

    test('should return appropriate browser info', () {
      final browserInfo = WebPlatformService.browserInfo;
      
      if (kIsWeb) {
        expect(browserInfo, isNotEmpty);
        expect(browserInfo, isNot(equals('Not Web')));
      } else {
        expect(browserInfo, equals('Not Web'));
      }
    });

    test('should handle title updates safely', () {
      // Should not throw even in non-web environment
      expect(() => WebPlatformService.updateTitle('Test Title'), returnsNormally);
    });

    test('should handle device type detection', () {
      // These should not throw in any environment
      expect(() => WebPlatformService.isMobileDevice, returnsNormally);
      expect(() => WebPlatformService.isTabletDevice, returnsNormally);
      expect(() => WebPlatformService.isDesktopDevice, returnsNormally);
    });

    test('should return valid device pixel ratio', () {
      final ratio = WebPlatformService.devicePixelRatio;
      expect(ratio, greaterThan(0));
      expect(ratio, lessThanOrEqualTo(4.0)); // Reasonable upper bound
    });

    test('should handle PWA detection safely', () {
      expect(() => WebPlatformService.supportsPWAInstall, returnsNormally);
      expect(() => WebPlatformService.isRunningAsPWA, returnsNormally);
    });

    test('should return valid preferred language', () {
      final language = WebPlatformService.preferredLanguage;
      expect(language, isNotEmpty);
      expect(language.length, greaterThanOrEqualTo(2));
    });

    test('should handle online status safely', () {
      expect(() => WebPlatformService.isOnline, returnsNormally);
      expect(WebPlatformService.isOnline, isA<bool>());
    });

    test('should provide online status stream', () {
      final stream = WebPlatformService.onlineStatusStream;
      expect(stream, isA<Stream<bool>>());
    });

    group('File download', () {
      test('should handle download safely in non-web environment', () {
        expect(() => WebPlatformService.downloadFile(
          'test.txt',
          [1, 2, 3],
          'text/plain',
        ), returnsNormally);
      });
    });

    group('Notifications', () {
      test('should handle notification request safely', () async {
        await expectLater(
          WebPlatformService.showNotification('Test', 'Body'),
          completes,
        );
      });
    });

    group('PWA Install', () {
      test('should handle PWA install prompt safely', () async {
        final result = await WebPlatformService.promptPWAInstall();
        expect(result, isA<bool>());
      });
    });
  });
}