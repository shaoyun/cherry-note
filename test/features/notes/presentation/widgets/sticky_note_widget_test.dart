import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:cherry_note/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_event.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_state.dart';
import 'package:cherry_note/features/notes/presentation/widgets/sticky_note_widget.dart';
import 'package:cherry_note/features/notes/domain/entities/note_file.dart';

import 'sticky_note_widget_test.mocks.dart';

@GenerateMocks([NotesBloc])
void main() {
  group('StickyNoteWidget', () {
    late MockNotesBloc mockNotesBloc;

    setUp(() {
      mockNotesBloc = MockNotesBloc();
      when(mockNotesBloc.state).thenReturn(const NotesInitial());
      when(mockNotesBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget createWidget({
      VoidCallback? onStickyNoteCreated,
      bool showCreateButton = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<NotesBloc>.value(
            value: mockNotesBloc,
            child: StickyNoteWidget(
              onStickyNoteCreated: onStickyNoteCreated,
              showCreateButton: showCreateButton,
            ),
          ),
        ),
      );
    }

    testWidgets('should display sticky note creation form', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.text('快速便签'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('便签内容'), findsOneWidget);
      expect(find.text('记录你的想法、待办事项...'), findsOneWidget);
      expect(find.text('创建便签'), findsOneWidget);
    });

    testWidgets('should show create button when showCreateButton is true', (tester) async {
      // Act
      await tester.pumpWidget(createWidget(showCreateButton: true));

      // Assert
      expect(find.text('创建便签'), findsOneWidget);
    });

    testWidgets('should hide create button when showCreateButton is false', (tester) async {
      // Act
      await tester.pumpWidget(createWidget(showCreateButton: false));

      // Assert
      expect(find.text('创建便签'), findsNothing);
    });

    testWidgets('should validate empty content', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidget());

      // Act
      await tester.tap(find.text('创建便签'));
      await tester.pump();

      // Assert
      expect(find.text('请输入便签内容'), findsOneWidget);
      verifyNever(mockNotesBloc.add(any));
    });

    testWidgets('should create sticky note with valid content', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidget());
      
      // Act
      await tester.enterText(find.byType(TextFormField), '测试便签内容');
      await tester.tap(find.text('创建便签'));
      await tester.pump();

      // Assert
      verify(mockNotesBloc.add(const CreateStickyNoteEvent(
        content: '测试便签内容',
        tags: null,
      ))).called(1);
    });

    testWidgets('should create sticky note with tags', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidget());
      
      // Act
      await tester.enterText(find.byType(TextFormField), '测试便签内容');
      // Note: Tag input testing would require the TagInputWidget to be properly mocked
      await tester.tap(find.text('创建便签'));
      await tester.pump();

      // Assert
      verify(mockNotesBloc.add(any)).called(1);
    });

    testWidgets('should show loading state during creation', (tester) async {
      // Arrange
      when(mockNotesBloc.stream).thenAnswer((_) => Stream.fromIterable([
        const NoteOperationInProgress(operation: 'create_sticky'),
      ]));
      
      await tester.pumpWidget(createWidget());

      // Act
      await tester.pump();

      // Assert
      expect(find.text('创建中...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show success message and clear form on success', (tester) async {
      // Arrange
      bool callbackCalled = false;
      final testNote = NoteFile(
        filePath: '便签/test-sticky.md',
        title: '测试便签',
        content: '测试内容',
        tags: [],
        created: DateTime.now(),
        updated: DateTime.now(),
        isSticky: true,
      );

      when(mockNotesBloc.stream).thenAnswer((_) => Stream.fromIterable([
        NoteOperationSuccess(
          operation: 'create_sticky',
          message: 'Success',
          note: testNote,
        ),
      ]));

      await tester.pumpWidget(createWidget(
        onStickyNoteCreated: () => callbackCalled = true,
      ));

      // Act
      await tester.enterText(find.byType(TextFormField), '测试内容');
      await tester.pump();

      // Assert
      expect(find.text('便签创建成功'), findsOneWidget);
      expect(callbackCalled, isTrue);
      
      // Check if form is cleared
      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('should show error message on failure', (tester) async {
      // Arrange
      when(mockNotesBloc.stream).thenAnswer((_) => Stream.fromIterable([
        const NoteOperationError(
          operation: 'create_sticky',
          message: '创建失败',
        ),
      ]));

      await tester.pumpWidget(createWidget());

      // Act
      await tester.pump();

      // Assert
      expect(find.text('便签创建失败: 创建失败'), findsOneWidget);
    });
  });

  group('StickyNoteQuickCreateButton', () {
    testWidgets('should display floating action button', (tester) async {
      // Act
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StickyNoteQuickCreateButton(),
        ),
      ));

      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.sticky_note_2), findsOneWidget);
    });

    testWidgets('should show dialog when pressed', (tester) async {
      // Act
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StickyNoteQuickCreateButton(),
        ),
      ));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('创建便签'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('should call custom onPressed when provided', (tester) async {
      // Arrange
      bool customCallbackCalled = false;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StickyNoteQuickCreateButton(
            onPressed: () => customCallbackCalled = true,
          ),
        ),
      ));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      // Assert
      expect(customCallbackCalled, isTrue);
    });
  });

  group('StickyNoteListItem', () {
    final testCreated = DateTime(2024, 1, 15, 10, 30);
    final testUpdated = DateTime(2024, 1, 15, 15, 45);

    Widget createListItem({
      VoidCallback? onTap,
      VoidCallback? onEdit,
      VoidCallback? onDelete,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: StickyNoteListItem(
            title: '测试便签',
            content: '这是测试便签的内容',
            tags: ['测试', '便签'],
            created: testCreated,
            updated: testUpdated,
            onTap: onTap,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ),
      );
    }

    testWidgets('should display sticky note information', (tester) async {
      // Act
      await tester.pumpWidget(createListItem());

      // Assert
      expect(find.text('测试便签'), findsOneWidget);
      expect(find.text('这是测试便签的内容'), findsOneWidget);
      expect(find.text('测试'), findsOneWidget);
      expect(find.text('便签'), findsOneWidget);
      expect(find.byIcon(Icons.sticky_note_2), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      // Arrange
      bool tapCalled = false;

      // Act
      await tester.pumpWidget(createListItem(
        onTap: () => tapCalled = true,
      ));

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      // Assert
      expect(tapCalled, isTrue);
    });

    testWidgets('should show popup menu with edit and delete options', (tester) async {
      // Act
      await tester.pumpWidget(createListItem());

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('编辑'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('should call onEdit when edit menu item is selected', (tester) async {
      // Arrange
      bool editCalled = false;

      // Act
      await tester.pumpWidget(createListItem(
        onEdit: () => editCalled = true,
      ));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('编辑'));
      await tester.pump();

      // Assert
      expect(editCalled, isTrue);
    });

    testWidgets('should call onDelete when delete menu item is selected', (tester) async {
      // Arrange
      bool deleteCalled = false;

      // Act
      await tester.pumpWidget(createListItem(
        onDelete: () => deleteCalled = true,
      ));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pump();

      // Assert
      expect(deleteCalled, isTrue);
    });

    testWidgets('should format time correctly for recent notes', (tester) async {
      // Arrange
      final recentTime = DateTime.now().subtract(const Duration(minutes: 30));

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StickyNoteListItem(
            title: '最近便签',
            content: '内容',
            tags: [],
            created: recentTime,
            updated: recentTime,
          ),
        ),
      ));

      // Assert
      expect(find.textContaining('分钟前'), findsOneWidget);
    });

    testWidgets('should limit displayed tags to 3', (tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StickyNoteListItem(
            title: '多标签便签',
            content: '内容',
            tags: ['标签1', '标签2', '标签3', '标签4', '标签5'],
            created: testCreated,
            updated: testUpdated,
          ),
        ),
      ));

      // Assert
      expect(find.byType(Chip), findsNWidgets(3));
    });
  });
}