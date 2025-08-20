import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tag.dart';
import '../../domain/entities/tag_filter.dart';
import '../bloc/tags_bloc.dart';
import '../bloc/tags_event.dart';
import '../bloc/tags_state.dart';
import 'tag_chip_widget.dart';

/// 标签过滤界面组件
class TagFilterWidget extends StatefulWidget {
  /// 过滤器变更回调
  final ValueChanged<TagFilter>? onFilterChanged;
  
  /// 是否显示搜索框
  final bool showSearch;
  
  /// 是否显示逻辑选择器
  final bool showLogicSelector;
  
  /// 是否显示清除按钮
  final bool showClearButton;
  
  /// 是否显示统计信息
  final bool showStats;
  
  /// 最大显示标签数量
  final int? maxDisplayTags;

  const TagFilterWidget({
    super.key,
    this.onFilterChanged,
    this.showSearch = true,
    this.showLogicSelector = true,
    this.showClearButton = true,
    this.showStats = true,
    this.maxDisplayTags,
  });

  @override
  State<TagFilterWidget> createState() => _TagFilterWidgetState();
}

class _TagFilterWidgetState extends State<TagFilterWidget> {
  final TextEditingController _searchController = TextEditingController();
  bool _showAllTags = false;

  @override
  void initState() {
    super.initState();
    // 加载标签数据
    context.read<TagsBloc>().add(const LoadTagsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTagToggle(String tagName) {
    context.read<TagsBloc>().add(ToggleTagFilterEvent(tagName: tagName));
  }

  void _onLogicChanged(TagFilterLogic logic) {
    context.read<TagsBloc>().add(SetTagFilterLogicEvent(logic: logic));
  }

  void _onClearFilter() {
    context.read<TagsBloc>().add(const ClearTagFilterEvent());
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      context.read<TagsBloc>().add(const ClearTagSearchEvent());
    } else {
      context.read<TagsBloc>().add(SearchTagsEvent(query: query));
    }
  }

  List<Tag> _getDisplayTags(List<Tag> allTags, List<Tag>? searchResults) {
    final tags = searchResults ?? allTags;
    
    if (widget.maxDisplayTags != null && !_showAllTags) {
      return tags.take(widget.maxDisplayTags!).toList();
    }
    
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TagsBloc, TagsState>(
      listener: (context, state) {
        if (state is TagsLoaded) {
          widget.onFilterChanged?.call(state.filter);
        }
      },
      builder: (context, state) {
        if (state is TagsLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is TagsError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 8),
                Text(
                  '加载标签失败',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  state.message,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<TagsBloc>().add(const LoadTagsEvent(forceRefresh: true));
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        if (state is! TagsLoaded) {
          return const SizedBox.shrink();
        }

        final displayTags = _getDisplayTags(state.tags, state.searchResults);
        final hasMoreTags = widget.maxDisplayTags != null && 
            state.tags.length > widget.maxDisplayTags! && 
            !_showAllTags;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题和统计信息
                Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '标签过滤',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (widget.showStats) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${state.tags.length}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // 搜索框
                if (widget.showSearch) ...[
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: '搜索标签...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 过滤逻辑选择器和清除按钮
                if (state.filter.hasSelectedTags) ...[
                  Row(
                    children: [
                      if (widget.showLogicSelector) ...[
                        Text(
                          '过滤逻辑:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 8),
                        SegmentedButton<TagFilterLogic>(
                          segments: const [
                            ButtonSegment(
                              value: TagFilterLogic.and,
                              label: Text('AND'),
                              tooltip: '笔记必须包含所有选中的标签',
                            ),
                            ButtonSegment(
                              value: TagFilterLogic.or,
                              label: Text('OR'),
                              tooltip: '笔记包含任意一个选中的标签即可',
                            ),
                          ],
                          selected: {state.filter.logic},
                          onSelectionChanged: (Set<TagFilterLogic> selection) {
                            _onLogicChanged(selection.first);
                          },
                        ),
                      ],
                      const Spacer(),
                      if (widget.showClearButton) ...[
                        TextButton.icon(
                          onPressed: _onClearFilter,
                          icon: const Icon(Icons.clear_all),
                          label: const Text('清除'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // 选中标签显示
                if (state.filter.hasSelectedTags) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.filter_alt,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '已选择 ${state.filter.selectedCount} 个标签',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: state.filter.selectedTags.map((tagName) {
                            return SelectableTagChip(
                              tag: tagName,
                              isSelected: true,
                              onSelectionChanged: (_) => _onTagToggle(tagName),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 标签列表
                if (displayTags.isEmpty) ...[
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 48,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.searchQuery != null && state.searchQuery!.isNotEmpty
                              ? '没有找到匹配的标签'
                              : '暂无标签',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    '可用标签:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: displayTags.map((tag) {
                      final isSelected = state.filter.isTagSelected(tag.name);
                      return CountedTagChip(
                        tag: tag.name,
                        count: tag.noteCount,
                        isSelected: isSelected,
                        onTap: () => _onTagToggle(tag.name),
                      );
                    }).toList(),
                  ),

                  // 显示更多按钮
                  if (hasMoreTags) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showAllTags = true;
                          });
                        },
                        icon: const Icon(Icons.expand_more),
                        label: Text('显示全部 ${state.tags.length} 个标签'),
                      ),
                    ),
                  ] else if (_showAllTags && widget.maxDisplayTags != null) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showAllTags = false;
                          });
                        },
                        icon: const Icon(Icons.expand_less),
                        label: const Text('收起'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 紧凑版标签过滤器组件
class CompactTagFilterWidget extends StatelessWidget {
  /// 过滤器变更回调
  final ValueChanged<TagFilter>? onFilterChanged;
  
  /// 最大显示标签数量
  final int maxDisplayTags;

  const CompactTagFilterWidget({
    super.key,
    this.onFilterChanged,
    this.maxDisplayTags = 10,
  });

  @override
  Widget build(BuildContext context) {
    return TagFilterWidget(
      onFilterChanged: onFilterChanged,
      showSearch: false,
      showLogicSelector: false,
      showClearButton: false,
      showStats: false,
      maxDisplayTags: maxDisplayTags,
    );
  }
}

/// 标签过滤器底部面板
class TagFilterBottomSheet extends StatelessWidget {
  /// 当前过滤器
  final TagFilter currentFilter;
  
  /// 过滤器变更回调
  final ValueChanged<TagFilter>? onFilterChanged;

  const TagFilterBottomSheet({
    super.key,
    required this.currentFilter,
    this.onFilterChanged,
  });

  static Future<TagFilter?> show(
    BuildContext context, {
    required TagFilter currentFilter,
  }) {
    return showModalBottomSheet<TagFilter>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => TagFilterBottomSheet(
        currentFilter: currentFilter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 拖拽指示器
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).hintColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              
              // 标题
              Row(
                children: [
                  Text(
                    '标签过滤',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(currentFilter),
                    child: const Text('完成'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 过滤器内容
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: TagFilterWidget(
                    onFilterChanged: onFilterChanged,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}