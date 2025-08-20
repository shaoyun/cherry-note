import '../repositories/tag_repository.dart';

/// 删除标签用例
class DeleteTag {
  final TagRepository _repository;

  const DeleteTag(this._repository);

  /// 执行删除标签操作
  Future<void> call(DeleteTagParams params) async {
    // 检查标签是否存在
    final tag = await _repository.getTagByName(params.name);
    if (tag == null) {
      throw StateError('Tag not found: ${params.name}');
    }

    // 检查是否为系统标签
    if (tag.isSystem) {
      throw StateError('Cannot delete system tag: ${params.name}');
    }

    // 如果强制删除或标签未被使用，则删除
    if (params.force || tag.isEmpty) {
      await _repository.deleteTag(params.name);
    } else {
      throw StateError('Cannot delete tag in use: ${params.name}. Use force=true to delete anyway.');
    }
  }
}

/// 删除标签参数
class DeleteTagParams {
  final String name;
  final bool force;

  const DeleteTagParams({
    required this.name,
    this.force = false,
  });
}