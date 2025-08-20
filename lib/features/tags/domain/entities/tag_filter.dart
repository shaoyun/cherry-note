import 'package:equatable/equatable.dart';

/// 标签过滤器
class TagFilter extends Equatable {
  /// 选中的标签名称列表
  final List<String> selectedTags;
  
  /// 过滤逻辑类型
  final TagFilterLogic logic;
  
  /// 是否启用过滤
  final bool enabled;

  const TagFilter({
    this.selectedTags = const [],
    this.logic = TagFilterLogic.and,
    this.enabled = false,
  });

  /// 创建过滤器副本并更新指定字段
  TagFilter copyWith({
    List<String>? selectedTags,
    TagFilterLogic? logic,
    bool? enabled,
  }) {
    return TagFilter(
      selectedTags: selectedTags ?? this.selectedTags,
      logic: logic ?? this.logic,
      enabled: enabled ?? this.enabled,
    );
  }

  /// 添加标签到过滤器
  TagFilter addTag(String tagName) {
    if (selectedTags.contains(tagName)) {
      return this;
    }
    
    return copyWith(
      selectedTags: [...selectedTags, tagName],
      enabled: true,
    );
  }

  /// 从过滤器中移除标签
  TagFilter removeTag(String tagName) {
    final newTags = selectedTags.where((tag) => tag != tagName).toList();
    
    return copyWith(
      selectedTags: newTags,
      enabled: newTags.isNotEmpty,
    );
  }

  /// 切换标签选择状态
  TagFilter toggleTag(String tagName) {
    if (selectedTags.contains(tagName)) {
      return removeTag(tagName);
    } else {
      return addTag(tagName);
    }
  }

  /// 清除所有选中的标签
  TagFilter clear() {
    return copyWith(
      selectedTags: [],
      enabled: false,
    );
  }

  /// 检查标签是否被选中
  bool isTagSelected(String tagName) {
    return selectedTags.contains(tagName);
  }

  /// 检查是否有选中的标签
  bool get hasSelectedTags => selectedTags.isNotEmpty;

  /// 获取选中标签数量
  int get selectedCount => selectedTags.length;

  @override
  List<Object?> get props => [selectedTags, logic, enabled];

  @override
  String toString() {
    return 'TagFilter(selectedTags: $selectedTags, logic: $logic, enabled: $enabled)';
  }
}

/// 标签过滤逻辑类型
enum TagFilterLogic {
  /// AND逻辑：笔记必须包含所有选中的标签
  and,
  
  /// OR逻辑：笔记包含任意一个选中的标签即可
  or,
}

extension TagFilterLogicExtension on TagFilterLogic {
  /// 获取显示名称
  String get displayName {
    switch (this) {
      case TagFilterLogic.and:
        return 'AND';
      case TagFilterLogic.or:
        return 'OR';
    }
  }

  /// 获取描述
  String get description {
    switch (this) {
      case TagFilterLogic.and:
        return '笔记必须包含所有选中的标签';
      case TagFilterLogic.or:
        return '笔记包含任意一个选中的标签即可';
    }
  }
}