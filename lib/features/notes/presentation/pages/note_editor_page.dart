import 'package:flutter/material.dart';
import '../widgets/markdown_editor.dart';

class NoteEditorPage extends StatefulWidget {
  final String? noteId;
  
  const NoteEditorPage({super.key, this.noteId});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  String _content = '';
  bool _hasUnsavedChanges = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.noteId != null ? 'Edit Note' : 'New Note'),
        actions: [
          if (_hasUnsavedChanges)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          IconButton(
            onPressed: _hasUnsavedChanges ? _saveNote : null,
            icon: const Icon(Icons.save),
            tooltip: 'Save Note',
          ),
        ],
      ),
      body: MarkdownEditor(
        initialContent: _content,
        onContentChanged: _onContentChanged,
        onAutoSave: _saveNote,
        showPreview: true,
        enableSyntaxHighlighting: true,
        showToolbar: true,
        enableAutoSave: true,
        autoSaveInterval: const Duration(seconds: 30),
      ),
    );
  }

  void _onContentChanged(String content) {
    setState(() {
      _content = content;
      _hasUnsavedChanges = true;
    });
  }

  void _saveNote() {
    // TODO: Implement save functionality with BLoC
    setState(() {
      _hasUnsavedChanges = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note saved successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}