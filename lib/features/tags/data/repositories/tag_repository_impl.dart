import 'package:injectable/injectable.dart';

import '../../domain/entities/tag.dart';
import '../../domain/repositories/tag_repository.dart';

/// 标签仓储实现类（内存存储）
@LazySingleton(as: TagRepository)
class TagRepositoryImpl implements TagRepository {
  // 使用内存存储，实际应用中应该使用数据库
  final List<Tag> _tags = [];

  @override
  Future<List<Tag>> getAllTags() async {
    return List.from(_tags);
  }

  @override
  Future<Tag?> getTagByName(String name) async {
    try {
      return _tags.firstWhere((tag) => tag.name == name);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Tag> createTag({
    required String name,
    String? color,
    String? description,
  }) async {
    if (await tagExists(name)) {
      throw Exception('Tag with name "$name" already exists');
    }

    final now = DateTime.now();
    final tag = Tag(
      name: name,
      color: color,
      description: description,
      createdAt: now,
      lastUsedAt: now,
    );

    _tags.add(tag);
    return tag;
  }

  @override
  Future<Tag> updateTag(Tag tag) async {
    final index = _tags.indexWhere((t) => t.name == tag.name);
    if (index == -1) {
      throw Exception('Tag with name "${tag.name}" not found');
    }

    _tags[index] = tag;
    return tag;
  }

  @override
  Future<void> deleteTag(String name) async {
    _tags.removeWhere((tag) => tag.name == name);
  }

  @override
  Future<void> deleteTags(List<String> names) async {
    _tags.removeWhere((tag) => names.contains(tag.name));
  }

  @override
  Future<List<Tag>> searchTags({
    required String query,
    int? limit,
  }) async {
    final queryLower = query.toLowerCase();
    var results = _tags.where((tag) {
      return tag.name.toLowerCase().contains(queryLower) ||
             (tag.description?.toLowerCase().contains(queryLower) ?? false);
    }).toList();

    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }

  @override
  Future<List<String>> getTagSuggestions({
    required String query,
    int limit = 10,
  }) async {
    final queryLower = query.toLowerCase();
    var suggestions = _tags
        .where((tag) => tag.name.toLowerCase().startsWith(queryLower))
        .map((tag) => tag.name)
        .take(limit)
        .toList();

    return suggestions;
  }

  @override
  Future<List<Tag>> getMostUsedTags({
    int limit = 20,
  }) async {
    final sortedTags = List<Tag>.from(_tags);
    sortedTags.sort((a, b) => b.noteCount.compareTo(a.noteCount));
    return sortedTags.take(limit).toList();
  }

  @override
  Future<List<Tag>> getRecentlyUsedTags({
    int limit = 10,
  }) async {
    final sortedTags = List<Tag>.from(_tags);
    sortedTags.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    return sortedTags.take(limit).toList();
  }

  @override
  Future<void> updateTagUsage(String tagName) async {
    final index = _tags.indexWhere((tag) => tag.name == tagName);
    if (index != -1) {
      _tags[index] = _tags[index].copyWith(
        noteCount: _tags[index].noteCount + 1,
        lastUsedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> updateTagsUsage(List<String> tagNames) async {
    final now = DateTime.now();
    for (final tagName in tagNames) {
      final index = _tags.indexWhere((tag) => tag.name == tagName);
      if (index != -1) {
        _tags[index] = _tags[index].copyWith(
          noteCount: _tags[index].noteCount + 1,
          lastUsedAt: now,
        );
      }
    }
  }

  @override
  Future<List<String>> cleanupUnusedTags() async {
    final unusedTags = _tags.where((tag) => tag.isEmpty && !tag.isSystem);
    final unusedNames = unusedTags.map((tag) => tag.name).toList();
    _tags.removeWhere((tag) => tag.isEmpty && !tag.isSystem);
    return unusedNames;
  }

  @override
  Future<TagStats> getTagStats() async {
    final total = _tags.length;
    final used = _tags.where((tag) => !tag.isEmpty).length;
    final unused = _tags.where((tag) => tag.isEmpty).length;
    final system = _tags.where((tag) => tag.isSystem).length;

    Tag? mostUsed;
    Tag? newest;

    if (_tags.isNotEmpty) {
      mostUsed = _tags.reduce((a, b) => 
          a.noteCount > b.noteCount ? a : b);
      newest = _tags.reduce((a, b) => 
          a.createdAt.isAfter(b.createdAt) ? a : b);
    }

    return TagStats(
      totalTags: total,
      usedTags: used,
      unusedTags: unused,
      systemTags: system,
      mostUsedTag: mostUsed,
      newestTag: newest,
    );
  }

  @override
  bool isValidTagName(String name) {
    return name.trim().isNotEmpty && 
           !name.contains(RegExp(r'[<>:"/\\|?*]')) &&
           name.length <= 50;
  }

  @override
  Future<bool> tagExists(String name) async {
    return _tags.any((tag) => tag.name == name);
  }

  @override
  Future<void> syncTags() async {
    // TODO: 实现标签同步逻辑
    // 这里应该与远程存储同步标签数据
  }
}