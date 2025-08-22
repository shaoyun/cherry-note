import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/tag.dart';
import '../../domain/entities/tag_filter.dart';
import '../../domain/repositories/tag_repository.dart';
import '../../domain/usecases/get_all_tags.dart';
import '../../domain/usecases/create_tag.dart';
import '../../domain/usecases/search_tags.dart';
import '../../domain/usecases/get_tag_suggestions.dart';
import '../../domain/usecases/delete_tag.dart';
import 'tags_event.dart';
import 'tags_state.dart';

/// 标签管理BLoC
@injectable
class TagsBloc extends Bloc<TagsEvent, TagsState> {
  final TagRepository _tagRepository;
  final GetAllTags _getAllTags;
  final CreateTag _createTag;
  final SearchTags _searchTags;
  final GetTagSuggestions _getTagSuggestions;
  final DeleteTag _deleteTag;

  // 当前状态缓存
  List<Tag> _allTags = [];
  TagFilter _currentFilter = const TagFilter();
  TagSortBy _currentSortBy = TagSortBy.name;
  bool _currentAscending = true;
  String? _currentSearchQuery;

  TagsBloc({
    required TagRepository tagRepository,
    required GetAllTags getAllTags,
    required CreateTag createTag,
    required SearchTags searchTags,
    required GetTagSuggestions getTagSuggestions,
    required DeleteTag deleteTag,
  })  : _tagRepository = tagRepository,
        _getAllTags = getAllTags,
        _createTag = createTag,
        _searchTags = searchTags,
        _getTagSuggestions = getTagSuggestions,
        _deleteTag = deleteTag,
        super(const TagsInitial()) {
    // 注册事件处理器
    on<LoadTagsEvent>(_onLoadTags);
    on<CreateTagEvent>(_onCreateTag);
    on<UpdateTagEvent>(_onUpdateTag);
    on<DeleteTagEvent>(_onDeleteTag);
    on<BatchDeleteTagsEvent>(_onBatchDeleteTags);
    on<SearchTagsEvent>(_onSearchTags);
    on<ClearTagSearchEvent>(_onClearTagSearch);
    on<GetTagSuggestionsEvent>(_onGetTagSuggestions);
    on<SelectTagForFilterEvent>(_onSelectTagForFilter);
    on<DeselectTagForFilterEvent>(_onDeselectTagForFilter);
    on<ToggleTagFilterEvent>(_onToggleTagFilter);
    on<SetTagFilterLogicEvent>(_onSetTagFilterLogic);
    on<ClearTagFilterEvent>(_onClearTagFilter);
    on<ApplyTagFilterEvent>(_onApplyTagFilter);
    on<GetMostUsedTagsEvent>(_onGetMostUsedTags);
    on<GetRecentlyUsedTagsEvent>(_onGetRecentlyUsedTags);
    on<UpdateTagUsageEvent>(_onUpdateTagUsage);
    on<BatchUpdateTagUsageEvent>(_onBatchUpdateTagUsage);
    on<CleanupUnusedTagsEvent>(_onCleanupUnusedTags);
    on<GetTagStatsEvent>(_onGetTagStats);
    on<SyncTagsEvent>(_onSyncTags);
    on<SetTagSortEvent>(_onSetTagSort);
  }

