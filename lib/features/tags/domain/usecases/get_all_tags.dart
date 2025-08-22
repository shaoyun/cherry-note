import 'package:injectable/injectable.dart';

import '../entities/tag.dart';
import '../repositories/tag_repository.dart';

/// 获取所有标签用例
@injectable
class GetAllTags {
  final TagRepository _repository;

  const GetAllTags(this._repository);

  /// 执行获取所有标签操作
  Future<List<Tag>> call() async {
    return await _repository.getAllTags();
  }
}