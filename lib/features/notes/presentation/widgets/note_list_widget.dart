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

/// 笔记列表视图类型
enum NoteListViewType {
  list,
  grid,
}

/// 笔记列表组件
class NoteListWidget extends StatefulWidget {
  final String? folderPath;
  final List<String>? filterTags;
  final Function(NoteFile)? onNoteSelected;
  final Function(NoteFile)? onNoteEdit;
  final Function(NoteFile)? onNoteDelete;
  final bool showSearch;
  final bool showSortOptions;
  final bool allowMultiSelect;
  final NoteListViewType viewType;

  const NoteListWidget({
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
  });

  @override
  State<NoteListWidget> createState() => _NoteListWidgetState();
}

class _NoteListWidgetState extends State<NoteListWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  NoteListViewType _currentViewType = NoteListViewType.list;
  NotesSortBy _currentSortBy = NotesSortBy.modifiedDate;
  bool _sortAscending = false;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _currentViewType = widget.viewType;
    
    // 初始加载笔记
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotes();
    });
  }

  @override
  void didUpdateWidget(NoteListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 如果文件夹路径或过滤标签发生变化，重新加载
    if (oldWidget.folderPath != widget.folderPath ||
        oldWidget.filterTags != widget.filterTags) {
      _loadNotes();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _loadNotes() {
    context.read<NotesBloc>().add(LoadNotesEvent(
      folderPath: widget.folderPath,
      searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      tags: widget.filterTags,
      sortBy: _currentSortBy,
      ascending: _sortAscending,
    ));
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    
    // 延迟搜索以避免频繁请求
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchQuery == query) {
        _loadNotes();
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
    
    context.read<NotesBloc>().add(SortNotesEvent(
      sortBy: _currentSortBy,
      ascending: _sortAscending,
    ));
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
              // Use the original context that has access to the BLoC
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
          child: BlocBuilder<NotesBloc, NotesState>(
            builder: (context, state) {
              if (state is NotesLoading) {
                return const Center(
                  child: CustomCircularProgressIndicator(
                    label: '加载笔记中...',
                  ),
                );
              }
              
              if (state is NotesError) {
                return _buildErrorWidget(state);
              }
              
              if (state is NotesLoaded) {
                return _buildNotesList(state);
              }
              
              if (state is NotesSearchResults) {
                return _buildSearchResults(state);
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
              context.read<NotesBloc>().add(const RefreshNotesEvent());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(NotesLoaded state) {
    if (state.notes.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<NotesBloc>().add(const RefreshNotesEvent());
      },
      child: _currentViewType == NoteListViewType.list
          ? _buildListView(state.notes, state.selectedNoteId)
          : _buildGridView(state.notes, state.selectedNoteId),
    );
  }

  Widget _buildSearchResults(NotesSearchResults state) {
    return Column(
      children: [
        // 搜索结果统计
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '找到 ${state.totalResults} 个结果',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              CustomTextButton(
                text: '清除搜索',
                icon: Icons.clear,
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                  context.read<NotesBloc>().add(const ClearSearchEvent());
                },
              ),
            ],
          ),
        ),
        
        // 搜索结果列表
        Expanded(
          child: state.results.isEmpty
              ? _buildNoSearchResults()
              : _currentViewType == NoteListViewType.list
                  ? _buildListView(state.results, null)
                  : _buildGridView(state.results, null),
        ),
      ],
    );
  }

  Widget _buildListView(List<NoteFile> notes, String? selectedNoteId) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final isSelected = selectedNoteId == note.filePath;
        
        return NoteListItem(
          note: note,
          isSelected: isSelected,
          onTap: () => _onNoteSelected(note),
          onEdit: () => _onNoteEdit(note),
          onDelete: () => _onNoteDelete(note),
        );
      },
    );
  }

  Widget _buildGridView(List<NoteFile> notes, String? selectedNoteId) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final isSelected = selectedNoteId == note.filePath;
        
        return NoteGridItem(
          note: note,
          isSelected: isSelected,
          onTap: () => _onNoteSelected(note),
          onEdit: () => _onNoteEdit(note),
          onDelete: () => _onNoteDelete(note),
        );
      },
    );
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

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '未找到匹配的笔记',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '尝试使用不同的关键词搜索',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// 笔记列表项组件
class NoteListItem extends StatelessWidget {
  final NoteFile note;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const NoteListItem({
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

/// 笔记网格项组件
class NoteGridItem extends StatelessWidget {
  final NoteFile note;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const NoteGridItem({
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