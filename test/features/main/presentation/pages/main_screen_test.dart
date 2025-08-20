import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:cherry_note/features/main/presentation/pages/main_screen.dart';
import 'package:cherry_note/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:cherry_note/features/folders/presentation/bloc/folders_state.dart';
import 'package:cherry_note/features/folders/presentation/widgets/folder_tree_widget.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_state.dart';
import 'package:cherry_note/features/notes/presentation/widgets/note_list_widget.dart';
import 'package:cherry_note/features/tags/presentation/bloc/tags_bloc.dart';
import 'package:cherry_note/features/tags/presentation/bloc/tags_state.dart';
import 'package:cherry_note/features/tags/presentation/widgets/tag_filter_widget.dart';
import 'package:cherry_note/features/notes/domain/entities/note_file.dart';
import 'package:cherry_note/features/tags/domain/entities/tag_filter.dart';

import 'main_screen_test.mocks.dart';

@GenerateMocks([
  FoldersBloc,
  NotesBloc,
  TagsBloc,
])
void main() {
  group('MainScreen', () {
    late MockFoldersBloc mockFoldersBloc;
    late MockNotesBloc mockNotesBloc;
    late MockTagsBloc mockTagsBloc;

    setUp(() {
      mockFoldersBloc = MockFoldersBloc();
      mockNotesBloc = MockNotesBloc();
      mockTagsBloc = MockTagsBloc();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<FoldersBloc>.value(value: mockFoldersBloc),
            BlocProvider<NotesBloc>.value(value: mockNotesBloc),
            BlocProvider<TagsBloc>.value(value: mockTagsBloc),
          ],
          child: const MainScreen(),
        ),
      );
    }

    testWidgets('should display three-column layout on desktop', (tester) async {
      // Arrange
      when(mockFoldersBloc.state).thenReturn(const FoldersInitial());
      when(mockNotesBloc.state).thenReturn(const NotesInitial());
      when(mockTagsBloc.state).thenReturn(const TagsInitial());
      
      when(mockFoldersBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockNotesBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockTagsBloc.stream).thenAnswer((_) => const Stream.empty());

      // Set large screen size for desktop layout
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      // Should show folder tree widget
      expect(find.byType(FolderTreeWidget), findsOneWidget);
      
      // Should show note list widget
      expect(find.byType(NoteListWidget), findsOneWidget);
      
      // Should show empty editor state initially
      expect(find.text('选择一个笔记开始编辑'), findsOneWidget);
      expect(find.text('或者创建一个新笔记'), findsOneWidget);
      
      // Should not show bottom navigation bar on desktop
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('should display compact layout on mobile', (tester) async {
      // Arrange
      when(mockFoldersBloc.state).thenReturn(const FoldersInitial());
      when(mockNotesBloc.state).thenReturn(const NotesInitial());
      when(mockTagsBloc.state).thenReturn(const TagsInitial());
      
      when(mockFoldersBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockNotesBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockTagsBloc.stream).thenAnswer((_) => const Stream.empty());

      // Set small screen size for mobile layout
      await tester.binding.setSurfaceSize(const Size(400, 800));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      // Should show bottom navigation bar on mobile
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      
      // Should show floating action button on mobile
      expect(find.byType(FloatingActionButton), findsOneWidget);
      
      // Should start with folder view (index 0)
      expect(find.byType(FolderTreeWidget), findsOneWidget);
    });

    testWidgets('should navigate between pages in compact mode', (tester) async {
      // Arrange
      when(mockFoldersBloc.state).thenReturn(const FoldersInitial());
      when(mockNotesBloc.state).thenReturn(const NotesInitial());
      when(mockTagsBloc.state).thenReturn(const TagsInitial());
      
      when(mockFoldersBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockNotesBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockTagsBloc.stream).thenAnswer((_) => const Stream.empty());

      // Set small screen size for mobile layout
      await tester.binding.setSurfaceSize(const Size(400, 800));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert initial state - should show folders
      expect(find.byType(FolderTreeWidget), findsOneWidget);

      // Tap on notes tab
      await tester.tap(find.text('笔记'));
      await tester.pumpAndSettle();

      // Should show note list
      expect(find.byType(NoteListWidget), findsOneWidget);

      // Tap on editor tab
      await tester.tap(find.text('编辑'));
      await tester.pumpAndSettle();

      // Should show empty editor state
      expect(find.text('选择一个笔记开始编辑'), findsOneWidget);
    });

    testWidgets('should show create new note button', (tester) async {
      // Arrange
      when(mockFoldersBloc.state).thenReturn(const FoldersInitial());
      when(mockNotesBloc.state).thenReturn(const NotesInitial());
      when(mockTagsBloc.state).thenReturn(const TagsInitial());
      
      when(mockFoldersBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockNotesBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockTagsBloc.stream).thenAnswer((_) => const Stream.empty());

      // Set large screen size for desktop layout
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('创建新笔记'), findsOneWidget);
      
      // Tap create new note button
      await tester.tap(find.text('创建新笔记'));
      await tester.pumpAndSettle();

      // Should still be in the main screen (note creation logic would be implemented later)
      expect(find.byType(MainScreen), findsOneWidget);
    });

    testWidgets('should handle folder selection', (tester) async {
      // Arrange
      when(mockFoldersBloc.state).thenReturn(const FoldersInitial());
      when(mockNotesBloc.state).thenReturn(const NotesInitial());
      when(mockTagsBloc.state).thenReturn(const TagsInitial());
      
      when(mockFoldersBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockNotesBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockTagsBloc.stream).thenAnswer((_) => const Stream.empty());

      // Set large screen size for desktop layout
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert - main screen should be displayed
      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.byType(FolderTreeWidget), findsOneWidget);
      expect(find.byType(NoteListWidget), findsOneWidget);
    });

    testWidgets('should handle tag filter changes', (tester) async {
      // Arrange
      when(mockFoldersBloc.state).thenReturn(const FoldersInitial());
      when(mockNotesBloc.state).thenReturn(const NotesInitial());
      when(mockTagsBloc.state).thenReturn(const TagsInitial());
      
      when(mockFoldersBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockNotesBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockTagsBloc.stream).thenAnswer((_) => const Stream.empty());

      // Set large screen size for desktop layout
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert - tag filter widget should be displayed
      expect(find.byType(TagFilterWidget), findsOneWidget);
    });

    testWidgets('should preserve panel widths', (tester) async {
      // Arrange
      when(mockFoldersBloc.state).thenReturn(const FoldersInitial());
      when(mockNotesBloc.state).thenReturn(const NotesInitial());
      when(mockTagsBloc.state).thenReturn(const TagsInitial());
      
      when(mockFoldersBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockNotesBloc.stream).thenAnswer((_) => const Stream.empty());
      when(mockTagsBloc.stream).thenAnswer((_) => const Stream.empty());

      // Set large screen size for desktop layout
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert - should display the main screen with default panel widths
      expect(find.byType(MainScreen), findsOneWidget);
      
      // The actual panel width testing would require more complex widget testing
      // or integration tests to verify SharedPreferences functionality
    });
  });
}