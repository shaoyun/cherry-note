import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 应用菜单栏组件
class AppMenuBar extends StatelessWidget {
  final VoidCallback? onNewNote;
  final VoidCallback? onNewFolder;
  final VoidCallback? onOpenFile;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAs;
  final VoidCallback? onImport;
  final VoidCallback? onExport;
  final VoidCallback? onSettings;
  final VoidCallback? onAbout;
  final VoidCallback? onExit;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onCut;
  final VoidCallback? onCopy;
  final VoidCallback? onPaste;
  final VoidCallback? onSelectAll;
  final VoidCallback? onFind;
  final VoidCallback? onReplace;
  final VoidCallback? onTogglePreview;
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onResetZoom;
  final VoidCallback? onFullScreen;

  const AppMenuBar({
    super.key,
    this.onNewNote,
    this.onNewFolder,
    this.onOpenFile,
    this.onSave,
    this.onSaveAs,
    this.onImport,
    this.onExport,
    this.onSettings,
    this.onAbout,
    this.onExit,
    this.onUndo,
    this.onRedo,
    this.onCut,
    this.onCopy,
    this.onPaste,
    this.onSelectAll,
    this.onFind,
    this.onReplace,
    this.onTogglePreview,
    this.onToggleSidebar,
    this.onZoomIn,
    this.onZoomOut,
    this.onResetZoom,
    this.onFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    return MenuBar(
      children: [
        // 文件菜单
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: onNewNote,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyN, control: true),
              child: const CustomMenuAcceleratorLabel('新建笔记(&N)'),
            ),
            MenuItemButton(
              onPressed: onNewFolder,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyN, control: true, shift: true),
              child: const CustomMenuAcceleratorLabel('新建文件夹(&F)'),
            ),
            const MenuItemButton(
              onPressed: null,
              child: Divider(),
            ),
            MenuItemButton(
              onPressed: onOpenFile,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyO, control: true),
              child: const CustomMenuAcceleratorLabel('打开文件(&O)'),
            ),
            const MenuItemButton(
              onPressed: null,
              child: Divider(),
            ),
            MenuItemButton(
              onPressed: onSave,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyS, control: true),
              child: const CustomMenuAcceleratorLabel('保存(&S)'),
            ),
            MenuItemButton(
              onPressed: onSaveAs,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true),
              child: const CustomMenuAcceleratorLabel('另存为(&A)'),
            ),
            const MenuItemButton(
              onPressed: null,
              child: Divider(),
            ),
            MenuItemButton(
              onPressed: onImport,
              child: const CustomMenuAcceleratorLabel('导入(&I)'),
            ),
            MenuItemButton(
              onPressed: onExport,
              child: const CustomMenuAcceleratorLabel('导出(&E)'),
            ),
            const MenuItemButton(
              onPressed: null,
              child: Divider(),
            ),
            MenuItemButton(
              onPressed: onSettings,
              shortcut: const SingleActivator(LogicalKeyboardKey.comma, control: true),
              child: const CustomMenuAcceleratorLabel('设置(&P)'),
            ),
            const MenuItemButton(
              onPressed: null,
              child: Divider(),
            ),
            MenuItemButton(
              onPressed: onExit,
              shortcut: const SingleActivator(LogicalKeyboardKey.f4, alt: true),
              child: const CustomMenuAcceleratorLabel('退出(&X)'),
            ),
          ],
          child: const CustomMenuAcceleratorLabel('文件(&F)'),
        ),
        
        // 编辑菜单
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: onUndo,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyZ, control: true),
              child: const CustomMenuAcceleratorLabel('撤销(&U)'),
            ),
            MenuItemButton(
              onPressed: onRedo,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyY, control: true),
              child: const CustomMenuAcceleratorLabel('重做(&R)'),
            ),
            const MenuItemButton(
              onPressed: null,
              child: Divider(),
            ),
            MenuItemButton(
              onPressed: onCut,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyX, control: true),
              child: const CustomMenuAcceleratorLabel('剪切(&T)'),
            ),
            MenuItemButton(
              onPressed: onCopy,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyC, control: true),
              child: const CustomMenuAcceleratorLabel('复制(&C)'),
            ),
            MenuItemButton(
              onPressed: onPaste,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyV, control: true),
              child: const CustomMenuAcceleratorLabel('粘贴(&P)'),
            ),
            const MenuItemButton(
              onPressed: null,
              child: Divider(),
            ),
            MenuItemButton(
              onPressed: onSelectAll,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyA, control: true),
              child: const CustomMenuAcceleratorLabel('全选(&A)'),
            ),
            const MenuItemButton(
              onPressed: null,
              child: Divider(),
            ),
            MenuItemButton(
              onPressed: onFind,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyF, control: true),
              child: const CustomMenuAcceleratorLabel('查找(&F)'),
            ),
            MenuItemButton(
              onPressed: onReplace,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyH, control: true),
              child: const CustomMenuAcceleratorLabel('替换(&H)'),
            ),
          ],
          child: const CustomMenuAcceleratorLabel('编辑(&E)'),
        ),
        
        // 视图菜单
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: onTogglePreview,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyP, control: true, shift: true),
              child: const CustomMenuAcceleratorLabel('切换预览(&P)'),
            ),
            MenuItemButton(
              onPressed: onToggleSidebar,
              shortcut: const SingleActivator(LogicalKeyboardKey.keyB, control: true),
              child: const CustomMenuAcceleratorLabel('切换侧边栏(&S)'),
            ),
            const MenuItemButton(
              onPressed: null,
              child: Divider(),
            ),
            MenuItemButton(
              onPressed: onZoomIn,
              shortcut: const SingleActivator(LogicalKeyboardKey.equal, control: true),
              child: const CustomMenuAcceleratorLabel('放大(&I)'),
            ),
            MenuItemButton(
              onPressed: onZoomOut,
              shortcut: const SingleActivator(LogicalKeyboardKey.minus, control: true),
              child: const CustomMenuAcceleratorLabel('缩小(&O)'),
            ),
            MenuItemButton(
              onPressed: onResetZoom,
              shortcut: const SingleActivator(LogicalKeyboardKey.digit0, control: true),
              child: const CustomMenuAcceleratorLabel('重置缩放(&R)'),
            ),
            const MenuItemButton(
              onPressed: null,
              child: Divider(),
            ),
            MenuItemButton(
              onPressed: onFullScreen,
              shortcut: const SingleActivator(LogicalKeyboardKey.f11),
              child: const CustomMenuAcceleratorLabel('全屏(&F)'),
            ),
          ],
          child: const CustomMenuAcceleratorLabel('视图(&V)'),
        ),
        
        // 帮助菜单
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: onAbout,
              child: const CustomMenuAcceleratorLabel('关于(&A)'),
            ),
          ],
          child: const CustomMenuAcceleratorLabel('帮助(&H)'),
        ),
      ],
    );
  }
}

/// 自定义菜单加速键标签组件
class CustomMenuAcceleratorLabel extends StatelessWidget {
  final String label;
  
  const CustomMenuAcceleratorLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(label);
  }
}