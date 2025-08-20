import 'package:flutter/material.dart';

import '../../domain/entities/folder_node.dart';

/// 文件夹右键菜单
class FolderContextMenu {
  /// 构建右键菜单项
  static List<PopupMenuEntry<String>> buildMenuItems({
    required BuildContext context,
    required FolderNode folder,
    VoidCallback? onCreateSubfolder,
    VoidCallback? onCreateNote,
    VoidCallback? onRename,
    VoidCallback? onDelete,
    VoidCallback? onCopy,
    VoidCallback? onCut,
    VoidCallback? onPaste,
    VoidCallback? onRefresh,
    VoidCallback? onProperties,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return [
      // 新建子文件夹
      PopupMenuItem<String>(
        value: 'create_subfolder',
        child: _buildMenuItem(
          icon: Icons.create_new_folder,
          text: '新建子文件夹',
          iconColor: colorScheme.primary,
        ),
        onTap: onCreateSubfolder,
      ),
      
      // 新建笔记
      PopupMenuItem<String>(
        value: 'create_note',
        child: _buildMenuItem(
          icon: Icons.note_add,
          text: '新建笔记',
          iconColor: colorScheme.primary,
        ),
        onTap: onCreateNote,
      ),

      const PopupMenuDivider(),

      // 重命名
      PopupMenuItem<String>(
        value: 'rename',
        child: _buildMenuItem(
          icon: Icons.edit,
          text: '重命名',
        ),
        onTap: onRename,
      ),

      // 删除
      PopupMenuItem<String>(
        value: 'delete',
        child: _buildMenuItem(
          icon: Icons.delete,
          text: '删除',
          iconColor: colorScheme.error,
          textColor: colorScheme.error,
        ),
        onTap: onDelete,
      ),

      const PopupMenuDivider(),

      // 复制
      PopupMenuItem<String>(
        value: 'copy',
        child: _buildMenuItem(
          icon: Icons.copy,
          text: '复制',
        ),
        onTap: onCopy,
      ),

      // 剪切
      PopupMenuItem<String>(
        value: 'cut',
        child: _buildMenuItem(
          icon: Icons.content_cut,
          text: '剪切',
        ),
        onTap: onCut,
      ),

      // 粘贴
      PopupMenuItem<String>(
        value: 'paste',
        child: _buildMenuItem(
          icon: Icons.content_paste,
          text: '粘贴',
        ),
        onTap: onPaste,
      ),

      const PopupMenuDivider(),

      // 刷新
      PopupMenuItem<String>(
        value: 'refresh',
        child: _buildMenuItem(
          icon: Icons.refresh,
          text: '刷新',
        ),
        onTap: onRefresh,
      ),

      // 属性
      PopupMenuItem<String>(
        value: 'properties',
        child: _buildMenuItem(
          icon: Icons.info_outline,
          text: '属性',
        ),
        onTap: onProperties,
      ),
    ];
  }

  /// 构建菜单项
  static Widget _buildMenuItem({
    required IconData icon,
    required String text,
    Color? iconColor,
    Color? textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: iconColor,
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(color: textColor),
        ),
      ],
    );
  }

  /// 显示右键菜单
  static Future<String?> show({
    required BuildContext context,
    required Offset position,
    required FolderNode folder,
    VoidCallback? onCreateSubfolder,
    VoidCallback? onCreateNote,
    VoidCallback? onRename,
    VoidCallback? onDelete,
    VoidCallback? onCopy,
    VoidCallback? onCut,
    VoidCallback? onPaste,
    VoidCallback? onRefresh,
    VoidCallback? onProperties,
  }) {
    return showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: buildMenuItems(
        context: context,
        folder: folder,
        onCreateSubfolder: onCreateSubfolder,
        onCreateNote: onCreateNote,
        onRename: onRename,
        onDelete: onDelete,
        onCopy: onCopy,
        onCut: onCut,
        onPaste: onPaste,
        onRefresh: onRefresh,
        onProperties: onProperties,
      ),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

/// 文件夹操作对话框集合
class FolderDialogs {
  /// 显示创建文件夹对话框
  static Future<String?> showCreateFolderDialog({
    required BuildContext context,
    required String parentPath,
    String title = '新建文件夹',
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => _CreateFolderDialog(
        title: title,
        parentPath: parentPath,
      ),
    );
  }

  /// 显示重命名文件夹对话框
  static Future<String?> showRenameFolderDialog({
    required BuildContext context,
    required FolderNode folder,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => _RenameFolderDialog(folder: folder),
    );
  }

  /// 显示删除确认对话框
  static Future<bool?> showDeleteConfirmDialog({
    required BuildContext context,
    required FolderNode folder,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmDialog(folder: folder),
    );
  }

  /// 显示文件夹属性对话框
  static Future<void> showPropertiesDialog({
    required BuildContext context,
    required FolderNode folder,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => _PropertiesDialog(folder: folder),
    );
  }
}

/// 创建文件夹对话框
class _CreateFolderDialog extends StatefulWidget {
  final String title;
  final String parentPath;

  const _CreateFolderDialog({
    required this.title,
    required this.parentPath,
  });

  @override
  State<_CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<_CreateFolderDialog> {
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
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.parentPath.isNotEmpty) ...[
              Text('父文件夹: ${widget.parentPath}'),
              const SizedBox(height: 16),
            ],
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
                if (value.length > 255) {
                  return '文件夹名称不能超过255个字符';
                }
                return null;
              },
              onFieldSubmitted: (_) => _confirm(),
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
          onPressed: _confirm,
          child: const Text('创建'),
        ),
      ],
    );
  }

  void _confirm() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }
}

