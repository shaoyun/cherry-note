import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cherry_note/features/folders/domain/entities/folder_node.dart';
import 'package:cherry_note/features/folders/presentation/widgets/folder_tree_item.dart';
import 'package:cherry_note/features/notes/domain/entities/note_file.dart';

void main() {
  group('FolderTreeItem', () {
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
      String? color,
      String? description,
    }) {
      return FolderNode(
        folderPath: path,
        name: name,
        created: DateTime.now(),
        updated: DateTime.now(),
        subFolders: subFolders,
        notes: List.generate(noteCount, (index) => createTestNote('note_$index')),
        color: color,
        description: description,
      );
    }

    Widget createWidget({
      required FolderNode folder,
      int depth = 0,
      bool isExpanded = false,
      bool isSelected = false,
      bool hasSubfolders = false,
      double height = 32.0,
      VoidCallback? onTap,
      VoidCallback? onDoubleTap,
      VoidCallback? onToggleExpanded,
      Function(TapDownDetails)? onSecondaryTap,
      bool isDragTarget = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: FolderTreeItem(
            folder: folder,
            depth: depth,
            isExpanded: isExpanded,
            isSelected: isSelected,
            hasSubfolders: hasSubfolders,
            height: height,
            onTap: onTap,
            onDoubleTap: onDoubleTap,
            onToggleExpanded: onToggleExpanded,
            onSecondaryTap: onSecondaryTap,
            isDragTarget: isDragTarget,
          ),
        ),
      );
    }

    testWidgets('should display folder name correctly', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(folder: folder));

      // Assert
      expect(find.text('Test Folder'), findsOneWidget);
    });

    testWidgets('should show folder icon', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(folder: folder));

      // Assert
      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('should show open folder icon when expanded', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(
        folder: folder,
        isExpanded: true,
        hasSubfolders: true,
      ));

      // Assert
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });

    testWidgets('should show expand button when has subfolders', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(
        folder: folder,
        hasSubfolders: true,
      ));

      // Assert
      expect(find.byTooltip('展开'), findsOneWidget);
    });

    testWidgets('should not show expand button when no subfolders', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(
        folder: folder,
        hasSubfolders: false,
      ));

      // Assert
      expect(find.byTooltip('展开'), findsNothing);
      expect(find.byTooltip('折叠'), findsNothing);
    });

    testWidgets('should show note count badge when folder has notes', (tester) async {
      // Arrange
      final folder = createTestFolder(
        path: '/test',
        name: 'Test Folder',
        noteCount: 5,
      );

      // Act
      await tester.pumpWidget(createWidget(folder: folder));

      // Assert
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('should not show note count badge when folder has no notes', (tester) async {
      // Arrange
      final folder = createTestFolder(
        path: '/test',
        name: 'Test Folder',
        noteCount: 0,
      );

      // Act
      await tester.pumpWidget(createWidget(folder: folder));

      // Assert
      expect(find.text('0'), findsNothing);
    });

    testWidgets('should apply correct indentation based on depth', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(
        folder: folder,
        depth: 2,
      ));

      // Assert
      // 验证缩进是否正确应用（depth * 16.0 = 32.0）
      final sizedBox = tester.widget<SizedBox>(
        find.byType(SizedBox).first,
      );
      expect(sizedBox.width, equals(32.0));
    });

    testWidgets('should call onTap when tapped', (tester) async {
      // Arrange
      bool tapped = false;
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(
        folder: folder,
        onTap: () => tapped = true,
      ));

      await tester.tap(find.text('Test Folder'));

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('should call onDoubleTap when double tapped', (tester) async {
      // Arrange
      bool doubleTapped = false;
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(
        folder: folder,
        onDoubleTap: () => doubleTapped = true,
      ));

      await tester.tap(find.text('Test Folder'));
      await tester.tap(find.text('Test Folder'));

      // Assert
      expect(doubleTapped, isTrue);
    });

    testWidgets('should call onToggleExpanded when expand button is tapped', (tester) async {
      // Arrange
      bool toggled = false;
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(
        folder: folder,
        hasSubfolders: true,
        onToggleExpanded: () => toggled = true,
      ));

      await tester.tap(find.byTooltip('展开'));

      // Assert
      expect(toggled, isTrue);
    });

    testWidgets('should show selected state styling', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(
        folder: folder,
        isSelected: true,
      ));

      // Assert
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
    });

    testWidgets('should show drag target styling', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(
        folder: folder,
        isDragTarget: true,
      ));

      // Assert
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('should show hover state when mouse enters', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(folder: folder));

      // 模拟鼠标悬停
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.text('Test Folder')));
      await tester.pumpAndSettle();

      // Assert
      // 验证悬停状态下显示操作按钮
      expect(find.byTooltip('新建子文件夹'), findsOneWidget);
      expect(find.byTooltip('更多操作'), findsOneWidget);
    });

    testWidgets('should use custom color for folder icon', (tester) async {
      // Arrange
      final folder = createTestFolder(
        path: '/test',
        name: 'Test Folder',
        color: '#FF5722',
      );

      // Act
      await tester.pumpWidget(createWidget(folder: folder));

      // Assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.folder));
      expect(icon.color, isNotNull);
    });

    testWidgets('should animate expand button rotation', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(
        folder: folder,
        hasSubfolders: true,
        isExpanded: false,
      ));

      // 初始状态
      await tester.pumpAndSettle();

      // 切换到展开状态
      await tester.pumpWidget(createWidget(
        folder: folder,
        hasSubfolders: true,
        isExpanded: true,
      ));

      // 等待动画完成
      await tester.pumpAndSettle();

      // Assert
      // 验证动画已完成（这里主要是确保没有异常）
      expect(find.byType(AnimatedBuilder), findsOneWidget);
    });

    testWidgets('should handle right click for context menu', (tester) async {
      // Arrange
      TapDownDetails? receivedDetails;
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(
        folder: folder,
        onSecondaryTap: (details) => receivedDetails = details,
      ));

      await tester.tap(find.text('Test Folder'), buttons: kSecondaryButton);

      // Assert
      expect(receivedDetails, isNotNull);
    });

    testWidgets('should show create subfolder dialog when action button is tapped', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(folder: folder));

      // 模拟鼠标悬停以显示操作按钮
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Test Folder')));
      await tester.pumpAndSettle();

      // 点击新建子文件夹按钮
      await tester.tap(find.byTooltip('新建子文件夹'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('新建子文件夹'), findsOneWidget);
      expect(find.text('父文件夹: Test Folder'), findsOneWidget);
    });

    testWidgets('should validate folder name in create subfolder dialog', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(folder: folder));

      // 显示对话框
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Test Folder')));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('新建子文件夹'));
      await tester.pumpAndSettle();

      // 尝试提交空名称
      await tester.tap(find.text('创建'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('请输入文件夹名称'), findsOneWidget);
    });

    testWidgets('should reject invalid characters in folder name', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(folder: folder));

      // 显示对话框
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Test Folder')));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('新建子文件夹'));
      await tester.pumpAndSettle();

      // 输入包含非法字符的名称
      await tester.enterText(find.byType(TextFormField), 'invalid/name');
      await tester.tap(find.text('创建'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('文件夹名称不能包含 / 或 \\ 字符'), findsOneWidget);
    });

    testWidgets('should handle different folder heights', (tester) async {
      // Arrange
      final folder = createTestFolder(path: '/test', name: 'Test Folder');

      // Act
      await tester.pumpWidget(createWidget(
        folder: folder,
        height: 48.0,
      ));

      // Assert
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(container.constraints?.maxHeight, equals(48.0));
    });

    testWidgets('should truncate long folder names', (tester) async {
      // Arrange
      final folder = createTestFolder(
        path: '/test',
        name: 'This is a very long folder name that should be truncated',
      );

      // Act
      await tester.pumpWidget(createWidget(folder: folder));

      // Assert
      final text = tester.widget<Text>(
        find.text('This is a very long folder name that should be truncated'),
      );
      expect(text.overflow, equals(TextOverflow.ellipsis));
      expect(text.maxLines, equals(1));
    });
  });
}