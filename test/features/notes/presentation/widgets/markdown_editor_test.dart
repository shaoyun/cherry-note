import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cherry_note/features/notes/presentation/widgets/markdown_editor.dart';

void main() {
  group('MarkdownEditor', () {
    testWidgets('should display initial content', (tester) async {
      const initialContent = '# Hello World\n\nThis is a test.';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: initialContent,
            ),
          ),
        ),
      );

      expect(find.text(initialContent), findsOneWidget);
    });

    testWidgets('should call onContentChanged when text changes', (tester) async {
      String? changedContent;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: '',
              onContentChanged: (content) {
                changedContent = content;
              },
            ),
          ),
        ),
      );

      const newText = 'New content';
      await tester.enterText(find.byType(TextField), newText);
      
      expect(changedContent, equals(newText));
    });

    testWidgets('should show split view by default when showPreview is true', (tester) async {
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

      // Should find both TextField (editor) and Markdown widget (preview)
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(Markdown), findsOneWidget);
    });

    testWidgets('should show only editor when showPreview is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: '# Test',
              showPreview: false,
            ),
          ),
        ),
      );

      // Should find only TextField (editor)
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(Markdown), findsNothing);
    });

    testWidgets('should toggle between edit and preview modes', (tester) async {
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

      // Initially should show split view
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(Markdown), findsOneWidget);

      // Find and tap the preview/edit toggle button
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

    testWidgets('should display character count', (tester) async {
      const content = 'Hello World';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: content,
            ),
          ),
        ),
      );

      expect(find.text('${content.length} characters'), findsOneWidget);
    });

    testWidgets('should update character count when content changes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: '',
            ),
          ),
        ),
      );

      // Initially should show 0 characters
      expect(find.text('0 characters'), findsOneWidget);

      const newText = 'Hello';
      await tester.enterText(find.byType(TextField), newText);
      await tester.pumpAndSettle();

      expect(find.text('${newText.length} characters'), findsOneWidget);
    });

    testWidgets('should render markdown in preview', (tester) async {
      const markdownContent = '# Header\n\n**Bold text**\n\n*Italic text*';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: markdownContent,
              showPreview: true,
            ),
          ),
        ),
      );

      // The markdown widget should be present
      expect(find.byType(Markdown), findsOneWidget);
    });

    testWidgets('should show placeholder when preview is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: '',
              showPreview: true,
            ),
          ),
        ),
      );

      // Should show the empty preview message (rendered as italic by markdown)
      expect(find.textContaining('No content to preview'), findsOneWidget);
    });

    testWidgets('should apply custom text style', (tester) async {
      const customStyle = TextStyle(fontSize: 20, color: Colors.red);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: 'Test',
              textStyle: customStyle,
              showPreview: false,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.style?.fontSize, equals(20));
    });

    testWidgets('should apply custom padding', (tester) async {
      const customPadding = EdgeInsets.all(32.0);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownEditor(
              initialContent: 'Test',
              padding: customPadding,
              showPreview: false,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(TextField),
          matching: find.byType(Container),
        ).first,
      );
      
      expect(container.padding, equals(customPadding));
    });

    group('Toolbar', () {
      testWidgets('should show toolbar with correct elements', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MarkdownEditor(
                initialContent: 'Test content',
                showPreview: true,
              ),
            ),
          ),
        );

        // Should show title
        expect(find.text('Markdown Editor'), findsOneWidget);
        
        // Should show character count
        expect(find.text('12 characters'), findsOneWidget);
        
        // Should show preview toggle button
        expect(find.byIcon(Icons.preview), findsOneWidget);
      });

      testWidgets('should not show preview toggle when showPreview is false', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: MarkdownEditor(
                initialContent: 'Test',
                showPreview: false,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.preview), findsNothing);
        expect(find.byIcon(Icons.edit), findsNothing);
      });
    });
  });
}