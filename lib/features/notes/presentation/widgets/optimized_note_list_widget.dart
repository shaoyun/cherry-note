import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:cherry_note/features/notes/domain/entities/note_file.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_bloc.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_event.dart';
import 'package:cherry_note/features/notes/presentation/bloc/notes_state.dart';
import 'package:cherry_note/shared/widgets/custom_input.dart';
import 'package:cherry_note/shared/widgets/custom_button.dart';
import 'package:cherry_note/shared/widgets/progress_indicator.dart';
import 'package:cherry_note/shared/widgets/virtual_list_view.dart';
import 'package:cherry_note/core/performance/debouncer.dart';
import 'package:cherry_note/core/performance/memory_manager.dart';

/// 优化的笔记列表组件 - 支持虚拟滚动和懒加载
class OptimizedNoteListWidget extends StatefulWidget {
  final String? folderPath;
  final List<String>? filterTags;
  final Function(NoteFile)? onNoteSelected;
  final Function(NoteFile)? onNoteEdit;
  final Function(NoteFile)? onNoteDelete;
  final bool showSearch;
  final bool showSortOptions;
  final bool allowMultiSelect;
  final NoteListViewType viewType;
  final bool enableVirtualScrolling;
  final bool enableLazyLoading;
  final int pageSize;

  const OptimizedNoteListWidget({
    super.key,
    this.folderPath,
    this.filterTags,
    this.onNoteSelected,
    this.onNoteEdit,
    this.onNoteDelete,
    this.showSearch = true,
    this.showSortOptions = true,
    this.allowMultiSelect = false,
    this.viewType = NoteListViewType.list,
    this.enableVirtualScrolling = true,
    this.enableLazyLoading = true,
    this.pageSize = 50,
  });

  @override
  State<OptimizedNoteListWidget> createState() => _OptimizedNoteListWidgetState();
}

