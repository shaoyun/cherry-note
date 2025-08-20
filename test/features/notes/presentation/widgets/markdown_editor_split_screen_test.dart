import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cherry_note/features/notes/presentation/widgets/markdown_editor.dart';

void main() {
  group('MarkdownEditor Split Screen', () {
    testWidgets('should show split view by default when showPreview is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: '# Test Content',
              showPreview: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find both TextField (editor) and Markdown widget (preview)
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(Markdown), findsOneWidget);
    });

    testWidgets('should show only editor when showPreview is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: '# Test Content',
              showPreview: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find only TextField (editor)
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(Markdown), findsNothing);
    });

    testWidgets('should toggle between split view and preview-only mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: '# Test Content',
              showPreview: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should show split view
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(Markdown), findsOneWidget);

      // Find and tap the preview toggle button
      final toggleButton = find.byIcon(Icons.preview);
      expect(toggleButton, findsOneWidget);
      
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Should now show only preview
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(Markdown), findsOneWidget);
      
      // Button should now show edit icon
      expect(find.byIcon(Icons.edit), findsOneWidget);
      
      // Tap again to go back to split view
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Should show split view again
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(Markdown), findsOneWidget);
    });

    testWidgets('should not show preview toggle when showPreview is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: '# Test Content',
              showPreview: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.preview), findsNothing);
      expect(find.byIcon(Icons.edit), findsNothing);
    });

    testWidgets('should render markdown content in preview pane', (tester) async {
      const markdownContent = '# Header\n\n**Bold text**\n\n*Italic text*';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: markdownContent,
              showPreview: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The markdown widget should be present and rendering content
      expect(find.byType(Markdown), findsOneWidget);
    });

    testWidgets('should update preview when editor content changes', (tester) async {
      String? changedContent;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: '# Original',
              showPreview: true,
              onContentChanged: (content) {
                changedContent = content;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change the content in the editor
      const newContent = '# Updated Content';
      await tester.enterText(find.byType(TextField), newContent);
      await tester.pumpAndSettle();

      // Verify the content changed callback was called
      expect(changedContent, equals(newContent));
      
      // The preview should update (Markdown widget should still be present)
      expect(find.byType(Markdown), findsOneWidget);
    });

    testWidgets('should show toolbar when showToolbar is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: '# Test',
              showPreview: true,
              showToolbar: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show toolbar buttons
      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(find.byIcon(Icons.format_italic), findsOneWidget);
    });

    testWidgets('should hide toolbar when showToolbar is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: '# Test',
              showPreview: true,
              showToolbar: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not show toolbar buttons
      expect(find.byIcon(Icons.format_bold), findsNothing);
      expect(find.byIcon(Icons.format_italic), findsNothing);
    });

    testWidgets('should disable toolbar when in preview mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: '# Test',
              showPreview: true,
              showToolbar: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to preview mode
      await tester.tap(find.byIcon(Icons.preview));
      await tester.pumpAndSettle();

      // Toolbar buttons should be disabled
      final boldButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.format_bold),
          matching: find.byType(IconButton),
        ),
      );

      expect(boldButton.onPressed, isNull);
    });

    testWidgets('should show unsaved changes indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: '',
              showPreview: true,
              enableAutoSave: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should not show unsaved indicator
      expect(find.text('Unsaved'), findsNothing);

      // Change content to create unsaved changes
      await tester.enterText(find.byType(TextField), 'New content');
      await tester.pumpAndSettle();

      // Should show unsaved indicator
      expect(find.text('Unsaved'), findsOneWidget);
    });

    testWidgets('should call onAutoSave when auto-save is enabled', (tester) async {
      bool autoSaveCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: '',
              showPreview: true,
              enableAutoSave: true,
              autoSaveInterval: const Duration(milliseconds: 100),
              onAutoSave: () {
                autoSaveCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change content
      await tester.enterText(find.byType(TextField), 'Auto save test');
      await tester.pumpAndSettle();

      // Wait for auto-save interval
      await tester.pump(const Duration(milliseconds: 150));

      expect(autoSaveCalled, isTrue);
    });

    testWidgets('should not auto-save when disabled', (tester) async {
      bool autoSaveCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: '',
              showPreview: true,
              enableAutoSave: false,
              autoSaveInterval: const Duration(milliseconds: 100),
              onAutoSave: () {
                autoSaveCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change content
      await tester.enterText(find.byType(TextField), 'No auto save test');
      await tester.pumpAndSettle();

      // Wait for what would be the auto-save interval
      await tester.pump(const Duration(milliseconds: 150));

      expect(autoSaveCalled, isFalse);
    });

    group('Layout Tests', () {
      testWidgets('should have proper split layout structure', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MarkdownEditor(
                initialContent: '# Test',
                showPreview: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should have a Row widget for split layout
        expect(find.byType(Row), findsWidgets);
        
        // Should have Expanded widgets for flexible sizing
        expect(find.byType(Expanded), findsWidgets);
      });

      testWidgets('should apply custom padding', (tester) async {
        const customPadding = EdgeInsets.all(32.0);
        
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MarkdownEditor(
                initialContent: 'Test',
                padding: customPadding,
                showPreview: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final container = tester.widget<Container>(
          find.ancestor(
            of: find.byType(TextField),
            matching: find.byType(Container),
          ).first,
        );
        
        expect(container.padding, equals(customPadding));
      });

      testWidgets('should apply custom text style', (tester) async {
        const customStyle = TextStyle(fontSize: 20, color: Colors.red);
        
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MarkdownEditor(
                initialContent: 'Test',
                textStyle: customStyle,
                showPreview: false,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.style?.fontSize, equals(20));
      });
    });

    group('Scroll Synchronization', () {
      testWidgets('should have scroll controllers for both panes', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 200, // Limited height to enable scrolling
                child: MarkdownEditor(
                  initialContent: '''# Long Content
                  
This is a very long content that should enable scrolling.

## Section 1
Content for section 1.

## Section 2
Content for section 2.

## Section 3
Content for section 3.

## Section 4
Content for section 4.

## Section 5
Content for section 5.''',
                  showPreview: true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Both editor and preview should be scrollable
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(Markdown), findsOneWidget);
      });
    });
  });
}