import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cherry_note/features/main/presentation/widgets/app_toolbar.dart';

void main() {
  group('AppToolbar', () {
    testWidgets('should display toolbar buttons', (tester) async {
      // Arrange
      bool newNotePressed = false;
      bool savePressed = false;
      bool syncPressed = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppToolbar(
              onNewNote: () => newNotePressed = true,
              onSave: () => savePressed = true,
              onSync: () => syncPressed = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.note_add), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
      expect(find.byIcon(Icons.cloud_sync), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('should handle button callbacks', (tester) async {
      // Arrange
      bool newNotePressed = false;
      bool savePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppToolbar(
              onNewNote: () => newNotePressed = true,
              onSave: () => savePressed = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.note_add));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.save));
      await tester.pumpAndSettle();

      // Assert
      expect(newNotePressed, isTrue);
      expect(savePressed, isTrue);
    });

    testWidgets('should show sync progress when syncing', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppToolbar(
              isSyncing: true,
              onSync: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should highlight save button when has unsaved changes', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppToolbar(
              hasUnsavedChanges: true,
              onSave: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.save), findsOneWidget);
      
      // Find the save button and check if it's highlighted
      final saveButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.save),
          matching: find.byType(IconButton),
        ),
      );
      
      // The button should be enabled when there are unsaved changes
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets('should toggle sidebar and preview buttons', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppToolbar(
              showSidebar: true,
              showPreview: false,
              onToggleSidebar: () {},
              onTogglePreview: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.menu_open), findsOneWidget); // Sidebar shown
      expect(find.byIcon(Icons.visibility_off), findsOneWidget); // Preview hidden
    });
  });

  group('CompactAppToolbar', () {
    testWidgets('should display compact toolbar', (tester) async {
      // Arrange
      bool newNotePressed = false;
      bool syncPressed = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: CompactAppToolbar(
              onNewNote: () => newNotePressed = true,
              onSync: () => syncPressed = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Cherry Note'), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.cloud_sync), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should handle compact toolbar callbacks', (tester) async {
      // Arrange
      bool newNotePressed = false;
      bool syncPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: CompactAppToolbar(
              onNewNote: () => newNotePressed = true,
              onSync: () => syncPressed = true,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.cloud_sync));
      await tester.pumpAndSettle();

      // Assert
      expect(newNotePressed, isTrue);
      expect(syncPressed, isTrue);
    });

    testWidgets('should show sync progress in compact mode', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: CompactAppToolbar(
              isSyncing: true,
              onSync: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}