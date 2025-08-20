import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cherry_note/features/folders/domain/entities/folder_node.dart';
import 'package:cherry_note/features/folders/presentation/widgets/folder_context_menu.dart';
import 'package:cherry_note/features/notes/domain/entities/note_file.dart';

void main() {
  group('FolderContextMenu', () {
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
      String? description,
    }) {
      return FolderNode(
        folderPath: path,
        name: name,
        created: DateTime.now(),
        updated: DateTime.now(),
        subFolders: subFolders,
        notes: List.generate(noteCount, (index) => createTestNote('note_$index')),
        description: description,
      );
    }

    Widget createTestApp({required Widget child}) {
      return MaterialApp(
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('should build menu items correctly', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');
      bool createSubfolderCalled = false;
      bool renameCalled = false;
      bool deleteCalled = false;

      // Act
      await tester.pumpWidget(createTestApp(
        child: Builder(
          builder: (context) {
            final menuItems = FolderContextMenu.buildMenuItems(
              context: context,
              folder: folder,
              onCreateSubfolder: () => createSubfolderCalled = true,
              onRename: () => renameCalled = true,
              onDelete: () => deleteCalled = true,
            );

            return Column(
              children: menuItems.map((item) {
                if (item is PopupMenuItem<String>) {
                  return GestureDetector(
                    onTap: item.onTap,
                    child: item.child,
                  );
                }
                return const Divider();
              }).toList(),
            );
          },
        ),
      ));

      // Assert
      expect(find.text('新建子文件夹'), findsOneWidget);
      expect(find.text('新建笔记'), findsOneWidget);
      expect(find.text('重命名'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
      expect(find.text('复制'), findsOneWidget);
      expect(find.text('剪切'), findsOneWidget);
      expect(find.text('粘贴'), findsOneWidget);
      expect(find.text('刷新'), findsOneWidget);
      expect(find.text('属性'), findsOneWidget);
    });

    testWidgets('should call callbacks when menu items are tapped', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');
      bool createSubfolderCalled = false;
      bool renameCalled = false;
      bool deleteCalled = false;

      // Act
      await tester.pumpWidget(createTestApp(
        child: Builder(
          builder: (context) {
            final menuItems = FolderContextMenu.buildMenuItems(
              context: context,
              folder: folder,
              onCreateSubfolder: () => createSubfolderCalled = true,
              onRename: () => renameCalled = true,
              onDelete: () => deleteCalled = true,
            );

            return Column(
              children: menuItems.map((item) {
                if (item is PopupMenuItem<String>) {
                  return GestureDetector(
                    onTap: item.onTap,
                    child: item.child,
                  );
                }
                return const Divider();
              }).toList(),
            );
          },
        ),
      ));

      // 测试各个回调
      await tester.tap(find.text('新建子文件夹'));
      expect(createSubfolderCalled, isTrue);

      await tester.tap(find.text('重命名'));
      expect(renameCalled, isTrue);

      await tester.tap(find.text('删除'));
      expect(deleteCalled, isTrue);
    });

    testWidgets('should show menu with correct icons', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createTestApp(
        child: Builder(
          builder: (context) {
            final menuItems = FolderContextMenu.buildMenuItems(
              context: context,
              folder: folder,
            );

            return Column(
              children: menuItems.map((item) {
                if (item is PopupMenuItem<String>) {
                  return item.child;
                }
                return const Divider();
              }).toList(),
            );
          },
        ),
      ));

      // Assert
      expect(find.byIcon(Icons.create_new_folder), findsOneWidget);
      expect(find.byIcon(Icons.note_add), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
      expect(find.byIcon(Icons.content_cut), findsOneWidget);
      expect(find.byIcon(Icons.content_paste), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });
  });

  group('FolderDialogs', () {
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
      String? description,
    }) {
      return FolderNode(
        folderPath: path,
        name: name,
        created: DateTime.now(),
        updated: DateTime.now(),
        subFolders: subFolders,
        notes: List.generate(noteCount, (index) => createTestNote('note_$index')),
        description: description,
      );
    }

    testWidgets('should show create folder dialog', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FolderDialogs.showCreateFolderDialog(
                context: context,
                parentPath: '/parent',
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('新建文件夹'), findsOneWidget);
      expect(find.text('父文件夹: /parent'), findsOneWidget);
      expect(find.text('文件夹名称'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('创建'), findsOneWidget);
    });

    testWidgets('should validate folder name in create dialog', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FolderDialogs.showCreateFolderDialog(
                context: context,
                parentPath: '/parent',
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 尝试提交空名称
      await tester.tap(find.text('创建'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('请输入文件夹名称'), findsOneWidget);
    });

    testWidgets('should reject invalid characters in create dialog', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FolderDialogs.showCreateFolderDialog(
                context: context,
                parentPath: '/parent',
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 输入包含非法字符的名称
      await tester.enterText(find.byType(TextFormField), 'invalid/name');
      await tester.tap(find.text('创建'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('文件夹名称不能包含 / 或 \\ 字符'), findsOneWidget);
    });

    testWidgets('should show rename folder dialog', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FolderDialogs.showRenameFolderDialog(
                context: context,
                folder: folder,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('重命名文件夹'), findsOneWidget);
      expect(find.text('Test Folder'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('重命名'), findsOneWidget);
    });

    testWidgets('should validate new name in rename dialog', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FolderDialogs.showRenameFolderDialog(
                context: context,
                folder: folder,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 清空输入并尝试提交
      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.text('重命名'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('请输入文件夹名称'), findsOneWidget);
    });

    testWidgets('should reject same name in rename dialog', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FolderDialogs.showRenameFolderDialog(
                context: context,
                folder: folder,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // 尝试提交相同的名称
      await tester.tap(find.text('重命名'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('新名称不能与原名称相同'), findsOneWidget);
    });

    testWidgets('should show delete confirmation dialog', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FolderDialogs.showDeleteConfirmDialog(
                context: context,
                folder: folder,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('删除文件夹'), findsOneWidget);
      expect(find.text('确定要删除文件夹 "Test Folder" 吗？'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
    });

    testWidgets('should show warning for folder with content', (tester) async {
      // Arrange
      final folder = createTestFolder(
        path: '/test',
        name: 'Test Folder',
        noteCount: 3,
        subFolders: [
          createTestFolder(path: '/test/sub', name: 'Sub Folder'),
        ],
      );

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FolderDialogs.showDeleteConfirmDialog(
                context: context,
                folder: folder,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('警告'), findsOneWidget);
      expect(find.text('• 1 个子文件夹'), findsOneWidget);
      expect(find.text('• 3 个笔记'), findsOneWidget);
      expect(find.text('删除后无法恢复！'), findsOneWidget);
    });

    testWidgets('should show properties dialog', (tester) async {
      // Arrange
      final folder = createTestFolder(
        path: '/test/folder',
        name: 'Test Folder',
        noteCount: 5,
        description: 'Test description',
      );

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FolderDialogs.showPropertiesDialog(
                context: context,
                folder: folder,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('文件夹属性 - Test Folder'), findsOneWidget);
      expect(find.text('基本信息'), findsOneWidget);
      expect(find.text('统计信息'), findsOneWidget);
      expect(find.text('时间信息'), findsOneWidget);
      expect(find.text('名称:'), findsOneWidget);
      expect(find.text('路径:'), findsOneWidget);
      expect(find.text('Test Folder'), findsAtLeastNWidgets(2)); // 标题和内容中都有
      expect(find.text('/test/folder'), findsOneWidget);
      expect(find.text('关闭'), findsOneWidget);
    });

    testWidgets('should display folder statistics correctly', (tester) async {
      // Arrange
      final subFolder = createTestFolder(
        path: '/test/folder/sub',
        name: 'Sub Folder',
        noteCount: 2,
      );
      final folder = createTestFolder(
        path: '/test/folder',
        name: 'Test Folder',
        noteCount: 3,
        subFolders: [subFolder],
      );

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FolderDialogs.showPropertiesDialog(
                context: context,
                folder: folder,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('直接子文件夹:'), findsOneWidget);
      expect(find.text('直接笔记:'), findsOneWidget);
      expect(find.text('总笔记数:'), findsOneWidget);
      expect(find.text('3 个'), findsOneWidget); // 直接笔记
      expect(find.text('5 个'), findsOneWidget); // 总笔记数 (3 + 2)
    });

    testWidgets('should close dialogs when cancel is tapped', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => FolderDialogs.showCreateFolderDialog(
                context: context,
                parentPath: '/parent',
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('新建文件夹'), findsOneWidget);

      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('新建文件夹'), findsNothing);
    });

    testWidgets('should return result when confirmed', (tester) async {
      // Arrange
      String? result;

      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await FolderDialogs.showCreateFolderDialog(
                  context: context,
                  parentPath: '/parent',
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'New Folder');
      await tester.tap(find.text('创建'));
      await tester.pumpAndSettle();

      // Assert
      expect(result, equals('New Folder'));
    });
  });
}