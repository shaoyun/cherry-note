import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cherry_note/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:cherry_note/features/notes/presentation/bloc/web_notes_bloc.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_event.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_state.dart';
import 'package:cherry_note/features/notes/presentation/widgets/sticky_note_widget.dart';
import 'package:cherry_note/features/notes/domain/entities/note_file.dart';
import 'package:cherry_note/shared/widgets/loading_widget.dart';
import 'package:cherry_note/shared/widgets/error_widget.dart' as CustomErrorWidget;

/// 便签页面
class StickyNotesPage extends StatefulWidget {
  const StickyNotesPage({super.key});

  @override
  State<StickyNotesPage> createState() => _StickyNotesPageState();
}

class _StickyNotesPageState extends State<StickyNotesPage> {
  @override
  void initState() {
    super.initState();
    _loadStickyNotes();
  }

  void _loadStickyNotes() {
    if (kIsWeb) {
      context.read<WebNotesBloc>().add(const LoadStickyNotesEvent());
    } else {
      context.read<NotesBloc>().add(const LoadStickyNotesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('便签'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStickyNotes,
            tooltip: '刷新',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateStickyNoteDialog(context),
            tooltip: '创建便签',
          ),
        ],
      ),
      body: Column(
        children: [
          // 快速创建便签区域
          Container(
            padding: const EdgeInsets.all(16),
            child: StickyNoteWidget(
              onStickyNoteCreated: _loadStickyNotes,
            ),
          ),
          
          const Divider(),
          
          // 便签列表
          Expanded(
            child: kIsWeb
                ? BlocBuilder<WebNotesBloc, NotesState>(
                    builder: (context, state) => _buildStickyNotesList(context, state),
                  )
                : BlocBuilder<NotesBloc, NotesState>(
                    builder: (context, state) => _buildStickyNotesList(context, state),
                  ),
          ),
        ],
      ),
      floatingActionButton: StickyNoteQuickCreateButton(
        onPressed: () => _showCreateStickyNoteDialog(context),
      ),
    );
  }

  Widget _buildStickyNotesList(BuildContext context, NotesState state) {
    if (state is NotesLoading) {
      return const LoadingWidget(message: '加载便签中...');
    }
    
    if (state is NotesError) {
      return CustomErrorWidget.CustomErrorWidget(
        message: state.message,
        onRetry: _loadStickyNotes,
      );
    }
    
    if (state is NotesLoaded) {
      final stickyNotes = state.notes.where((note) => note.isSticky).toList();
      
      if (stickyNotes.isEmpty) {
        return const _EmptyStickyNotesWidget();
      }
      
      return _StickyNotesList(
        stickyNotes: stickyNotes,
        onRefresh: _loadStickyNotes,
      );
    }
    
    return const _EmptyStickyNotesWidget();
  }

  void _showCreateStickyNoteDialog(BuildContext context) {
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
              _loadStickyNotes();
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

/// 便签列表组件
class _StickyNotesList extends StatelessWidget {
  final List<NoteFile> stickyNotes;
  final VoidCallback? onRefresh;

  const _StickyNotesList({
    required this.stickyNotes,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: stickyNotes.length,
        itemBuilder: (context, index) {
          final stickyNote = stickyNotes[index];
          
          return StickyNoteListItem(
            title: stickyNote.title,
            content: stickyNote.content,
            tags: stickyNote.tags,
            created: stickyNote.created,
            updated: stickyNote.updated,
            onTap: () => _openStickyNote(context, stickyNote),
            onEdit: () => _editStickyNote(context, stickyNote),
            onDelete: () => _deleteStickyNote(context, stickyNote),
          );
        },
      ),
    );
  }

  void _openStickyNote(BuildContext context, NoteFile stickyNote) {
    // 导航到笔记编辑页面
    Navigator.of(context).pushNamed(
      '/note-editor',
      arguments: stickyNote.filePath,
    );
  }

  void _editStickyNote(BuildContext context, NoteFile stickyNote) {
    showDialog(
      context: context,
      builder: (context) => _EditStickyNoteDialog(stickyNote: stickyNote),
    );
  }

  void _deleteStickyNote(BuildContext context, NoteFile stickyNote) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除便签'),
        content: Text('确定要删除便签 "${stickyNote.title}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (kIsWeb) {
                context.read<WebNotesBloc>().add(
                  DeleteNoteEvent(filePath: stickyNote.filePath),
                );
              } else {
                context.read<NotesBloc>().add(
                  DeleteNoteEvent(filePath: stickyNote.filePath),
                );
              }
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 空便签状态组件
class _EmptyStickyNotesWidget extends StatelessWidget {
  const _EmptyStickyNotesWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sticky_note_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有便签',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击上方的输入框或浮动按钮创建你的第一个便签',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 编辑便签对话框
class _EditStickyNoteDialog extends StatefulWidget {
  final NoteFile stickyNote;

  const _EditStickyNoteDialog({required this.stickyNote});

  @override
  State<_EditStickyNoteDialog> createState() => _EditStickyNoteDialogState();
}

class _EditStickyNoteDialogState extends State<_EditStickyNoteDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late List<String> _tags;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.stickyNote.title);
    _contentController = TextEditingController(text: widget.stickyNote.content);
    _tags = List.from(widget.stickyNote.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑便签'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '内容',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入内容';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // TODO: Add TagInputWidget here when available
              // TagInputWidget(
              //   initialTags: _tags,
              //   onTagsChanged: (tags) {
              //     setState(() {
              //       _tags = tags;
              //     });
              //   },
              // ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _updateStickyNote,
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _updateStickyNote() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<NotesBloc>().add(
      UpdateNoteEvent(
        filePath: widget.stickyNote.filePath,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: _tags,
      ),
    );

    Navigator.of(context).pop();
  }
}