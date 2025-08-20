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
import 'package:cherry_note/features/tags/presentation/widgets/tag_filter_widget.dart';

import 'tag_filter_widget_test.mocks.dart';

@GenerateMocks([TagsBloc])
void main() {
  group('TagFilterWidget', () {
    late MockTagsBloc mockTagsBloc;
    late List<Tag> mockTags;

    setUp(() {
      mockTagsBloc = MockTagsBloc();
      mockTags = [
        Tag(
          name: '工作',
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
          noteCount: 10,
          color: '#2196F3',
        ),
        Tag(
          name: '学习',
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
          noteCount: 5,
          color: '#4CAF50',
        ),
        Tag(
          name: '重要',
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
          noteCount: 8,
        ),
      ];

      when(mockTagsBloc.state).thenReturn(const TagsInitial());
      when(mockTagsBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget createWidget({
      ValueChanged<TagFilter>? onFilterChanged,
      bool showSearch = true,
      bool showLogicSelector = true,
      bool showClearButton = true,
      bool showStats = true,
      int? maxDisplayTags,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<TagsBloc>.value(
            value: mockTagsBloc,
            child: TagFilterWidget(
              onFilterChanged: onFilterChanged,
              showSearch: showSearch,
              showLogicSelector: showLogicSelector,
              showClearButton: showClearButton,
              showStats: showStats,
              maxDisplayTags: maxDisplayTags,
            ),
          ),
        ),
      );
    }

    testWidgets('should show loading indicator when loading', (tester) async {
      when(mockTagsBloc.state).thenReturn(const TagsLoading());

      await tester.pumpWidget(createWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error state when error occurs', (tester) async {
      when(mockTagsBloc.state).thenReturn(const TagsError(message: '加载失败'));

      await tester.pumpWidget(createWidget());

      expect(find.text('加载标签失败'), findsOneWidget);
      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('should display tags when loaded', (tester) async {
      when(mockTagsBloc.state).thenReturn(TagsLoaded(tags: mockTags));

      await tester.pumpWidget(createWidget());

      expect(find.text('工作'), findsOneWidget);
      expect(find.text('学习'), findsOneWidget);
      expect(find.text('重要'), findsOneWidget);
      expect(find.text('10'), findsOneWidget); // Note count for 工作
      expect(find.text('5'), findsOneWidget);  // Note count for 学习
      expect(find.text('8'), findsOneWidget);  // Note count for 重要
    });

    testWidgets('should show search box when showSearch is true', (tester) async {
      when(mockTagsBloc.state).thenReturn(TagsLoaded(tags: mockTags));

      await tester.pumpWidget(createWidget(showSearch: true));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('搜索标签...'), findsOneWidget);
    });

    testWidgets('should hide search box when showSearch is false', (tester) async {
      when(mockTagsBloc.state).thenReturn(TagsLoaded(tags: mockTags));

      await tester.pumpWidget(createWidget(showSearch: false));

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('should show stats when showStats is true', (tester) async {
      when(mockTagsBloc.state).thenReturn(TagsLoaded(tags: mockTags));

      await tester.pumpWidget(createWidget(showStats: true));

      expect(find.text('3'), findsOneWidget); // Total tag count
    });

    testWidgets('should trigger search when text is entered', (tester) async {
      when(mockTagsBloc.state).thenReturn(TagsLoaded(tags: mockTags));

      await tester.pumpWidget(createWidget());

      await tester.enterText(find.byType(TextField), '工');
      await tester.pump();

      // Verify that SearchTagsEvent was called
      final capturedEvents = verify(mockTagsBloc.add(captureAny)).captured;
      expect(
        capturedEvents.any((event) => 
          event is SearchTagsEvent && event.query == '工'),
        isTrue,
      );
    });

    testWidgets('should handle text input in search field', (tester) async {
      when(mockTagsBloc.state).thenReturn(TagsLoaded(tags: mockTags));

      await tester.pumpWidget(createWidget());

      // Enter search text
      await tester.enterText(find.byType(TextField), '搜索测试');
      await tester.pump();

      // Text field should contain the entered text
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('搜索测试'));
    });

    testWidgets('should display tags as clickable chips', (tester) async {
      when(mockTagsBloc.state).thenReturn(TagsLoaded(tags: mockTags));

      await tester.pumpWidget(createWidget());

      // Tags should be displayed as clickable chips
      expect(find.text('工作'), findsOneWidget);
      expect(find.text('学习'), findsOneWidget);
      expect(find.text('重要'), findsOneWidget);
    });

    testWidgets('should show logic selector when tags are selected', (tester) async {
      final filter = const TagFilter(
        selectedTags: ['工作', '学习'],
        logic: TagFilterLogic.and,
        enabled: true,
      );

      when(mockTagsBloc.state).thenReturn(TagsLoaded(
        tags: mockTags,
        filter: filter,
      ));

      await tester.pumpWidget(createWidget());

      expect(find.text('过滤逻辑:'), findsOneWidget);
      expect(find.text('AND'), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
    });

    testWidgets('should show logic selector when tags are selected', (tester) async {
      final filter = const TagFilter(
        selectedTags: ['工作'],
        logic: TagFilterLogic.and,
        enabled: true,
      );

      when(mockTagsBloc.state).thenReturn(TagsLoaded(
        tags: mockTags,
        filter: filter,
      ));

      await tester.pumpWidget(createWidget());

      expect(find.text('过滤逻辑:'), findsOneWidget);
      expect(find.text('AND'), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
    });

    testWidgets('should show selected tags section when tags are selected', (tester) async {
      final filter = const TagFilter(
        selectedTags: ['工作', '学习'],
        logic: TagFilterLogic.and,
        enabled: true,
      );

      when(mockTagsBloc.state).thenReturn(TagsLoaded(
        tags: mockTags,
        filter: filter,
      ));

      await tester.pumpWidget(createWidget());

      expect(find.text('已选择 2 个标签'), findsOneWidget);
      expect(find.byIcon(Icons.filter_alt), findsOneWidget);
    });

    testWidgets('should show clear button when tags are selected', (tester) async {
      final filter = const TagFilter(
        selectedTags: ['工作'],
        logic: TagFilterLogic.and,
        enabled: true,
      );

      when(mockTagsBloc.state).thenReturn(TagsLoaded(
        tags: mockTags,
        filter: filter,
      ));

      await tester.pumpWidget(createWidget());

      expect(find.text('清除'), findsOneWidget);
    });

    testWidgets('should show "show more" button when maxDisplayTags is set', (tester) async {
      when(mockTagsBloc.state).thenReturn(TagsLoaded(tags: mockTags));

      await tester.pumpWidget(createWidget(maxDisplayTags: 2));

      expect(find.text('显示全部 3 个标签'), findsOneWidget);
    });

    testWidgets('should show all tags when "show more" is tapped', (tester) async {
      when(mockTagsBloc.state).thenReturn(TagsLoaded(tags: mockTags));

      await tester.pumpWidget(createWidget(maxDisplayTags: 2));

      await tester.tap(find.text('显示全部 3 个标签'));
      await tester.pump();

      expect(find.text('收起'), findsOneWidget);
      expect(find.text('工作'), findsOneWidget);
      expect(find.text('学习'), findsOneWidget);
      expect(find.text('重要'), findsOneWidget);
    });

    testWidgets('should show empty state when no tags available', (tester) async {
      when(mockTagsBloc.state).thenReturn(const TagsLoaded(tags: []));

      await tester.pumpWidget(createWidget());

      expect(find.text('暂无标签'), findsOneWidget);
      expect(find.byIcon(Icons.local_offer_outlined), findsOneWidget);
    });

    testWidgets('should show no results message when search returns empty', (tester) async {
      when(mockTagsBloc.state).thenReturn(const TagsLoaded(
        tags: [],
        searchQuery: '不存在的标签',
        searchResults: [],
      ));

      await tester.pumpWidget(createWidget());

      expect(find.text('没有找到匹配的标签'), findsOneWidget);
    });

    testWidgets('should handle filter state changes', (tester) async {
      TagFilter? changedFilter;
      final filter = const TagFilter(
        selectedTags: ['工作'],
        logic: TagFilterLogic.and,
        enabled: true,
      );

      when(mockTagsBloc.stream).thenAnswer((_) => Stream.fromIterable([
        TagsLoaded(tags: mockTags, filter: filter),
      ]));

      await tester.pumpWidget(createWidget(
        onFilterChanged: (filter) => changedFilter = filter,
      ));

      await tester.pump();

      expect(changedFilter, equals(filter));
    });

    testWidgets('should load tags on init', (tester) async {
      await tester.pumpWidget(createWidget());

      // Verify that LoadTagsEvent was called
      final capturedEvents = verify(mockTagsBloc.add(captureAny)).captured;
      expect(
        capturedEvents.any((event) => event is LoadTagsEvent),
        isTrue,
      );
    });
  });

  group('CompactTagFilterWidget', () {
    late MockTagsBloc mockTagsBloc;

    setUp(() {
      mockTagsBloc = MockTagsBloc();
      when(mockTagsBloc.state).thenReturn(const TagsInitial());
      when(mockTagsBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    testWidgets('should create TagFilterWidget with compact settings', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<TagsBloc>.value(
              value: mockTagsBloc,
              child: const CompactTagFilterWidget(),
            ),
          ),
        ),
      );

      // Should not show search box in compact mode
      expect(find.byType(TextField), findsNothing);
    });
  });

  group('TagFilterBottomSheet', () {
    late MockTagsBloc mockBottomSheetTagsBloc;

    setUp(() {
      mockBottomSheetTagsBloc = MockTagsBloc();
      when(mockBottomSheetTagsBloc.state).thenReturn(const TagsInitial());
      when(mockBottomSheetTagsBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    testWidgets('should create bottom sheet widget', (tester) async {
      const filter = TagFilter(
        selectedTags: ['工作'],
        logic: TagFilterLogic.and,
        enabled: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<TagsBloc>.value(
              value: mockBottomSheetTagsBloc,
              child: TagFilterBottomSheet(
                currentFilter: filter,
              ),
            ),
          ),
        ),
      );

      expect(find.text('标签过滤'), findsOneWidget);
      expect(find.text('完成'), findsOneWidget);
    });
  });
}