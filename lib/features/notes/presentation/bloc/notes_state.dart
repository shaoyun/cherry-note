import 'package:equatable/equatable.dart';
import 'package:cherry_note/features/notes/domain/entities/note_file.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_event.dart';

/// 笔记管理状态基类
abstract class NotesState extends Equatable {
  const NotesState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class NotesInitial extends NotesState {
  const NotesInitial();
}

/// 加载中状态
class NotesLoading extends NotesState {
  const NotesLoading();
}

/// 加载成功状态
class NotesLoaded extends NotesState {
  final List<NoteFile> notes;
  final String? currentFolderPath;
  final String? searchQuery;
  final List<String>? filterTags;
  final NotesSortBy sortBy;
  final bool ascending;
  final String? selectedNoteId;
  final List<String> selectedNoteIds;
  final int totalCount;
  final bool hasMore;

  const NotesLoaded({
    required this.notes,
    this.currentFolderPath,
    this.searchQuery,
    this.filterTags,
    this.sortBy = NotesSortBy.modifiedDate,
    this.ascending = false,
    this.selectedNoteId,
    this.selectedNoteIds = const [],
    this.totalCount = 0,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [
        notes,
        currentFolderPath,
        searchQuery,
        filterTags,
        sortBy,
        ascending,
        selectedNoteId,
        selectedNoteIds,
        totalCount,
        hasMore,
      ];

  /// 复制状态并更新部分字段
  NotesLoaded copyWith({
    List<NoteFile>? notes,
    String? currentFolderPath,
    String? searchQuery,
    List<String>? filterTags,
    NotesSortBy? sortBy,
    bool? ascending,
    String? selectedNoteId,
    List<String>? selectedNoteIds,
    int? totalCount,
    bool? hasMore,
  }) {
    return NotesLoaded(
      notes: notes ?? this.notes,
      currentFolderPath: currentFolderPath ?? this.currentFolderPath,
      searchQuery: searchQuery ?? this.searchQuery,
      filterTags: filterTags ?? this.filterTags,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      selectedNoteId: selectedNoteId ?? this.selectedNoteId,
      selectedNoteIds: selectedNoteIds ?? this.selectedNoteIds,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  /// 清除搜索和过滤
  NotesLoaded clearFilters() {
    return copyWith(
      searchQuery: null,
      filterTags: null,
    );
  }

  /// 是否有活动的过滤器
  bool get hasActiveFilters => searchQuery != null || (filterTags?.isNotEmpty ?? false);

  /// 是否有选中的笔记
  bool get hasSelection => selectedNoteId != null || selectedNoteIds.isNotEmpty;

  /// 是否为多选模式
  bool get isMultiSelectMode => selectedNoteIds.isNotEmpty;
}

/// 加载失败状态
class NotesError extends NotesState {
  final String message;
  final String? errorCode;
  final dynamic error;

  const NotesError({
    required this.message,
    this.errorCode,
    this.error,
  });

  @override
  List<Object?> get props => [message, errorCode, error];
}

/// 笔记操作中状态
class NoteOperationInProgress extends NotesState {
  final String operation;
  final String? filePath;
  final double? progress;

  const NoteOperationInProgress({
    required this.operation,
    this.filePath,
    this.progress,
  });

  @override
  List<Object?> get props => [operation, filePath, progress];
}

/// 笔记操作成功状态
class NoteOperationSuccess extends NotesState {
  final String operation;
  final String message;
  final String? filePath;
  final NoteFile? note;

  const NoteOperationSuccess({
    required this.operation,
    required this.message,
    this.filePath,
    this.note,
  });

  @override
  List<Object?> get props => [operation, message, filePath, note];
}

/// 笔记操作失败状态
class NoteOperationError extends NotesState {
  final String operation;
  final String message;
  final String? filePath;
  final String? errorCode;
  final dynamic error;

  const NoteOperationError({
    required this.operation,
    required this.message,
    this.filePath,
    this.errorCode,
    this.error,
  });

  @override
  List<Object?> get props => [operation, message, filePath, errorCode, error];
}

/// 搜索状态
class NotesSearching extends NotesState {
  final String query;
  final String? folderPath;

  const NotesSearching({
    required this.query,
    this.folderPath,
  });

  @override
  List<Object?> get props => [query, folderPath];
}

/// 搜索结果状态
class NotesSearchResults extends NotesState {
  final String query;
  final List<NoteFile> results;
  final int totalResults;
  final String? folderPath;
  final List<String>? tags;
  final bool searchInContent;

  const NotesSearchResults({
    required this.query,
    required this.results,
    required this.totalResults,
    this.folderPath,
    this.tags,
    this.searchInContent = true,
  });

  @override
  List<Object?> get props => [
        query,
        results,
        totalResults,
        folderPath,
        tags,
        searchInContent,
      ];
}

/// 导出状态
class NoteExporting extends NotesState {
  final String filePath;
  final ExportFormat format;
  final double? progress;

  const NoteExporting({
    required this.filePath,
    required this.format,
    this.progress,
  });

  @override
  List<Object?> get props => [filePath, format, progress];
}

/// 导出成功状态
class NoteExportSuccess extends NotesState {
  final String filePath;
  final String exportPath;
  final ExportFormat format;

  const NoteExportSuccess({
    required this.filePath,
    required this.exportPath,
    required this.format,
  });

  @override
  List<Object?> get props => [filePath, exportPath, format];
}

/// 导入状态
class NoteImporting extends NotesState {
  final String importPath;
  final ImportFormat format;
  final double? progress;

  const NoteImporting({
    required this.importPath,
    required this.format,
    this.progress,
  });

  @override
  List<Object?> get props => [importPath, format, progress];
}

/// 导入成功状态
class NoteImportSuccess extends NotesState {
  final String importPath;
  final List<NoteFile> importedNotes;
  final ImportFormat format;

  const NoteImportSuccess({
    required this.importPath,
    required this.importedNotes,
    required this.format,
  });

  @override
  List<Object?> get props => [importPath, importedNotes, format];
}

/// 批量操作状态
class NotesBatchOperation extends NotesState {
  final String operation;
  final List<String> filePaths;
  final int completed;
  final int total;
  final String? currentFile;

  const NotesBatchOperation({
    required this.operation,
    required this.filePaths,
    required this.completed,
    required this.total,
    this.currentFile,
  });

  @override
  List<Object?> get props => [operation, filePaths, completed, total, currentFile];

  double get progress => total > 0 ? completed / total : 0.0;
}

/// 批量操作成功状态
class NotesBatchOperationSuccess extends NotesState {
  final String operation;
  final List<String> filePaths;
  final int successCount;
  final int failureCount;
  final List<String> errors;

  const NotesBatchOperationSuccess({
    required this.operation,
    required this.filePaths,
    required this.successCount,
    required this.failureCount,
    this.errors = const [],
  });

  @override
  List<Object?> get props => [operation, filePaths, successCount, failureCount, errors];

  bool get hasErrors => failureCount > 0;
  bool get allSuccessful => failureCount == 0;
}