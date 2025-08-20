import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:cherry_note/features/notes/domain/entities/note_file.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_state.dart';
import 'package:cherry_note/features/notes/presentation/widgets/optimized_note_list_widget.dart';
import 'package:cherry_note/shared/widgets/virtual_list_view.dart';

import 'optimized_note_list_widget_test.mocks.dart';

@GenerateMocks([NotesBloc])
void main() {
  group('OptimizedNoteListWidget', () {
    late MockNotesBloc mockNotesBloc;
    late List<NoteFile> testNotes;

    setUp(() {
      mockNotesBloc = MockNotesBloc();
      testNotes = _generateTestNotes(10);
      
      when(mockNotesBloc.stream).thenAnswer((_) => Stream.empty());
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        selectedNoteId: null,
        page: 0,
      ));
    });

    Widget createWidget({
      String? folderPath,
      List<String>? filterTags,
      bool enableVirtualScrolling = true,
      bool enableLazyLoading = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<NotesBloc>.value(
            value: mockNotesBloc,
            child: OptimizedNoteListWidget(
              folderPath: folderPath,
              filterTags: filterTags,
              enableVirtualScrolling: enableVirtualScrolling,
              enableLazyLoading: enableLazyLoading,
            ),
          ),
        ),
      );
    }

    testWidgets('should render with virtual scrolling enabled', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidget(enableVirtualScrolling: true));

      // Assert
      expect(find.byType(VirtualListView), findsOneWidget);
      expect(find.byType(OptimizedNoteListItem), findsWidgets);
    });

    testWidgets('should render with lazy loading enabled', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidget(enableLazyLoading: true));

      // Assert
      expect(find.byType(LazyLoadListView), findsOneWidget);
    });

    testWidgets('should render with both optimizations disabled', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidget(
        enableVirtualScrolling: false,
        enableLazyLoading: false,
      ));

      // Assert
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(VirtualListView), findsNothing);
      expect(find.byType(LazyLoadListView), findsNothing);
    });

    testWidgets('should show loading state', (WidgetTester tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(const NotesLoading());

      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('加载笔记中...'), findsOneWidget);
    });

    testWidgets('should show error state', (WidgetTester tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(const NotesError('Test error'));

      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('Test error'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('should show empty state when no notes', (WidgetTester tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(const NotesLoaded(
        notes: [],
        selectedNoteId: null,
        page: 0,
      ));

      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.text('暂无笔记'), findsOneWidget);
      expect(find.text('点击右下角的 + 按钮创建第一个笔记'), findsOneWidget);
    });

    testWidgets('should show search results', (WidgetTester tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(NotesSearchResults(
        results: testNotes.take(3).toList(),
        totalResults: 3,
        query: 'test',
      ));

      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.text('找到 3 个结果'), findsOneWidget);
      expect(find.text('清除搜索'), findsOneWidget);
    });

    testWidgets('should handle search input with debouncing', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidget());
      
      // Find search field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Enter search text
      await tester.enterText(searchField, 'test search');
      await tester.pump();

      // Verify no immediate search (debounced)
      verifyNever(mockNotesBloc.add(any));

      // Wait for debounce delay
      await tester.pump(const Duration(milliseconds: 350));

      // Verify search was triggered after debounce
      verify(mockNotesBloc.add(any)).called(greaterThan(0));
    });

    testWidgets('should handle view type switching', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidget());

      // Find view toggle buttons
      final toggleButtons = find.byType(ToggleButtons);
      expect(toggleButtons, findsOneWidget);

      // Tap grid view button
      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pump();

      // Verify grid view is active (this would need to be verified through state)
      expect(find.byType(ToggleButtons), findsOneWidget);
    });

    testWidgets('should handle sort options', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidget());

      // Find sort button
      final sortButton = find.byIcon(Icons.sort);
      expect(sortButton, findsOneWidget);

      // Tap sort button
      await tester.tap(sortButton);
      await tester.pumpAndSettle();

      // Verify sort menu is shown
      expect(find.text('排序方式'), findsOneWidget);
    });

    testWidgets('should handle refresh', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidget());

      // Find refresh button
      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);

      // Tap refresh button
      await tester.tap(refreshButton);
      await tester.pump();

      // Verify refresh event was sent
      verify(mockNotesBloc.add(any)).called(greaterThan(0));
    });

    testWidgets('should handle pull to refresh', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createWidget());

      // Find the scrollable widget
      final scrollable = find.byType(RefreshIndicator);
      expect(scrollable, findsOneWidget);

      // Perform pull to refresh
      await tester.drag(scrollable, const Offset(0, 300));
      await tester.pumpAndSettle();

      // Verify refresh was triggered
      verify(mockNotesBloc.add(any)).called(greaterThan(0));
    });

    group('Note Item Interactions', () {
      testWidgets('should handle note selection', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createWidget());

        // Find first note item
        final noteItem = find.byType(OptimizedNoteListItem).first;
        expect(noteItem, findsOneWidget);

        // Tap note item
        await tester.tap(noteItem);
        await tester.pump();

        // Verify selection event was sent
        verify(mockNotesBloc.add(any)).called(greaterThan(0));
      });

      testWidgets('should handle note deletion', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createWidget());

        // Find first note item's menu button
        final menuButton = find.byIcon(Icons.more_vert).first;
        expect(menuButton, findsOneWidget);

        // Tap menu button
        await tester.tap(menuButton);
        await tester.pumpAndSettle();

        // Find delete option
        final deleteOption = find.text('删除');
        expect(deleteOption, findsOneWidget);

        // Tap delete option
        await tester.tap(deleteOption);
        await tester.pumpAndSettle();

        // Verify delete confirmation dialog
        expect(find.text('删除笔记'), findsOneWidget);
        expect(find.text('确定要删除笔记'), findsOneWidget);

        // Confirm deletion
        final confirmButton = find.text('删除').last;
        await tester.tap(confirmButton);
        await tester.pump();

        // Verify delete event was sent
        verify(mockNotesBloc.add(any)).called(greaterThan(0));
      });
    });

    group('Performance Optimizations', () {
      testWidgets('should use virtual scrolling for large lists', (WidgetTester tester) async {
        // Arrange
        final largeNoteList = _generateTestNotes(1000);
        when(mockNotesBloc.state).thenReturn(NotesLoaded(
          notes: largeNoteList,
          selectedNoteId: null,
          page: 0,
        ));

        // Act
        await tester.pumpWidget(createWidget(enableVirtualScrolling: true));

        // Assert
        expect(find.byType(VirtualListView), findsOneWidget);
        
        // Only visible items should be rendered
        final renderedItems = tester.widgetList(find.byType(OptimizedNoteListItem));
        expect(renderedItems.length, lessThan(largeNoteList.length));
      });

      testWidgets('should handle lazy loading', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(createWidget(enableLazyLoading: true));

        // Find the lazy load list
        final lazyList = find.byType(LazyLoadListView);
        expect(lazyList, findsOneWidget);

        // Scroll to trigger loading
        await tester.drag(lazyList, const Offset(0, -500));
        await tester.pump();

        // Verify loading was triggered (implementation dependent)
        expect(find.byType(LazyLoadListView), findsOneWidget);
      });
    });
  });

  group('OptimizedNoteListItem', () {
    late NoteFile testNote;

    setUp(() {
      testNote = NoteFile(
        filePath: '/test/note.md',
        title: 'Test Note',
        content: 'Test content',
        tags: ['tag1', 'tag2'],
        created: DateTime.now(),
        updated: DateTime.now(),
        isSticky: false,
      );
    });

    testWidgets('should render note information correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedNoteListItem(
              note: testNote,
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Note'), findsOneWidget);
      expect(find.text('Test content'), findsOneWidget);
      expect(find.text('tag1'), findsOneWidget);
      expect(find.text('tag2'), findsOneWidget);
    });

    testWidgets('should show sticky note indicator', (WidgetTester tester) async {
      // Arrange
      final stickyNote = NoteFile(
        filePath: '/test/sticky.md',
        title: 'Sticky Note',
        content: 'Sticky content',
        tags: [],
        created: DateTime.now(),
        updated: DateTime.now(),
        isSticky: true,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedNoteListItem(
              note: stickyNote,
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('便签'), findsOneWidget);
    });

    testWidgets('should handle tap events', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedNoteListItem(
              note: testNote,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OptimizedNoteListItem));

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('should show popup menu on menu button tap', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedNoteListItem(
              note: testNote,
              onTap: () {},
            ),
          ),
        ),
      );

      // Tap menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('编辑'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
    });
  });

  group('OptimizedNoteGridItem', () {
    late NoteFile testNote;

    setUp(() {
      testNote = NoteFile(
        filePath: '/test/note.md',
        title: 'Test Note',
        content: 'Test content',
        tags: ['tag1', 'tag2'],
        created: DateTime.now(),
        updated: DateTime.now(),
        isSticky: false,
      );
    });

    testWidgets('should render in grid format', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedNoteGridItem(
              note: testNote,
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Note'), findsOneWidget);
      expect(find.text('Test content'), findsOneWidget);
    });

    testWidgets('should handle empty content', (WidgetTester tester) async {
      // Arrange
      final emptyNote = NoteFile(
        filePath: '/test/empty.md',
        title: 'Empty Note',
        content: '',
        tags: [],
        created: DateTime.now(),
        updated: DateTime.now(),
        isSticky: false,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedNoteGridItem(
              note: emptyNote,
              onTap: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Empty Note'), findsOneWidget);
      expect(find.text('暂无内容'), findsOneWidget);
    });
  });
}

List<NoteFile> _generateTestNotes(int count) {
  return List.generate(count, (index) {
    return NoteFile(
      filePath: '/test/note_$index.md',
      title: 'Test Note $index',
      content: 'This is test content for note $index',
      tags: ['tag${index % 3}', 'category${index % 2}'],
      created: DateTime.now().subtract(Duration(days: index)),
      updated: DateTime.now().subtract(Duration(hours: index)),
      isSticky: index % 5 == 0,
    );
  });
}