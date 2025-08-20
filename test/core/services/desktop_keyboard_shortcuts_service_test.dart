import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/core/services/desktop_keyboard_shortcuts_service.dart';

void main() {
  group('DesktopKeyboardShortcutsService', () {
    setUp(() {
      DesktopKeyboardShortcutsService.initialize();
    });

    test('should register and unregister shortcuts', () {
      bool callbackExecuted = false;
      
      DesktopKeyboardShortcutsService.registerShortcut(
        id: 'test_shortcut',
        keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyT),
        callback: () => callbackExecuted = true,
      );
      
      final shortcuts = DesktopKeyboardShortcutsService.getShortcuts();
      expect(shortcuts.length, greaterThan(0));
      
      DesktopKeyboardShortcutsService.unregisterShortcut('test_shortcut');
      
      final shortcutsAfterUnregister = DesktopKeyboardShortcutsService.getShortcuts();
      expect(shortcutsAfterUnregister.length, lessThan(shortcuts.length));
    });

    test('should get correct modifier key name for platform', () {
      final modifierKey = DesktopKeyboardShortcutsService.getModifierKeyName();
      expect(modifierKey, isA<String>());
      expect(modifierKey.isNotEmpty, isTrue);
    });

    test('should get shortcut display text', () {
      DesktopKeyboardShortcutsService.registerShortcut(
        id: 'test_display',
        keySet: LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS),
        callback: () {},
      );
      
      final displayText = DesktopKeyboardShortcutsService.getShortcutDisplayText('test_display');
      expect(displayText, isA<String>());
      expect(displayText.isNotEmpty, isTrue);
    });

    testWidgets('should create shortcuts wrapper widget', (tester) async {
      final testWidget = Container(child: const Text('Test'));
      
      final wrappedWidget = DesktopKeyboardShortcutsService.createShortcutsWrapper(
        child: testWidget,
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: wrappedWidget,
          ),
        ),
      );
      
      expect(find.byType(Shortcuts), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should handle additional shortcuts in wrapper', (tester) async {
      bool additionalShortcutExecuted = false;
      
      final testWidget = Container(child: const Text('Test'));
      
      final wrappedWidget = DesktopKeyboardShortcutsService.createShortcutsWrapper(
        child: testWidget,
        additionalShortcuts: {
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyX): 
              () => additionalShortcutExecuted = true,
        },
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: wrappedWidget,
          ),
        ),
      );
      
      expect(find.byType(Shortcuts), findsOneWidget);
    });

    test('should initialize default shortcuts', () {
      final shortcuts = DesktopKeyboardShortcutsService.getShortcuts();
      expect(shortcuts.isNotEmpty, isTrue);
      
      // Check that some default shortcuts are registered
      final shortcutKeys = shortcuts.keys.toList();
      expect(shortcutKeys.any((keySet) => 
        keySet.keys.contains(LogicalKeyboardKey.keyN)), isTrue);
    });
  });
}