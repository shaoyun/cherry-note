import 'package:flutter/material.dart';

import '../../domain/entities/folder_node.dart';

/// 文件夹树项组件 - 单个文件夹的显示项
class FolderTreeItem extends StatefulWidget {
  final FolderNode folder;
  final int depth;
  final bool isExpanded;
  final bool isSelected;
  final bool hasSubfolders;
  final double height;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onToggleExpanded;
  final Function(TapDownDetails)? onSecondaryTap;
  final bool isDragTarget;

  const FolderTreeItem({
    super.key,
    required this.folder,
    required this.depth,
    required this.isExpanded,
    required this.isSelected,
    required this.hasSubfolders,
    required this.height,
    this.onTap,
    this.onDoubleTap,
    this.onToggleExpanded,
    this.onSecondaryTap,
    this.isDragTarget = false,
  });

  @override
  State<FolderTreeItem> createState() => _FolderTreeItemState();
}

class _FolderTreeItemState extends State<FolderTreeItem>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (widget.isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(FolderTreeItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onSecondaryTapDown: widget.onSecondaryTap,
        child: Container(
          height: widget.height,
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: _getBackgroundColor(colorScheme),
            borderRadius: BorderRadius.circular(4),
            border: widget.isDragTarget
                ? Border.all(
                    color: colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Row(
            children: [
              // 缩进
              SizedBox(width: widget.depth * 16.0),
              // 展开/折叠按钮
              _buildExpandButton(),
              // 文件夹图标
              _buildFolderIcon(colorScheme),
              const SizedBox(width: 8),
              // 文件夹名称
              Expanded(
                child: _buildFolderName(theme),
              ),
              // 笔记数量徽章
              if (widget.folder.notes.isNotEmpty)
                _buildNoteBadge(colorScheme),
              // 操作按钮（悬停时显示）
              if (_isHovered) _buildActionButtons(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取背景颜色
  Color _getBackgroundColor(ColorScheme colorScheme) {
    if (widget.isSelected) {
      return colorScheme.primaryContainer;
    }
    if (_isHovered) {
      return colorScheme.surfaceVariant.withOpacity(0.5);
    }
    if (widget.isDragTarget) {
      return colorScheme.primaryContainer.withOpacity(0.3);
    }
    return Colors.transparent;
  }

  /// 构建展开/折叠按钮
  Widget _buildExpandButton() {
    if (!widget.hasSubfolders) {
      return const SizedBox(width: 24);
    }

    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        onPressed: widget.onToggleExpanded,
        padding: EdgeInsets.zero,
        iconSize: 16,
        icon: AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _expandAnimation.value * 1.5708, // 90 degrees in radians
              child: const Icon(Icons.chevron_right),
            );
          },
        ),
        tooltip: widget.isExpanded ? '折叠' : '展开',
      ),
    );
  }

  /// 构建文件夹图标
  Widget _buildFolderIcon(ColorScheme colorScheme) {
    IconData iconData;
    Color? iconColor;

    if (widget.hasSubfolders && widget.isExpanded) {
      iconData = Icons.folder_open;
    } else {
      iconData = Icons.folder;
    }

    // 使用自定义颜色（如果有）
    if (widget.folder.color != null) {
      try {
        iconColor = Color(int.parse(widget.folder.color!.replaceFirst('#', '0xFF')));
      } catch (e) {
        iconColor = null;
      }
    }

    iconColor ??= widget.isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.primary;

    return Icon(
      iconData,
      size: 18,
      color: iconColor,
    );
  }

  /// 构建文件夹名称
  Widget _buildFolderName(ThemeData theme) {
    return Text(
      widget.folder.name,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: widget.isSelected
            ? theme.colorScheme.onPrimaryContainer
            : null,
        fontWeight: widget.isSelected ? FontWeight.w500 : null,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  /// 构建笔记数量徽章
  Widget _buildNoteBadge(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${widget.folder.notes.length}',
        style: TextStyle(
          fontSize: 10,
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 添加子文件夹按钮
        _buildActionButton(
          icon: Icons.create_new_folder,
          tooltip: '新建子文件夹',
          onPressed: () => _createSubfolder(),
        ),
        // 更多操作按钮
        _buildActionButton(
          icon: Icons.more_vert,
          tooltip: '更多操作',
          onPressed: () => _showMoreActions(),
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 24,
      height: 24,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        iconSize: 14,
        icon: Icon(icon),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  /// 创建子文件夹
  void _createSubfolder() {
    // 触发父组件的创建子文件夹逻辑
    // 这里可以通过回调或者事件来实现
    showDialog(
      context: context,
      builder: (context) => _CreateSubfolderDialog(
        parentFolder: widget.folder,
      ),
    );
  }

  /// 显示更多操作
  void _showMoreActions() {
    // 触发右键菜单
    if (widget.onSecondaryTap != null) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      widget.onSecondaryTap!(TapDownDetails(
        globalPosition: Offset(
          position.dx + renderBox.size.width,
          position.dy + renderBox.size.height / 2,
        ),
      ));
    }
  }
}

/// 创建子文件夹对话框
class _CreateSubfolderDialog extends StatefulWidget {
  final FolderNode parentFolder;

  const _CreateSubfolderDialog({
    required this.parentFolder,
  });

  @override
  State<_CreateSubfolderDialog> createState() => _CreateSubfolderDialogState();
}

class _CreateSubfolderDialogState extends State<_CreateSubfolderDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建子文件夹'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('父文件夹: ${widget.parentFolder.name}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '文件夹名称',
                hintText: '请输入文件夹名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入文件夹名称';
                }
                if (value.contains('/') || value.contains('\\')) {
                  return '文件夹名称不能包含 / 或 \\ 字符';
                }
                return null;
              },
              onFieldSubmitted: (_) => _createFolder(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _createFolder,
          child: const Text('创建'),
        ),
      ],
    );
  }

  void _createFolder() {
    if (_formKey.currentState?.validate() ?? false) {
      final folderName = _controller.text.trim();
      Navigator.of(context).pop(folderName);
      
      // TODO: 触发创建文件夹事件
      // 这里需要通过BLoC或者回调来创建文件夹
    }
  }
}