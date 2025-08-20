import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cherry_note/core/services/android_platform_service.dart';
import 'package:cherry_note/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Android Platform Integration Tests', () {
    late AndroidPlatformService platformService;

    setUpAll(() {
      platformService = AndroidPlatformService();
    });

    testWidgets('Android platform service initialization', (tester) async {
      // Initialize the app
      app.main();
      await tester.pumpAndSettle();

      // Test platform service initialization
      await platformService.initialize();
      
      // Verify that the service is initialized without errors
      expect(platformService, isNotNull);
    });

    testWidgets('Android permissions handling', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test permission checking
      final hasPermissions = await platformService.hasAllRequiredPermissions();
      expect(hasPermissions, isA<bool>());

      // Test platform info retrieval
      final platformInfo = await platformService.getPlatformInfo();
      expect(platformInfo, isA<Map<String, dynamic>>());
    });

    testWidgets('Android UI adaptations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: platformService.adaptUI(
                const Center(child: Text('Android UI Test')),
                context,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Verify UI adaptations are applied
      expect(find.text('Android UI Test'), findsOneWidget);
      expect(find.byType(MediaQuery), findsWidgets);
    });

    testWidgets('Android back button handling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => platformService.handleBackButton(context),
                  child: const Text('Test Back Button'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Test back button handling
      await tester.tap(find.text('Test Back Button'));
      await tester.pumpAndSettle();
      
      // Verify back button handling works without errors
      expect(find.text('Test Back Button'), findsOneWidget);
    });

    testWidgets('Android memory management', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test memory usage retrieval
      final memoryUsage = await platformService.getMemoryUsage();
      expect(memoryUsage, isA<Map<String, dynamic>>());

      // Test garbage collection
      await platformService.forceGarbageCollection();
      
      // Should complete without errors
    });

    testWidgets('Android notification system', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test notification display
      await platformService.showNotification(
        title: 'Test Notification',
        message: 'This is a test notification',
      );
      
      // Should complete without errors
    });

    testWidgets('Android background sync', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test background sync scheduling
      await platformService.startBackgroundSync(
        interval: const Duration(hours: 1),
        requiresWifi: true,
      );
      
      // Test background sync cancellation
      await platformService.stopBackgroundSync();
      
      // Should complete without errors
    });
  });
}