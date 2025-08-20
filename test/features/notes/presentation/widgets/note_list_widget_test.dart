import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:cherry_note/features/notes/domain/entities/note_file.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_event.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_state.dart';
import 'package:cherry_note/features/notes/presentation/widgets/note_list_widget.dart';

import 'note_list_widget_test.mocks.dart';

@GenerateMocks([NotesBloc])
void main() {
  group('NoteListWidget', () {
    late MockNotesBloc mockNotesBloc;
    late List<NoteFile> testNotes;

    setUp(() {
      mockNotesBloc = MockNotesBloc();
      testNotes = [
        NoteFile(
          filePath: 'test/note1.md',
          title: 'Test Note 1',
          content: 'This is the content of test note 1',
          tags: ['tag1', 'tag2'],
          created: DateTime(2024, 1, 1),
          updated: DateTime(2024, 1, 2),
          isSticky: false,
        ),
        NoteFile(
          filePath: 'test/note2.md',
          title: 'Test Note 2',
          content: 'This is the content of test note 2',
          tags: ['tag2', 'tag3'],
          created: DateTime(2024, 1, 3),
          updated: DateTime(2024, 1, 4),
          isSticky: true,
        ),
        NoteFile(
          filePath: 'test/note3.md',
          title: 'Test Note 3',
          content: 'This is the content of test note 3',
          tags: ['tag1'],
          created: DateTime(2024, 1, 5),
          updated: DateTime(2024, 1, 6),
          isSticky: false,
        ),
      ];

      when(mockNotesBloc.stream).thenAnswer((_) => Stream.empty());
      when(mockNotesBloc.state).thenReturn(const NotesInitial());
    });

    Widget createTestWidget({
      String? folderPath,
      List<String>? filterTags,
      Function(NoteFile)? onNoteSelected,
      bool showSearch = true,
      bool showSortOptions = true,
      NoteListViewType viewType = NoteListViewType.list,
    }) {
      return MaterialApp(
        home: BlocProvider<NotesBloc>.value(
          value: mockNotesBloc,
          child: Scaffold(
            body: NoteListWidget(
              folderPath: folderPath,
              filterTags: filterTags,
              onNoteSelected: onNoteSelected,
              showSearch: showSearch,
              showSortOptions: showSortOptions,
              viewType: viewType,
            ),
          ),
        ),
      );
    }

    testWidgets('should display loading indicator when state is NotesLoading', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(const NotesLoading());

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('加载笔记中...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error message when state is NotesError', (tester) async {
      // Arrange
      const errorMessage = 'Failed to load notes';
      when(mockNotesBloc.state).thenReturn(const NotesError(message: errorMessage));

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('should display empty state when no notes are loaded', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(const NotesLoaded(
        notes: [],
        totalCount: 0,
      ));

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('暂无笔记'), findsOneWidget);
      expect(find.text('点击右下角的 + 按钮创建第一个笔记'), findsOneWidget);
    });

    testWidgets('should display notes in list view when notes are loaded', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        totalCount: testNotes.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Test Note 1'), findsOneWidget);
      expect(find.text('Test Note 2'), findsOneWidget);
      expect(find.text('Test Note 3'), findsOneWidget);
    });

    testWidgets('should display notes in grid view when viewType is grid', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        totalCount: testNotes.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget(viewType: NoteListViewType.grid));

      // Assert
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Test Note 1'), findsOneWidget);
      expect(find.text('Test Note 2'), findsOneWidget);
      // Note: Grid view might not show all items due to viewport constraints
      // So we'll just check that at least some notes are displayed
    });

    testWidgets('should display search field when showSearch is true', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        totalCount: testNotes.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget(showSearch: true));

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('搜索笔记标题、内容或标签...'), findsOneWidget);
    });

    testWidgets('should not display search field when showSearch is false', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        totalCount: testNotes.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget(showSearch: false));

      // Assert
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('should display sort options when showSortOptions is true', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        totalCount: testNotes.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget(showSortOptions: true));

      // Assert
      expect(find.byType(ToggleButtons), findsOneWidget);
      expect(find.byIcon(Icons.sort), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should not display sort options when showSortOptions is false', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        totalCount: testNotes.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget(showSortOptions: false));

      // Assert
      expect(find.byType(ToggleButtons), findsNothing);
      expect(find.byIcon(Icons.sort), findsNothing);
    });

    testWidgets('should trigger search when text is entered in search field', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        totalCount: testNotes.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.byType(TextField), 'test query');
      await tester.pump(const Duration(milliseconds: 350)); // Wait for debounce

      // Assert
      verify(mockNotesBloc.add(any)).called(greaterThan(0));
    });

    testWidgets('should call onNoteSelected when note is tapped', (tester) async {
      // Arrange
      NoteFile? selectedNote;
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        totalCount: testNotes.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget(
        onNoteSelected: (note) => selectedNote = note,
      ));
      await tester.tap(find.text('Test Note 1'));

      // Assert
      expect(selectedNote, equals(testNotes[0]));
      verify(mockNotesBloc.add(SelectNoteEvent(filePath: testNotes[0].filePath)));
    });

    testWidgets('should show delete confirmation dialog when delete is tapped', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        totalCount: testNotes.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('删除笔记'), findsOneWidget);
      expect(find.text('确定要删除笔记 "Test Note 1" 吗？此操作无法撤销。'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('删除'), findsAtLeastNWidgets(1));
    });

    testWidgets('should trigger delete when confirmed in dialog', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        totalCount: testNotes.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      
      // Find the delete button in the dialog by looking for TextButton with red color
      final dialogDeleteButton = find.byWidgetPredicate(
        (widget) => widget is TextButton && 
                    widget.style?.foregroundColor?.resolve({}) == Colors.red,
      );
      await tester.tap(dialogDeleteButton);

      // Assert
      verify(mockNotesBloc.add(DeleteNoteEvent(filePath: testNotes[0].filePath)));
    });

    testWidgets('should show sort options sheet when sort button is tapped', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        totalCount: testNotes.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('排序方式'), findsOneWidget);
      expect(find.text('修改时间'), findsOneWidget);
      expect(find.text('创建时间'), findsOneWidget);
      expect(find.text('标题'), findsOneWidget);
      expect(find.text('大小'), findsOneWidget);
      expect(find.text('标签'), findsOneWidget);
    });

    testWidgets('should trigger sort when sort option is selected', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        totalCount: testNotes.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();
      await tester.tap(find.text('标题'));

      // Assert
      verify(mockNotesBloc.add(const SortNotesEvent(sortBy: NotesSortBy.title)));
    });

    testWidgets('should trigger refresh when refresh button is tapped', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        totalCount: testNotes.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.byIcon(Icons.refresh));

      // Assert
      verify(mockNotesBloc.add(const RefreshNotesEvent()));
    });

    testWidgets('should switch between list and grid view when toggle buttons are tapped', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        totalCount: testNotes.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget());
      
      // Initially should show list view
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
      
      // Tap grid view button
      await tester.tap(find.byIcon(Icons.grid_view));
      await tester.pump();
      
      // Should now show grid view
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      
      // Tap list view button
      await tester.tap(find.byIcon(Icons.list));
      await tester.pump();
      
      // Should now show list view again
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('should display sticky note indicator for sticky notes', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        totalCount: testNotes.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('便签'), findsOneWidget); // Only note2 is sticky
    });

    testWidgets('should display tags for notes', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        totalCount: testNotes.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('tag1'), findsAtLeastNWidgets(1));
      expect(find.text('tag2'), findsAtLeastNWidgets(1));
      expect(find.text('tag3'), findsOneWidget);
    });

    testWidgets('should display search results when state is NotesSearchResults', (tester) async {
      // Arrange
      const searchQuery = 'test';
      final searchResults = [testNotes[0], testNotes[1]];
      when(mockNotesBloc.state).thenReturn(NotesSearchResults(
        query: searchQuery,
        results: searchResults,
        totalResults: searchResults.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('找到 ${searchResults.length} 个结果'), findsOneWidget);
      expect(find.text('清除搜索'), findsOneWidget);
      expect(find.text('Test Note 1'), findsOneWidget);
      expect(find.text('Test Note 2'), findsOneWidget);
      expect(find.text('Test Note 3'), findsNothing);
    });

    testWidgets('should clear search when clear search button is tapped', (tester) async {
      // Arrange
      const searchQuery = 'test';
      final searchResults = [testNotes[0]];
      when(mockNotesBloc.state).thenReturn(NotesSearchResults(
        query: searchQuery,
        results: searchResults,
        totalResults: searchResults.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('清除搜索'));
      await tester.pump(const Duration(milliseconds: 350)); // Wait for any pending timers

      // Assert
      verify(mockNotesBloc.add(const ClearSearchEvent()));
    });

    testWidgets('should display no search results message when search returns empty', (tester) async {
      // Arrange
      const searchQuery = 'nonexistent';
      when(mockNotesBloc.state).thenReturn(const NotesSearchResults(
        query: searchQuery,
        results: [],
        totalResults: 0,
      ));

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('未找到匹配的笔记'), findsOneWidget);
      expect(find.text('尝试使用不同的关键词搜索'), findsOneWidget);
    });

    testWidgets('should load notes on init with correct parameters', (tester) async {
      // Arrange
      const folderPath = 'test/folder';
      const filterTags = ['tag1', 'tag2'];
      when(mockNotesBloc.state).thenReturn(const NotesInitial());

      // Act
      await tester.pumpWidget(createTestWidget(
        folderPath: folderPath,
        filterTags: filterTags,
      ));

      // Assert
      verify(mockNotesBloc.add(const LoadNotesEvent(
        folderPath: folderPath,
        tags: filterTags,
        sortBy: NotesSortBy.modifiedDate,
        ascending: false,
      )));
    });

    testWidgets('should reload notes when folder path changes', (tester) async {
      // Arrange
      when(mockNotesBloc.state).thenReturn(NotesLoaded(
        notes: testNotes,
        totalCount: testNotes.length,
      ));

      // Act
      await tester.pumpWidget(createTestWidget(folderPath: 'folder1'));
      await tester.pumpWidget(createTestWidget(folderPath: 'folder2'));

      // Assert
      verify(mockNotesBloc.add(any)).called(greaterThan(1));
    });
  });

  group('NoteListItem', () {
    late NoteFile testNote;

    setUp(() {
      testNote = NoteFile(
        filePath: 'test/note.md',
        title: 'Test Note',
        content: 'This is test content',
        tags: ['tag1', 'tag2'],
        created: DateTime(2024, 1, 1),
        updated: DateTime(2024, 1, 2),
        isSticky: false,
      );
    });

    Widget createTestWidget({
      bool isSelected = false,
      VoidCallback? onTap,
      VoidCallback? onEdit,
      VoidCallback? onDelete,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: NoteListItem(
            note: testNote,
            isSelected: isSelected,
            onTap: onTap,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ),
      );
    }

    testWidgets('should display note information correctly', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Test Note'), findsOneWidget);
      expect(find.text('This is test content'), findsOneWidget);
      expect(find.text('tag1'), findsOneWidget);
      expect(find.text('tag2'), findsOneWidget);
      expect(find.text('2024-01-02 00:00'), findsOneWidget);
    });

    testWidgets('should show sticky indicator for sticky notes', (tester) async {
      // Arrange
      final stickyNote = testNote.copyWith(isSticky: true);

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NoteListItem(note: stickyNote),
        ),
      ));

      // Assert
      expect(find.text('便签'), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      // Arrange
      bool tapped = false;

      // Act
      await tester.pumpWidget(createTestWidget(
        onTap: () => tapped = true,
      ));
      await tester.tap(find.text('Test Note')); // Tap on the title instead

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('should show popup menu when more button is tapped', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('编辑'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
    });

    testWidgets('should call onEdit when edit menu item is tapped', (tester) async {
      // Arrange
      bool edited = false;

      // Act
      await tester.pumpWidget(createTestWidget(
        onEdit: () => edited = true,
      ));
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('编辑'));

      // Assert
      expect(edited, isTrue);
    });

    testWidgets('should call onDelete when delete menu item is tapped', (tester) async {
      // Arrange
      bool deleted = false;

      // Act
      await tester.pumpWidget(createTestWidget(
        onDelete: () => deleted = true,
      ));
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));

      // Assert
      expect(deleted, isTrue);
    });

    testWidgets('should apply selected styling when isSelected is true', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(isSelected: true));

      // Assert
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, equals(4));
    });
  });

  group('NoteGridItem', () {
    late NoteFile testNote;

    setUp(() {
      testNote = NoteFile(
        filePath: 'test/note.md',
        title: 'Test Note',
        content: 'This is test content',
        tags: ['tag1', 'tag2'],
        created: DateTime(2024, 1, 1),
        updated: DateTime(2024, 1, 2),
        isSticky: false,
      );
    });

    Widget createTestWidget({
      bool isSelected = false,
      VoidCallback? onTap,
      VoidCallback? onEdit,
      VoidCallback? onDelete,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: NoteGridItem(
            note: testNote,
            isSelected: isSelected,
            onTap: onTap,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ),
      );
    }

    testWidgets('should display note information correctly in grid format', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Test Note'), findsOneWidget);
      expect(find.text('This is test content'), findsOneWidget);
      expect(find.text('01-02'), findsOneWidget); // Short date format
    });

    testWidgets('should show sticky indicator for sticky notes', (tester) async {
      // Arrange
      final stickyNote = testNote.copyWith(isSticky: true);

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NoteGridItem(note: stickyNote),
        ),
      ));

      // Assert
      expect(find.text('便签'), findsOneWidget);
    });

    testWidgets('should display limited tags in grid view', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('tag1'), findsOneWidget);
      expect(find.text('tag2'), findsOneWidget);
    });

    testWidgets('should show empty content message when note has no content', (tester) async {
      // Arrange
      final emptyNote = testNote.copyWith(content: '');

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NoteGridItem(note: emptyNote),
        ),
      ));

      // Assert
      expect(find.text('暂无内容'), findsOneWidget);
    });
  });
}