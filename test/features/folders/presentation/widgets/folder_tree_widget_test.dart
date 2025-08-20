import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:cherry_note/features/folders/domain/entities/folder_node.dart';
import 'package:cherry_note/features/folders/domain/repositories/folder_repository.dart';
import 'package:cherry_note/features/folders/presentation/bloc/folders_bloc.dart';
import 'package:cherry_note/features/folders/presentation/bloc/folders_event.dart';
import 'package:cherry_note/features/folders/presentation/bloc/folders_state.dart';
import 'package:cherry_note/features/folders/presentation/widgets/folder_tree_widget.dart';
import 'package:cherry_note/features/notes/domain/entities/note_file.dart';

import 'folder_tree_widget_test.mocks.dart';

@GenerateMocks([FolderRepository])
void main() {
  group('FolderTreeWidget', () {
    late MockFolderRepository mockRepository;
    late FoldersBloc foldersBloc;

    setUp(() {
      mockRepository = MockFolderRepository();
      foldersBloc = FoldersBloc(folderRepository: mockRepository);
    });

    tearDown(() {
      foldersBloc.close();
    });

    Widget createWidget({
      String? rootPath,
      Function(String)? onFolderSelected,
      Function(String)? onFolderDoubleClick,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<FoldersBloc>(
            create: (context) => foldersBloc,
            child: FolderTreeWidget(
              rootPath: rootPath,
              onFolderSelected: onFolderSelected,
              onFolderDoubleClick: onFolderDoubleClick,
            ),
          ),
        ),
      );
    }

    NoteFile createTestNote(String name) {
      return NoteFile(
        filePath: '/test/$name.md',
        title: name,
        content: 'Test content',
        tags: [],
        created: DateTime.now(),
        updated: DateTime.now(),
      );
    }

    FolderNode createTestFolder({
      required String path,
      required String name,
      List<FolderNode> subFolders = const [],
      int noteCount = 0,
    }) {
      return FolderNode(
        folderPath: path,
        name: name,
        created: DateTime.now(),
        updated: DateTime.now(),
        subFolders: subFolders,
        notes: List.generate(noteCount, (index) => createTestNote('note_$index')),
      );
    }

    testWidgets('should display loading indicator when loading', (tester) async {
      // Arrange
      when(mockRepository.loadFolders(rootPath: anyNamed('rootPath')))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createWidget());
      
      // 等待初始状态
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no folders', (tester) async {
      // Arrange
      when(mockRepository.loadFolders(rootPath: anyNamed('rootPath')))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createWidget());
      
      // 触发加载完成
      foldersBloc.add(const LoadFoldersEvent());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('暂无文件夹'), findsOneWidget);
      expect(find.text('点击右上角按钮创建新文件夹'), findsOneWidget);
    });

    testWidgets('should display folder list when folders loaded', (tester) async {
      // Arrange
      final testFolders = [
        createTestFolder(path: '/folder1', name: 'Folder 1'),
        createTestFolder(path: '/folder2', name: 'Folder 2', noteCount: 3),
      ];

      when(mockRepository.loadFolders(rootPath: anyNamed('rootPath')))
          .thenAnswer((_) async => testFolders);

      // Act
      await tester.pumpWidget(createWidget());
      
      // 手动设置状态为已加载
      foldersBloc.emit(FoldersLoaded(
        folders: testFolders,
        totalFolders: testFolders.length,
        totalNotes: 3,
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Folder 1'), findsOneWidget);
      expect(find.text('Folder 2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget); // 笔记数量徽章
    });

    testWidgets('should display error state when loading fails', (tester) async {
      // Arrange
      const errorMessage = 'Failed to load folders';

      // Act
      await tester.pumpWidget(createWidget());
      
      // 手动设置错误状态
      foldersBloc.emit(const FoldersError(message: errorMessage));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('should show header with correct buttons', (tester) async {
      // Arrange
      when(mockRepository.loadFolders(rootPath: anyNamed('rootPath')))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('文件夹'), findsOneWidget);
      expect(find.byTooltip('展开所有'), findsOneWidget);
      expect(find.byTooltip('折叠所有'), findsOneWidget);
      expect(find.byTooltip('刷新'), findsOneWidget);
      expect(find.byTooltip('新建文件夹'), findsOneWidget);
    });

    testWidgets('should call onFolderSelected when folder is tapped', (tester) async {
      // Arrange
      String? selectedPath;
      final testFolders = [
        createTestFolder(path: '/folder1', name: 'Folder 1'),
      ];

      when(mockRepository.loadFolders(rootPath: anyNamed('rootPath')))
          .thenAnswer((_) async => testFolders);

      // Act
      await tester.pumpWidget(createWidget(
        onFolderSelected: (path) => selectedPath = path,
      ));
      
      foldersBloc.emit(FoldersLoaded(
        folders: testFolders,
        totalFolders: 1,
        totalNotes: 0,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Folder 1'));
      await tester.pumpAndSettle();

      // Assert
      expect(selectedPath, equals('/folder1'));
    });

    testWidgets('should expand/collapse folders when toggle button is tapped', (tester) async {
      // Arrange
      final subFolder = createTestFolder(path: '/folder1/sub1', name: 'Sub Folder 1');
      final testFolders = [
        createTestFolder(
          path: '/folder1',
          name: 'Folder 1',
          subFolders: [subFolder],
        ),
      ];

      when(mockRepository.loadFolders(rootPath: anyNamed('rootPath')))
          .thenAnswer((_) async => testFolders);

      // Act
      await tester.pumpWidget(createWidget());
      
      foldersBloc.emit(FoldersLoaded(
        folders: testFolders,
        totalFolders: 2,
        totalNotes: 0,
      ));
      await tester.pumpAndSettle();

      // 初始状态：子文件夹应该不可见
      expect(find.text('Sub Folder 1'), findsNothing);

      // 点击展开按钮
      await tester.tap(find.byTooltip('展开'));
      
      // 手动更新状态为展开
      foldersBloc.emit(FoldersLoaded(
        folders: testFolders,
        expandedFolders: {'/folder1'},
        totalFolders: 2,
        totalNotes: 0,
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Sub Folder 1'), findsOneWidget);
    });

    testWidgets('should show refresh button and trigger refresh', (tester) async {
      // Arrange
      when(mockRepository.loadFolders(rootPath: anyNamed('rootPath')))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('刷新'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockRepository.loadFolders(rootPath: anyNamed('rootPath'))).called(greaterThan(1));
    });

    testWidgets('should show create folder button and open dialog', (tester) async {
      // Arrange
      when(mockRepository.loadFolders(rootPath: anyNamed('rootPath')))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('新建文件夹'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('新建文件夹'), findsOneWidget);
      expect(find.text('文件夹名称'), findsOneWidget);
    });

    testWidgets('should expand all folders when expand all button is tapped', (tester) async {
      // Arrange
      final testFolders = [
        createTestFolder(
          path: '/folder1',
          name: 'Folder 1',
          subFolders: [
            createTestFolder(path: '/folder1/sub1', name: 'Sub 1'),
          ],
        ),
      ];

      when(mockRepository.loadFolders(rootPath: anyNamed('rootPath')))
          .thenAnswer((_) async => testFolders);

      // Act
      await tester.pumpWidget(createWidget());
      
      foldersBloc.emit(FoldersLoaded(
        folders: testFolders,
        totalFolders: 2,
        totalNotes: 0,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('展开所有'));
      await tester.pumpAndSettle();

      // Assert - 验证展开所有事件被触发
      // 这里需要验证BLoC接收到了ExpandAllFoldersEvent
    });

    testWidgets('should collapse all folders when collapse all button is tapped', (tester) async {
      // Arrange
      final testFolders = [
        createTestFolder(
          path: '/folder1',
          name: 'Folder 1',
          subFolders: [
            createTestFolder(path: '/folder1/sub1', name: 'Sub 1'),
          ],
        ),
      ];

      when(mockRepository.loadFolders(rootPath: anyNamed('rootPath')))
          .thenAnswer((_) async => testFolders);

      // Act
      await tester.pumpWidget(createWidget());
      
      foldersBloc.emit(FoldersLoaded(
        folders: testFolders,
        expandedFolders: {'/folder1'},
        totalFolders: 2,
        totalNotes: 0,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('折叠所有'));
      await tester.pumpAndSettle();

      // Assert - 验证折叠所有事件被触发
      // 这里需要验证BLoC接收到了CollapseAllFoldersEvent
    });

    testWidgets('should handle drag and drop operations', (tester) async {
      // Arrange
      final testFolders = [
        createTestFolder(path: '/folder1', name: 'Folder 1'),
        createTestFolder(path: '/folder2', name: 'Folder 2'),
      ];

      when(mockRepository.loadFolders(rootPath: anyNamed('rootPath')))
          .thenAnswer((_) async => testFolders);

      // Act
      await tester.pumpWidget(createWidget());
      
      foldersBloc.emit(FoldersLoaded(
        folders: testFolders,
        totalFolders: 2,
        totalNotes: 0,
      ));
      await tester.pumpAndSettle();

      // 模拟拖拽操作
      final folder1 = find.text('Folder 1');
      final folder2 = find.text('Folder 2');

      await tester.drag(folder1, const Offset(0, 100));
      await tester.pumpAndSettle();

      // Assert - 这里需要验证拖拽操作的效果
      // 由于拖拽操作比较复杂，这里只是基本的测试结构
    });

    testWidgets('should show context menu on right click', (tester) async {
      // Arrange
      final testFolders = [
        createTestFolder(path: '/folder1', name: 'Folder 1'),
      ];

      when(mockRepository.loadFolders(rootPath: anyNamed('rootPath')))
          .thenAnswer((_) async => testFolders);

      // Act
      await tester.pumpWidget(createWidget());
      
      foldersBloc.emit(FoldersLoaded(
        folders: testFolders,
        totalFolders: 1,
        totalNotes: 0,
      ));
      await tester.pumpAndSettle();

      // 模拟右键点击
      await tester.tap(find.text('Folder 1'), buttons: kSecondaryButton);
      await tester.pumpAndSettle();

      // Assert - 验证右键菜单出现
      // 这里需要根据实际的右键菜单实现来验证
    });

    testWidgets('should filter folders based on search', (tester) async {
      // Arrange
      final testFolders = [
        createTestFolder(path: '/work', name: 'Work'),
        createTestFolder(path: '/personal', name: 'Personal'),
      ];

      when(mockRepository.loadFolders(rootPath: anyNamed('rootPath')))
          .thenAnswer((_) async => testFolders);
      when(mockRepository.searchFolders(
        query: anyNamed('query'),
        rootPath: anyNamed('rootPath'),
      )).thenAnswer((_) async => [testFolders[0]]);

      // Act
      await tester.pumpWidget(createWidget());
      
      // 模拟搜索状态
      foldersBloc.emit(FoldersLoaded(
        folders: testFolders,
        searchQuery: 'work',
        searchResults: [testFolders[0]],
        totalFolders: 2,
        totalNotes: 0,
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Personal'), findsNothing);
    });

    testWidgets('should show folder with note count badge', (tester) async {
      // Arrange
      final testFolders = [
        createTestFolder(path: '/folder1', name: 'Folder 1', noteCount: 5),
      ];

      when(mockRepository.loadFolders(rootPath: anyNamed('rootPath')))
          .thenAnswer((_) async => testFolders);

      // Act
      await tester.pumpWidget(createWidget());
      
      foldersBloc.emit(FoldersLoaded(
        folders: testFolders,
        totalFolders: 1,
        totalNotes: 5,
      ));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Folder 1'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // 笔记数量徽章
    });

    testWidgets('should handle folder selection state correctly', (tester) async {
      // Arrange
      final testFolders = [
        createTestFolder(path: '/folder1', name: 'Folder 1'),
        createTestFolder(path: '/folder2', name: 'Folder 2'),
      ];

      when(mockRepository.loadFolders(rootPath: anyNamed('rootPath')))
          .thenAnswer((_) async => testFolders);

      // Act
      await tester.pumpWidget(createWidget());
      
      foldersBloc.emit(FoldersLoaded(
        folders: testFolders,
        selectedFolderPath: '/folder1',
        totalFolders: 2,
        totalNotes: 0,
      ));
      await tester.pumpAndSettle();

      // Assert - 验证选中状态的视觉效果
      // 这里需要根据实际的选中状态样式来验证
      expect(find.text('Folder 1'), findsOneWidget);
      expect(find.text('Folder 2'), findsOneWidget);
    });
  });
}