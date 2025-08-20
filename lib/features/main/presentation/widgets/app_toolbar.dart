import 'package:flutter/material.dart';

/// 应用工具栏组件
class AppToolbar extends StatelessWidget {
  final VoidCallback? onNewNote;
  final VoidCallback? onNewFolder;
  final VoidCallback? onSave;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onTogglePreview;
  final VoidCallback? onToggleSidebar;
  final VoidCallback? onSearch;
  final VoidCallback? onSync;
  final VoidCallback? onSettings;
  final bool showSidebar;
  final bool showPreview;
  final bool isSyncing;
  final bool hasUnsavedChanges;

  const AppToolbar({
    super.key,
    this.onNewNote,
    this.onNewFolder,
    this.onSave,
    this.onUndo,
    this.onRedo,
    this.onTogglePreview,
    this.onToggleSidebar,
    this.onSearch,
    this.onSync,
    this.onSettings,
    this.showSidebar = true,
    this.showPreview = true,
    this.isSyncing = false,
    this.hasUnsavedChanges = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 文件操作组
          _buildToolbarGroup([
            _buildToolbarButton(
              context,
              icon: Icons.note_add,
              tooltip: '新建笔记 (Ctrl+N)',
              onPressed: onNewNote,
            ),
            _buildToolbarButton(
              context,
              icon: Icons.create_new_folder,
              tooltip: '新建文件夹 (Ctrl+Shift+N)',
              onPressed: onNewFolder,
            ),
          ]),
          
          _buildDivider(context),
          
          // 编辑操作组
          _buildToolbarGroup([
            _buildToolbarButton(
              context,
              icon: Icons.save,
              tooltip: '保存 (Ctrl+S)',
              onPressed: onSave,
              isHighlighted: hasUnsavedChanges,
            ),
            _buildToolbarButton(
              context,
              icon: Icons.undo,
              tooltip: '撤销 (Ctrl+Z)',
              onPressed: onUndo,
            ),
            _buildToolbarButton(
              context,
              icon: Icons.redo,
              tooltip: '重做 (Ctrl+Y)',
              onPressed: onRedo,
            ),
          ]),
          
          _buildDivider(context),
          
          // 视图操作组
          _buildToolbarGroup([
            _buildToolbarButton(
              context,
              icon: showSidebar ? Icons.menu_open : Icons.menu,
              tooltip: '切换侧边栏 (Ctrl+B)',
              onPressed: onToggleSidebar,
              isToggled: showSidebar,
            ),
            _buildToolbarButton(
              context,
              icon: showPreview ? Icons.preview : Icons.visibility_off,
              tooltip: '切换预览 (Ctrl+Shift+P)',
              onPressed: onTogglePreview,
              isToggled: showPreview,
            ),
          ]),
          
          _buildDivider(context),
          
          // 搜索
          _buildToolbarButton(
            context,
            icon: Icons.search,
            tooltip: '搜索 (Ctrl+F)',
            onPressed: onSearch,
          ),
          
          const Spacer(),
          
          // 同步状态和设置
          _buildToolbarGroup([
            _buildSyncButton(context),
            _buildToolbarButton(
              context,
              icon: Icons.settings,
              tooltip: '设置 (Ctrl+,)',
              onPressed: onSettings,
            ),
          ]),
        ],
      ),
    );
  }

  /// 构建工具栏按钮组
  Widget _buildToolbarGroup(List<Widget> buttons) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: buttons,
    );
  }

  /// 构建工具栏按钮
  Widget _buildToolbarButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
    bool isToggled = false,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: isToggled 
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          foregroundColor: isHighlighted
              ? Theme.of(context).colorScheme.error
              : isToggled
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : null,
        ),
      ),
    );
  }

  /// 构建同步按钮
  Widget _buildSyncButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            icon: Icon(isSyncing ? Icons.sync : Icons.cloud_sync),
            tooltip: isSyncing ? '同步中...' : '同步',
            onPressed: isSyncing ? null : onSync,
          ),
          if (isSyncing)
            Positioned.fill(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建分割线
  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Theme.of(context).dividerColor,
    );
  }
}

/// 紧凑工具栏（移动端）
class CompactAppToolbar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNewNote;
  final VoidCallback? onSearch;
  final VoidCallback? onSync;
  final VoidCallback? onMenu;
  final bool isSyncing;

  const CompactAppToolbar({
    super.key,
    this.onNewNote,
    this.onSearch,
    this.onSync,
    this.onMenu,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Cherry Note'),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenu,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: onSearch,
          tooltip: '搜索',
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(isSyncing ? Icons.sync : Icons.cloud_sync),
              onPressed: isSyncing ? null : onSync,
              tooltip: isSyncing ? '同步中...' : '同步',
            ),
            if (isSyncing)
              Positioned.fill(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: onNewNote,
          tooltip: '新建笔记',
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}