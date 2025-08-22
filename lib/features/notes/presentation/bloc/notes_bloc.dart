import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as path;

import 'package:cherry_note/features/notes/domain/entities/note_file.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_event.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_state.dart';
import 'package:cherry_note/shared/utils/filename_generator.dart';
import 'package:cherry_note/shared/utils/path_utils.dart';
import 'package:cherry_note/shared/utils/file_utils.dart';
import 'package:cherry_note/core/error/exceptions.dart';

/// 笔记管理BLoC
@injectable
class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final String _notesDirectory;
  
  // 当前状态缓存
  List<NoteFile> _allNotes = [];
  String? _currentFolderPath;
  String? _currentSearchQuery;
  List<String>? _currentFilterTags;
  NotesSortBy _currentSortBy = NotesSortBy.modifiedDate;
  bool _currentAscending = false;

  NotesBloc({
    @Named('notesDirectory') required String notesDirectory,
  })  : _notesDirectory = notesDirectory,
        super(const NotesInitial()) {
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

  /// 加载笔记列表
  Future<void> _onLoadNotes(LoadNotesEvent event, Emitter<NotesState> emit) async {
    try {
      emit(const NotesLoading());

      // 更新当前状态
      _currentFolderPath = event.folderPath;
      _currentSearchQuery = event.searchQuery;
      _currentFilterTags = event.tags;
      _currentSortBy = event.sortBy;
      _currentAscending = event.ascending;

      // 加载所有笔记
      await _loadAllNotes();

      // 应用过滤和排序
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

  /// 创建笔记
  Future<void> _onCreateNote(CreateNoteEvent event, Emitter<NotesState> emit) async {
    try {
      emit(const NoteOperationInProgress(operation: 'create'));

      // 生成文件名
      final fileName = FilenameGenerator.fromTitle(event.title);
      final folderPath = event.folderPath ?? _currentFolderPath ?? '';
      final fullPath = path.join(_notesDirectory, folderPath, fileName);

      // 确保目录存在
      final directory = Directory(path.dirname(fullPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 创建笔记文件
      final noteFile = NoteFile(
        filePath: PathUtils.toRelativePath(fullPath, _notesDirectory),
        title: event.title,
        content: event.content ?? '',
        tags: event.tags ?? [],
        created: DateTime.now(),
        updated: DateTime.now(),
      );

      // 写入文件
      await _writeNoteFile(fullPath, noteFile);

      // 更新缓存
      _allNotes.add(noteFile);

      // 重新应用过滤和排序
      final filteredNotes = _applyFiltersAndSort();

      emit(NoteOperationSuccess(
        operation: 'create',
        message: 'Note created successfully',
        filePath: noteFile.filePath,
        note: noteFile,
      ));

      // 立即更新列表状态
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

  /// 更新笔记
  Future<void> _onUpdateNote(UpdateNoteEvent event, Emitter<NotesState> emit) async {
    try {
      emit(NoteOperationInProgress(
        operation: 'update',
        filePath: event.filePath,
      ));

      // 查找现有笔记
      final existingNoteIndex = _allNotes.indexWhere((note) => note.filePath == event.filePath);
      if (existingNoteIndex == -1) {
        throw Exception('Note not found: ${event.filePath}');
      }

      final existingNote = _allNotes[existingNoteIndex];
      final fullPath = path.join(_notesDirectory, event.filePath);

      // 更新笔记
      final updatedNote = existingNote.copyWith(
        title: event.title,
        content: event.content,
        tags: event.tags,
        updated: DateTime.now(),
      );

      // 写入文件
      await _writeNoteFile(fullPath, updatedNote);

      // 更新缓存
      _allNotes[existingNoteIndex] = updatedNote;

      // 重新应用过滤和排序
      final filteredNotes = _applyFiltersAndSort();

      emit(NoteOperationSuccess(
        operation: 'update',
        message: 'Note updated successfully',
        filePath: updatedNote.filePath,
        note: updatedNote,
      ));

      // 立即更新列表状态
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
        filePath: event.filePath,
        error: e,
      ));
    }
  }

  /// 删除笔记
  Future<void> _onDeleteNote(DeleteNoteEvent event, Emitter<NotesState> emit) async {
    try {
      emit(NoteOperationInProgress(
        operation: 'delete',
        filePath: event.filePath,
      ));

      final fullPath = path.join(_notesDirectory, event.filePath);
      final file = File(fullPath);

      if (await file.exists()) {
        await file.delete();
      }

      // 从缓存中移除
      _allNotes.removeWhere((note) => note.filePath == event.filePath);

      // 重新应用过滤和排序
      final filteredNotes = _applyFiltersAndSort();

      emit(NoteOperationSuccess(
        operation: 'delete',
        message: 'Note deleted successfully',
        filePath: event.filePath,
      ));

      // 立即更新列表状态
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
        filePath: event.filePath,
        error: e,
      ));
    }
  }

  /// 移动笔记
  Future<void> _onMoveNote(MoveNoteEvent event, Emitter<NotesState> emit) async {
    try {
      emit(NoteOperationInProgress(
        operation: 'move',
        filePath: event.filePath,
      ));

      final oldPath = path.join(_notesDirectory, event.filePath);
      final fileName = path.basename(event.filePath);
      final newPath = path.join(_notesDirectory, event.newFolderPath, fileName);

      // 确保目标目录存在
      final targetDirectory = Directory(path.dirname(newPath));
      if (!await targetDirectory.exists()) {
        await targetDirectory.create(recursive: true);
      }

      // 移动文件
      final file = File(oldPath);
      if (await file.exists()) {
        await file.rename(newPath);
      }

      // 更新缓存中的路径
      final noteIndex = _allNotes.indexWhere((note) => note.filePath == event.filePath);
      if (noteIndex != -1) {
        final newFilePath = PathUtils.toRelativePath(newPath, _notesDirectory);
        _allNotes[noteIndex] = _allNotes[noteIndex].copyWith(
          filePath: newFilePath,
          updated: DateTime.now(),
        );
      }

      // 重新应用过滤和排序
      final filteredNotes = _applyFiltersAndSort();

      emit(NoteOperationSuccess(
        operation: 'move',
        message: 'Note moved successfully',
        filePath: event.filePath,
      ));

      // 立即更新列表状态
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
        operation: 'move',
        message: 'Failed to move note: ${e.toString()}',
        filePath: event.filePath,
        error: e,
      ));
    }
  }

  /// 复制笔记
  Future<void> _onCopyNote(CopyNoteEvent event, Emitter<NotesState> emit) async {
    try {
      emit(NoteOperationInProgress(
        operation: 'copy',
        filePath: event.filePath,
      ));

      // 查找原笔记
      final originalNote = _allNotes.firstWhere(
        (note) => note.filePath == event.filePath,
        orElse: () => throw Exception('Note not found: ${event.filePath}'),
      );

      // 生成新文件名
      final newTitle = event.newTitle ?? '${originalNote.title} (Copy)';
      final fileName = FilenameGenerator.fromTitle(newTitle);
      final newPath = path.join(_notesDirectory, event.newFolderPath, fileName);

      // 确保目标目录存在
      final targetDirectory = Directory(path.dirname(newPath));
      if (!await targetDirectory.exists()) {
        await targetDirectory.create(recursive: true);
      }

      // 创建新笔记
      final newNote = originalNote.copyWith(
        filePath: PathUtils.toRelativePath(newPath, _notesDirectory),
        title: newTitle,
        created: DateTime.now(),
        updated: DateTime.now(),
      );

      // 写入文件
      await _writeNoteFile(newPath, newNote);

      // 添加到缓存
      _allNotes.add(newNote);

      // 重新应用过滤和排序
      final filteredNotes = _applyFiltersAndSort();

      emit(NoteOperationSuccess(
        operation: 'copy',
        message: 'Note copied successfully',
        filePath: event.filePath,
        note: newNote,
      ));

      // 立即更新列表状态
      emit(NotesLoaded(
        notes: filteredNotes,
        currentFolderPath: _currentFolderPath,
        searchQuery: _currentSearchQuery,
        filterTags: _currentFilterTags,
        sortBy: _currentSortBy,
        ascending: _currentAscending,
        selectedNoteId: newNote.filePath,
        totalCount: filteredNotes.length,
      ));
    } catch (e) {
      emit(NoteOperationError(
        operation: 'copy',
        message: 'Failed to copy note: ${e.toString()}',
        filePath: event.filePath,
        error: e,
      ));
    }
  }

  /// 搜索笔记
  Future<void> _onSearchNotes(SearchNotesEvent event, Emitter<NotesState> emit) async {
    try {
      emit(NotesSearching(
        query: event.query,
        folderPath: event.folderPath,
      ));

      // 更新搜索状态
      _currentSearchQuery = event.query;
      _currentFolderPath = event.folderPath;
      _currentFilterTags = event.tags;

      // 执行搜索
      final results = _searchNotes(
        query: event.query,
        folderPath: event.folderPath,
        tags: event.tags,
        searchInContent: event.searchInContent,
      );

      emit(NotesSearchResults(
        query: event.query,
        results: results,
        totalResults: results.length,
        folderPath: event.folderPath,
        tags: event.tags,
        searchInContent: event.searchInContent,
      ));
    } catch (e) {
      emit(NotesError(
        message: 'Search failed: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 按标签过滤笔记
  Future<void> _onFilterNotesByTags(FilterNotesByTagsEvent event, Emitter<NotesState> emit) async {
    try {
      _currentFilterTags = event.tags;
      _currentFolderPath = event.folderPath;

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
        message: 'Filter failed: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 排序笔记
  Future<void> _onSortNotes(SortNotesEvent event, Emitter<NotesState> emit) async {
    try {
      _currentSortBy = event.sortBy;
      _currentAscending = event.ascending;

      final sortedNotes = _applyFiltersAndSort();

      if (state is NotesLoaded) {
        final currentState = state as NotesLoaded;
        emit(currentState.copyWith(
          notes: sortedNotes,
          sortBy: _currentSortBy,
          ascending: _currentAscending,
        ));
      }
    } catch (e) {
      emit(NotesError(
        message: 'Sort failed: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 刷新笔记列表
  Future<void> _onRefreshNotes(RefreshNotesEvent event, Emitter<NotesState> emit) async {
    add(LoadNotesEvent(
      folderPath: _currentFolderPath,
      searchQuery: _currentSearchQuery,
      tags: _currentFilterTags,
      sortBy: _currentSortBy,
      ascending: _currentAscending,
    ));
  }

  /// 清除搜索
  Future<void> _onClearSearch(ClearSearchEvent event, Emitter<NotesState> emit) async {
    _currentSearchQuery = null;
    _currentFilterTags = null;

    final filteredNotes = _applyFiltersAndSort();

    emit(NotesLoaded(
      notes: filteredNotes,
      currentFolderPath: _currentFolderPath,
      searchQuery: null,
      filterTags: null,
      sortBy: _currentSortBy,
      ascending: _currentAscending,
      totalCount: filteredNotes.length,
    ));
  }

  /// 选择笔记
  Future<void> _onSelectNote(SelectNoteEvent event, Emitter<NotesState> emit) async {
    if (state is NotesLoaded) {
      final currentState = state as NotesLoaded;
      emit(currentState.copyWith(
        selectedNoteId: event.filePath,
        selectedNoteIds: [], // 清除多选
      ));
    }
  }

  /// 取消选择笔记
  Future<void> _onDeselectNote(DeselectNoteEvent event, Emitter<NotesState> emit) async {
    if (state is NotesLoaded) {
      final currentState = state as NotesLoaded;
      emit(currentState.copyWith(
        selectedNoteId: null,
        selectedNoteIds: [],
      ));
    }
  }

  /// 多选笔记
  Future<void> _onSelectMultipleNotes(SelectMultipleNotesEvent event, Emitter<NotesState> emit) async {
    if (state is NotesLoaded) {
      final currentState = state as NotesLoaded;
      emit(currentState.copyWith(
        selectedNoteId: null, // 清除单选
        selectedNoteIds: event.filePaths,
      ));
    }
  }

  /// 批量删除笔记
  Future<void> _onDeleteMultipleNotes(DeleteMultipleNotesEvent event, Emitter<NotesState> emit) async {
    try {
      emit(NotesBatchOperation(
        operation: 'delete',
        filePaths: event.filePaths,
        completed: 0,
        total: event.filePaths.length,
      ));

      int completed = 0;
      int failed = 0;
      final errors = <String>[];

      for (final filePath in event.filePaths) {
        try {
          emit(NotesBatchOperation(
            operation: 'delete',
            filePaths: event.filePaths,
            completed: completed,
            total: event.filePaths.length,
            currentFile: filePath,
          ));

          final fullPath = path.join(_notesDirectory, filePath);
          final file = File(fullPath);

          if (await file.exists()) {
            await file.delete();
          }

          // 从缓存中移除
          _allNotes.removeWhere((note) => note.filePath == filePath);
          completed++;
        } catch (e) {
          failed++;
          errors.add('$filePath: ${e.toString()}');
        }
      }

      // 重新应用过滤和排序
      final filteredNotes = _applyFiltersAndSort();

      emit(NotesBatchOperationSuccess(
        operation: 'delete',
        filePaths: event.filePaths,
        successCount: completed,
        failureCount: failed,
        errors: errors,
      ));

      // 立即更新列表状态
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
        message: 'Batch delete failed: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 导出笔记
  Future<void> _onExportNote(ExportNoteEvent event, Emitter<NotesState> emit) async {
    try {
      emit(NoteExporting(
        filePath: event.filePath,
        format: event.format,
      ));

      // 查找笔记
      final note = _allNotes.firstWhere(
        (note) => note.filePath == event.filePath,
        orElse: () => throw Exception('Note not found: ${event.filePath}'),
      );

      // 执行导出
      await _exportNote(note, event.exportPath, event.format);

      emit(NoteExportSuccess(
        filePath: event.filePath,
        exportPath: event.exportPath,
        format: event.format,
      ));
    } catch (e) {
      emit(NoteOperationError(
        operation: 'export',
        message: 'Export failed: ${e.toString()}',
        filePath: event.filePath,
        error: e,
      ));
    }
  }

  /// 导入笔记
  Future<void> _onImportNote(ImportNoteEvent event, Emitter<NotesState> emit) async {
    try {
      emit(NoteImporting(
        importPath: event.importPath,
        format: event.format,
      ));

      // 执行导入
      final importedNotes = await _importNote(
        event.importPath,
        event.targetFolderPath,
        event.format,
      );

      // 添加到缓存
      _allNotes.addAll(importedNotes);

      // 重新应用过滤和排序
      final filteredNotes = _applyFiltersAndSort();

      emit(NoteImportSuccess(
        importPath: event.importPath,
        importedNotes: importedNotes,
        format: event.format,
      ));

      // 立即更新列表状态
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
        operation: 'import',
        message: 'Import failed: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 加载所有笔记
  Future<void> _loadAllNotes() async {
    _allNotes.clear();
    
    final notesDir = Directory(_notesDirectory);
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
      return;
    }

    await for (final entity in notesDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md')) {
        try {
          final noteFile = await _readNoteFile(entity.path);
          _allNotes.add(noteFile);
        } catch (e) {
          // 跳过无法读取的文件
          continue;
        }
      }
    }
  }

  /// 应用过滤和排序
  List<NoteFile> _applyFiltersAndSort() {
    var notes = List<NoteFile>.from(_allNotes);

    // 应用文件夹过滤
    if (_currentFolderPath != null && _currentFolderPath!.isNotEmpty) {
      notes = notes.where((note) {
        final noteFolder = path.dirname(note.filePath);
        return noteFolder.startsWith(_currentFolderPath!);
      }).toList();
    }

    // 应用搜索过滤
    if (_currentSearchQuery != null && _currentSearchQuery!.isNotEmpty) {
      notes = _searchNotes(
        query: _currentSearchQuery!,
        notes: notes,
      );
    }

    // 应用标签过滤
    if (_currentFilterTags != null && _currentFilterTags!.isNotEmpty) {
      notes = notes.where((note) {
        return _currentFilterTags!.any((tag) => note.tags.contains(tag));
      }).toList();
    }

    // 应用排序
    notes.sort((a, b) {
      int comparison = 0;
      
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

    return notes;
  }

  /// 搜索笔记
  List<NoteFile> _searchNotes({
    required String query,
    String? folderPath,
    List<String>? tags,
    bool searchInContent = true,
    List<NoteFile>? notes,
  }) {
    final searchNotes = notes ?? _allNotes;
    final lowerQuery = query.toLowerCase();

    return searchNotes.where((note) {
      // 文件夹过滤
      if (folderPath != null && folderPath.isNotEmpty) {
        final noteFolder = path.dirname(note.filePath);
        if (!noteFolder.startsWith(folderPath)) {
          return false;
        }
      }

      // 标签过滤
      if (tags != null && tags.isNotEmpty) {
        if (!tags.any((tag) => note.tags.contains(tag))) {
          return false;
        }
      }

      // 文本搜索
      if (note.title.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      if (searchInContent && note.content.toLowerCase().contains(lowerQuery)) {
        return true;
      }

      // 标签搜索
      if (note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))) {
        return true;
      }

      return false;
    }).toList();
  }

  /// 读取笔记文件
  Future<NoteFile> _readNoteFile(String fullPath) async {
    final file = File(fullPath);
    final content = await file.readAsString();
    final relativePath = PathUtils.toRelativePath(fullPath, _notesDirectory);
    
    return NoteFile.fromMarkdown(
      filePath: relativePath,
      content: content,
    );
  }

  /// 写入笔记文件
  Future<void> _writeNoteFile(String fullPath, NoteFile noteFile) async {
    final file = File(fullPath);
    final markdownContent = noteFile.toMarkdown();
    await file.writeAsString(markdownContent);
  }

  /// 导出笔记
  Future<void> _exportNote(NoteFile note, String exportPath, ExportFormat format) async {
    final file = File(exportPath);
    
    switch (format) {
      case ExportFormat.markdown:
        await file.writeAsString(note.toMarkdown());
        break;
      case ExportFormat.txt:
        await file.writeAsString(note.content);
        break;
      case ExportFormat.html:
        // 简化的HTML导出
        final html = '''
<!DOCTYPE html>
<html>
<head>
    <title>${note.title}</title>
    <meta charset="utf-8">
</head>
<body>
    <h1>${note.title}</h1>
    <pre>${note.content}</pre>
</body>
</html>
''';
        await file.writeAsString(html);
        break;
      case ExportFormat.pdf:
        throw UnimplementedError('PDF export not implemented');
    }
  }

  /// 导入笔记
  Future<List<NoteFile>> _importNote(
    String importPath,
    String? targetFolderPath,
    ImportFormat format,
  ) async {
    final file = File(importPath);
    if (!await file.exists()) {
      throw Exception('Import file not found: $importPath');
    }

    final content = await file.readAsString();
    final fileName = path.basenameWithoutExtension(importPath);
    final targetFolder = targetFolderPath ?? '';
    
    NoteFile noteFile;
    
    switch (format) {
      case ImportFormat.markdown:
        noteFile = NoteFile.fromMarkdown(
          filePath: path.join(targetFolder, '$fileName.md'),
          content: content,
        );
        break;
      case ImportFormat.txt:
      case ImportFormat.html:
        noteFile = NoteFile(
          filePath: path.join(targetFolder, '$fileName.md'),
          title: fileName,
          content: content,
          tags: [],
          created: DateTime.now(),
          updated: DateTime.now(),
        );
        break;
    }

    // 写入文件
    final fullPath = path.join(_notesDirectory, noteFile.filePath);
    await _writeNoteFile(fullPath, noteFile);

    return [noteFile];
  }

  /// 创建便签
  Future<void> _onCreateStickyNote(CreateStickyNoteEvent event, Emitter<NotesState> emit) async {
    try {
      emit(const NoteOperationInProgress(operation: 'create_sticky'));

      // 生成便签标题和文件名
      final now = DateTime.now();
      final title = _generateStickyNoteTitle(now, event.content);
      final fileName = _generateStickyNoteFileName(now);
      
      // 便签保存到 "便签" 文件夹
      const stickyFolderPath = '便签';
      final fullPath = path.join(_notesDirectory, stickyFolderPath, fileName);

      // 确保便签目录存在
      final directory = Directory(path.dirname(fullPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 创建便签文件
      final stickyNote = NoteFile(
        filePath: PathUtils.toRelativePath(fullPath, _notesDirectory),
        title: title,
        content: event.content ?? '',
        tags: event.tags ?? [],
        created: now,
        updated: now,
        isSticky: true, // 标记为便签
      );

      // 写入文件
      await _writeNoteFile(fullPath, stickyNote);

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

  /// 加载便签列表
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