import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cherry_note/main.dart' as app;
import 'package:cherry_note/core/services/web_platform_service.dart';
import 'package:cherry_note/core/ui/web_ui_adaptations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Web Platform Integration Tests', () {
    testWidgets('should initialize app successfully on web', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify app loads without errors
      expect(find.byType(app.MyApp), findsOneWidget);
    });

    testWidgets('should handle responsive layout correctly', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test different screen sizes if on web
      if (kIsWeb) {
        // Test mobile layout
        await tester.binding.setSurfaceSize(const Size(400, 800));
        await tester.pumpAndSettle();
        
        // Verify mobile adaptations are applied
        // This would depend on your specific UI implementation
        
        // Test tablet layout
        await tester.binding.setSurfaceSize(const Size(800, 1024));
        await tester.pumpAndSettle();
        
        // Test desktop layout
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should handle web-specific features', (tester) async {
      if (!kIsWeb) return;

      app.main();
      await tester.pumpAndSettle();

      // Test web platform service functionality
      expect(WebPlatformService.isWeb, isTrue);
      expect(WebPlatformService.supportsRequiredFeatures, isTrue);
      
      // Test browser info
      final browserInfo = WebPlatformService.browserInfo;
      expect(browserInfo, isNotEmpty);
      expect(browserInfo, isNot(equals('Not Web')));
    });

    testWidgets('should handle file operations on web', (tester) async {
      if (!kIsWeb) return;

      app.main();
      await tester.pumpAndSettle();

      // Test that file service is available
      // Note: Actual file picking requires user interaction
      // so we can only test the service availability
      expect(() => WebPlatformService.downloadFile(
        'test.txt',
        [72, 101, 108, 108, 111], // "Hello"
        'text/plain',
      ), returnsNormally);
    });

    testWidgets('should handle PWA features', (tester) async {
      if (!kIsWeb) return;

      app.main();
      await tester.pumpAndSettle();

      // Test PWA detection
      expect(() => WebPlatformService.isRunningAsPWA, returnsNormally);
      expect(() => WebPlatformService.supportsPWAInstall, returnsNormally);
    });

    testWidgets('should handle online/offline status', (tester) async {
      if (!kIsWeb) return;

      app.main();
      await tester.pumpAndSettle();

      // Test online status
      expect(WebPlatformService.isOnline, isA<bool>());
      
      // Test online status stream
      final stream = WebPlatformService.onlineStatusStream;
      expect(stream, isA<Stream<bool>>());
    });

    testWidgets('should apply web UI adaptations', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(app.MyApp));
      
      // Test layout type detection
      final layoutType = WebUIAdaptations.getLayoutType(context);
      expect(layoutType, isA<LayoutType>());
      
      // Test responsive padding
      final padding = WebUIAdaptations.getResponsivePadding(context);
      expect(padding, isA<EdgeInsets>());
      
      // Test responsive font size
      final fontSize = WebUIAdaptations.getResponsiveFontSize(context, 16.0);
      expect(fontSize, greaterThan(0));
      
      // Test responsive column count
      final columnCount = WebUIAdaptations.getResponsiveColumnCount(context);
      expect(columnCount, greaterThan(0));
      expect(columnCount, lessThanOrEqualTo(3));
    });

    testWidgets('should handle web scroll behavior', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test web scroll behavior
      final scrollBehavior = WebUIAdaptations.getWebScrollBehavior();
      expect(scrollBehavior, isA<ScrollBehavior>());
    });

    testWidgets('should create responsive widgets', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(app.MyApp));
      
      // Test responsive dialog constraints
      final constraints = WebUIAdaptations.getResponsiveDialogConstraints(context);
      expect(constraints.maxWidth, greaterThan(0));
      expect(constraints.maxHeight, greaterThan(0));
      
      // Test responsive button size
      final buttonSize = WebUIAdaptations.getResponsiveButtonSize(context);
      expect(buttonSize.width, greaterThan(0));
      expect(buttonSize.height, greaterThan(0));
    });
  });
}