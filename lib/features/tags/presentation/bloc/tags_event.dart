import 'package:equatable/equatable.dart';
import '../../domain/entities/tag_filter.dart';

/// 标签管理事件基类
abstract class TagsEvent extends Equatable {
  const TagsEvent();

  @override
  List<Object?> get props => [];
}

/// 加载所有标签事件
class LoadTagsEvent extends TagsEvent {
  final bool forceRefresh;

  const LoadTagsEvent({
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [forceRefresh];
}

/// 创建标签事件
class CreateTagEvent extends TagsEvent {
  final String name;
  final String? color;
  final String? description;

  const CreateTagEvent({
    required this.name,
    this.color,
    this.description,
  });

  @override
  List<Object?> get props => [name, color, description];
}

/// 更新标签事件
class UpdateTagEvent extends TagsEvent {
  final String originalName;
  final String? newName;
  final String? color;
  final String? description;

  const UpdateTagEvent({
    required this.originalName,
    this.newName,
    this.color,
    this.description,
  });

  @override
  List<Object?> get props => [originalName, newName, color, description];
}

/// 删除标签事件
class DeleteTagEvent extends TagsEvent {
  final String name;
  final bool force;

  const DeleteTagEvent({
    required this.name,
    this.force = false,
  });

  @override
  List<Object?> get props => [name, force];
}

/// 批量删除标签事件
class BatchDeleteTagsEvent extends TagsEvent {
  final List<String> names;
  final bool force;

  const BatchDeleteTagsEvent({
    required this.names,
    this.force = false,
  });

  @override
  List<Object?> get props => [names, force];
}

/// 搜索标签事件
class SearchTagsEvent extends TagsEvent {
  final String query;
  final int? limit;

  const SearchTagsEvent({
    required this.query,
    this.limit,
  });

  @override
  List<Object?> get props => [query, limit];
}

/// 清除标签搜索事件
class ClearTagSearchEvent extends TagsEvent {
  const ClearTagSearchEvent();
}

/// 获取标签自动补全建议事件
class GetTagSuggestionsEvent extends TagsEvent {
  final String query;
  final int limit;

  const GetTagSuggestionsEvent({
    required this.query,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [query, limit];
}

/// 选择标签进行过滤事件
class SelectTagForFilterEvent extends TagsEvent {
  final String tagName;

  const SelectTagForFilterEvent({
    required this.tagName,
  });

  @override
  List<Object?> get props => [tagName];
}

/// 取消选择标签过滤事件
class DeselectTagForFilterEvent extends TagsEvent {
  final String tagName;

  const DeselectTagForFilterEvent({
    required this.tagName,
  });

  @override
  List<Object?> get props => [tagName];
}

/// 切换标签过滤选择事件
class ToggleTagFilterEvent extends TagsEvent {
  final String tagName;

  const ToggleTagFilterEvent({
    required this.tagName,
  });

  @override
  List<Object?> get props => [tagName];
}

/// 设置标签过滤逻辑事件
class SetTagFilterLogicEvent extends TagsEvent {
  final TagFilterLogic logic;

  const SetTagFilterLogicEvent({
    required this.logic,
  });

  @override
  List<Object?> get props => [logic];
}

/// 清除标签过滤事件
class ClearTagFilterEvent extends TagsEvent {
  const ClearTagFilterEvent();
}

/// 应用标签过滤事件
class ApplyTagFilterEvent extends TagsEvent {
  const ApplyTagFilterEvent();
}

/// 获取最常用标签事件
class GetMostUsedTagsEvent extends TagsEvent {
  final int limit;

  const GetMostUsedTagsEvent({
    this.limit = 20,
  });

  @override
  List<Object?> get props => [limit];
}

/// 获取最近使用标签事件
class GetRecentlyUsedTagsEvent extends TagsEvent {
  final int limit;

  const GetRecentlyUsedTagsEvent({
    this.limit = 10,
  });

  @override
  List<Object?> get props => [limit];
}

/// 更新标签使用统计事件
class UpdateTagUsageEvent extends TagsEvent {
  final String tagName;

  const UpdateTagUsageEvent({
    required this.tagName,
  });

  @override
  List<Object?> get props => [tagName];
}

/// 批量更新标签使用统计事件
class BatchUpdateTagUsageEvent extends TagsEvent {
  final List<String> tagNames;

  const BatchUpdateTagUsageEvent({
    required this.tagNames,
  });

  @override
  List<Object?> get props => [tagNames];
}

/// 清理未使用标签事件
class CleanupUnusedTagsEvent extends TagsEvent {
  const CleanupUnusedTagsEvent();
}

/// 获取标签统计信息事件
class GetTagStatsEvent extends TagsEvent {
  const GetTagStatsEvent();
}

/// 同步标签事件
class SyncTagsEvent extends TagsEvent {
  const SyncTagsEvent();
}

/// 设置标签排序事件
class SetTagSortEvent extends TagsEvent {
  final TagSortBy sortBy;
  final bool ascending;

  const SetTagSortEvent({
    required this.sortBy,
    this.ascending = true,
  });

  @override
  List<Object?> get props => [sortBy, ascending];
}

/// 标签排序方式
enum TagSortBy {
  name,
  noteCount,
  createdDate,
  lastUsedDate,
  color,
}