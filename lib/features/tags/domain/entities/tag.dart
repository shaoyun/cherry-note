import 'package:equatable/equatable.dart';

/// 标签实体
class Tag extends Equatable {
  /// 标签名称（唯一标识）
  final String name;
  
  /// 标签颜色（十六进制颜色代码）
  final String? color;
  
  /// 标签描述
  final String? description;
  
  /// 使用该标签的笔记数量
  final int noteCount;
  
  /// 标签创建时间
  final DateTime createdAt;
  
  /// 标签最后使用时间
  final DateTime lastUsedAt;
  
  /// 是否为系统标签（不可删除）
  final bool isSystem;

  const Tag({
    required this.name,
    this.color,
    this.description,
    this.noteCount = 0,
    required this.createdAt,
    required this.lastUsedAt,
    this.isSystem = false,
  });

  /// 创建标签副本并更新指定字段
  Tag copyWith({
    String? name,
    String? color,
    String? description,
    int? noteCount,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    bool? isSystem,
  }) {
    return Tag(
      name: name ?? this.name,
      color: color ?? this.color,
      description: description ?? this.description,
      noteCount: noteCount ?? this.noteCount,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      isSystem: isSystem ?? this.isSystem,
    );
  }

  /// 检查标签是否为空（未使用）
  bool get isEmpty => noteCount == 0;

  /// 检查标签是否可以删除
  bool get canDelete => !isSystem && isEmpty;

  @override
  List<Object?> get props => [
        name,
        color,
        description,
        noteCount,
        createdAt,
        lastUsedAt,
        isSystem,
      ];

  @override
  String toString() {
    return 'Tag(name: $name, noteCount: $noteCount, color: $color)';
  }
}