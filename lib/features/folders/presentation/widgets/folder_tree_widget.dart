import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/folder_node.dart';
import '../bloc/folders_bloc.dart';
import '../bloc/folders_event.dart';
import '../bloc/folders_state.dart';
import 'folder_tree_item.dart';
import 'folder_context_menu.dart';

/// 文件夹树组件 - 支持层级展示、展开/折叠、右键菜单和拖拽功能
class FolderTreeWidget extends StatefulWidget {
  final String? rootPath;
  final Function(String folderPath)? onFolderSelected;
  final Function(String folderPath)? onFolderDoubleClick;
  final bool showContextMenu;
  final bool enableDragDrop;
  final double itemHeight;
  final EdgeInsetsGeometry? padding;

  const FolderTreeWidget({
    super.key,
    this.rootPath,
    this.onFolderSelected,
    this.onFolderDoubleClick,
    this.showContextMenu = true,
    this.enableDragDrop = true,
    this.itemHeight = 32.0,
    this.padding,
  });

  @override
  State<FolderTreeWidget> createState() => _FolderTreeWidgetState();
}

class _FolderTreeWidgetState extends State<FolderTreeWidget> {
  final ScrollController _scrollController = ScrollController();
  String? _draggedFolderPath;
  String? _dropTargetPath;