class _OptimizedNoteListWidgetState extends State<OptimizedNoteListWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  late final Debouncer _searchDebouncer;
  late final MemoryManager _memoryManager;
  
  NoteListViewType _currentViewType = NoteListViewType.list;
  NotesSortBy _currentSortBy = NotesSortBy.modifiedDate;
  bool _sortAscending = false;
  String _searchQuery = '';
  
  // 分页相关
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  List<NoteFile> _allNotes = [];
  List<NoteFile> _displayedNotes = [];

  @override
  void initState() {
    super.initState();
    _currentViewType = widget.viewType;
    _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 300));
    _memoryManager = MemoryManager();
    
    // 初始加载笔记
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialNotes();
    });
  }

  @override
  void didUpdateWidget(OptimizedNoteListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 如果文件夹路径或过滤标签发生变化，重新加载
    if (oldWidget.folderPath != widget.folderPath ||
        oldWidget.filterTags != widget.filterTags) {
      _resetAndLoadNotes();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  void _loadInitialNotes() {
    _resetPagination();
    context.read<NotesBloc>().add(LoadNotesEvent(
      folderPath: widget.folderPath,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      tags: widget.filterTags,
      sortBy: _currentSortBy,
      ascending: _sortAscending,
      page: 0,
      pageSize: widget.pageSize,
    ));
  }

  void _resetAndLoadNotes() {
    _resetPagination();
    _loadInitialNotes();
  }

  void _resetPagination() {
    _currentPage = 0;
    _isLoadingMore = false;
    _hasMoreData = true;
    _allNotes.clear();
    _displayedNotes.clear();
  }

  Future<void> _loadMoreNotes() async {
    if (_isLoadingMore || !_hasMoreData || !widget.enableLazyLoading) return;

    setState(() {
      _isLoadingMore = true;
    });

    context.read<NotesBloc>().add(LoadNotesEvent(
      folderPath: widget.folderPath,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      tags: widget.filterTags,
      sortBy: _currentSortBy,
      ascending: _sortAscending,
      page: _currentPage + 1,
      pageSize: widget.pageSize,
    ));
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    
    // 使用防抖动器延迟搜索
    _searchDebouncer.call(() {
      if (_searchQuery == query && mounted) {
        _resetAndLoadNotes();
      }
    });
  }

  void _onSortChanged(NotesSortBy sortBy) {
    setState(() {
      if (_currentSortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _currentSortBy = sortBy;
        _sortAscending = false;
      }
    });
    
    _resetAndLoadNotes();
  }

  void _onViewTypeChanged(NoteListViewType viewType) {
    setState(() {
      _currentViewType = viewType;
    });
  }

  void _onNoteSelected(NoteFile note) {
    context.read<NotesBloc>().add(SelectNoteEvent(filePath: note.filePath));
    widget.onNoteSelected?.call(note);
  }

  void _onNoteEdit(NoteFile note) {
    widget.onNoteEdit?.call(note);
  }

  void _onNoteDelete(NoteFile note) {
    _showDeleteConfirmDialog(note);
  }

  void _showDeleteConfirmDialog(NoteFile note) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除笔记'),
        content: Text('确定要删除笔记 "${note.title}" 吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<NotesBloc>().add(DeleteNoteEvent(filePath: note.filePath));
              widget.onNoteDelete?.call(note);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _SortOptionsSheet(
        currentSortBy: _currentSortBy,
        ascending: _sortAscending,
        onSortChanged: _onSortChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索和工具栏
        if (widget.showSearch || widget.showSortOptions)
          _buildToolbar(),
        
        // 笔记列表
        Expanded(
          child: BlocConsumer<NotesBloc, NotesState>(
            listener: _handleStateChange,
            builder: (context, state) {
              if (state is NotesLoading && _displayedNotes.isEmpty) {
                return const Center(
                  child: CustomCircularProgressIndicator(
                    label: '加载笔记中...',
                  ),
                );
              }
              
              if (state is NotesError && _displayedNotes.isEmpty) {
                return _buildErrorWidget(state);
              }
              
              if (state is NotesLoaded || state is NotesSearchResults) {
                return _buildOptimizedNotesList(state);
              }
              
              return const Center(
                child: Text('暂无笔记'),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleStateChange(BuildContext context, NotesState state) {
    if (state is NotesLoaded) {
      setState(() {
        if (state.page == 0) {
          // 首次加载或重新加载
          _allNotes = List.from(state.notes);
          _displayedNotes = List.from(state.notes);
          _currentPage = 0;
        } else {
          // 加载更多
          _allNotes.addAll(state.notes);
          _displayedNotes.addAll(state.notes);
          _currentPage = state.page;
        }
        
        _isLoadingMore = false;
        _hasMoreData = state.notes.length >= widget.pageSize;
      });
    } else if (state is NotesSearchResults) {
      setState(() {
        _displayedNotes = List.from(state.results);
        _isLoadingMore = false;
        _hasMoreData = false; // 搜索结果不支持分页
      });
    } else if (state is NotesError) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 搜索框
          if (widget.showSearch)
            SearchTextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              hint: '搜索笔记标题、内容或标签...',
              onChanged: _onSearchChanged,
              onClear: () => _onSearchChanged(''),
            ),
          
          if (widget.showSearch && widget.showSortOptions)
            const SizedBox(height: 12),
          
          // 工具栏按钮
          if (widget.showSortOptions)
            Row(
              children: [
                // 视图切换按钮
                ToggleButtons(
                  isSelected: [
                    _currentViewType == NoteListViewType.list,
                    _currentViewType == NoteListViewType.grid,
                  ],
                  onPressed: (index) {
                    _onViewTypeChanged(
                      index == 0 ? NoteListViewType.list : NoteListViewType.grid,
                    );
                  },
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  children: const [
                    Icon(Icons.list),
                    Icon(Icons.grid_view),
                  ],
                ),
                
                const SizedBox(width: 12),
                
                // 排序按钮
                CustomIconButton(
                  icon: Icons.sort,
                  tooltip: '排序选项',
                  onPressed: _showSortMenu,
                ),
                
                const Spacer(),
                
                // 性能指标显示
                if (_displayedNotes.isNotEmpty)
                  Text(
                    '${_displayedNotes.length} 项',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                
                const SizedBox(width: 8),
                
                // 刷新按钮
                CustomIconButton(
                  icon: Icons.refresh,
                  tooltip: '刷新',
                  onPressed: () {
                    context.read<NotesBloc>().add(const RefreshNotesEvent());
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(NotesError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: '重试',
            icon: Icons.refresh,
            onPressed: () {
              _resetAndLoadNotes();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizedNotesList(NotesState state) {
    if (_displayedNotes.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _resetAndLoadNotes();
      },
      child: _currentViewType == NoteListViewType.list
          ? _buildOptimizedListView()
          : _buildOptimizedGridView(),
    );
  }

  Widget _buildOptimizedListView() {
    const itemHeight = 120.0;
    
    if (widget.enableVirtualScrolling) {
      return VirtualListView<NoteFile>(
        items: _displayedNotes,
        itemHeight: itemHeight,
        controller: _scrollController,
        onEndReached: widget.enableLazyLoading ? _loadMoreNotes : null,
        itemBuilder: (context, note, index) {
          return _buildOptimizedNoteListItem(note, index);
        },
      );
    } else if (widget.enableLazyLoading) {
      return LazyLoadListView<NoteFile>(
        items: _displayedNotes,
        itemHeight: itemHeight,
        controller: _scrollController,
        onLoadMore: (page, pageSize) async {
          await _loadMoreNotes();
          return _displayedNotes.skip(page * pageSize).take(pageSize).toList();
        },
        hasMore: _hasMoreData,
        itemBuilder: (context, note, index) {
          return _buildOptimizedNoteListItem(note, index);
        },
      );
    } else {
      return ListView.builder(
        controller: _scrollController,
        itemCount: _displayedNotes.length,
        itemExtent: itemHeight,
        itemBuilder: (context, index) {
          return _buildOptimizedNoteListItem(_displayedNotes[index], index);
        },
      );
    }
  }

  Widget _buildOptimizedGridView() {
    const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.8,
    );

    if (widget.enableVirtualScrolling) {
      return VirtualGridView<NoteFile>(
        items: _displayedNotes,
        gridDelegate: gridDelegate,
        padding: const EdgeInsets.all(16),
        controller: _scrollController,
        onEndReached: widget.enableLazyLoading ? _loadMoreNotes : null,
        itemBuilder: (context, note, index) {
          return _buildOptimizedNoteGridItem(note, index);
        },
      );
    } else {
      return GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: gridDelegate,
        itemCount: _displayedNotes.length,
        itemBuilder: (context, index) {
          return _buildOptimizedNoteGridItem(_displayedNotes[index], index);
        },
      );
    }
  }

  Widget _buildOptimizedNoteListItem(NoteFile note, int index) {
    // 使用缓存键来避免重复构建
    final cacheKey = 'note_list_item_${note.filePath}_${note.updated.millisecondsSinceEpoch}';
    
    return _memoryManager.getCached<Widget>(cacheKey) ?? 
      _buildAndCacheNoteListItem(note, index, cacheKey);
  }

  Widget _buildAndCacheNoteListItem(NoteFile note, int index, String cacheKey) {
    final widget = OptimizedNoteListItem(
      note: note,
      isSelected: false, // TODO: 从状态获取选中状态
      onTap: () => _onNoteSelected(note),
      onEdit: () => _onNoteEdit(note),
      onDelete: () => _onNoteDelete(note),
    );
    
    _memoryManager.cache(cacheKey, widget);
    return widget;
  }

  Widget _buildOptimizedNoteGridItem(NoteFile note, int index) {
    // 使用缓存键来避免重复构建
    final cacheKey = 'note_grid_item_${note.filePath}_${note.updated.millisecondsSinceEpoch}';
    
    return _memoryManager.getCached<Widget>(cacheKey) ?? 
      _buildAndCacheNoteGridItem(note, index, cacheKey);
  }

  Widget _buildAndCacheNoteGridItem(NoteFile note, int index, String cacheKey) {
    final widget = OptimizedNoteGridItem(
      note: note,
      isSelected: false, // TODO: 从状态获取选中状态
      onTap: () => _onNoteSelected(note),
      onEdit: () => _onNoteEdit(note),
      onDelete: () => _onNoteDelete(note),
    );
    
    _memoryManager.cache(cacheKey, widget);
    return widget;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无笔记',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角的 + 按钮创建第一个笔记',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// 优化的笔记列表项组件
class OptimizedNoteListItem extends StatelessWidget {
  final NoteFile note;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const OptimizedNoteListItem({
    super.key,
    required this.note,
    this.isSelected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和操作按钮
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // 便签标识
                  if (note.isSticky)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '便签',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  
                  // 操作菜单
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('编辑'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 内容预览
              if (note.content.isNotEmpty)
                Text(
                  note.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected 
                        ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                        : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              const SizedBox(height: 12),
              
              // 标签和时间
              Row(
                children: [
                  // 标签
                  if (note.tags.isNotEmpty)
                    Expanded(
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: note.tags.take(3).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                  
                  // 修改时间
                  Text(
                    dateFormat.format(note.updated),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected 
                          ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                          : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 优化的笔记网格项组件
class OptimizedNoteGridItem extends StatelessWidget {
  final NoteFile note;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const OptimizedNoteGridItem({
    super.key,
    required this.note,
    this.isSelected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MM-dd');
    
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和操作按钮
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('编辑'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      size: 18,
                      color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 内容预览
              Expanded(
                child: note.content.isNotEmpty
                    ? Text(
                        note.content,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected 
                              ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                              : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        '暂无内容',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),
              
              const SizedBox(height: 8),
              
              // 底部信息
              Row(
                children: [
                  // 便签标识
                  if (note.isSticky)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text(
                        '便签',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  
                  const Spacer(),
                  
                  // 修改时间
                  Text(
                    dateFormat.format(note.updated),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected 
                          ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                          : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              
              // 标签
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: note.tags.take(2).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      tag,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontSize: 9,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 笔记列表视图类型
enum NoteListViewType {
  list,
  grid,
}

/// 笔记排序方式
enum NotesSortBy {
  modifiedDate,
  createdDate,
  title,
  size,
  tags,
}

/// 排序选项底部表单
class _SortOptionsSheet extends StatelessWidget {
  final NotesSortBy currentSortBy;
  final bool ascending;
  final Function(NotesSortBy) onSortChanged;

  const _SortOptionsSheet({
    required this.currentSortBy,
    required this.ascending,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sortOptions = [
      (NotesSortBy.modifiedDate, '修改时间', Icons.schedule),
      (NotesSortBy.createdDate, '创建时间', Icons.add_circle_outline),
      (NotesSortBy.title, '标题', Icons.sort_by_alpha),
      (NotesSortBy.size, '大小', Icons.data_usage),
      (NotesSortBy.tags, '标签', Icons.label),
    ];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '排序方式',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              ...sortOptions.map((option) {
                final sortBy = option.$1;
                final label = option.$2;
                final icon = option.$3;
                final isSelected = currentSortBy == sortBy;
                
                return ListTile(
                  leading: Icon(icon),
                  title: Text(label),
                  trailing: isSelected
                      ? Icon(
                          ascending ? Icons.arrow_upward : Icons.arrow_downward,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  selected: isSelected,
                  onTap: () {
                    Navigator.of(context).pop();
                    onSortChanged(sortBy);
                  },
                );
              }),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}