  /// 加载所有标签
  Future<void> _onLoadTags(LoadTagsEvent event, Emitter<TagsState> emit) async {
    try {
      emit(const TagsLoading());

      // 如果不是强制刷新且已有数据，直接使用缓存
      if (!event.forceRefresh && _allTags.isNotEmpty) {
        final sortedTags = _applySorting(_allTags);
        emit(_buildLoadedState(sortedTags));
        return;
      }

      // 从仓储加载标签
      final tags = await _getAllTags();
      _allTags = tags;

      // 应用排序
      final sortedTags = _applySorting(tags);

      emit(_buildLoadedState(sortedTags));
    } catch (e) {
      emit(TagsError(
        message: 'Failed to load tags: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 创建标签
  Future<void> _onCreateTag(CreateTagEvent event, Emitter<TagsState> emit) async {
    try {
      emit(TagOperationInProgress(
        operation: 'create',
        tagName: event.name,
        message: 'Creating tag "${event.name}"...',
      ));

      // 创建标签
      final newTag = await _createTag(CreateTagParams(
        name: event.name,
        color: event.color,
        description: event.description,
      ));

      // 更新缓存
      _addTagToCache(newTag);

      emit(TagOperationSuccess(
        operation: 'create',
        message: 'Tag "${event.name}" created successfully',
        tagName: newTag.name,
        tag: newTag,
      ));

      // 立即更新列表状态
      final sortedTags = _applySorting(_allTags);
      emit(_buildLoadedState(sortedTags));
    } catch (e) {
      emit(TagOperationError(
        operation: 'create',
        message: 'Failed to create tag: ${e.toString()}',
        tagName: event.name,
        error: e,
      ));
    }
  }

  /// 更新标签
  Future<void> _onUpdateTag(UpdateTagEvent event, Emitter<TagsState> emit) async {
    try {
      emit(TagOperationInProgress(
        operation: 'update',
        tagName: event.originalName,
        message: 'Updating tag "${event.originalName}"...',
      ));

      // 获取现有标签
      final existingTag = await _tagRepository.getTagByName(event.originalName);
      if (existingTag == null) {
        throw Exception('Tag not found: ${event.originalName}');
      }

      // 更新标签
      final updatedTag = existingTag.copyWith(
        name: event.newName ?? existingTag.name,
        color: event.color ?? existingTag.color,
        description: event.description ?? existingTag.description,
        lastUsedAt: DateTime.now(),
      );

      final savedTag = await _tagRepository.updateTag(updatedTag);

      // 更新缓存
      _updateTagInCache(event.originalName, savedTag);

      // 如果标签名称发生变化，更新过滤器
      if (event.newName != null && event.newName != event.originalName) {
        if (_currentFilter.isTagSelected(event.originalName)) {
          _currentFilter = _currentFilter
              .removeTag(event.originalName)
              .addTag(event.newName!);
        }
      }

      emit(TagOperationSuccess(
        operation: 'update',
        message: 'Tag updated successfully',
        tagName: savedTag.name,
        tag: savedTag,
      ));

      // 立即更新列表状态
      final sortedTags = _applySorting(_allTags);
      emit(_buildLoadedState(sortedTags));
    } catch (e) {
      emit(TagOperationError(
        operation: 'update',
        message: 'Failed to update tag: ${e.toString()}',
        tagName: event.originalName,
        error: e,
      ));
    }
  }

  /// 删除标签
  Future<void> _onDeleteTag(DeleteTagEvent event, Emitter<TagsState> emit) async {
    try {
      emit(TagOperationInProgress(
        operation: 'delete',
        tagName: event.name,
        message: 'Deleting tag "${event.name}"...',
      ));

      // 删除标签
      await _deleteTag(DeleteTagParams(
        name: event.name,
        force: event.force,
      ));

      // 从缓存中移除
      _removeTagFromCache(event.name);

      // 从过滤器中移除
      if (_currentFilter.isTagSelected(event.name)) {
        _currentFilter = _currentFilter.removeTag(event.name);
      }

      emit(TagOperationSuccess(
        operation: 'delete',
        message: 'Tag "${event.name}" deleted successfully',
        tagName: event.name,
      ));

      // 立即更新列表状态
      final sortedTags = _applySorting(_allTags);
      emit(_buildLoadedState(sortedTags));
    } catch (e) {
      emit(TagOperationError(
        operation: 'delete',
        message: 'Failed to delete tag: ${e.toString()}',
        tagName: event.name,
        error: e,
      ));
    }
  }

  /// 批量删除标签
  Future<void> _onBatchDeleteTags(BatchDeleteTagsEvent event, Emitter<TagsState> emit) async {
    try {
      emit(TagsBatchOperation(
        operation: 'delete',
        tagNames: event.names,
        completed: 0,
        total: event.names.length,
      ));

      Map<String, bool> results = {};
      int completed = 0;
      final errors = <String>[];

      for (final tagName in event.names) {
        try {
          emit(TagsBatchOperation(
            operation: 'delete',
            tagNames: event.names,
            completed: completed,
            total: event.names.length,
            currentTag: tagName,
          ));

          await _deleteTag(DeleteTagParams(
            name: tagName,
            force: event.force,
          ));

          _removeTagFromCache(tagName);
          
          // 从过滤器中移除
          if (_currentFilter.isTagSelected(tagName)) {
            _currentFilter = _currentFilter.removeTag(tagName);
          }

          results[tagName] = true;
          completed++;
        } catch (e) {
          results[tagName] = false;
          errors.add('$tagName: ${e.toString()}');
        }
      }

      final failureCount = event.names.length - completed;

      emit(TagsBatchOperationSuccess(
        operation: 'delete',
        tagNames: event.names,
        successCount: completed,
        failureCount: failureCount,
        errors: errors,
      ));

      // 立即更新列表状态
      final sortedTags = _applySorting(_allTags);
      emit(_buildLoadedState(sortedTags));
    } catch (e) {
      emit(TagsError(
        message: 'Batch delete failed: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 搜索标签
  Future<void> _onSearchTags(SearchTagsEvent event, Emitter<TagsState> emit) async {
    try {
      emit(TagsSearching(query: event.query));

      _currentSearchQuery = event.query;

      // 执行搜索
      final searchResults = await _searchTags(SearchTagsParams(
        query: event.query,
        limit: event.limit,
      ));

      emit(TagsSearchResults(
        query: event.query,
        results: searchResults,
        totalResults: searchResults.length,
      ));

      // 更新主状态以包含搜索结果
      if (state is TagsLoaded || _allTags.isNotEmpty) {
        final sortedTags = _applySorting(_allTags);
        emit(_buildLoadedState(
          sortedTags,
          searchResults: searchResults,
        ));
      }
    } catch (e) {
      emit(TagsError(
        message: 'Search failed: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 清除标签搜索
  Future<void> _onClearTagSearch(ClearTagSearchEvent event, Emitter<TagsState> emit) async {
    _currentSearchQuery = null;
    
    if (state is TagsLoaded) {
      final currentState = state as TagsLoaded;
      emit(currentState.copyWith(clearSearch: true));
    }
  }

  /// 获取标签自动补全建议
  Future<void> _onGetTagSuggestions(GetTagSuggestionsEvent event, Emitter<TagsState> emit) async {
    try {
      final suggestions = await _getTagSuggestions(GetTagSuggestionsParams(
        query: event.query,
        limit: event.limit,
      ));

      emit(TagSuggestions(
        query: event.query,
        suggestions: suggestions,
      ));

      // 如果当前是已加载状态，更新建议
      if (state is TagsLoaded) {
        final currentState = state as TagsLoaded;
        emit(currentState.copyWith(suggestions: suggestions));
      }
    } catch (e) {
      emit(TagsError(
        message: 'Failed to get suggestions: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 选择标签进行过滤
  Future<void> _onSelectTagForFilter(SelectTagForFilterEvent event, Emitter<TagsState> emit) async {
    _currentFilter = _currentFilter.addTag(event.tagName);
    
    if (state is TagsLoaded) {
      final currentState = state as TagsLoaded;
      emit(currentState.copyWith(filter: _currentFilter));
    }
  }

  /// 取消选择标签过滤
  Future<void> _onDeselectTagForFilter(DeselectTagForFilterEvent event, Emitter<TagsState> emit) async {
    _currentFilter = _currentFilter.removeTag(event.tagName);
    
    if (state is TagsLoaded) {
      final currentState = state as TagsLoaded;
      emit(currentState.copyWith(filter: _currentFilter));
    }
  }

  /// 切换标签过滤选择
  Future<void> _onToggleTagFilter(ToggleTagFilterEvent event, Emitter<TagsState> emit) async {
    _currentFilter = _currentFilter.toggleTag(event.tagName);
    
    if (state is TagsLoaded) {
      final currentState = state as TagsLoaded;
      emit(currentState.copyWith(filter: _currentFilter));
    }
  }

  /// 设置标签过滤逻辑
  Future<void> _onSetTagFilterLogic(SetTagFilterLogicEvent event, Emitter<TagsState> emit) async {
    _currentFilter = _currentFilter.copyWith(logic: event.logic);
    
    if (state is TagsLoaded) {
      final currentState = state as TagsLoaded;
      emit(currentState.copyWith(filter: _currentFilter));
    }
  }

  /// 清除标签过滤
  Future<void> _onClearTagFilter(ClearTagFilterEvent event, Emitter<TagsState> emit) async {
    _currentFilter = _currentFilter.clear();
    
    if (state is TagsLoaded) {
      final currentState = state as TagsLoaded;
      emit(currentState.copyWith(filter: _currentFilter));
    }
  }

  /// 应用标签过滤
  Future<void> _onApplyTagFilter(ApplyTagFilterEvent event, Emitter<TagsState> emit) async {
    // 这个事件主要用于通知其他组件应用过滤器
    // 实际的过滤逻辑应该在使用标签过滤器的地方实现
    if (state is TagsLoaded) {
      final currentState = state as TagsLoaded;
      emit(currentState.copyWith(filter: _currentFilter));
    }
  }

  /// 获取最常用标签
  Future<void> _onGetMostUsedTags(GetMostUsedTagsEvent event, Emitter<TagsState> emit) async {
    try {
      final mostUsedTags = await _tagRepository.getMostUsedTags(limit: event.limit);
      
      if (state is TagsLoaded) {
        final currentState = state as TagsLoaded;
        emit(currentState.copyWith(mostUsedTags: mostUsedTags));
      }
    } catch (e) {
      emit(TagsError(
        message: 'Failed to get most used tags: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 获取最近使用标签
  Future<void> _onGetRecentlyUsedTags(GetRecentlyUsedTagsEvent event, Emitter<TagsState> emit) async {
    try {
      final recentlyUsedTags = await _tagRepository.getRecentlyUsedTags(limit: event.limit);
      
      if (state is TagsLoaded) {
        final currentState = state as TagsLoaded;
        emit(currentState.copyWith(recentlyUsedTags: recentlyUsedTags));
      }
    } catch (e) {
      emit(TagsError(
        message: 'Failed to get recently used tags: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 更新标签使用统计
  Future<void> _onUpdateTagUsage(UpdateTagUsageEvent event, Emitter<TagsState> emit) async {
    try {
      await _tagRepository.updateTagUsage(event.tagName);
      
      // 更新缓存中的标签
      final tagIndex = _allTags.indexWhere((tag) => tag.name == event.tagName);
      if (tagIndex != -1) {
        final updatedTag = _allTags[tagIndex].copyWith(
          lastUsedAt: DateTime.now(),
          noteCount: _allTags[tagIndex].noteCount + 1,
        );
        _allTags[tagIndex] = updatedTag;
        
        // 如果当前是已加载状态，更新显示
        if (state is TagsLoaded) {
          final sortedTags = _applySorting(_allTags);
          emit(_buildLoadedState(sortedTags));
        }
      }
    } catch (e) {
      // 静默处理错误，不影响主要功能
    }
  }

  /// 批量更新标签使用统计
  Future<void> _onBatchUpdateTagUsage(BatchUpdateTagUsageEvent event, Emitter<TagsState> emit) async {
    try {
      await _tagRepository.updateTagsUsage(event.tagNames);
      
      // 更新缓存中的标签
      final now = DateTime.now();
      for (final tagName in event.tagNames) {
        final tagIndex = _allTags.indexWhere((tag) => tag.name == tagName);
        if (tagIndex != -1) {
          final updatedTag = _allTags[tagIndex].copyWith(
            lastUsedAt: now,
            noteCount: _allTags[tagIndex].noteCount + 1,
          );
          _allTags[tagIndex] = updatedTag;
        }
      }
      
      // 如果当前是已加载状态，更新显示
      if (state is TagsLoaded) {
        final sortedTags = _applySorting(_allTags);
        emit(_buildLoadedState(sortedTags));
      }
    } catch (e) {
      // 静默处理错误，不影响主要功能
    }
  }

  /// 清理未使用标签
  Future<void> _onCleanupUnusedTags(CleanupUnusedTagsEvent event, Emitter<TagsState> emit) async {
    try {
      emit(TagOperationInProgress(
        operation: 'cleanup',
        message: 'Cleaning up unused tags...',
      ));

      final cleanedTags = await _tagRepository.cleanupUnusedTags();
      
      // 从缓存中移除清理的标签
      for (final tagName in cleanedTags) {
        _removeTagFromCache(tagName);
        
        // 从过滤器中移除
        if (_currentFilter.isTagSelected(tagName)) {
          _currentFilter = _currentFilter.removeTag(tagName);
        }
      }

      emit(TagsCleanupSuccess(
        cleanedTags: cleanedTags,
        message: 'Cleaned up ${cleanedTags.length} unused tags',
      ));

      // 立即更新列表状态
      final sortedTags = _applySorting(_allTags);
      emit(_buildLoadedState(sortedTags));
    } catch (e) {
      emit(TagsError(
        message: 'Failed to cleanup unused tags: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 获取标签统计信息
  Future<void> _onGetTagStats(GetTagStatsEvent event, Emitter<TagsState> emit) async {
    try {
      final stats = await _tagRepository.getTagStats();
      
      if (state is TagsLoaded) {
        final currentState = state as TagsLoaded;
        emit(currentState.copyWith(stats: stats));
      }
    } catch (e) {
      emit(TagsError(
        message: 'Failed to get tag stats: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 同步标签
  Future<void> _onSyncTags(SyncTagsEvent event, Emitter<TagsState> emit) async {
    try {
      emit(const TagsSyncing(message: 'Syncing tags...'));

      await _tagRepository.syncTags();

      // 重新加载标签
      final tags = await _getAllTags();
      _allTags = tags;

      emit(TagsSyncSuccess(
        message: 'Tags synced successfully',
        syncedCount: tags.length,
      ));

      // 立即更新列表状态
      final sortedTags = _applySorting(_allTags);
      emit(_buildLoadedState(sortedTags));
    } catch (e) {
      emit(TagsError(
        message: 'Failed to sync tags: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 设置标签排序
  Future<void> _onSetTagSort(SetTagSortEvent event, Emitter<TagsState> emit) async {
    _currentSortBy = event.sortBy;
    _currentAscending = event.ascending;

    final sortedTags = _applySorting(_allTags);

    if (state is TagsLoaded) {
      final currentState = state as TagsLoaded;
      emit(currentState.copyWith(
        tags: sortedTags,
        sortBy: _currentSortBy,
        ascending: _currentAscending,
      ));
    }
  }

  /// 应用排序
  List<Tag> _applySorting(List<Tag> tags) {
    final sortedTags = List<Tag>.from(tags);
    
    sortedTags.sort((a, b) {
      int comparison = 0;
      
      switch (_currentSortBy) {
        case TagSortBy.name:
          comparison = a.name.compareTo(b.name);
          break;
        case TagSortBy.noteCount:
          comparison = a.noteCount.compareTo(b.noteCount);
          break;
        case TagSortBy.createdDate:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case TagSortBy.lastUsedDate:
          comparison = a.lastUsedAt.compareTo(b.lastUsedAt);
          break;
        case TagSortBy.color:
          comparison = (a.color ?? '').compareTo(b.color ?? '');
          break;
      }

      return _currentAscending ? comparison : -comparison;
    });

    return sortedTags;
  }

  /// 构建已加载状态
  TagsLoaded _buildLoadedState(
    List<Tag> tags, {
    List<Tag>? searchResults,
  }) {
    return TagsLoaded(
      tags: tags,
      filter: _currentFilter,
      sortBy: _currentSortBy,
      ascending: _currentAscending,
      searchQuery: _currentSearchQuery,
      searchResults: searchResults,
    );
  }

  /// 添加标签到缓存
  void _addTagToCache(Tag tag) {
    _allTags.add(tag);
  }

  /// 从缓存中移除标签
  void _removeTagFromCache(String tagName) {
    _allTags.removeWhere((tag) => tag.name == tagName);
  }

  /// 更新缓存中的标签
  void _updateTagInCache(String originalName, Tag updatedTag) {
    final index = _allTags.indexWhere((tag) => tag.name == originalName);
    if (index != -1) {
      _allTags[index] = updatedTag;
    }
  }

  /// 获取当前过滤器
  TagFilter get currentFilter => _currentFilter;

  /// 检查标签是否被选中用于过滤
  bool isTagSelectedForFilter(String tagName) {
    return _currentFilter.isTagSelected(tagName);
  }

  /// 获取选中的标签数量
  int get selectedTagCount => _currentFilter.selectedCount;

  /// 检查是否有激活的过滤器
  bool get hasActiveFilter => _currentFilter.enabled && _currentFilter.hasSelectedTags;
}