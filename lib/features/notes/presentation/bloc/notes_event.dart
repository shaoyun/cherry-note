import 'package:equatable/equatable.dart';
import 'package:cherry_note/features/notes/domain/entities/note_file.dart';

/// 笔记管理事件基类
abstract class NotesEvent extends Equatable {
  const NotesEvent();

  @override
  List<Object?> get props => [];
}

/// 加载笔记列表事件
class LoadNotesEvent extends NotesEvent {
  final String? folderPath;
  final String? searchQuery;
  final List<String>? tags;
  final NotesSortBy sortBy;
  final bool ascending;

  const LoadNotesEvent({
    this.folderPath,
    this.searchQuery,
    this.tags,
    this.sortBy = NotesSortBy.modifiedDate,
    this.ascending = false,
  });

  @override
  List<Object?> get props => [folderPath, searchQuery, tags, sortBy, ascending];
}

/// 创建笔记事件
class CreateNoteEvent extends NotesEvent {
  final String title;
  final String? folderPath;
  final String? content;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;

  const CreateNoteEvent({
    required this.title,
    this.folderPath,
    this.content,
    this.tags,
    this.metadata,
  });

  @override
  List<Object?> get props => [title, folderPath, content, tags, metadata];
}

/// 更新笔记事件
class UpdateNoteEvent extends NotesEvent {
  final String filePath;
  final String? title;
  final String? content;
  final List<String>? tags;
  final Map<String, dynamic>? metadata;

  const UpdateNoteEvent({
    required this.filePath,
    this.title,
    this.content,
    this.tags,
    this.metadata,
  });

  @override
  List<Object?> get props => [filePath, title, content, tags, metadata];
}

/// 删除笔记事件
class DeleteNoteEvent extends NotesEvent {
  final String filePath;

  const DeleteNoteEvent({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

/// 移动笔记事件
class MoveNoteEvent extends NotesEvent {
  final String filePath;
  final String newFolderPath;

  const MoveNoteEvent({
    required this.filePath,
    required this.newFolderPath,
  });

  @override
  List<Object?> get props => [filePath, newFolderPath];
}

/// 复制笔记事件
class CopyNoteEvent extends NotesEvent {
  final String filePath;
  final String newFolderPath;
  final String? newTitle;

  const CopyNoteEvent({
    required this.filePath,
    required this.newFolderPath,
    this.newTitle,
  });

  @override
  List<Object?> get props => [filePath, newFolderPath, newTitle];
}

/// 搜索笔记事件
class SearchNotesEvent extends NotesEvent {
  final String query;
  final String? folderPath;
  final List<String>? tags;
  final bool searchInContent;

  const SearchNotesEvent({
    required this.query,
    this.folderPath,
    this.tags,
    this.searchInContent = true,
  });

  @override
  List<Object?> get props => [query, folderPath, tags, searchInContent];
}

/// 按标签过滤笔记事件
class FilterNotesByTagsEvent extends NotesEvent {
  final List<String> tags;
  final String? folderPath;
  final bool matchAll;

  const FilterNotesByTagsEvent({
    required this.tags,
    this.folderPath,
    this.matchAll = false,
  });

  @override
  List<Object?> get props => [tags, folderPath, matchAll];
}

/// 排序笔记事件
class SortNotesEvent extends NotesEvent {
  final NotesSortBy sortBy;
  final bool ascending;

  const SortNotesEvent({
    required this.sortBy,
    this.ascending = false,
  });

  @override
  List<Object?> get props => [sortBy, ascending];
}

/// 刷新笔记列表事件
class RefreshNotesEvent extends NotesEvent {
  const RefreshNotesEvent();
}

/// 清除搜索事件
class ClearSearchEvent extends NotesEvent {
  const ClearSearchEvent();
}

/// 选择笔记事件
class SelectNoteEvent extends NotesEvent {
  final String filePath;

  const SelectNoteEvent({required this.filePath});

  @override
  List<Object?> get props => [filePath];
}

/// 取消选择笔记事件
class DeselectNoteEvent extends NotesEvent {
  const DeselectNoteEvent();
}

/// 批量选择笔记事件
class SelectMultipleNotesEvent extends NotesEvent {
  final List<String> filePaths;

  const SelectMultipleNotesEvent({required this.filePaths});

  @override
  List<Object?> get props => [filePaths];
}

/// 批量删除笔记事件
class DeleteMultipleNotesEvent extends NotesEvent {
  final List<String> filePaths;

  const DeleteMultipleNotesEvent({required this.filePaths});

  @override
  List<Object?> get props => [filePaths];
}

/// 导出笔记事件
class ExportNoteEvent extends NotesEvent {
  final String filePath;
  final String exportPath;
  final ExportFormat format;

  const ExportNoteEvent({
    required this.filePath,
    required this.exportPath,
    required this.format,
  });

  @override
  List<Object?> get props => [filePath, exportPath, format];
}

/// 导入笔记事件
class ImportNoteEvent extends NotesEvent {
  final String importPath;
  final String? targetFolderPath;
  final ImportFormat format;

  const ImportNoteEvent({
    required this.importPath,
    this.targetFolderPath,
    required this.format,
  });

  @override
  List<Object?> get props => [importPath, targetFolderPath, format];
}

/// 笔记排序方式
enum NotesSortBy {
  title,
  createdDate,
  modifiedDate,
  size,
  tags,
}

/// 导出格式
enum ExportFormat {
  markdown,
  html,
  pdf,
  txt,
}

/// 导入格式
enum ImportFormat {
  markdown,
  txt,
  html,
}