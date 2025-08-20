import 'package:cherry_note/features/notes/domain/entities/note_file.dart';

/// 便签服务接口
abstract class StickyNoteService {
  /// 创建快速便签
  Future<NoteFile> createQuickStickyNote({
    String? content,
    List<String>? tags,
  });

  /// 获取所有便签
  Future<List<NoteFile>> getAllStickyNotes();

  /// 获取最近的便签
  Future<List<NoteFile>> getRecentStickyNotes({int limit = 10});

  /// 按标签过滤便签
  Future<List<NoteFile>> getStickyNotesByTags(List<String> tags);

  /// 搜索便签
  Future<List<NoteFile>> searchStickyNotes(String query);

  /// 删除便签
  Future<void> deleteStickyNote(String filePath);

  /// 更新便签
  Future<NoteFile> updateStickyNote({
    required String filePath,
    String? title,
    String? content,
    List<String>? tags,
  });

  /// 生成便签标题
  String generateStickyNoteTitle(String? content);

  /// 生成便签文件名
  String generateStickyNoteFileName();

  /// 获取便签文件夹路径
  String get stickyNotesFolderPath;
}

/// 便签排序方式
enum StickyNoteSortBy {
  createdDate,
  modifiedDate,
  title,
  content,
}

/// 便签过滤选项
class StickyNoteFilter {
  final List<String>? tags;
  final String? searchQuery;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final StickyNoteSortBy sortBy;
  final bool ascending;

  const StickyNoteFilter({
    this.tags,
    this.searchQuery,
    this.createdAfter,
    this.createdBefore,
    this.sortBy = StickyNoteSortBy.createdDate,
    this.ascending = false,
  });

  StickyNoteFilter copyWith({
    List<String>? tags,
    String? searchQuery,
    DateTime? createdAfter,
    DateTime? createdBefore,
    StickyNoteSortBy? sortBy,
    bool? ascending,
  }) {
    return StickyNoteFilter(
      tags: tags ?? this.tags,
      searchQuery: searchQuery ?? this.searchQuery,
      createdAfter: createdAfter ?? this.createdAfter,
      createdBefore: createdBefore ?? this.createdBefore,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }
}