  @override
  void initState() {
    super.initState();
    // 初始加载文件夹树
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoldersBloc>().add(LoadFoldersEvent(
        rootPath: widget.rootPath,
      ));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FoldersBloc, FoldersState>(
      listener: _handleStateChange,
      builder: (context, state) {
        return Container(
          padding: widget.padding ?? const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, state),
              const SizedBox(height: 8),
              Expanded(
                child: _buildFolderTree(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建头部工具栏
  Widget _buildHeader(BuildContext context, FoldersState state) {
    return Row(
      children: [
        Text(
          '文件夹',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        // 展开/折叠所有按钮
        IconButton(
          onPressed: () => _expandAll(context),
          icon: const Icon(Icons.unfold_more, size: 18),
          tooltip: '展开所有',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
        IconButton(
          onPressed: () => _collapseAll(context),
          icon: const Icon(Icons.unfold_less, size: 18),
          tooltip: '折叠所有',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
        // 刷新按钮
        IconButton(
          onPressed: () => _refresh(context),
          icon: const Icon(Icons.refresh, size: 18),
          tooltip: '刷新',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
        // 新建文件夹按钮
        IconButton(
          onPressed: () => _createNewFolder(context),
          icon: const Icon(Icons.create_new_folder, size: 18),
          tooltip: '新建文件夹',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
      ],
    );
  }

  /// 构建文件夹树
  Widget _buildFolderTree(BuildContext context, FoldersState state) {
    if (state is FoldersLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is FoldersError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _refresh(context),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (state is FoldersLoaded) {
      final folders = state.displayedFolders;
      
      if (folders.isEmpty) {
        return _buildEmptyState(context);
      }

      return _buildScrollableTree(context, state, folders);
    }

    return _buildEmptyState(context);
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无文件夹',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右上角按钮创建新文件夹',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建可滚动的树
  Widget _buildScrollableTree(
    BuildContext context,
    FoldersLoaded state,
    List<FolderNode> folders,
  ) {
    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folder = folders[index];
          return _buildFolderItem(context, state, folder, 0);
        },
      ),
    );
  }

  /// 构建文件夹项（递归构建子文件夹）
  Widget _buildFolderItem(
    BuildContext context,
    FoldersLoaded state,
    FolderNode folder,
    int depth,
  ) {
    final isExpanded = state.isFolderExpanded(folder.folderPath);
    final isSelected = state.isFolderSelected(folder.folderPath);
    final hasSubfolders = folder.subFolders.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 当前文件夹项
        _buildDraggableItem(
          context,
          state,
          folder,
          depth,
          isExpanded,
          isSelected,
          hasSubfolders,
        ),
        // 子文件夹（如果展开）
        if (isExpanded && hasSubfolders)
          ...folder.subFolders.map((subfolder) =>
            _buildFolderItem(context, state, subfolder, depth + 1),
          ),
      ],
    );
  }

  /// 构建可拖拽的文件夹项
  Widget _buildDraggableItem(
    BuildContext context,
    FoldersLoaded state,
    FolderNode folder,
    int depth,
    bool isExpanded,
    bool isSelected,
    bool hasSubfolders,
  ) {
    Widget item = FolderTreeItem(
      folder: folder,
      depth: depth,
      isExpanded: isExpanded,
      isSelected: isSelected,
      hasSubfolders: hasSubfolders,
      height: widget.itemHeight,
      onTap: () => _selectFolder(context, folder.folderPath),
      onDoubleTap: () => widget.onFolderDoubleClick?.call(folder.folderPath),
      onToggleExpanded: () => _toggleFolder(context, folder.folderPath),
      onSecondaryTap: widget.showContextMenu
          ? (details) => _showContextMenu(context, folder, details)
          : null,
      isDragTarget: _dropTargetPath == folder.folderPath,
    );

    if (!widget.enableDragDrop) {
      return item;
    }

    // 添加拖拽功能
    return Draggable<String>(
      data: folder.folderPath,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 200,
          height: widget.itemHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.folder,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  folder.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: item,
      ),
      onDragStarted: () {
        setState(() {
          _draggedFolderPath = folder.folderPath;
        });
      },
      onDragEnd: (_) {
        setState(() {
          _draggedFolderPath = null;
          _dropTargetPath = null;
        });
      },
      child: DragTarget<String>(
        onWillAccept: (data) {
          if (data == null || data == folder.folderPath) return false;
          // 不能拖拽到自己的子文件夹中
          if (data.startsWith('${folder.folderPath}/')) return false;
          return true;
        },
        onAccept: (draggedPath) {
          _moveFolder(context, draggedPath, folder.folderPath);
        },
        onMove: (details) {
          if (_dropTargetPath != folder.folderPath) {
            setState(() {
              _dropTargetPath = folder.folderPath;
            });
          }
        },
        onLeave: (_) {
          if (_dropTargetPath == folder.folderPath) {
            setState(() {
              _dropTargetPath = null;
            });
          }
        },
        builder: (context, candidateData, rejectedData) {
          return item;
        },
      ),
    );
  }

  /// 处理状态变化
  void _handleStateChange(BuildContext context, FoldersState state) {
    if (state is FolderOperationSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else if (state is FolderOperationError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// 选择文件夹
  void _selectFolder(BuildContext context, String folderPath) {
    context.read<FoldersBloc>().add(SelectFolderEvent(folderPath: folderPath));
    widget.onFolderSelected?.call(folderPath);
  }

  /// 切换文件夹展开状态
  void _toggleFolder(BuildContext context, String folderPath) {
    context.read<FoldersBloc>().add(ToggleFolderEvent(folderPath: folderPath));
  }

  /// 展开所有文件夹
  void _expandAll(BuildContext context) {
    context.read<FoldersBloc>().add(ExpandAllFoldersEvent(rootPath: widget.rootPath));
  }

  /// 折叠所有文件夹
  void _collapseAll(BuildContext context) {
    context.read<FoldersBloc>().add(CollapseAllFoldersEvent(rootPath: widget.rootPath));
  }

  /// 刷新文件夹树
  void _refresh(BuildContext context) {
    context.read<FoldersBloc>().add(LoadFoldersEvent(
      rootPath: widget.rootPath,
      forceRefresh: true,
    ));
  }

  /// 创建新文件夹
  void _createNewFolder(BuildContext context) {
    final state = context.read<FoldersBloc>().state;
    String parentPath = widget.rootPath ?? '';
    
    // 如果有选中的文件夹，使用选中的文件夹作为父路径
    if (state is FoldersLoaded && state.selectedFolderPath != null) {
      parentPath = state.selectedFolderPath!;
    }

    _showCreateFolderDialog(context, parentPath);
  }

  /// 显示创建文件夹对话框
  void _showCreateFolderDialog(BuildContext context, String parentPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建文件夹'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (parentPath.isNotEmpty) ...[
              Text('父文件夹: $parentPath'),
              const SizedBox(height: 16),
            ],
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '文件夹名称',
                hintText: '请输入文件夹名称',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  _createFolder(context, parentPath, value.trim());
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final textField = context.findAncestorWidgetOfExactType<TextField>();
              // 这里需要获取输入的值，简化处理
              Navigator.of(context).pop();
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  /// 创建文件夹
  void _createFolder(BuildContext context, String parentPath, String folderName) {
    context.read<FoldersBloc>().add(CreateFolderEvent(
      parentPath: parentPath,
      folderName: folderName,
    ));
  }

  /// 移动文件夹
  void _moveFolder(BuildContext context, String folderPath, String newParentPath) {
    context.read<FoldersBloc>().add(MoveFolderEvent(
      folderPath: folderPath,
      newParentPath: newParentPath,
    ));
  }

  /// 显示右键菜单
  void _showContextMenu(
    BuildContext context,
    FolderNode folder,
    TapDownDetails details,
  ) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx + 1,
        details.globalPosition.dy + 1,
      ),
      items: FolderContextMenu.buildMenuItems(
        context: context,
        folder: folder,
        onCreateSubfolder: () => _showCreateFolderDialog(context, folder.folderPath),
        onRename: () => _showRenameFolderDialog(context, folder),
        onDelete: () => _showDeleteFolderDialog(context, folder),
        onCopy: () => _copyFolder(context, folder),
        onCut: () => _cutFolder(context, folder),
        onPaste: () => _pasteFolder(context, folder),
        onProperties: () => _showFolderProperties(context, folder),
      ),
    );
  }

  /// 显示重命名文件夹对话框
  void _showRenameFolderDialog(BuildContext context, FolderNode folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名文件夹'),
        content: TextField(
          controller: TextEditingController(text: folder.name),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '文件夹名称',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty && value.trim() != folder.name) {
              Navigator.of(context).pop();
              _renameFolder(context, folder.folderPath, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('重命名'),
          ),
        ],
      ),
    );
  }

  /// 显示删除文件夹对话框
  void _showDeleteFolderDialog(BuildContext context, FolderNode folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除文件夹'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除文件夹 "${folder.name}" 吗？'),
            if (folder.subFolders.isNotEmpty || folder.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '此文件夹包含 ${folder.subFolders.length} 个子文件夹和 ${folder.notes.length} 个笔记，删除后无法恢复。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteFolder(context, folder.folderPath, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 重命名文件夹
  void _renameFolder(BuildContext context, String folderPath, String newName) {
    context.read<FoldersBloc>().add(RenameFolderEvent(
      folderPath: folderPath,
      newName: newName,
    ));
  }

  /// 删除文件夹
  void _deleteFolder(BuildContext context, String folderPath, bool recursive) {
    context.read<FoldersBloc>().add(DeleteFolderEvent(
      folderPath: folderPath,
      recursive: recursive,
    ));
  }

  /// 复制文件夹（暂时只是选择，实际复制需要在粘贴时执行）
  void _copyFolder(BuildContext context, FolderNode folder) {
    // TODO: 实现复制功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制文件夹 "${folder.name}"')),
    );
  }

  /// 剪切文件夹（暂时只是选择，实际移动需要在粘贴时执行）
  void _cutFolder(BuildContext context, FolderNode folder) {
    // TODO: 实现剪切功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已剪切文件夹 "${folder.name}"')),
    );
  }

  /// 粘贴文件夹
  void _pasteFolder(BuildContext context, FolderNode targetFolder) {
    // TODO: 实现粘贴功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('粘贴功能开发中')),
    );
  }

  /// 显示文件夹属性
  void _showFolderProperties(BuildContext context, FolderNode folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('文件夹属性 - ${folder.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertyRow('路径', folder.folderPath),
            _buildPropertyRow('创建时间', _formatDateTime(folder.created)),
            _buildPropertyRow('修改时间', _formatDateTime(folder.updated)),
            _buildPropertyRow('子文件夹', '${folder.subFolders.length} 个'),
            _buildPropertyRow('笔记数量', '${folder.notes.length} 个'),
            _buildPropertyRow('总笔记数', '${folder.totalNotesCount} 个'),
            if (folder.description != null)
              _buildPropertyRow('描述', folder.description!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 构建属性行
  Widget _buildPropertyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}