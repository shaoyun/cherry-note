import '../entities/tag.dart';

/// 标签仓储接口
abstract class TagRepository {
  /// 获取所有标签
  Future<List<Tag>> getAllTags();

  /// 根据名称获取标签
  Future<Tag?> getTagByName(String name);

  /// 创建新标签
  Future<Tag> createTag({
    required String name,
    String? color,
    String? description,
  });

  /// 更新标签
  Future<Tag> updateTag(Tag tag);

  /// 删除标签
  Future<void> deleteTag(String name);

  /// 批量删除标签
  Future<void> deleteTags(List<String> names);

  /// 搜索标签
  Future<List<Tag>> searchTags({
    required String query,
    int? limit,
  });

  /// 获取标签自动补全建议
  Future<List<String>> getTagSuggestions({
    required String query,
    int limit = 10,
  });

  /// 获取最常用的标签
  Future<List<Tag>> getMostUsedTags({
    int limit = 20,
  });

  /// 获取最近使用的标签
  Future<List<Tag>> getRecentlyUsedTags({
    int limit = 10,
  });

  /// 更新标签使用统计
  Future<void> updateTagUsage(String tagName);

  /// 批量更新标签使用统计
  Future<void> updateTagsUsage(List<String> tagNames);

  /// 清理未使用的标签
  Future<List<String>> cleanupUnusedTags();

  /// 获取标签统计信息
  Future<TagStats> getTagStats();

  /// 检查标签名称是否有效
  bool isValidTagName(String name);

  /// 检查标签是否存在
  Future<bool> tagExists(String name);

  /// 同步标签数据
  Future<void> syncTags();
}

/// 标签统计信息
class TagStats {
  /// 总标签数
  final int totalTags;
  
  /// 使用中的标签数
  final int usedTags;
  
  /// 未使用的标签数
  final int unusedTags;
  
  /// 系统标签数
  final int systemTags;
  
  /// 最常用的标签
  final Tag? mostUsedTag;
  
  /// 最近创建的标签
  final Tag? newestTag;

  const TagStats({
    required this.totalTags,
    required this.usedTags,
    required this.unusedTags,
    required this.systemTags,
    this.mostUsedTag,
    this.newestTag,
  });

  /// 获取使用率
  double get usageRate {
    if (totalTags == 0) return 0.0;
    return usedTags / totalTags;
  }
}