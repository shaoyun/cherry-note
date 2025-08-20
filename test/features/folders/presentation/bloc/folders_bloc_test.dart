import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:cherry_note/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:cherry_note/features/folders/presentation/bloc/folders_event.dart';
import 'package:cherry_note/features/folders/presentation/bloc/folders_state.dart';
import 'package:cherry_note/features/folders/domain/entities/folder_node.dart';
import 'package:cherry_note/features/folders/domain/repositories/folder_repository.dart';

import 'folders_bloc_test.mocks.dart';

@GenerateMocks([FolderRepository])
void main() {
  late FoldersBloc foldersBloc;
  late MockFolderRepository mockRepository;

  setUp(() {
    mockRepository = MockFolderRepository();
    foldersBloc = FoldersBloc(folderRepository: mockRepository);
  });

  tearDown(() async {
    await foldersBloc.close();
  });

  group('FoldersBloc', () {
    test('初始状态应该是FoldersInitial', () {
      expect(foldersBloc.state, equals(const FoldersInitial()));
    });

    group('LoadFoldersEvent', () {
      final testFolders = [
        FolderNode(
          folderPath: 'folder1',
          name: 'Folder 1',
          created: DateTime(2024, 1, 1),
          updated: DateTime(2024, 1, 1),
        ),
        FolderNode(
          folderPath: 'folder2',
          name: 'Folder 2',
          created: DateTime(2024, 1, 2),
          updated: DateTime(2024, 1, 2),
        ),
      ];

      blocTest<FoldersBloc, FoldersState>(
        '应该加载文件夹列表',
        build: () {
          when(mockRepository.loadFolders(rootPath: any))
              .thenAnswer((_) async => testFolders);
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const LoadFoldersEvent()),
        expect: () => [
          const FoldersLoading(),
          isA<FoldersLoaded>()
              .having((state) => state.folders.length, 'folders count', equals(2))
              .having((state) => state.totalFolders, 'total folders', equals(2))
              .having((state) => state.sortBy, 'sort by', equals(FolderSortBy.name))
              .having((state) => state.ascending, 'ascending', isTrue),
        ],
        verify: (bloc) {
          verify(mockRepository.loadFolders(rootPath: null)).called(1);
        },
      );

      blocTest<FoldersBloc, FoldersState>(
        '应该加载指定根路径的文件夹',
        build: () {
          when(mockRepository.loadFolders(rootPath: 'root'))
              .thenAnswer((_) async => testFolders);
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const LoadFoldersEvent(rootPath: 'root')),
        expect: () => [
          const FoldersLoading(),
          isA<FoldersLoaded>(),
        ],
        verify: (bloc) {
          verify(mockRepository.loadFolders(rootPath: 'root')).called(1);
        },
      );

      blocTest<FoldersBloc, FoldersState>(
        '加载失败时应该发出错误状态',
        build: () {
          when(mockRepository.loadFolders(rootPath: any))
              .thenThrow(Exception('Load failed'));
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const LoadFoldersEvent()),
        expect: () => [
          const FoldersLoading(),
          isA<FoldersError>()
              .having((state) => state.message, 'error message', 
                      contains('Failed to load folders')),
        ],
      );

      blocTest<FoldersBloc, FoldersState>(
        '强制刷新应该重新加载文件夹',
        build: () {
          when(mockRepository.loadFolders(rootPath: any))
              .thenAnswer((_) async => testFolders);
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const LoadFoldersEvent(forceRefresh: true)),
        expect: () => [
          const FoldersLoading(),
          isA<FoldersLoaded>(),
        ],
        verify: (bloc) {
          verify(mockRepository.loadFolders(rootPath: null)).called(1);
        },
      );
    });

    group('CreateFolderEvent', () {
      final newFolder = FolderNode(
        folderPath: 'parent/new-folder',
        name: 'New Folder',
        created: DateTime(2024, 1, 3),
        updated: DateTime(2024, 1, 3),
      );

      blocTest<FoldersBloc, FoldersState>(
        '应该创建新文件夹',
        build: () {
          when(mockRepository.isValidFolderName('New Folder')).thenReturn(true);
          when(mockRepository.createFolder(
            parentPath: 'parent',
            folderName: 'New Folder',
            metadata: null,
          )).thenAnswer((_) async => newFolder);
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const CreateFolderEvent(
          parentPath: 'parent',
          folderName: 'New Folder',
        )),
        expect: () => [
          const FolderOperationInProgress(
            operation: 'create',
            message: 'Creating folder "New Folder"...',
          ),
          isA<FolderOperationSuccess>()
              .having((state) => state.operation, 'operation', equals('create'))
              .having((state) => state.folder?.name, 'folder name', equals('New Folder'))
              .having((state) => state.folderPath, 'folder path', equals('parent/new-folder')),
          isA<FoldersLoaded>()
              .having((state) => state.selectedFolderPath, 'selected', equals('parent/new-folder')),
        ],
        verify: (bloc) {
          verify(mockRepository.isValidFolderName('New Folder')).called(1);
          verify(mockRepository.createFolder(
            parentPath: 'parent',
            folderName: 'New Folder',
            metadata: null,
          )).called(1);
        },
      );

      blocTest<FoldersBloc, FoldersState>(
        '无效文件夹名称应该失败',
        build: () {
          when(mockRepository.isValidFolderName('Invalid/Name')).thenReturn(false);
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const CreateFolderEvent(
          parentPath: 'parent',
          folderName: 'Invalid/Name',
        )),
        expect: () => [
          const FolderOperationInProgress(
            operation: 'create',
            message: 'Creating folder "Invalid/Name"...',
          ),
          isA<FolderOperationError>()
              .having((state) => state.operation, 'operation', equals('create'))
              .having((state) => state.message, 'error message', 
                      contains('Invalid folder name')),
        ],
        verify: (bloc) {
          verify(mockRepository.isValidFolderName('Invalid/Name')).called(1);
          verifyNever(mockRepository.createFolder(
            parentPath: any,
            folderName: any,
            metadata: any,
          ));
        },
      );

      blocTest<FoldersBloc, FoldersState>(
        '创建失败时应该发出错误状态',
        build: () {
          when(mockRepository.isValidFolderName('New Folder')).thenReturn(true);
          when(mockRepository.createFolder(
            parentPath: any,
            folderName: any,
            metadata: any,
          )).thenThrow(Exception('Creation failed'));
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const CreateFolderEvent(
          parentPath: 'parent',
          folderName: 'New Folder',
        )),
        expect: () => [
          const FolderOperationInProgress(
            operation: 'create',
            message: 'Creating folder "New Folder"...',
          ),
          isA<FolderOperationError>()
              .having((state) => state.operation, 'operation', equals('create'))
              .having((state) => state.message, 'error message', 
                      contains('Failed to create folder')),
        ],
      );
    });

    group('RenameFolderEvent', () {
      final renamedFolder = FolderNode(
        folderPath: 'parent/renamed-folder',
        name: 'Renamed Folder',
        created: DateTime(2024, 1, 1),
        updated: DateTime(2024, 1, 3),
      );

      blocTest<FoldersBloc, FoldersState>(
        '应该重命名文件夹',
        build: () {
          when(mockRepository.isValidFolderName('Renamed Folder')).thenReturn(true);
          when(mockRepository.renameFolder('parent/old-folder', 'Renamed Folder'))
              .thenAnswer((_) async => renamedFolder);
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const RenameFolderEvent(
          folderPath: 'parent/old-folder',
          newName: 'Renamed Folder',
        )),
        expect: () => [
          const FolderOperationInProgress(
            operation: 'rename',
            folderPath: 'parent/old-folder',
            message: 'Renaming folder to "Renamed Folder"...',
          ),
          isA<FolderOperationSuccess>()
              .having((state) => state.operation, 'operation', equals('rename'))
              .having((state) => state.folder?.name, 'folder name', equals('Renamed Folder')),
          isA<FoldersLoaded>(),
        ],
        verify: (bloc) {
          verify(mockRepository.isValidFolderName('Renamed Folder')).called(1);
          verify(mockRepository.renameFolder('parent/old-folder', 'Renamed Folder')).called(1);
        },
      );

      blocTest<FoldersBloc, FoldersState>(
        '无效新名称应该失败',
        build: () {
          when(mockRepository.isValidFolderName('Invalid/Name')).thenReturn(false);
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const RenameFolderEvent(
          folderPath: 'parent/folder',
          newName: 'Invalid/Name',
        )),
        expect: () => [
          const FolderOperationInProgress(
            operation: 'rename',
            folderPath: 'parent/folder',
            message: 'Renaming folder to "Invalid/Name"...',
          ),
          isA<FolderOperationError>()
              .having((state) => state.operation, 'operation', equals('rename'))
              .having((state) => state.message, 'error message', 
                      contains('Invalid folder name')),
        ],
      );
    });

    group('DeleteFolderEvent', () {
      blocTest<FoldersBloc, FoldersState>(
        '应该删除文件夹',
        build: () {
          when(mockRepository.deleteFolder('folder-to-delete', recursive: false))
              .thenAnswer((_) async {});
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const DeleteFolderEvent(
          folderPath: 'folder-to-delete',
        )),
        expect: () => [
          const FolderOperationInProgress(
            operation: 'delete',
            folderPath: 'folder-to-delete',
            message: 'Deleting folder...',
          ),
          isA<FolderOperationSuccess>()
              .having((state) => state.operation, 'operation', equals('delete'))
              .having((state) => state.folderPath, 'folder path', equals('folder-to-delete')),
          isA<FoldersLoaded>(),
        ],
        verify: (bloc) {
          verify(mockRepository.deleteFolder('folder-to-delete', recursive: false)).called(1);
        },
      );

      blocTest<FoldersBloc, FoldersState>(
        '应该递归删除文件夹',
        build: () {
          when(mockRepository.deleteFolder('folder-to-delete', recursive: true))
              .thenAnswer((_) async {});
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const DeleteFolderEvent(
          folderPath: 'folder-to-delete',
          recursive: true,
        )),
        expect: () => [
          const FolderOperationInProgress(
            operation: 'delete',
            folderPath: 'folder-to-delete',
            message: 'Deleting folder...',
          ),
          isA<FolderOperationSuccess>(),
          isA<FoldersLoaded>(),
        ],
        verify: (bloc) {
          verify(mockRepository.deleteFolder('folder-to-delete', recursive: true)).called(1);
        },
      );

      blocTest<FoldersBloc, FoldersState>(
        '删除失败时应该发出错误状态',
        build: () {
          when(mockRepository.deleteFolder(any, recursive: any))
              .thenThrow(Exception('Delete failed'));
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const DeleteFolderEvent(
          folderPath: 'folder-to-delete',
        )),
        expect: () => [
          const FolderOperationInProgress(
            operation: 'delete',
            folderPath: 'folder-to-delete',
            message: 'Deleting folder...',
          ),
          isA<FolderOperationError>()
              .having((state) => state.operation, 'operation', equals('delete'))
              .having((state) => state.message, 'error message', 
                      contains('Failed to delete folder')),
        ],
      );
    });

    group('MoveFolderEvent', () {
      final movedFolder = FolderNode(
        folderPath: 'new-parent/moved-folder',
        name: 'Moved Folder',
        created: DateTime(2024, 1, 1),
        updated: DateTime(2024, 1, 3),
      );

      blocTest<FoldersBloc, FoldersState>(
        '应该移动文件夹',
        build: () {
          when(mockRepository.moveFolder('old-parent/folder', 'new-parent'))
              .thenAnswer((_) async => movedFolder);
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const MoveFolderEvent(
          folderPath: 'old-parent/folder',
          newParentPath: 'new-parent',
        )),
        expect: () => [
          const FolderOperationInProgress(
            operation: 'move',
            folderPath: 'old-parent/folder',
            message: 'Moving folder...',
          ),
          isA<FolderOperationSuccess>()
              .having((state) => state.operation, 'operation', equals('move'))
              .having((state) => state.folderPath, 'folder path', equals('new-parent/moved-folder')),
          isA<FoldersLoaded>(),
        ],
        verify: (bloc) {
          verify(mockRepository.moveFolder('old-parent/folder', 'new-parent')).called(1);
        },
      );
    });

    group('CopyFolderEvent', () {
      final copiedFolder = FolderNode(
        folderPath: 'target/copied-folder',
        name: 'Copied Folder',
        created: DateTime(2024, 1, 3),
        updated: DateTime(2024, 1, 3),
      );

      blocTest<FoldersBloc, FoldersState>(
        '应该复制文件夹',
        build: () {
          when(mockRepository.copyFolder('source/folder', 'target', newName: null))
              .thenAnswer((_) async => copiedFolder);
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const CopyFolderEvent(
          folderPath: 'source/folder',
          newParentPath: 'target',
        )),
        expect: () => [
          const FolderOperationInProgress(
            operation: 'copy',
            folderPath: 'source/folder',
            message: 'Copying folder...',
          ),
          isA<FolderOperationSuccess>()
              .having((state) => state.operation, 'operation', equals('copy'))
              .having((state) => state.folderPath, 'folder path', equals('target/copied-folder')),
          isA<FoldersLoaded>()
              .having((state) => state.selectedFolderPath, 'selected', equals('target/copied-folder')),
        ],
        verify: (bloc) {
          verify(mockRepository.copyFolder('source/folder', 'target', newName: null)).called(1);
        },
      );

      blocTest<FoldersBloc, FoldersState>(
        '应该用新名称复制文件夹',
        build: () {
          when(mockRepository.copyFolder('source/folder', 'target', newName: 'New Name'))
              .thenAnswer((_) async => copiedFolder);
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const CopyFolderEvent(
          folderPath: 'source/folder',
          newParentPath: 'target',
          newName: 'New Name',
        )),
        expect: () => [
          const FolderOperationInProgress(
            operation: 'copy',
            folderPath: 'source/folder',
            message: 'Copying folder...',
          ),
          isA<FolderOperationSuccess>(),
          isA<FoldersLoaded>(),
        ],
        verify: (bloc) {
          verify(mockRepository.copyFolder('source/folder', 'target', newName: 'New Name')).called(1);
        },
      );
    });

    group('文件夹展开/折叠', () {
      setUp(() async {
        // 设置初始状态
        when(mockRepository.loadFolders(rootPath: any))
            .thenAnswer((_) async => [
              FolderNode(
                folderPath: 'folder1',
                name: 'Folder 1',
                created: DateTime(2024, 1, 1),
                updated: DateTime(2024, 1, 1),
              ),
            ]);
        
        foldersBloc.add(const LoadFoldersEvent());
        await Future.delayed(const Duration(milliseconds: 10));
      });

      blocTest<FoldersBloc, FoldersState>(
        '应该展开文件夹',
        build: () => foldersBloc,
        act: (bloc) => bloc.add(const ExpandFolderEvent(folderPath: 'folder1')),
        skip: 2, // 跳过加载状态
        expect: () => [
          isA<FoldersLoaded>()
              .having((state) => state.isFolderExpanded('folder1'), 'is expanded', isTrue),
        ],
      );

      blocTest<FoldersBloc, FoldersState>(
        '应该折叠文件夹',
        build: () => foldersBloc,
        act: (bloc) {
          bloc.add(const ExpandFolderEvent(folderPath: 'folder1'));
          bloc.add(const CollapseFolderEvent(folderPath: 'folder1'));
        },
        skip: 2, // 跳过加载状态
        expect: () => [
          isA<FoldersLoaded>()
              .having((state) => state.isFolderExpanded('folder1'), 'is expanded', isTrue),
          isA<FoldersLoaded>()
              .having((state) => state.isFolderExpanded('folder1'), 'is expanded', isFalse),
        ],
      );

      blocTest<FoldersBloc, FoldersState>(
        '应该切换文件夹展开状态',
        build: () => foldersBloc,
        act: (bloc) {
          bloc.add(const ToggleFolderEvent(folderPath: 'folder1'));
          bloc.add(const ToggleFolderEvent(folderPath: 'folder1'));
        },
        skip: 2, // 跳过加载状态
        expect: () => [
          isA<FoldersLoaded>()
              .having((state) => state.isFolderExpanded('folder1'), 'is expanded', isTrue),
          isA<FoldersLoaded>()
              .having((state) => state.isFolderExpanded('folder1'), 'is expanded', isFalse),
        ],
      );
    });

    group('文件夹选择', () {
      setUp(() async {
        when(mockRepository.loadFolders(rootPath: any))
            .thenAnswer((_) async => [
              FolderNode(
                folderPath: 'folder1',
                name: 'Folder 1',
                created: DateTime(2024, 1, 1),
                updated: DateTime(2024, 1, 1),
              ),
            ]);
        
        foldersBloc.add(const LoadFoldersEvent());
        await Future.delayed(const Duration(milliseconds: 10));
      });

      blocTest<FoldersBloc, FoldersState>(
        '应该选择文件夹',
        build: () => foldersBloc,
        act: (bloc) => bloc.add(const SelectFolderEvent(folderPath: 'folder1')),
        skip: 2, // 跳过加载状态
        expect: () => [
          isA<FoldersLoaded>()
              .having((state) => state.selectedFolderPath, 'selected', equals('folder1'))
              .having((state) => state.isFolderSelected('folder1'), 'is selected', isTrue),
        ],
      );

      blocTest<FoldersBloc, FoldersState>(
        '应该取消选择文件夹',
        build: () => foldersBloc,
        act: (bloc) {
          bloc.add(const SelectFolderEvent(folderPath: 'folder1'));
          bloc.add(const DeselectFolderEvent());
        },
        skip: 2, // 跳过加载状态
        expect: () => [
          isA<FoldersLoaded>()
              .having((state) => state.selectedFolderPath, 'selected', equals('folder1')),
          isA<FoldersLoaded>()
              .having((state) => state.selectedFolderPath, 'selected', isNull),
        ],
      );
    });

    group('SearchFoldersEvent', () {
      final searchResults = [
        FolderNode(
          folderPath: 'search-result',
          name: 'Search Result',
          created: DateTime(2024, 1, 1),
          updated: DateTime(2024, 1, 1),
        ),
      ];

      blocTest<FoldersBloc, FoldersState>(
        '应该搜索文件夹',
        build: () {
          when(mockRepository.searchFolders(query: 'search', rootPath: null))
              .thenAnswer((_) async => searchResults);
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const SearchFoldersEvent(query: 'search')),
        expect: () => [
          const FoldersSearching(query: 'search'),
          isA<FoldersSearchResults>()
              .having((state) => state.query, 'query', equals('search'))
              .having((state) => state.results.length, 'results count', equals(1))
              .having((state) => state.totalResults, 'total results', equals(1)),
          isA<FoldersLoaded>()
              .having((state) => state.searchQuery, 'search query', equals('search'))
              .having((state) => state.searchResults?.length, 'search results', equals(1)),
        ],
        verify: (bloc) {
          verify(mockRepository.searchFolders(query: 'search', rootPath: null)).called(1);
        },
      );

      blocTest<FoldersBloc, FoldersState>(
        '搜索失败时应该发出错误状态',
        build: () {
          when(mockRepository.searchFolders(query: any, rootPath: any))
              .thenThrow(Exception('Search failed'));
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const SearchFoldersEvent(query: 'search')),
        expect: () => [
          const FoldersSearching(query: 'search'),
          isA<FoldersError>()
              .having((state) => state.message, 'error message', 
                      contains('Search failed')),
        ],
      );
    });

    group('ClearFolderSearchEvent', () {
      setUp(() async {
        when(mockRepository.loadFolders(rootPath: any))
            .thenAnswer((_) async => []);
        when(mockRepository.searchFolders(query: any, rootPath: any))
            .thenAnswer((_) async => []);
        
        foldersBloc.add(const LoadFoldersEvent());
        await Future.delayed(const Duration(milliseconds: 10));
        foldersBloc.add(const SearchFoldersEvent(query: 'test'));
        await Future.delayed(const Duration(milliseconds: 10));
      });

      blocTest<FoldersBloc, FoldersState>(
        '应该清除搜索',
        build: () => foldersBloc,
        act: (bloc) => bloc.add(const ClearFolderSearchEvent()),
        skip: 5, // 跳过加载和搜索状态
        expect: () => [
          isA<FoldersLoaded>()
              .having((state) => state.searchQuery, 'search query', isNull)
              .having((state) => state.searchResults, 'search results', isNull),
        ],
      );
    });

    group('SetFolderSortEvent', () {
      final testFolders = [
        FolderNode(
          folderPath: 'folder-b',
          name: 'B Folder',
          created: DateTime(2024, 1, 2),
          updated: DateTime(2024, 1, 2),
        ),
        FolderNode(
          folderPath: 'folder-a',
          name: 'A Folder',
          created: DateTime(2024, 1, 1),
          updated: DateTime(2024, 1, 1),
        ),
      ];

      setUp(() async {
        when(mockRepository.loadFolders(rootPath: any))
            .thenAnswer((_) async => testFolders);
        
        foldersBloc.add(const LoadFoldersEvent());
        await Future.delayed(const Duration(milliseconds: 10));
      });

      blocTest<FoldersBloc, FoldersState>(
        '应该按名称升序排序',
        build: () => foldersBloc,
        act: (bloc) => bloc.add(const SetFolderSortEvent(
          sortBy: FolderSortBy.name,
          ascending: true,
        )),
        skip: 2, // 跳过加载状态
        expect: () => [
          isA<FoldersLoaded>()
              .having((state) => state.sortBy, 'sort by', equals(FolderSortBy.name))
              .having((state) => state.ascending, 'ascending', isTrue)
              .having((state) => state.folders.first.name, 'first folder', equals('A Folder')),
        ],
      );

      blocTest<FoldersBloc, FoldersState>(
        '应该按创建日期降序排序',
        build: () => foldersBloc,
        act: (bloc) => bloc.add(const SetFolderSortEvent(
          sortBy: FolderSortBy.createdDate,
          ascending: false,
        )),
        skip: 2, // 跳过加载状态
        expect: () => [
          isA<FoldersLoaded>()
              .having((state) => state.sortBy, 'sort by', equals(FolderSortBy.createdDate))
              .having((state) => state.ascending, 'ascending', isFalse)
              .having((state) => state.folders.first.name, 'first folder', equals('B Folder')),
        ],
      );
    });

    group('BatchFolderOperationEvent', () {
      blocTest<FoldersBloc, FoldersState>(
        '应该批量删除文件夹',
        build: () {
          when(mockRepository.deleteFolder('folder1', recursive: true))
              .thenAnswer((_) async {});
          when(mockRepository.deleteFolder('folder2', recursive: true))
              .thenAnswer((_) async {});
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const BatchFolderOperationEvent(
          folderPaths: ['folder1', 'folder2'],
          operation: FolderBatchOperation.delete,
        )),
        expect: () => [
          const FoldersBatchOperation(
            operation: 'delete',
            folderPaths: ['folder1', 'folder2'],
            completed: 0,
            total: 2,
          ),
          const FoldersBatchOperation(
            operation: 'delete',
            folderPaths: ['folder1', 'folder2'],
            completed: 0,
            total: 2,
            currentFolder: 'folder1',
          ),
          const FoldersBatchOperation(
            operation: 'delete',
            folderPaths: ['folder1', 'folder2'],
            completed: 1,
            total: 2,
            currentFolder: 'folder2',
          ),
          isA<FoldersBatchOperationSuccess>()
              .having((state) => state.operation, 'operation', equals('delete'))
              .having((state) => state.successCount, 'success count', equals(2))
              .having((state) => state.failureCount, 'failure count', equals(0)),
          isA<FoldersLoaded>(),
        ],
        verify: (bloc) {
          verify(mockRepository.deleteFolder('folder1', recursive: true)).called(1);
          verify(mockRepository.deleteFolder('folder2', recursive: true)).called(1);
        },
      );

      blocTest<FoldersBloc, FoldersState>(
        '批量操作部分失败时应该记录错误',
        build: () {
          when(mockRepository.deleteFolder('folder1', recursive: true))
              .thenAnswer((_) async {});
          when(mockRepository.deleteFolder('folder2', recursive: true))
              .thenThrow(Exception('Delete failed'));
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const BatchFolderOperationEvent(
          folderPaths: ['folder1', 'folder2'],
          operation: FolderBatchOperation.delete,
        )),
        expect: () => [
          const FoldersBatchOperation(
            operation: 'delete',
            folderPaths: ['folder1', 'folder2'],
            completed: 0,
            total: 2,
          ),
          const FoldersBatchOperation(
            operation: 'delete',
            folderPaths: ['folder1', 'folder2'],
            completed: 0,
            total: 2,
            currentFolder: 'folder1',
          ),
          const FoldersBatchOperation(
            operation: 'delete',
            folderPaths: ['folder1', 'folder2'],
            completed: 1,
            total: 2,
            currentFolder: 'folder2',
          ),
          isA<FoldersBatchOperationSuccess>()
              .having((state) => state.successCount, 'success count', equals(1))
              .having((state) => state.failureCount, 'failure count', equals(1))
              .having((state) => state.errors.length, 'errors count', equals(1)),
          isA<FoldersLoaded>(),
        ],
      );
    });

    group('ExpandAllFoldersEvent', () {
      final testFolders = [
        FolderNode(
          folderPath: 'folder1',
          name: 'Folder 1',
          created: DateTime(2024, 1, 1),
          updated: DateTime(2024, 1, 1),
          subFolders: [
            FolderNode(
              folderPath: 'folder1/subfolder',
              name: 'Subfolder',
              created: DateTime(2024, 1, 1),
              updated: DateTime(2024, 1, 1),
            ),
          ],
        ),
      ];

      setUp(() async {
        when(mockRepository.loadFolders(rootPath: any))
            .thenAnswer((_) async => testFolders);
        
        foldersBloc.add(const LoadFoldersEvent());
        await Future.delayed(const Duration(milliseconds: 10));
      });

      blocTest<FoldersBloc, FoldersState>(
        '应该展开所有文件夹',
        build: () => foldersBloc,
        act: (bloc) => bloc.add(const ExpandAllFoldersEvent()),
        skip: 2, // 跳过加载状态
        expect: () => [
          isA<FoldersLoaded>()
              .having((state) => state.expandedFolders.length, 'expanded count', greaterThan(0)),
        ],
      );
    });

    group('CollapseAllFoldersEvent', () {
      setUp(() async {
        when(mockRepository.loadFolders(rootPath: any))
            .thenAnswer((_) async => []);
        
        foldersBloc.add(const LoadFoldersEvent());
        await Future.delayed(const Duration(milliseconds: 10));
        foldersBloc.add(const ExpandFolderEvent(folderPath: 'folder1'));
        await Future.delayed(const Duration(milliseconds: 10));
      });

      blocTest<FoldersBloc, FoldersState>(
        '应该折叠所有文件夹',
        build: () => foldersBloc,
        act: (bloc) => bloc.add(const CollapseAllFoldersEvent()),
        skip: 4, // 跳过加载和展开状态
        expect: () => [
          isA<FoldersLoaded>()
              .having((state) => state.expandedFolders.isEmpty, 'all collapsed', isTrue),
        ],
      );
    });

    group('RefreshFolderEvent', () {
      blocTest<FoldersBloc, FoldersState>(
        '应该刷新文件夹',
        build: () {
          when(mockRepository.loadFolders(rootPath: any))
              .thenAnswer((_) async => []);
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const RefreshFolderEvent()),
        expect: () => [
          const FoldersLoading(),
          isA<FoldersLoaded>(),
        ],
        verify: (bloc) {
          verify(mockRepository.loadFolders(rootPath: null)).called(1);
        },
      );
    });

    group('UpdateFolderMetadataEvent', () {
      final existingFolder = FolderNode(
        folderPath: 'folder1',
        name: 'Folder 1',
        created: DateTime(2024, 1, 1),
        updated: DateTime(2024, 1, 1),
      );

      final updatedFolder = FolderNode(
        folderPath: 'folder1',
        name: 'Folder 1',
        created: DateTime(2024, 1, 1),
        updated: DateTime(2024, 1, 3),
        description: 'Updated description',
        color: '#FF0000',
      );

      blocTest<FoldersBloc, FoldersState>(
        '应该更新文件夹元数据',
        build: () {
          when(mockRepository.getFolder('folder1'))
              .thenAnswer((_) async => existingFolder);
          when(mockRepository.updateFolder(any))
              .thenAnswer((_) async => updatedFolder);
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const UpdateFolderMetadataEvent(
          folderPath: 'folder1',
          metadata: {
            'description': 'Updated description',
            'color': '#FF0000',
          },
        )),
        expect: () => [
          const FolderOperationInProgress(
            operation: 'update_metadata',
            folderPath: 'folder1',
            message: 'Updating folder metadata...',
          ),
          isA<FolderOperationSuccess>()
              .having((state) => state.operation, 'operation', equals('update_metadata'))
              .having((state) => state.folder?.description, 'description', equals('Updated description')),
          isA<FoldersLoaded>(),
        ],
        verify: (bloc) {
          verify(mockRepository.getFolder('folder1')).called(1);
          verify(mockRepository.updateFolder(any)).called(1);
        },
      );

      blocTest<FoldersBloc, FoldersState>(
        '更新不存在的文件夹应该失败',
        build: () {
          when(mockRepository.getFolder('nonexistent'))
              .thenAnswer((_) async => null);
          return foldersBloc;
        },
        act: (bloc) => bloc.add(const UpdateFolderMetadataEvent(
          folderPath: 'nonexistent',
          metadata: {'description': 'test'},
        )),
        expect: () => [
          const FolderOperationInProgress(
            operation: 'update_metadata',
            folderPath: 'nonexistent',
            message: 'Updating folder metadata...',
          ),
          isA<FolderOperationError>()
              .having((state) => state.operation, 'operation', equals('update_metadata'))
              .having((state) => state.message, 'error message', 
                      contains('Folder not found')),
        ],
      );
    });
  });

  group('FoldersBloc 辅助方法', () {
    test('应该正确检查文件夹展开状态', () {
      expect(foldersBloc.isFolderExpanded('folder1'), isFalse);
    });

    test('应该正确检查文件夹选中状态', () {
      expect(foldersBloc.isFolderSelected('folder1'), isFalse);
    });

    test('应该返回当前选中的文件夹路径', () {
      expect(foldersBloc.selectedFolderPath, isNull);
    });

    test('应该返回当前展开的文件夹集合', () {
      expect(foldersBloc.expandedFolders, isEmpty);
    });
  });
}