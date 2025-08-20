import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:cherry_note/core/services/desktop_platform_service.dart';
import 'package:cherry_note/core/services/desktop_keyboard_shortcuts_service.dart';
import 'package:cherry_note/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Desktop Platform Integration Tests', () {
    late DesktopPlatformService platformService;

    setUpAll(() {
      platformService = DesktopPlatformService();
    });

    testWidgets('Desktop platform service initialization', (tester) async {
      // Initialize the app
      app.main();
      await tester.pumpAndSettle();

      // Test platform service initialization
      await platformService.initialize();
      
      // Verify that the service is initialized without errors
      expect(platformService, isNotNull);
    });

    testWidgets('Desktop keyboard shortcuts', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Initialize keyboard shortcuts
      DesktopKeyboardShortcutsService.initialize();
      
      // Test that shortcuts are registered
      final shortcuts = DesktopKeyboardShortcutsService.getShortcuts();
      expect(shortcuts.isNotEmpty, isTrue);
      
      // Test modifier key name
      final modifierKey = DesktopKeyboardShortcutsService.getModifierKeyName();
      expect(modifierKey, isA<String>());
      expect(modifierKey.isNotEmpty, isTrue);
    });

    testWidgets('Desktop UI adaptations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: platformService.createDesktopUI(
                child: const Center(child: Text('Desktop UI Test')),
                context: context,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Verify UI adaptations are applied
      expect(find.text('Desktop UI Test'), findsOneWidget);
      expect(find.byType(MediaQuery), findsWidgets);
    });

    testWidgets('Desktop app bar creation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: platformService.createDesktopAppBar(
              title: 'Desktop Test App',
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {},
                ),
              ],
            ),
            body: const Center(child: Text('Desktop App Bar Test')),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Verify app bar is created correctly
      expect(find.text('Desktop Test App'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('Desktop window management', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test window title setting
      await platformService.setWindowTitle('Test Window Title');
      
      // Test window centering
      await platformService.centerWindow();
      
      // Test window state saving
      await platformService.saveWindowState();
      
      // Should complete without errors
    });

    testWidgets('Desktop file dialogs', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test system directories retrieval
      final systemDirs = await platformService.getSystemDirectories();
      expect(systemDirs, isA<Map<String, String?>>());
      expect(systemDirs.containsKey('documents'), isTrue);
      expect(systemDirs.containsKey('downloads'), isTrue);
    });

    testWidgets('Desktop platform information', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test platform info retrieval
      final platformInfo = await platformService.getPlatformInfo();
      expect(platformInfo, isA<Map<String, dynamic>>());
    });

    testWidgets('Desktop application exit handling', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test application exit handling
      final shouldExit = await platformService.handleApplicationExit();
      expect(shouldExit, isA<bool>());
    });

    testWidgets('Desktop shortcuts wrapper', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DesktopKeyboardShortcutsService.createShortcutsWrapper(
            child: const Scaffold(
              body: Center(child: Text('Shortcuts Test')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Verify shortcuts wrapper is applied
      expect(find.text('Shortcuts Test'), findsOneWidget);
      expect(find.byType(Shortcuts), findsOneWidget);
    });
  });
}