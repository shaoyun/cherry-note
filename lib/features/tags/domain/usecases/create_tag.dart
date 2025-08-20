import '../entities/tag.dart';
import '../repositories/tag_repository.dart';

/// 创建标签用例
class CreateTag {
  final TagRepository _repository;

  const CreateTag(this._repository);

  /// 执行创建标签操作
  Future<Tag> call(CreateTagParams params) async {
    // 验证标签名称
    if (!_repository.isValidTagName(params.name)) {
      throw ArgumentError('Invalid tag name: ${params.name}');
    }

    // 检查标签是否已存在
    if (await _repository.tagExists(params.name)) {
      throw StateError('Tag already exists: ${params.name}');
    }

    return await _repository.createTag(
      name: params.name,
      color: params.color,
      description: params.description,
    );
  }
}

/// 创建标签参数
class CreateTagParams {
  final String name;
  final String? color;
  final String? description;

  const CreateTagParams({
    required this.name,
    this.color,
    this.description,
  });
}