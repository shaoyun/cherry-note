import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/features/notes/presentation/widgets/markdown_toolbar.dart';

void main() {
  group('MarkdownToolbar', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('should display all toolbar buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownToolbar(controller: controller),
          ),
        ),
      );

      // Check for main formatting buttons
      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(find.byIcon(Icons.format_italic), findsOneWidget);
      expect(find.byIcon(Icons.strikethrough_s), findsOneWidget);
      expect(find.byIcon(Icons.title), findsOneWidget);
      expect(find.byIcon(Icons.format_size), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
      expect(find.byIcon(Icons.format_quote), findsOneWidget);
      expect(find.byIcon(Icons.code), findsOneWidget);
      expect(find.byIcon(Icons.code_off), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.image), findsOneWidget);
      expect(find.byIcon(Icons.horizontal_rule), findsOneWidget);
      expect(find.byIcon(Icons.table_chart), findsOneWidget);
    });

    testWidgets('should insert bold markdown when bold button is pressed', (tester) async {
      controller.text = 'Hello World';
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 11); // Select "World"

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownToolbar(controller: controller),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pump();

      expect(controller.text, equals('Hello **World**'));
    });

    testWidgets('should insert italic markdown when italic button is pressed', (tester) async {
      controller.text = 'Hello World';
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 11); // Select "World"

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownToolbar(controller: controller),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.format_italic));
      await tester.pump();

      expect(controller.text, equals('Hello *World*'));
    });

    testWidgets('should insert strikethrough markdown when strikethrough button is pressed', (tester) async {
      controller.text = 'Hello World';
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 11); // Select "World"

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownToolbar(controller: controller),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.strikethrough_s));
      await tester.pump();

      expect(controller.text, equals('Hello ~~World~~'));
    });

    testWidgets('should insert heading when heading button is pressed', (tester) async {
      controller.text = 'Hello World';
      controller.selection = const TextSelection.collapsed(offset: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownToolbar(controller: controller),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.title));
      await tester.pump();

      expect(controller.text, equals('# Hello World'));
    });

    testWidgets('should insert bullet list when bullet list button is pressed', (tester) async {
      controller.text = 'Hello World';
      controller.selection = const TextSelection.collapsed(offset: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownToolbar(controller: controller),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.format_list_bulleted));
      await tester.pump();

      expect(controller.text, equals('- Hello World'));
    });

    testWidgets('should insert numbered list when numbered list button is pressed', (tester) async {
      controller.text = 'Hello World';
      controller.selection = const TextSelection.collapsed(offset: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownToolbar(controller: controller),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.format_list_numbered));
      await tester.pump();

      expect(controller.text, equals('1. Hello World'));
    });

    testWidgets('should insert quote when quote button is pressed', (tester) async {
      controller.text = 'Hello World';
      controller.selection = const TextSelection.collapsed(offset: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownToolbar(controller: controller),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.format_quote));
      await tester.pump();

      expect(controller.text, equals('> Hello World'));
    });

    testWidgets('should insert inline code when code button is pressed', (tester) async {
      controller.text = 'Hello World';
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 11); // Select "World"

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownToolbar(controller: controller),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.code));
      await tester.pump();

      expect(controller.text, equals('Hello `World`'));
    });

    testWidgets('should insert code block when code block button is pressed', (tester) async {
      controller.text = 'Hello World';
      controller.selection = const TextSelection.collapsed(offset: 11);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownToolbar(controller: controller),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.code_off));
      await tester.pump();

      expect(controller.text, equals('Hello World```\n\n```'));
    });

    testWidgets('should insert link when link button is pressed', (tester) async {
      controller.text = 'Hello World';
      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 11); // Select "World"

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownToolbar(controller: controller),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.link));
      await tester.pump();

      expect(controller.text, equals('Hello [World](URL)'));
    });

    testWidgets('should insert image when image button is pressed', (tester) async {
      controller.text = 'Hello World';
      controller.selection = const TextSelection.collapsed(offset: 11);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownToolbar(controller: controller),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.image));
      await tester.pump();

      expect(controller.text, equals('Hello World![Alt Text](image-url)'));
    });

    testWidgets('should insert horizontal rule when horizontal rule button is pressed', (tester) async {
      controller.text = 'Hello World';
      controller.selection = const TextSelection.collapsed(offset: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownToolbar(controller: controller),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.horizontal_rule));
      await tester.pump();

      expect(controller.text, equals('---\nHello World'));
    });

    testWidgets('should insert table when table button is pressed', (tester) async {
      controller.text = 'Hello World';
      controller.selection = const TextSelection.collapsed(offset: 11);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownToolbar(controller: controller),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.table_chart));
      await tester.pump();

      expect(controller.text, contains('Hello World'));
      expect(controller.text, contains('| Header 1 | Header 2 | Header 3 |'));
      expect(controller.text, contains('|----------|----------|----------|'));
    });

    testWidgets('should disable buttons when enabled is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownToolbar(
              controller: controller,
              enabled: false,
            ),
          ),
        ),
      );

      final boldButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.format_bold),
          matching: find.byType(IconButton),
        ),
      );

      expect(boldButton.onPressed, isNull);
    });

    testWidgets('should call onImageInsert callback when image button is pressed', (tester) async {
      bool imageInsertCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownToolbar(
              controller: controller,
              onImageInsert: () {
                imageInsertCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.image));
      await tester.pump();

      expect(imageInsertCalled, isTrue);
    });

    testWidgets('should call onLinkInsert callback when link button is pressed', (tester) async {
      bool linkInsertCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarkdownToolbar(
              controller: controller,
              onLinkInsert: () {
                linkInsertCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.link));
      await tester.pump();

      expect(linkInsertCalled, isTrue);
    });

    group('Edge Cases', () {
      testWidgets('should handle empty text when inserting markdown', (tester) async {
        controller.text = '';
        controller.selection = const TextSelection.collapsed(offset: 0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MarkdownToolbar(controller: controller),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.format_bold));
        await tester.pump();

        expect(controller.text, equals('****'));
        expect(controller.selection.baseOffset, equals(2)); // Cursor between asterisks
      });

      testWidgets('should handle cursor at end of text', (tester) async {
        controller.text = 'Hello';
        controller.selection = const TextSelection.collapsed(offset: 5);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MarkdownToolbar(controller: controller),
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.format_bold));
        await tester.pump();

        expect(controller.text, equals('Hello****'));
        expect(controller.selection.baseOffset, equals(7)); // Cursor between asterisks
      });
    });
  });
}