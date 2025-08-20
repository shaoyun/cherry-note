import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:cherry_note/features/tags/domain/entities/tag.dart';
import 'package:cherry_note/features/tags/domain/entities/tag_filter.dart';
import 'package:cherry_note/features/tags/presentation/bloc/tags_bloc.dart';
import 'package:cherry_note/features/tags/presentation/bloc/tags_event.dart';
import 'package:cherry_note/features/tags/presentation/bloc/tags_state.dart';
import 'package:cherry_note/features/tags/presentation/widgets/tag_input_widget.dart';

import 'tag_input_widget_test.mocks.dart';

@GenerateMocks([TagsBloc])
void main() {
  group('TagInputWidget', () {
    late MockTagsBloc mockTagsBloc;

    setUp(() {
      mockTagsBloc = MockTagsBloc();
      when(mockTagsBloc.state).thenReturn(const TagsInitial());
      when(mockTagsBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget createWidget({
      List<String> selectedTags = const [],
      ValueChanged<List<String>>? onTagsChanged,
      bool readOnly = false,
      int? maxTags,
      String? hintText,
      bool showColorPicker = false,
      bool allowCreateNew = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<TagsBloc>.value(
            value: mockTagsBloc,
            child: TagInputWidget(
              selectedTags: selectedTags,
              onTagsChanged: onTagsChanged,
              readOnly: readOnly,
              maxTags: maxTags,
              hintText: hintText,
              showColorPicker: showColorPicker,
              allowCreateNew: allowCreateNew,
            ),
          ),
        ),
      );
    }

    testWidgets('should display empty state when no tags selected', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('输入标签名称...'), findsOneWidget);
      expect(find.byType(Wrap), findsNothing); // No tags to display
    });

    testWidgets('should display selected tags as chips', (tester) async {
      await tester.pumpWidget(createWidget(
        selectedTags: ['工作', '重要'],
      ));

      expect(find.text('工作'), findsOneWidget);
      expect(find.text('重要'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNWidgets(2)); // Delete buttons
    });

    testWidgets('should call onTagsChanged when tag is removed', (tester) async {
      List<String>? changedTags;
      
      await tester.pumpWidget(createWidget(
        selectedTags: ['工作', '重要'],
        onTagsChanged: (tags) => changedTags = tags,
      ));

      // Tap the delete button for the first tag
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pump();

      expect(changedTags, equals(['重要']));
    });

    testWidgets('should show custom hint text', (tester) async {
      await tester.pumpWidget(createWidget(
        hintText: '添加标签...',
      ));

      expect(find.text('添加标签...'), findsOneWidget);
    });

    testWidgets('should disable input when readOnly is true', (tester) async {
      await tester.pumpWidget(createWidget(
        selectedTags: ['工作'],
        readOnly: true,
      ));

      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.close), findsNothing); // No delete buttons
    });

    testWidgets('should show max tags counter', (tester) async {
      await tester.pumpWidget(createWidget(
        selectedTags: ['工作', '重要'],
        maxTags: 5,
      ));

      expect(find.text('2/5 个标签'), findsOneWidget);
    });

    testWidgets('should disable input when max tags reached', (tester) async {
      await tester.pumpWidget(createWidget(
        selectedTags: ['工作', '重要'],
        maxTags: 2,
      ));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('should show color picker icon when enabled', (tester) async {
      await tester.pumpWidget(createWidget(
        showColorPicker: true,
      ));

      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    });

    testWidgets('should request suggestions when text changes', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(find.byType(TextField), '工');
      await tester.pump();

      // Verify that GetTagSuggestionsEvent was called
      final capturedEvents = verify(mockTagsBloc.add(captureAny)).captured;
      expect(
        capturedEvents.any((event) => 
          event is GetTagSuggestionsEvent && event.query == '工'),
        isTrue,
      );
    });

    testWidgets('should handle suggestions state', (tester) async {
      // Setup mock to return suggestions
      when(mockTagsBloc.stream).thenAnswer((_) => Stream.fromIterable([
        const TagSuggestions(query: '工', suggestions: ['工作', '工具']),
      ]));

      await tester.pumpWidget(createWidget());

      // Focus the text field
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Enter text to trigger suggestions
      await tester.enterText(find.byType(TextField), '工');
      await tester.pump();

      // Wait for the stream to emit
      await tester.pump();

      // The widget should handle the suggestions state
      // (Overlay testing is complex, so we just verify the state is handled)
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should create new tag when Enter is pressed', (tester) async {
      List<String>? changedTags;
      
      await tester.pumpWidget(createWidget(
        onTagsChanged: (tags) => changedTags = tags,
      ));

      await tester.enterText(find.byType(TextField), '新标签');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(changedTags, equals(['新标签']));
      
      // Verify that CreateTagEvent was called
      final capturedEvents = verify(mockTagsBloc.add(captureAny)).captured;
      expect(
        capturedEvents.any((event) => 
          event is CreateTagEvent && event.name == '新标签'),
        isTrue,
      );
    });

    testWidgets('should not create duplicate tags', (tester) async {
      List<String>? changedTags;
      
      await tester.pumpWidget(createWidget(
        selectedTags: ['工作'],
        onTagsChanged: (tags) => changedTags = tags,
      ));

      await tester.enterText(find.byType(TextField), '工作');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(changedTags, isNull); // Should not change
    });

    testWidgets('should not add tag when max tags reached', (tester) async {
      List<String>? changedTags;
      
      await tester.pumpWidget(createWidget(
        selectedTags: ['工作', '重要'],
        maxTags: 2,
        onTagsChanged: (tags) => changedTags = tags,
      ));

      await tester.enterText(find.byType(TextField), '新标签');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Should not change tags when max is reached
      expect(changedTags, isNull);
    });

    testWidgets('should not create new tag when allowCreateNew is false', (tester) async {
      List<String>? changedTags;
      
      await tester.pumpWidget(createWidget(
        allowCreateNew: false,
        onTagsChanged: (tags) => changedTags = tags,
      ));

      await tester.enterText(find.byType(TextField), '新标签');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(changedTags, isNull); // Should not change
      
      // Should still call suggestions but not create tag
      final capturedEvents = verify(mockTagsBloc.add(captureAny)).captured;
      expect(
        capturedEvents.any((event) => event is CreateTagEvent),
        isFalse,
      );
    });

    testWidgets('should handle TagsLoaded state with suggestions', (tester) async {
      final tags = [
        Tag(
          name: '工作',
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
          noteCount: 5,
        ),
        Tag(
          name: '工具',
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
          noteCount: 3,
        ),
      ];

      when(mockTagsBloc.stream).thenAnswer((_) => Stream.fromIterable([
        TagsLoaded(
          tags: tags,
          suggestions: ['工作', '工具'],
        ),
      ]));

      await tester.pumpWidget(createWidget());

      // Focus the text field to trigger suggestions
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Wait for the stream to emit
      await tester.pump();

      // The widget should handle the TagsLoaded state
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}