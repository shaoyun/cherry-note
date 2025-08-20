import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:path/path.dart' as path;

import 'package:cherry_note/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_event.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_state.dart';
import 'package:cherry_note/features/notes/domain/entities/note_file.dart';

void main() {
  late NotesBloc notesBloc;
  late Directory tempDir;
  late String notesDirectory;

  setUp(() async {
    // 创建临时目录
    tempDir = await Directory.systemTemp.createTemp('notes_test_');
    notesDirectory = tempDir.path;
    
    notesBloc = NotesBloc(notesDirectory: notesDirectory);
  });

  tearDown(() async {
    await notesBloc.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('NotesBloc', () {
    test('初始状态应该是NotesInitial', () {
      expect(notesBloc.state, equals(const NotesInitial()));
    });

    group('LoadNotesEvent', () {
      blocTest<NotesBloc, NotesState>(
        '应该加载空的笔记列表',
        build: () => notesBloc,
        act: (bloc) => bloc.add(const LoadNotesEvent()),
        expect: () => [
          const NotesLoading(),
          const NotesLoaded(
            notes: [],
            totalCount: 0,
          ),
        ],
      );

      blocTest<NotesBloc, NotesState>(
        '应该加载现有的笔记文件',
        build: () => notesBloc,
        setUp: () async {
          // 创建测试笔记文件
          final noteFile = File(path.join(notesDirectory, 'test-note.md'));
          await noteFile.writeAsString('''---
title: Test Note
tags: [test, sample]
created: 2024-01-01T10:00:00.000Z
modified: 2024-01-01T10:00:00.000Z
---

# Test Note

This is a test note content.
''');
        },
        act: (bloc) => bloc.add(const LoadNotesEvent()),
        expect: () => [
          const NotesLoading(),
          isA<NotesLoaded>().having(
            (state) => state.notes.length,
            'notes count',
            equals(1),
          ).having(
            (state) => state.notes.first.title,
            'first note title',
            equals('Test Note'),
          ),
        ],
      );
    });

    group('CreateNoteEvent', () {
      blocTest<NotesBloc, NotesState>(
        '应该创建新笔记',
        build: () => notesBloc,
        act: (bloc) => bloc.add(const CreateNoteEvent(
          title: 'New Note',
          content: 'This is a new note.',
          tags: ['new', 'test'],
        )),
        expect: () => [
          const NoteOperationInProgress(operation: 'create'),
          isA<NoteOperationSuccess>()
              .having((state) => state.operation, 'operation', equals('create'))
              .having((state) => state.note?.title, 'note title', equals('New Note')),
          isA<NotesLoaded>().having(
            (state) => state.notes.length,
            'notes count',
            equals(1),
          ),
        ],
        verify: (bloc) async {
          // 验证文件是否创建
          final files = await Directory(notesDirectory)
              .list()
              .where((entity) => entity is File && entity.path.endsWith('.md'))
              .toList();
          expect(files.length, equals(1));
        },
      );

      blocTest<NotesBloc, NotesState>(
        '应该在指定文件夹中创建笔记',
        build: () => notesBloc,
        act: (bloc) => bloc.add(const CreateNoteEvent(
          title: 'Folder Note',
          folderPath: 'subfolder',
          content: 'This is a note in a subfolder.',
        )),
        expect: () => [
          const NoteOperationInProgress(operation: 'create'),
          isA<NoteOperationSuccess>(),
          isA<NotesLoaded>(),
        ],
        verify: (bloc) async {
          // 验证子文件夹是否创建
          final subfolderDir = Directory(path.join(notesDirectory, 'subfolder'));
          expect(await subfolderDir.exists(), isTrue);
          
          // 验证文件是否在子文件夹中
          final files = await subfolderDir
              .list()
              .where((entity) => entity is File && entity.path.endsWith('.md'))
              .toList();
          expect(files.length, equals(1));
        },
      );
    });

    group('UpdateNoteEvent', () {
      late String testNoteFilePath;

      setUp(() async {
        // 先创建一个测试笔记
        await notesBloc.add(const CreateNoteEvent(
          title: 'Original Title',
          content: 'Original content',
          tags: ['original'],
        ));
        
        // 等待创建完成
        await Future.delayed(const Duration(milliseconds: 100));
        
        // 获取创建的笔记路径
        final state = notesBloc.state;
        if (state is NotesLoaded && state.notes.isNotEmpty) {
          testNoteFilePath = state.notes.first.filePath;
        }
      });

      blocTest<NotesBloc, NotesState>(
        '应该更新现有笔记',
        build: () => notesBloc,
        act: (bloc) => bloc.add(UpdateNoteEvent(
          filePath: testNoteFilePath,
          title: 'Updated Title',
          content: 'Updated content',
          tags: ['updated'],
        )),
        skip: 2, // 跳过创建笔记的状态
        expect: () => [
          NoteOperationInProgress(
            operation: 'update',
            filePath: testNoteFilePath,
          ),
          isA<NoteOperationSuccess>()
              .having((state) => state.operation, 'operation', equals('update'))
              .having((state) => state.note?.title, 'updated title', equals('Updated Title')),
          isA<NotesLoaded>().having(
            (state) => state.notes.first.title,
            'first note title',
            equals('Updated Title'),
          ),
        ],
      );

      blocTest<NotesBloc, NotesState>(
        '更新不存在的笔记应该失败',
        build: () => notesBloc,
        act: (bloc) => bloc.add(const UpdateNoteEvent(
          filePath: 'nonexistent.md',
          title: 'Updated Title',
        )),
        expect: () => [
          const NoteOperationInProgress(
            operation: 'update',
            filePath: 'nonexistent.md',
          ),
          isA<NoteOperationError>()
              .having((state) => state.operation, 'operation', equals('update'))
              .having((state) => state.filePath, 'file path', equals('nonexistent.md')),
        ],
      );
    });

    group('DeleteNoteEvent', () {
      late String testNoteFilePath;

      setUp(() async {
        // 先创建一个测试笔记
        await notesBloc.add(const CreateNoteEvent(
          title: 'Note to Delete',
          content: 'This note will be deleted',
        ));
        
        // 等待创建完成
        await Future.delayed(const Duration(milliseconds: 100));
        
        // 获取创建的笔记路径
        final state = notesBloc.state;
        if (state is NotesLoaded && state.notes.isNotEmpty) {
          testNoteFilePath = state.notes.first.filePath;
        }
      });

      blocTest<NotesBloc, NotesState>(
        '应该删除现有笔记',
        build: () => notesBloc,
        act: (bloc) => bloc.add(DeleteNoteEvent(filePath: testNoteFilePath)),
        skip: 2, // 跳过创建笔记的状态
        expect: () => [
          NoteOperationInProgress(
            operation: 'delete',
            filePath: testNoteFilePath,
          ),
          isA<NoteOperationSuccess>()
              .having((state) => state.operation, 'operation', equals('delete')),
          const NotesLoaded(
            notes: [],
            totalCount: 0,
          ),
        ],
        verify: (bloc) async {
          // 验证文件是否被删除
          final file = File(path.join(notesDirectory, testNoteFilePath));
          expect(await file.exists(), isFalse);
        },
      );
    });

    group('SearchNotesEvent', () {
      setUp(() async {
        // 创建多个测试笔记
        await notesBloc.add(const CreateNoteEvent(
          title: 'Flutter Development',
          content: 'Learning Flutter framework',
          tags: ['flutter', 'development'],
        ));
        
        await notesBloc.add(const CreateNoteEvent(
          title: 'Dart Programming',
          content: 'Dart language basics',
          tags: ['dart', 'programming'],
        ));
        
        await notesBloc.add(const CreateNoteEvent(
          title: 'Mobile Apps',
          content: 'Building mobile applications with Flutter',
          tags: ['mobile', 'flutter'],
        ));
        
        // 等待创建完成
        await Future.delayed(const Duration(milliseconds: 200));
      });

      blocTest<NotesBloc, NotesState>(
        '应该按标题搜索笔记',
        build: () => notesBloc,
        act: (bloc) => bloc.add(const SearchNotesEvent(query: 'Flutter')),
        skip: 6, // 跳过创建笔记的状态
        expect: () => [
          const NotesSearching(query: 'Flutter'),
          isA<NotesSearchResults>()
              .having((state) => state.query, 'query', equals('Flutter'))
              .having((state) => state.results.length, 'results count', equals(2)),
        ],
      );

      blocTest<NotesBloc, NotesState>(
        '应该按内容搜索笔记',
        build: () => notesBloc,
        act: (bloc) => bloc.add(const SearchNotesEvent(
          query: 'framework',
          searchInContent: true,
        )),
        skip: 6, // 跳过创建笔记的状态
        expect: () => [
          const NotesSearching(query: 'framework'),
          isA<NotesSearchResults>()
              .having((state) => state.results.length, 'results count', equals(1))
              .having(
                (state) => state.results.first.title,
                'first result title',
                equals('Flutter Development'),
              ),
        ],
      );

      blocTest<NotesBloc, NotesState>(
        '应该按标签搜索笔记',
        build: () => notesBloc,
        act: (bloc) => bloc.add(const SearchNotesEvent(query: 'dart')),
        skip: 6, // 跳过创建笔记的状态
        expect: () => [
          const NotesSearching(query: 'dart'),
          isA<NotesSearchResults>()
              .having((state) => state.results.length, 'results count', equals(1))
              .having(
                (state) => state.results.first.title,
                'first result title',
                equals('Dart Programming'),
              ),
        ],
      );
    });

    group('SortNotesEvent', () {
      setUp(() async {
        // 创建多个测试笔记，时间间隔确保排序差异
        await notesBloc.add(const CreateNoteEvent(
          title: 'B Note',
          content: 'Short',
        ));
        
        await Future.delayed(const Duration(milliseconds: 10));
        
        await notesBloc.add(const CreateNoteEvent(
          title: 'A Note',
          content: 'This is a longer content for testing',
        ));
        
        await Future.delayed(const Duration(milliseconds: 10));
        
        await notesBloc.add(const CreateNoteEvent(
          title: 'C Note',
          content: 'Medium length content',
        ));
        
        // 等待创建完成
        await Future.delayed(const Duration(milliseconds: 100));
      });

      blocTest<NotesBloc, NotesState>(
        '应该按标题升序排序',
        build: () => notesBloc,
        act: (bloc) => bloc.add(const SortNotesEvent(
          sortBy: NotesSortBy.title,
          ascending: true,
        )),
        skip: 6, // 跳过创建笔记的状态
        expect: () => [
          isA<NotesLoaded>()
              .having((state) => state.sortBy, 'sort by', equals(NotesSortBy.title))
              .having((state) => state.ascending, 'ascending', isTrue)
              .having(
                (state) => state.notes.map((n) => n.title).toList(),
                'sorted titles',
                equals(['A Note', 'B Note', 'C Note']),
              ),
        ],
      );

      blocTest<NotesBloc, NotesState>(
        '应该按内容长度降序排序',
        build: () => notesBloc,
        act: (bloc) => bloc.add(const SortNotesEvent(
          sortBy: NotesSortBy.size,
          ascending: false,
        )),
        skip: 6, // 跳过创建笔记的状态
        expect: () => [
          isA<NotesLoaded>()
              .having((state) => state.sortBy, 'sort by', equals(NotesSortBy.size))
              .having((state) => state.ascending, 'ascending', isFalse)
              .having(
                (state) => state.notes.first.title,
                'first note (longest)',
                equals('A Note'),
              ),
        ],
      );
    });

    group('FilterNotesByTagsEvent', () {
      setUp(() async {
        // 创建带不同标签的测试笔记
        await notesBloc.add(const CreateNoteEvent(
          title: 'Flutter Note',
          tags: ['flutter', 'mobile'],
        ));
        
        await notesBloc.add(const CreateNoteEvent(
          title: 'Dart Note',
          tags: ['dart', 'programming'],
        ));
        
        await notesBloc.add(const CreateNoteEvent(
          title: 'Mobile Note',
          tags: ['mobile', 'development'],
        ));
        
        // 等待创建完成
        await Future.delayed(const Duration(milliseconds: 200));
      });

      blocTest<NotesBloc, NotesState>(
        '应该按标签过滤笔记',
        build: () => notesBloc,
        act: (bloc) => bloc.add(const FilterNotesByTagsEvent(
          tags: ['mobile'],
        )),
        skip: 6, // 跳过创建笔记的状态
        expect: () => [
          isA<NotesLoaded>()
              .having((state) => state.filterTags, 'filter tags', equals(['mobile']))
              .having((state) => state.notes.length, 'filtered count', equals(2)),
        ],
      );

      blocTest<NotesBloc, NotesState>(
        '应该按多个标签过滤笔记',
        build: () => notesBloc,
        act: (bloc) => bloc.add(const FilterNotesByTagsEvent(
          tags: ['flutter', 'dart'],
        )),
        skip: 6, // 跳过创建笔记的状态
        expect: () => [
          isA<NotesLoaded>()
              .having((state) => state.notes.length, 'filtered count', equals(2)),
        ],
      );
    });

    group('ClearSearchEvent', () {
      setUp(() async {
        // 创建测试笔记并应用搜索
        await notesBloc.add(const CreateNoteEvent(title: 'Test Note'));
        await Future.delayed(const Duration(milliseconds: 50));
        await notesBloc.add(const SearchNotesEvent(query: 'Test'));
        await Future.delayed(const Duration(milliseconds: 50));
      });

      blocTest<NotesBloc, NotesState>(
        '应该清除搜索和过滤',
        build: () => notesBloc,
        act: (bloc) => bloc.add(const ClearSearchEvent()),
        skip: 4, // 跳过创建和搜索的状态
        expect: () => [
          isA<NotesLoaded>()
              .having((state) => state.searchQuery, 'search query', isNull)
              .having((state) => state.filterTags, 'filter tags', isNull)
              .having((state) => state.hasActiveFilters, 'has active filters', isFalse),
        ],
      );
    });

    group('SelectNoteEvent', () {
      late String testNoteFilePath;

      setUp(() async {
        await notesBloc.add(const CreateNoteEvent(title: 'Selectable Note'));
        await Future.delayed(const Duration(milliseconds: 50));
        
        final state = notesBloc.state;
        if (state is NotesLoaded && state.notes.isNotEmpty) {
          testNoteFilePath = state.notes.first.filePath;
        }
      });

      blocTest<NotesBloc, NotesState>(
        '应该选择笔记',
        build: () => notesBloc,
        act: (bloc) => bloc.add(SelectNoteEvent(filePath: testNoteFilePath)),
        skip: 2, // 跳过创建笔记的状态
        expect: () => [
          isA<NotesLoaded>()
              .having((state) => state.selectedNoteId, 'selected note', equals(testNoteFilePath))
              .having((state) => state.hasSelection, 'has selection', isTrue),
        ],
      );

      blocTest<NotesBloc, NotesState>(
        '应该取消选择笔记',
        build: () => notesBloc,
        act: (bloc) {
          bloc.add(SelectNoteEvent(filePath: testNoteFilePath));
          bloc.add(const DeselectNoteEvent());
        },
        skip: 2, // 跳过创建笔记的状态
        expect: () => [
          isA<NotesLoaded>().having((state) => state.selectedNoteId, 'selected', isNotNull),
          isA<NotesLoaded>()
              .having((state) => state.selectedNoteId, 'selected note', isNull)
              .having((state) => state.hasSelection, 'has selection', isFalse),
        ],
      );
    });
  });
}