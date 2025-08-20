import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/features/notes/presentation/widgets/auto_save_mixin.dart';

class TestWidget extends StatefulWidget {
  final String initialContent;
  final Function(String)? onAutoSave;
  final Duration autoSaveInterval;
  final bool autoSaveEnabled;

  const TestWidget({
    super.key,
    this.initialContent = '',
    this.onAutoSave,
    this.autoSaveInterval = const Duration(milliseconds: 100),
    this.autoSaveEnabled = true,
  });

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> with AutoSaveMixin {
  String _content = '';

  @override
  void initState() {
    super.initState();
    _content = widget.initialContent;
    initAutoSave();
  }

  @override
  void dispose() {
    disposeAutoSave();
    super.dispose();
  }

  @override
  String get currentContent => _content;

  @override
  void onAutoSave(String content) {
    widget.onAutoSave?.call(content);
  }

  @override
  Duration get autoSaveInterval => widget.autoSaveInterval;

  @override
  bool get autoSaveEnabled => widget.autoSaveEnabled;

  void updateContent(String newContent) {
    setState(() {
      _content = newContent;
    });
    onContentChanged(newContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('Content: $_content'),
          Text('Has unsaved changes: $hasUnsavedChanges'),
          ElevatedButton(
            onPressed: () => updateContent('New content'),
            child: const Text('Update Content'),
          ),
          ElevatedButton(
            onPressed: markAsSaved,
            child: const Text('Mark as Saved'),
          ),
          ElevatedButton(
            onPressed: forceAutoSave,
            child: const Text('Force Auto Save'),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('AutoSaveMixin', () {
    testWidgets('should initialize with no unsaved changes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestWidget(initialContent: 'Initial content'),
        ),
      );

      expect(find.text('Has unsaved changes: false'), findsOneWidget);
    });

    testWidgets('should mark as having unsaved changes when content changes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestWidget(initialContent: 'Initial content'),
        ),
      );

      await tester.tap(find.text('Update Content'));
      await tester.pump();

      expect(find.text('Has unsaved changes: true'), findsOneWidget);
    });

    testWidgets('should clear unsaved changes when marked as saved', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestWidget(initialContent: 'Initial content'),
        ),
      );

      // Update content to create unsaved changes
      await tester.tap(find.text('Update Content'));
      await tester.pump();
      expect(find.text('Has unsaved changes: true'), findsOneWidget);

      // Mark as saved
      await tester.tap(find.text('Mark as Saved'));
      await tester.pump();
      expect(find.text('Has unsaved changes: false'), findsOneWidget);
    });

    testWidgets('should trigger auto-save after interval', (tester) async {
      String? autoSavedContent;
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(
            initialContent: 'Initial content',
            autoSaveInterval: const Duration(milliseconds: 100),
            onAutoSave: (content) {
              autoSavedContent = content;
            },
          ),
        ),
      );

      // Update content
      await tester.tap(find.text('Update Content'));
      await tester.pump();

      // Wait for auto-save interval
      await tester.pump(const Duration(milliseconds: 150));

      expect(autoSavedContent, equals('New content'));
    });

    testWidgets('should not auto-save when disabled', (tester) async {
      String? autoSavedContent;
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(
            initialContent: 'Initial content',
            autoSaveInterval: const Duration(milliseconds: 100),
            autoSaveEnabled: false,
            onAutoSave: (content) {
              autoSavedContent = content;
            },
          ),
        ),
      );

      // Update content
      await tester.tap(find.text('Update Content'));
      await tester.pump();

      // Wait for what would be the auto-save interval
      await tester.pump(const Duration(milliseconds: 150));

      expect(autoSavedContent, isNull);
    });

    testWidgets('should force auto-save immediately', (tester) async {
      String? autoSavedContent;
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(
            initialContent: 'Initial content',
            onAutoSave: (content) {
              autoSavedContent = content;
            },
          ),
        ),
      );

      // Update content
      await tester.tap(find.text('Update Content'));
      await tester.pump();

      // Force auto-save
      await tester.tap(find.text('Force Auto Save'));
      await tester.pump();

      expect(autoSavedContent, equals('New content'));
    });

    testWidgets('should not auto-save empty content', (tester) async {
      String? autoSavedContent;
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(
            initialContent: '',
            autoSaveInterval: const Duration(milliseconds: 100),
            onAutoSave: (content) {
              autoSavedContent = content;
            },
          ),
        ),
      );

      // Update to empty content (simulating deletion)
      final state = tester.state<_TestWidgetState>(find.byType(TestWidget));
      state.updateContent('');
      await tester.pump();

      // Wait for auto-save interval
      await tester.pump(const Duration(milliseconds: 150));

      expect(autoSavedContent, isNull);
    });

    testWidgets('should reset timer when content changes multiple times', (tester) async {
      String? autoSavedContent;
      int autoSaveCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: TestWidget(
            initialContent: 'Initial content',
            autoSaveInterval: const Duration(milliseconds: 200),
            onAutoSave: (content) {
              autoSavedContent = content;
              autoSaveCount++;
            },
          ),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(TestWidget));

      // Update content multiple times quickly
      state.updateContent('Content 1');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      state.updateContent('Content 2');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      state.updateContent('Content 3');
      await tester.pump();

      // Wait for auto-save interval
      await tester.pump(const Duration(milliseconds: 250));

      // Should only auto-save once with the final content
      expect(autoSaveCount, equals(1));
      expect(autoSavedContent, equals('Content 3'));
    });
  });
}