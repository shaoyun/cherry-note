import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'package:cherry_note/features/notes/domain/entities/note_file.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_event.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_state.dart';
import 'package:cherry_note/shared/utils/filename_generator.dart';
import 'package:cherry_note/core/error/exceptions.dart';

/// Web-compatible Notes BLoC using SharedPreferences
@injectable
class WebNotesBloc extends Bloc<NotesEvent, NotesState> {
  static const String _notesKey = 'cherry_note_notes';
  static const String _noteContentPrefix = 'cherry_note_content_';
  
  // Current state cache
  List<NoteFile> _allNotes = [];
  String? _currentFolderPath;
  String? _currentSearchQuery;
  List<String>? _currentFilterTags;
  NotesSortBy _currentSortBy = NotesSortBy.modifiedDate;
  bool _currentAscending = false;

  WebNotesBloc() : super(const NotesInitial()) {
    on<LoadNotesEvent>(_onLoadNotes);
    on<CreateNoteEvent>(_onCreateNote);
    on<UpdateNoteEvent>(_onUpdateNote);
    on<DeleteNoteEvent>(_onDeleteNote);
    on<MoveNoteEvent>(_onMoveNote);
    on<CopyNoteEvent>(_onCopyNote);
    on<SearchNotesEvent>(_onSearchNotes);
    on<FilterNotesByTagsEvent>(_onFilterNotesByTags);
    on<SortNotesEvent>(_onSortNotes);
    on<RefreshNotesEvent>(_onRefreshNotes);
    on<ClearSearchEvent>(_onClearSearch);
    on<SelectNoteEvent>(_onSelectNote);
    on<DeselectNoteEvent>(_onDeselectNote);
    on<SelectMultipleNotesEvent>(_onSelectMultipleNotes);
    on<DeleteMultipleNotesEvent>(_onDeleteMultipleNotes);
    on<ExportNoteEvent>(_onExportNote);
    on<ImportNoteEvent>(_onImportNote);
    on<CreateStickyNoteEvent>(_onCreateStickyNote);
    on<LoadStickyNotesEvent>(_onLoadStickyNotes);
  }

