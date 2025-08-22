import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cherry_note/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:cherry_note/features/notes/presentation/bloc/web_notes_bloc.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_event.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_state.dart';

/// 便签创建和管理组件
class StickyNoteWidget extends StatefulWidget {
  final VoidCallback? onStickyNoteCreated;
  final bool showCreateButton;

  const StickyNoteWidget({
    super.key,
    this.onStickyNoteCreated,
    this.showCreateButton = true,
  });

  @override
  State<StickyNoteWidget> createState() => _StickyNoteWidgetState();
}

class _StickyNoteWidgetState extends State<StickyNoteWidget> {
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<String> _tags = [];
  bool _isCreating = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? BlocListener<WebNotesBloc, NotesState>(
            listener: _handleBlocState,
            child: _buildContent(context),
          )
        : BlocListener<NotesBloc, NotesState>(
            listener: _handleBlocState,
            child: _buildContent(context),
          );
  }

  void _handleBlocState(BuildContext context, NotesState state) {
    if (state is NoteOperationSuccess && state.operation == 'create_sticky') {
      setState(() {
        _isCreating = false;
      });
      _clearForm();
      widget.onStickyNoteCreated?.call();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('便签创建成功'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (state is NoteOperationError && state.operation == 'create_sticky') {
      setState(() {
        _isCreating = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('便签创建失败: ${state.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } else if (state is NoteOperationInProgress && state.operation == 'create_sticky') {
      setState(() {
        _isCreating = true;
      });
    }
  }

  Widget _buildContent(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.sticky_note_2,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '快速便签',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 内容输入框
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '便签内容',
                  hintText: '记录你的想法、待办事项...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入便签内容';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 创建按钮
              if (widget.showCreateButton)
                ElevatedButton.icon(
                  onPressed: _isCreating ? null : _createStickyNote,
                  icon: _isCreating 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add, size: 18),
                  label: Text(_isCreating ? '创建中...' : '创建便签'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _createStickyNote() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final content = _contentController.text.trim();
    
    if (kIsWeb) {
      context.read<WebNotesBloc>().add(
        CreateStickyNoteEvent(
          content: content,
          tags: _tags.isNotEmpty ? _tags : null,
        ),
      );
    } else {
      context.read<NotesBloc>().add(
        CreateStickyNoteEvent(
          content: content,
          tags: _tags.isNotEmpty ? _tags : null,
        ),
      );
    }
  }

  void _clearForm() {
    _contentController.clear();
    setState(() {
      _tags = [];
    });
  }
}

/// 便签快速创建按钮
class StickyNoteQuickCreateButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? tooltip;

  const StickyNoteQuickCreateButton({
    super.key,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed ?? () => _showStickyNoteDialog(context),
      tooltip: tooltip ?? '创建便签',
      backgroundColor: Colors.amber,
      child: const Icon(
        Icons.sticky_note_2,
        color: Colors.white,
      ),
    );
  }

  void _showStickyNoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建便签'),
        content: SizedBox(
          width: 400,
          child: StickyNoteWidget(
            showCreateButton: true,
            onStickyNoteCreated: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}

/// 便签列表项组件
class StickyNoteListItem extends StatelessWidget {
  final String title;
  final String content;
  final List<String> tags;
  final DateTime created;
  final DateTime updated;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const StickyNoteListItem({
    super.key,
    required this.title,
    required this.content,
    required this.tags,
    required this.created,
    required this.updated,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和操作按钮
              Row(
                children: [
                  const Icon(
                    Icons.sticky_note_2,
                    color: Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 16),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('编辑'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // 内容预览
              if (content.isNotEmpty)
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              
              // 标签和时间
              Row(
                children: [
                  // 标签
                  if (tags.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: tags.take(3).map((tag) => Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 10),
                          ),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        )).toList(),
                      ),
                    ),
                  
                  // 创建时间
                  Text(
                    _formatDateTime(created),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}