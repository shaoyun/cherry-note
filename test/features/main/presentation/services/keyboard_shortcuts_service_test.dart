import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cherry_note/features/main/presentation/services/keyboard_shortcuts_service.dart';

void main() {
  group('KeyboardShortcutsService', () {
    late KeyboardShortcutsService service;

    setUp(() {
      service = KeyboardShortcutsService();
    });

    tearDown(() {
      service.clearShortcuts();
    });

    test('should register and unregister shortcuts', () {
      // Arrange
      final keySet = LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN);
      bool callbackCalled = false;
      void callback() => callbackCalled = true;

      // Act
      service.registerShortcut(keySet, callback);

      // Assert
      expect(service.shortcuts.containsKey(keySet), isTrue);
      expect(service.shortcuts[keySet], equals(callback));

      // Act - Unregister
      service.unregisterShortcut(keySet);

      // Assert
      expect(service.shortcuts.containsKey(keySet), isFalse);
    });

    test('should clear all shortcuts', () {
      // Arrange
      final keySet1 = LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN);
      final keySet2 = LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS);
      
      service.registerShortcut(keySet1, () {});
      service.registerShortcut(keySet2, () {});

      // Act
      service.clearShortcuts();

      // Assert
      expect(service.shortcuts.isEmpty, isTrue);
    });

    test('should register default shortcuts', () {
      // Arrange
      bool newNoteCalled = false;
      bool saveCalled = false;

      // Act
      service.registerDefaultShortcuts(
        onNewNote: () => newNoteCalled = true,
        onSave: () => saveCalled = true,
      );

      // Assert
      expect(service.shortcuts.isNotEmpty, isTrue);
      
      // Check that Ctrl+N shortcut exists
      final newNoteKeySet = LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN);
      expect(service.shortcuts.containsKey(newNoteKeySet), isTrue);
      
      // Check that Ctrl+S shortcut exists
      final saveKeySet = LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS);
      expect(service.shortcuts.containsKey(saveKeySet), isTrue);
    });

    group('getShortcutDescription', () {
      test('should return correct description for single key', () {
        // Arrange
        final keySet = LogicalKeySet(LogicalKeyboardKey.f11);

        // Act
        final description = KeyboardShortcutsService.getShortcutDescription(keySet);

        // Assert
        expect(description, equals('F11'));
      });

      test('should return correct description for key combination', () {
        // Arrange
        final keySet = LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN);

        // Act
        final description = KeyboardShortcutsService.getShortcutDescription(keySet);

        // Assert
        expect(description, equals('Ctrl+N'));
      });

      test('should return correct description for complex combination', () {
        // Arrange
        final keySet = LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyP,
        );

        // Act
        final description = KeyboardShortcutsService.getShortcutDescription(keySet);

        // Assert
        expect(description, equals('Ctrl+Shift+P'));
      });
    });
  });

  group('ShortcutsWrapper', () {
    testWidgets('should handle keyboard shortcuts', (tester) async {
      // Arrange
      final shortcuts = {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): 
            () {},
      };

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ShortcutsWrapper(
            shortcuts: shortcuts,
            child: const Scaffold(
              body: Text('Test'),
            ),
          ),
        ),
      );

      // Assert - Just verify the widget is built correctly
      expect(find.text('Test'), findsOneWidget);
      expect(find.byType(ShortcutsWrapper), findsOneWidget);
    });

    testWidgets('should display child widget', (tester) async {
      // Arrange
      const testText = 'Test Content';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ShortcutsWrapper(
            child: const Scaffold(
              body: Text(testText),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(testText), findsOneWidget);
    });
  });
}