/// 重命名文件夹对话框
class _RenameFolderDialog extends StatefulWidget {
  final FolderNode folder;

  const _RenameFolderDialog({required this.folder});

  @override
  State<_RenameFolderDialog> createState() => _RenameFolderDialogState();
}

class _RenameFolderDialogState extends State<_RenameFolderDialog> {
  late TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.folder.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('重命名文件夹'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '文件夹名称',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入文件夹名称';
            }
            if (value.contains('/') || value.contains('\\')) {
              return '文件夹名称不能包含 / 或 \\ 字符';
            }
            if (value.length > 255) {
              return '文件夹名称不能超过255个字符';
            }
            if (value.trim() == widget.folder.name) {
              return '新名称不能与原名称相同';
            }
            return null;
          },
          onFieldSubmitted: (_) => _confirm(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _confirm,
          child: const Text('重命名'),
        ),
      ],
    );
  }

  void _confirm() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }
}

/// 删除确认对话框
class _DeleteConfirmDialog extends StatelessWidget {
  final FolderNode folder;

  const _DeleteConfirmDialog({required this.folder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasContent = folder.subFolders.isNotEmpty || folder.notes.isNotEmpty;

    return AlertDialog(
      title: const Text('删除文件夹'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('确定要删除文件夹 "${folder.name}" 吗？'),
          if (hasContent) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '警告',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '此文件夹包含：',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  if (folder.subFolders.isNotEmpty)
                    Text(
                      '• ${folder.subFolders.length} 个子文件夹',
                      style: theme.textTheme.bodySmall,
                    ),
                  if (folder.notes.isNotEmpty)
                    Text(
                      '• ${folder.notes.length} 个笔记',
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    '删除后无法恢复！',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: const Text('删除'),
        ),
      ],
    );
  }
}

/// 文件夹属性对话框
class _PropertiesDialog extends StatelessWidget {
  final FolderNode folder;

  const _PropertiesDialog({required this.folder});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = folder.stats;

    return AlertDialog(
      title: Text('文件夹属性 - ${folder.name}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoCard(
              context,
              title: '基本信息',
              children: [
                _buildInfoRow('名称', folder.name),
                _buildInfoRow('路径', folder.folderPath),
                _buildInfoRow('深度', '第 ${folder.depth + 1} 层'),
                if (folder.description != null)
                  _buildInfoRow('描述', folder.description!),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              title: '统计信息',
              children: [
                _buildInfoRow('直接子文件夹', '${stats.directSubfolders} 个'),
                _buildInfoRow('总子文件夹', '${stats.totalFolders} 个'),
                _buildInfoRow('直接笔记', '${stats.directNotes} 个'),
                _buildInfoRow('总笔记数', '${stats.totalNotes} 个'),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              title: '时间信息',
              children: [
                _buildInfoRow('创建时间', _formatDateTime(folder.created)),
                _buildInfoRow('修改时间', _formatDateTime(folder.updated)),
                _buildInfoRow('最后活动', _formatDateTime(stats.lastModified)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}