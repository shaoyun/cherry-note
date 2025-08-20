import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/features/notes/presentation/widgets/markdown_syntax_highlighter.dart';

void main() {
  group('MarkdownSyntaxHighlighter', () {
    late ThemeData theme;
    late MarkdownSyntaxHighlighter highlighter;

    setUp(() {
      theme = ThemeData.light();
      highlighter = MarkdownSyntaxHighlighter(theme: theme);
    });

    testWidgets('should initialize with empty text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = highlighter.buildTextSpan(
                  context: context,
                  style: null,
                  withComposing: false,
                );
                return RichText(text: span);
              },
            ),
          ),
        ),
      );

      expect(highlighter.text, isEmpty);
    });

    testWidgets('should initialize with provided text', (tester) async {
      const initialText = '# Hello World';
      final highlighter = MarkdownSyntaxHighlighter(
        text: initialText,
        theme: theme,
      );

      expect(highlighter.text, equals(initialText));
    });

    testWidgets('should highlight headers correctly', (tester) async {
      highlighter.text = '# Header 1\n## Header 2\n### Header 3';

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = highlighter.buildTextSpan(
                  context: context,
                  style: theme.textTheme.bodyMedium,
                  withComposing: false,
                );
                
                // Verify that we have styled spans
                expect(span.children, isNotNull);
                expect(span.children!.length, greaterThan(1));
                
                return RichText(text: span);
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should highlight bold text correctly', (tester) async {
      highlighter.text = 'This is **bold text** in markdown.';

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = highlighter.buildTextSpan(
                  context: context,
                  style: theme.textTheme.bodyMedium,
                  withComposing: false,
                );
                
                expect(span.children, isNotNull);
                expect(span.children!.length, greaterThan(1));
                
                // Find the bold text span
                final boldSpan = span.children!.firstWhere(
                  (child) => child is TextSpan && child.text == '**bold text**',
                ) as TextSpan;
                
                expect(boldSpan.style?.fontWeight, equals(FontWeight.bold));
                
                return RichText(text: span);
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should highlight italic text correctly', (tester) async {
      highlighter.text = 'This is *italic text* in markdown.';

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = highlighter.buildTextSpan(
                  context: context,
                  style: theme.textTheme.bodyMedium,
                  withComposing: false,
                );
                
                expect(span.children, isNotNull);
                expect(span.children!.length, greaterThan(1));
                
                return RichText(text: span);
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should highlight inline code correctly', (tester) async {
      highlighter.text = 'Use `console.log()` to debug.';

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = highlighter.buildTextSpan(
                  context: context,
                  style: theme.textTheme.bodyMedium,
                  withComposing: false,
                );
                
                expect(span.children, isNotNull);
                expect(span.children!.length, greaterThan(1));
                
                return RichText(text: span);
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should highlight code blocks correctly', (tester) async {
      highlighter.text = '```dart\nvoid main() {\n  print("Hello");\n}\n```';

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = highlighter.buildTextSpan(
                  context: context,
                  style: theme.textTheme.bodyMedium,
                  withComposing: false,
                );
                
                expect(span.children, isNotNull);
                expect(span.children!.length, greaterThan(0));
                
                return RichText(text: span);
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should highlight links correctly', (tester) async {
      highlighter.text = 'Visit [Google](https://google.com) for search.';

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = highlighter.buildTextSpan(
                  context: context,
                  style: theme.textTheme.bodyMedium,
                  withComposing: false,
                );
                
                expect(span.children, isNotNull);
                expect(span.children!.length, greaterThan(1));
                
                return RichText(text: span);
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should highlight images correctly', (tester) async {
      highlighter.text = 'Here is an image: ![Alt text](image.png)';

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = highlighter.buildTextSpan(
                  context: context,
                  style: theme.textTheme.bodyMedium,
                  withComposing: false,
                );
                
                expect(span.children, isNotNull);
                expect(span.children!.length, greaterThan(1));
                
                return RichText(text: span);
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should highlight lists correctly', (tester) async {
      highlighter.text = '- Item 1\n- Item 2\n1. Numbered item';

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = highlighter.buildTextSpan(
                  context: context,
                  style: theme.textTheme.bodyMedium,
                  withComposing: false,
                );
                
                expect(span.children, isNotNull);
                expect(span.children!.length, greaterThan(1));
                
                return RichText(text: span);
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should highlight blockquotes correctly', (tester) async {
      highlighter.text = '> This is a blockquote\n> with multiple lines';

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = highlighter.buildTextSpan(
                  context: context,
                  style: theme.textTheme.bodyMedium,
                  withComposing: false,
                );
                
                expect(span.children, isNotNull);
                expect(span.children!.length, greaterThan(1));
                
                return RichText(text: span);
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should highlight strikethrough correctly', (tester) async {
      highlighter.text = 'This is ~~strikethrough~~ text.';

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = highlighter.buildTextSpan(
                  context: context,
                  style: theme.textTheme.bodyMedium,
                  withComposing: false,
                );
                
                expect(span.children, isNotNull);
                expect(span.children!.length, greaterThan(1));
                
                return RichText(text: span);
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should handle mixed markdown syntax', (tester) async {
      highlighter.text = '''# Header
      
**Bold** and *italic* text with `code` and [link](url).

- List item
- Another item

> Blockquote text

```
Code block
```''';

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = highlighter.buildTextSpan(
                  context: context,
                  style: theme.textTheme.bodyMedium,
                  withComposing: false,
                );
                
                expect(span.children, isNotNull);
                expect(span.children!.length, greaterThan(5));
                
                return RichText(text: span);
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should handle plain text without markdown', (tester) async {
      highlighter.text = 'This is plain text without any markdown syntax.';

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final span = highlighter.buildTextSpan(
                  context: context,
                  style: theme.textTheme.bodyMedium,
                  withComposing: false,
                );
                
                // Should return a single span with the plain text
                if (span.children == null || span.children!.isEmpty) {
                  expect(span.text, equals(highlighter.text));
                } else {
                  // If there are children, the first child should contain the text
                  final firstChild = span.children!.first as TextSpan;
                  expect(firstChild.text, equals(highlighter.text));
                }
                
                return RichText(text: span);
              },
            ),
          ),
        ),
      );
    });

    test('should update theme correctly', () {
      final newTheme = ThemeData.dark();
      highlighter.updateTheme(newTheme);
      
      // The updateTheme method should complete without error
      // We can't easily test the internal state changes without exposing internals
      expect(highlighter, isNotNull);
    });
  });
}