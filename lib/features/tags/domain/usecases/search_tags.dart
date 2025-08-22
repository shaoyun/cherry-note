import 'package:injectable/injectable.dart';

import '../entities/tag.dart';
import '../repositories/tag_repository.dart';

/// 搜索标签用例
@injectable
class SearchTags {
  final TagRepository _repository;

  const SearchTags(this._repository);

  /// 执行搜索标签操作
  Future<List<Tag>> call(SearchTagsParams params) async {
    if (params.query.trim().isEmpty) {
      return [];
    }

    return await _repository.searchTags(
      query: params.query,
      limit: params.limit,
    );
  }
}

/// 搜索标签参数
class SearchTagsParams {
  final String query;
  final int? limit;

  const SearchTagsParams({
    required this.query,
    this.limit,
  });
}