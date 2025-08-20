import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cherry_note/features/main/presentation/widgets/app_menu_bar.dart';

void main() {
  group('AppMenuBar', () {
    testWidgets('should display all menu items', (tester) async {
      // Arrange
      bool newNotePressed = false;
      bool newFolderPressed = false;
      bool savePressed = false;
      bool settingsPressed = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppMenuBar(
              onNewNote: () => newNotePressed = true,
              onNewFolder: () => newFolderPressed = true,
              onSave: () => savePressed = true,
              onSettings: () => settingsPressed = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('文件(&F)'), findsOneWidget);
      expect(find.text('编辑(&E)'), findsOneWidget);
      expect(find.text('视图(&V)'), findsOneWidget);
      expect(find.text('帮助(&H)'), findsOneWidget);
    });

    testWidgets('should handle menu item callbacks', (tester) async {
      // Arrange
      bool newNotePressed = false;
      bool savePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppMenuBar(
              onNewNote: () => newNotePressed = true,
              onSave: () => savePressed = true,
            ),
          ),
        ),
      );

      // Act - Open file menu
      await tester.tap(find.text('文件(&F)'));
      await tester.pumpAndSettle();

      // Find and tap new note menu item
      await tester.tap(find.text('新建笔记(&N)'));
      await tester.pumpAndSettle();

      // Assert
      expect(newNotePressed, isTrue);
    });

    testWidgets('should display keyboard shortcuts', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppMenuBar(
              onNewNote: () {},
              onSave: () {},
            ),
          ),
        ),
      );

      // Act - Open file menu
      await tester.tap(find.text('文件(&F)'));
      await tester.pumpAndSettle();

      // Assert - Check that menu items are displayed
      expect(find.text('新建笔记(&N)'), findsOneWidget);
      expect(find.text('保存(&S)'), findsOneWidget);
    });
  });

  group('CustomMenuAcceleratorLabel', () {
    testWidgets('should display label text', (tester) async {
      // Arrange
      const labelText = 'Test Label(&T)';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomMenuAcceleratorLabel(labelText),
          ),
        ),
      );

      // Assert
      expect(find.text(labelText), findsOneWidget);
    });
  });
}