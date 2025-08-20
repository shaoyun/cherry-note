import '../repositories/tag_repository.dart';

/// 获取标签自动补全建议用例
class GetTagSuggestions {
  final TagRepository _repository;

  const GetTagSuggestions(this._repository);

  /// 执行获取标签建议操作
  Future<List<String>> call(GetTagSuggestionsParams params) async {
    if (params.query.trim().isEmpty) {
      // 如果查询为空，返回最近使用的标签
      final recentTags = await _repository.getRecentlyUsedTags(
        limit: params.limit,
      );
      return recentTags.map((tag) => tag.name).toList();
    }

    return await _repository.getTagSuggestions(
      query: params.query,
      limit: params.limit,
    );
  }
}

/// 获取标签建议参数
class GetTagSuggestionsParams {
  final String query;
  final int limit;

  const GetTagSuggestionsParams({
    required this.query,
    this.limit = 10,
  });
}