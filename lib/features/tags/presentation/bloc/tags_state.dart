import 'package:equatable/equatable.dart';
import '../../domain/entities/tag.dart';
import '../../domain/entities/tag_filter.dart';
import '../../domain/repositories/tag_repository.dart';
import 'tags_event.dart';

/// 标签管理状态基类
abstract class TagsState extends Equatable {
  const TagsState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class TagsInitial extends TagsState {
  const TagsInitial();
}

/// 加载中状态
class TagsLoading extends TagsState {
  const TagsLoading();
}

/// 标签已加载状态
class TagsLoaded extends TagsState {
  final List<Tag> tags;
  final TagFilter filter;
  final TagSortBy sortBy;
  final bool ascending;
  final String? searchQuery;
  final List<Tag>? searchResults;
  final List<String>? suggestions;
  final List<Tag>? mostUsedTags;
  final List<Tag>? recentlyUsedTags;
  final TagStats? stats;

  const TagsLoaded({
    required this.tags,
    this.filter = const TagFilter(),
    this.sortBy = TagSortBy.name,
    this.ascending = true,
    this.searchQuery,
    this.searchResults,
    this.suggestions,
    this.mostUsedTags,
    this.recentlyUsedTags,
    this.stats,
  });

  /// 复制状态并更新指定字段
  TagsLoaded copyWith({
    List<Tag>? tags,
    TagFilter? filter,
    TagSortBy? sortBy,
    bool? ascending,
    String? searchQuery,
    List<Tag>? searchResults,
    List<String>? suggestions,
    List<Tag>? mostUsedTags,
    List<Tag>? recentlyUsedTags,
    TagStats? stats,
    bool clearSearch = false,
    bool clearSuggestions = false,
  }) {
    return TagsLoaded(
      tags: tags ?? this.tags,
      filter: filter ?? this.filter,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      searchResults: clearSearch ? null : (searchResults ?? this.searchResults),
      suggestions: clearSuggestions ? null : (suggestions ?? this.suggestions),
      mostUsedTags: mostUsedTags ?? this.mostUsedTags,
      recentlyUsedTags: recentlyUsedTags ?? this.recentlyUsedTags,
      stats: stats ?? this.stats,
    );
  }

  /// 获取当前显示的标签列表（搜索结果或全部标签）
  List<Tag> get displayedTags {
    return searchResults ?? tags;
  }

  /// 检查是否在搜索模式
  bool get isSearching {
    return searchQuery != null && searchQuery!.isNotEmpty;
  }

  /// 检查是否有过滤器激活
  bool get hasActiveFilter {
    return filter.enabled && filter.hasSelectedTags;
  }

  /// 获取选中的标签数量
  int get selectedTagCount {
    return filter.selectedCount;
  }

  /// 检查标签是否被选中用于过滤
  bool isTagSelectedForFilter(String tagName) {
    return filter.isTagSelected(tagName);
  }

  /// 获取过滤逻辑显示文本
  String get filterLogicText {
    return filter.logic.displayName;
  }

  @override
  List<Object?> get props => [
        tags,
        filter,
        sortBy,
        ascending,
        searchQuery,
        searchResults,
        suggestions,
        mostUsedTags,
        recentlyUsedTags,
        stats,
      ];
}

/// 标签操作进行中状态
class TagOperationInProgress extends TagsState {
  final String operation;
  final String? tagName;
  final String? message;

  const TagOperationInProgress({
    required this.operation,
    this.tagName,
    this.message,
  });

  @override
  List<Object?> get props => [operation, tagName, message];
}

/// 标签操作成功状态
class TagOperationSuccess extends TagsState {
  final String operation;
  final String message;
  final String? tagName;
  final Tag? tag;

  const TagOperationSuccess({
    required this.operation,
    required this.message,
    this.tagName,
    this.tag,
  });

  @override
  List<Object?> get props => [operation, message, tagName, tag];
}

/// 标签操作错误状态
class TagOperationError extends TagsState {
  final String operation;
  final String message;
  final String? tagName;
  final Object? error;

  const TagOperationError({
    required this.operation,
    required this.message,
    this.tagName,
    this.error,
  });

  @override
  List<Object?> get props => [operation, message, tagName, error];
}

/// 标签搜索中状态
class TagsSearching extends TagsState {
  final String query;

  const TagsSearching({
    required this.query,
  });

  @override
  List<Object?> get props => [query];
}

/// 标签搜索结果状态
class TagsSearchResults extends TagsState {
  final String query;
  final List<Tag> results;
  final int totalResults;

  const TagsSearchResults({
    required this.query,
    required this.results,
    required this.totalResults,
  });

  @override
  List<Object?> get props => [query, results, totalResults];
}

/// 标签自动补全建议状态
class TagSuggestions extends TagsState {
  final String query;
  final List<String> suggestions;

  const TagSuggestions({
    required this.query,
    required this.suggestions,
  });

  @override
  List<Object?> get props => [query, suggestions];
}

/// 批量操作进行中状态
class TagsBatchOperation extends TagsState {
  final String operation;
  final List<String> tagNames;
  final int completed;
  final int total;
  final String? currentTag;

  const TagsBatchOperation({
    required this.operation,
    required this.tagNames,
    required this.completed,
    required this.total,
    this.currentTag,
  });

  /// 获取进度百分比
  double get progress {
    if (total == 0) return 0.0;
    return completed / total;
  }

  @override
  List<Object?> get props => [operation, tagNames, completed, total, currentTag];
}

/// 批量操作成功状态
class TagsBatchOperationSuccess extends TagsState {
  final String operation;
  final List<String> tagNames;
  final int successCount;
  final int failureCount;
  final List<String> errors;

  const TagsBatchOperationSuccess({
    required this.operation,
    required this.tagNames,
    required this.successCount,
    required this.failureCount,
    this.errors = const [],
  });

  /// 检查是否有失败的操作
  bool get hasFailures => failureCount > 0;

  /// 检查是否全部成功
  bool get allSuccessful => failureCount == 0;

  @override
  List<Object?> get props => [operation, tagNames, successCount, failureCount, errors];
}

/// 标签同步中状态
class TagsSyncing extends TagsState {
  final String? message;

  const TagsSyncing({
    this.message,
  });

  @override
  List<Object?> get props => [message];
}

/// 标签同步成功状态
class TagsSyncSuccess extends TagsState {
  final String message;
  final int syncedCount;

  const TagsSyncSuccess({
    required this.message,
    required this.syncedCount,
  });

  @override
  List<Object?> get props => [message, syncedCount];
}

/// 标签清理成功状态
class TagsCleanupSuccess extends TagsState {
  final List<String> cleanedTags;
  final String message;

  const TagsCleanupSuccess({
    required this.cleanedTags,
    required this.message,
  });

  @override
  List<Object?> get props => [cleanedTags, message];
}

/// 标签错误状态
class TagsError extends TagsState {
  final String message;
  final Object? error;

  const TagsError({
    required this.message,
    this.error,
  });

  @override
  List<Object?> get props => [message, error];
}