  /// Load notes list
  Future<void> _onLoadNotes(LoadNotesEvent event, Emitter<NotesState> emit) async {
    try {
      if (!kIsWeb) {
        throw UnsupportedError('WebNotesBloc is only for web platform');
      }

      emit(const NotesLoading());

      // Update current state
      _currentFolderPath = event.folderPath;
      _currentSearchQuery = event.searchQuery;
      _currentFilterTags = event.tags;
      _currentSortBy = event.sortBy;
      _currentAscending = event.ascending;

      // Load all notes
      await _loadAllNotes();

      // Apply filters and sorting
      final filteredNotes = _applyFiltersAndSort();

      emit(NotesLoaded(
        notes: filteredNotes,
        currentFolderPath: _currentFolderPath,
        searchQuery: _currentSearchQuery,
        filterTags: _currentFilterTags,
        sortBy: _currentSortBy,
        ascending: _currentAscending,
        totalCount: filteredNotes.length,
      ));
    } catch (e) {
      emit(NotesError(
        message: 'Failed to load notes: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// Create note
  Future<void> _onCreateNote(CreateNoteEvent event, Emitter<NotesState> emit) async {
    try {
      emit(const NoteOperationInProgress(operation: 'create'));

      // Generate file name
      final fileName = FilenameGenerator.fromTitle(event.title);
      final folderPath = event.folderPath ?? _currentFolderPath ?? '';
      final filePath = folderPath.isEmpty ? fileName : '$folderPath/$fileName';

      // Check if note already exists
      if (_allNotes.any((note) => note.filePath == filePath)) {
        throw StorageException('Note already exists: $filePath');
      }

      // Create note file
      final noteFile = NoteFile(
        filePath: filePath,
        title: event.title,
        content: event.content ?? '',
        tags: event.tags ?? [],
        created: DateTime.now(),
        updated: DateTime.now(),
      );

      // Save note
      await _saveNote(noteFile);

      // Update cache
      _allNotes.add(noteFile);

      // Re-apply filters and sorting
      final filteredNotes = _applyFiltersAndSort();

      emit(NoteOperationSuccess(
        operation: 'create',
        message: 'Note created successfully',
        filePath: noteFile.filePath,
        note: noteFile,
      ));

      // Immediately update list state
      emit(NotesLoaded(
        notes: filteredNotes,
        currentFolderPath: _currentFolderPath,
        searchQuery: _currentSearchQuery,
        filterTags: _currentFilterTags,
        sortBy: _currentSortBy,
        ascending: _currentAscending,
        selectedNoteId: noteFile.filePath,
        totalCount: filteredNotes.length,
      ));
    } catch (e) {
      emit(NoteOperationError(
        operation: 'create',
        message: 'Failed to create note: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// Update note
  Future<void> _onUpdateNote(UpdateNoteEvent event, Emitter<NotesState> emit) async {
    try {
      emit(NoteOperationInProgress(
        operation: 'update',
        filePath: event.filePath,
      ));

      // Find existing note
      final existingNoteIndex = _allNotes.indexWhere((note) => note.filePath == event.filePath);
      if (existingNoteIndex == -1) {
        throw Exception('Note not found: ${event.filePath}');
      }

      final existingNote = _allNotes[existingNoteIndex];

      // Update note
      final updatedNote = existingNote.copyWith(
        title: event.title,
        content: event.content,
        tags: event.tags,
        updated: DateTime.now(),
      );

      // Save note
      await _saveNote(updatedNote);

      // Update cache
      _allNotes[existingNoteIndex] = updatedNote;

      // Re-apply filters and sorting
      final filteredNotes = _applyFiltersAndSort();

      emit(NoteOperationSuccess(
        operation: 'update',
        message: 'Note updated successfully',
        filePath: updatedNote.filePath,
        note: updatedNote,
      ));

      // Immediately update list state
      emit(NotesLoaded(
        notes: filteredNotes,
        currentFolderPath: _currentFolderPath,
        searchQuery: _currentSearchQuery,
        filterTags: _currentFilterTags,
        sortBy: _currentSortBy,
        ascending: _currentAscending,
        selectedNoteId: updatedNote.filePath,
        totalCount: filteredNotes.length,
      ));
    } catch (e) {
      emit(NoteOperationError(
        operation: 'update',
        message: 'Failed to update note: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// Delete note
  Future<void> _onDeleteNote(DeleteNoteEvent event, Emitter<NotesState> emit) async {
    try {
      emit(NoteOperationInProgress(
        operation: 'delete',
        filePath: event.filePath,
      ));

      // Remove from storage
      await _deleteNote(event.filePath);

      // Remove from cache
      _allNotes.removeWhere((note) => note.filePath == event.filePath);

      // Re-apply filters and sorting
      final filteredNotes = _applyFiltersAndSort();

      emit(NoteOperationSuccess(
        operation: 'delete',
        message: 'Note deleted successfully',
        filePath: event.filePath,
      ));

      // Immediately update list state
      emit(NotesLoaded(
        notes: filteredNotes,
        currentFolderPath: _currentFolderPath,
        searchQuery: _currentSearchQuery,
        filterTags: _currentFilterTags,
        sortBy: _currentSortBy,
        ascending: _currentAscending,
        totalCount: filteredNotes.length,
      ));
    } catch (e) {
      emit(NoteOperationError(
        operation: 'delete',
        message: 'Failed to delete note: ${e.toString()}',
        error: e,
      ));
    }
  }

  // Implement other handlers with similar patterns...
  Future<void> _onMoveNote(MoveNoteEvent event, Emitter<NotesState> emit) async {
    // TODO: Implement move note for web
    emit(NoteOperationError(
      operation: 'move',
      message: 'Move note not yet implemented for web',
      error: UnsupportedError('Move note not implemented'),
    ));
  }

  Future<void> _onCopyNote(CopyNoteEvent event, Emitter<NotesState> emit) async {
    // TODO: Implement copy note for web
    emit(NoteOperationError(
      operation: 'copy',
      message: 'Copy note not yet implemented for web',
      error: UnsupportedError('Copy note not implemented'),
    ));
  }

  Future<void> _onSearchNotes(SearchNotesEvent event, Emitter<NotesState> emit) async {
    _currentSearchQuery = event.query;
    add(LoadNotesEvent(
      folderPath: _currentFolderPath,
      searchQuery: _currentSearchQuery,
      tags: _currentFilterTags,
      sortBy: _currentSortBy,
      ascending: _currentAscending,
    ));
  }

  Future<void> _onFilterNotesByTags(FilterNotesByTagsEvent event, Emitter<NotesState> emit) async {
    _currentFilterTags = event.tags;
    add(LoadNotesEvent(
      folderPath: _currentFolderPath,
      searchQuery: _currentSearchQuery,
      tags: _currentFilterTags,
      sortBy: _currentSortBy,
      ascending: _currentAscending,
    ));
  }

  Future<void> _onSortNotes(SortNotesEvent event, Emitter<NotesState> emit) async {
    _currentSortBy = event.sortBy;
    _currentAscending = event.ascending;
    add(LoadNotesEvent(
      folderPath: _currentFolderPath,
      searchQuery: _currentSearchQuery,
      tags: _currentFilterTags,
      sortBy: _currentSortBy,
      ascending: _currentAscending,
    ));
  }

  Future<void> _onRefreshNotes(RefreshNotesEvent event, Emitter<NotesState> emit) async {
    add(LoadNotesEvent(
      folderPath: _currentFolderPath,
      searchQuery: _currentSearchQuery,
      tags: _currentFilterTags,
      sortBy: _currentSortBy,
      ascending: _currentAscending,
    ));
  }

  Future<void> _onClearSearch(ClearSearchEvent event, Emitter<NotesState> emit) async {
    _currentSearchQuery = null;
    add(LoadNotesEvent(
      folderPath: _currentFolderPath,
      searchQuery: null,
      tags: _currentFilterTags,
      sortBy: _currentSortBy,
      ascending: _currentAscending,
    ));
  }

  Future<void> _onSelectNote(SelectNoteEvent event, Emitter<NotesState> emit) async {
    if (state is NotesLoaded) {
      final currentState = state as NotesLoaded;
      emit(currentState.copyWith(selectedNoteId: event.filePath));
    }
  }

  Future<void> _onDeselectNote(DeselectNoteEvent event, Emitter<NotesState> emit) async {
    if (state is NotesLoaded) {
      final currentState = state as NotesLoaded;
      emit(currentState.copyWith(selectedNoteId: null));
    }
  }

  Future<void> _onSelectMultipleNotes(SelectMultipleNotesEvent event, Emitter<NotesState> emit) async {
    // TODO: Implement multiple selection
  }

  Future<void> _onDeleteMultipleNotes(DeleteMultipleNotesEvent event, Emitter<NotesState> emit) async {
    // TODO: Implement multiple deletion
  }

  Future<void> _onExportNote(ExportNoteEvent event, Emitter<NotesState> emit) async {
    // TODO: Implement export
  }

  Future<void> _onImportNote(ImportNoteEvent event, Emitter<NotesState> emit) async {
    // TODO: Implement import
  }

  Future<void> _onCreateStickyNote(CreateStickyNoteEvent event, Emitter<NotesState> emit) async {
    try {
      emit(const NoteOperationInProgress(operation: 'create_sticky'));

      // 生成便签标题和文件名
      final now = DateTime.now();
      final title = _generateStickyNoteTitle(now, event.content);
      final fileName = _generateStickyNoteFileName(now);
      
      // 便签保存到 "便签" 文件夹
      const stickyFolderPath = '便签';
      final filePath = '$stickyFolderPath/$fileName';

      // 检查是否已存在
      if (_allNotes.any((note) => note.filePath == filePath)) {
        throw StorageException('Sticky note already exists: $filePath');
      }

      // 创建便签文件
      final stickyNote = NoteFile(
        filePath: filePath,
        title: title,
        content: event.content ?? '',
        tags: event.tags ?? [],
        created: now,
        updated: now,
        isSticky: true,
      );

      // 保存便签
      await _saveNote(stickyNote);

      // 更新缓存
      _allNotes.add(stickyNote);

      // 重新应用过滤和排序
      final filteredNotes = _applyFiltersAndSort();

      emit(NoteOperationSuccess(
        operation: 'create_sticky',
        message: 'Sticky note created successfully',
        filePath: stickyNote.filePath,
        note: stickyNote,
      ));

      // 立即更新列表状态
      emit(NotesLoaded(
        notes: filteredNotes,
        currentFolderPath: _currentFolderPath,
        searchQuery: _currentSearchQuery,
        filterTags: _currentFilterTags,
        sortBy: _currentSortBy,
        ascending: _currentAscending,
        selectedNoteId: stickyNote.filePath,
        totalCount: filteredNotes.length,
      ));
    } catch (e) {
      emit(NoteOperationError(
        operation: 'create_sticky',
        message: 'Failed to create sticky note: ${e.toString()}',
        error: e,
      ));
    }
  }

  Future<void> _onLoadStickyNotes(LoadStickyNotesEvent event, Emitter<NotesState> emit) async {
    try {
      emit(const NotesLoading());

      // 加载所有笔记
      await _loadAllNotes();

      // 过滤出便签
      final stickyNotes = _allNotes.where((note) => note.isSticky).toList();

      // 排序便签
      stickyNotes.sort((a, b) {
        int comparison = 0;
        
        switch (event.sortBy) {
          case NotesSortBy.title:
            comparison = a.title.compareTo(b.title);
            break;
          case NotesSortBy.createdDate:
            comparison = a.created.compareTo(b.created);
            break;
          case NotesSortBy.modifiedDate:
            comparison = a.updated.compareTo(b.updated);
            break;
          case NotesSortBy.size:
            comparison = a.content.length.compareTo(b.content.length);
            break;
          case NotesSortBy.tags:
            comparison = a.tags.join(',').compareTo(b.tags.join(','));
            break;
        }

        return event.ascending ? comparison : -comparison;
      });

      emit(NotesLoaded(
        notes: stickyNotes,
        currentFolderPath: '便签',
        sortBy: event.sortBy,
        ascending: event.ascending,
        totalCount: stickyNotes.length,
      ));
    } catch (e) {
      emit(NotesError(
        message: 'Failed to load sticky notes: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// Load all notes from storage
  Future<void> _loadAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString(_notesKey);
    
    if (notesJson == null) {
      // Create default note if none exist
      await _createDefaultNote();
      return await _loadAllNotes();
    }

    final List<dynamic> notesList = json.decode(notesJson);
    _allNotes = notesList.map((json) => NoteFile.fromJson(json)).toList();
  }

  /// Apply filters and sorting
  List<NoteFile> _applyFiltersAndSort() {
    List<NoteFile> filteredNotes = List.from(_allNotes);

    // Apply folder filter
    if (_currentFolderPath != null && _currentFolderPath!.isNotEmpty) {
      filteredNotes = filteredNotes.where((note) {
        return note.filePath.startsWith('${_currentFolderPath!}/') ||
               (!note.filePath.contains('/') && _currentFolderPath == '');
      }).toList();
    }

    // Apply search filter
    if (_currentSearchQuery != null && _currentSearchQuery!.isNotEmpty) {
      final query = _currentSearchQuery!.toLowerCase();
      filteredNotes = filteredNotes.where((note) {
        return note.title.toLowerCase().contains(query) ||
               note.content.toLowerCase().contains(query) ||
               note.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Apply tag filter
    if (_currentFilterTags != null && _currentFilterTags!.isNotEmpty) {
      filteredNotes = filteredNotes.where((note) {
        return _currentFilterTags!.any((tag) => note.tags.contains(tag));
      }).toList();
    }

    // Apply sorting
    filteredNotes.sort((a, b) {
      int comparison;
      switch (_currentSortBy) {
        case NotesSortBy.title:
          comparison = a.title.compareTo(b.title);
          break;
        case NotesSortBy.createdDate:
          comparison = a.created.compareTo(b.created);
          break;
        case NotesSortBy.modifiedDate:
          comparison = a.updated.compareTo(b.updated);
          break;
        case NotesSortBy.size:
          comparison = a.content.length.compareTo(b.content.length);
          break;
        case NotesSortBy.tags:
          comparison = a.tags.join(',').compareTo(b.tags.join(','));
          break;
      }
      return _currentAscending ? comparison : -comparison;
    });

    return filteredNotes;
  }

  /// Save note to storage
  Future<void> _saveNote(NoteFile note) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Update the notes list
    final existingIndex = _allNotes.indexWhere((n) => n.filePath == note.filePath);
    if (existingIndex >= 0) {
      _allNotes[existingIndex] = note;
    } else {
      _allNotes.add(note);
    }

    // Save notes list
    final notesJson = json.encode(_allNotes.map((n) => n.toJson()).toList());
    await prefs.setString(_notesKey, notesJson);

    // Save note content separately for faster loading
    await prefs.setString('$_noteContentPrefix${note.filePath}', note.content);
  }

  /// Delete note from storage
  Future<void> _deleteNote(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove from notes list
    _allNotes.removeWhere((note) => note.filePath == filePath);
    
    // Save updated notes list
    final notesJson = json.encode(_allNotes.map((n) => n.toJson()).toList());
    await prefs.setString(_notesKey, notesJson);

    // Remove note content
    await prefs.remove('$_noteContentPrefix$filePath');
  }

  /// Create default note on first run
  Future<void> _createDefaultNote() async {
    final defaultNote = NoteFile(
      filePath: 'Welcome.md',
      title: 'Welcome to Cherry Note',
      content: '''# Welcome to Cherry Note

This is your first note! Cherry Note is a cross-platform markdown note-taking application.

## Features
- Markdown support
- Folder organization
- Tag filtering
- Cross-platform sync
- Web support

Start writing your notes and organize them in folders. Use tags to categorize and quickly find your content.

Happy note-taking! 📝
''',
      tags: ['welcome', 'getting-started'],
      created: DateTime.now(),
      updated: DateTime.now(),
    );

    await _saveNote(defaultNote);
  }

  /// 生成便签标题
  String _generateStickyNoteTitle(DateTime dateTime, String? content) {
    // 如果有内容，使用内容的前几个字符作为标题
    if (content != null && content.trim().isNotEmpty) {
      final firstLine = content.trim().split('\n').first;
      if (firstLine.length <= 30) {
        return firstLine;
      } else {
        return '${firstLine.substring(0, 30)}...';
      }
    }
    
    // 否则使用日期时间作为标题
    return '便签 ${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 生成便签文件名
  String _generateStickyNoteFileName(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}-${dateTime.hour.toString().padLeft(2, '0')}${dateTime.minute.toString().padLeft(2, '0')}${dateTime.second.toString().padLeft(2, '0')}-${dateTime.millisecond.toString().padLeft(3, '0')}-便签.md';
  }
}