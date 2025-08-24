import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../../../folders/presentation/widgets/folder_tree_widget.dart';
import '../../../notes/presentation/widgets/note_list_widget.dart';
import '../../../notes/presentation/pages/note_editor_page.dart';
import '../../../tags/presentation/widgets/tag_filter_widget.dart';
import '../../../notes/domain/entities/note_file.dart';
import '../../../tags/domain/entities/tag_filter.dart';
import '../../../folders/presentation/bloc/folders_bloc.dart';
import '../../../notes/presentation/bloc/notes_bloc.dart';
import '../../../notes/presentation/bloc/web_notes_bloc.dart';
import '../../../notes/presentation/bloc/notes_event.dart';
import '../../../notes/presentation/bloc/notes_state.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../../core/constants/app_routes.dart';
import '../widgets/app_menu_bar.dart';
import '../widgets/app_toolbar.dart';
import '../services/keyboard_shortcuts_service.dart';

/// 主界面 - 三栏布局
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // 分栏宽度控制
  double _leftPanelWidth = 280.0;
  double _middlePanelWidth = 320.0;
  
  // 最小和最大宽度限制
  static const double _minPanelWidth = 200.0;
  static const double _maxLeftPanelWidth = 400.0;
  static const double _maxMiddlePanelWidth = 500.0;
  
  // 当前选中状态
  String? _selectedFolderPath;
  NoteFile? _selectedNote;
  TagFilter _currentTagFilter = const TagFilter();
  
  // 响应式布局控制
  bool _isCompactMode = false;
  int _currentPageIndex = 0; // 0: 文件夹, 1: 笔记列表, 2: 编辑器
  
  // 界面控制
  bool _showSidebar = true;
  bool _showPreview = true;
  bool _showToolbar = true;
  bool _isSyncing = false;
  bool _hasUnsavedChanges = false;
  
  // 动画控制器
  late AnimationController _panelAnimationController;
  late Animation<double> _panelAnimation;
  
  // 键盘快捷键服务
  late final KeyboardShortcutsService _shortcutsService;
  
  // 界面状态保存键
  static const String _leftPanelWidthKey = 'main_screen_left_panel_width';
  static const String _middlePanelWidthKey = 'main_screen_middle_panel_width';
  static const String _selectedFolderKey = 'main_screen_selected_folder';

  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
    _panelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelAnimationController,
      curve: Curves.easeInOut,
    );
    
    // 初始化键盘快捷键服务
    _shortcutsService = KeyboardShortcutsService();
    _registerKeyboardShortcuts();
    
    // 恢复界面状态
    _restoreInterfaceState();
  }

  @override
  void dispose() {
    _panelAnimationController.dispose();
    _shortcutsService.clearShortcuts();
    super.dispose();
  }

  /// 恢复界面状态
  Future<void> _restoreInterfaceState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _leftPanelWidth = prefs.getDouble(_leftPanelWidthKey) ?? _leftPanelWidth;
        _middlePanelWidth = prefs.getDouble(_middlePanelWidthKey) ?? _middlePanelWidth;
        _selectedFolderPath = prefs.getString(_selectedFolderKey);
      });
      
      // 确保宽度在合理范围内
      _leftPanelWidth = _leftPanelWidth.clamp(_minPanelWidth, _maxLeftPanelWidth);
      _middlePanelWidth = _middlePanelWidth.clamp(_minPanelWidth, _maxMiddlePanelWidth);
      
    } catch (e) {
      debugPrint('Failed to restore interface state: $e');
    }
  }

  /// 保存界面状态
  Future<void> _saveInterfaceState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setDouble(_leftPanelWidthKey, _leftPanelWidth);
      await prefs.setDouble(_middlePanelWidthKey, _middlePanelWidth);
      
      if (_selectedFolderPath != null) {
        await prefs.setString(_selectedFolderKey, _selectedFolderPath!);
      }
    } catch (e) {
      debugPrint('Failed to save interface state: $e');
    }
  }

  /// 处理文件夹选择
  void _onFolderSelected(String folderPath) {
    setState(() {
      _selectedFolderPath = folderPath;
      _selectedNote = null; // 清除选中的笔记
    });
    
    // 在紧凑模式下切换到笔记列表页面
    if (_isCompactMode) {
      setState(() {
        _currentPageIndex = 1;
      });
    }
    
    // 保存状态
    _saveInterfaceState();
  }

  /// 处理笔记选择
  void _onNoteSelected(NoteFile note) {
    setState(() {
      _selectedNote = note;
    });
    
    // 在紧凑模式下切换到编辑器页面
    if (_isCompactMode) {
      setState(() {
        _currentPageIndex = 2;
      });
    }
  }

  /// 处理标签过滤变更
  void _onTagFilterChanged(TagFilter filter) {
    setState(() {
      _currentTagFilter = filter;
    });
  }

  /// 处理左侧面板宽度调整
  void _onLeftPanelResize(double delta) {
    setState(() {
      _leftPanelWidth = (_leftPanelWidth + delta)
          .clamp(_minPanelWidth, _maxLeftPanelWidth);
    });
    _saveInterfaceState();
  }

  /// 处理中间面板宽度调整
  void _onMiddlePanelResize(double delta) {
    setState(() {
      _middlePanelWidth = (_middlePanelWidth + delta)
          .clamp(_minPanelWidth, _maxMiddlePanelWidth);
    });
    _saveInterfaceState();
  }

  /// 注册键盘快捷键
  void _registerKeyboardShortcuts() {
    _shortcutsService.registerDefaultShortcuts(
      onNewNote: _createNewNote,
      onNewFolder: _createNewFolder,
      onSave: _saveCurrentNote,
      onUndo: _undo,
      onRedo: _redo,
      onTogglePreview: _togglePreview,
      onToggleSidebar: _toggleSidebar,
      onSettings: _openSettings,
    );
  }

  /// 创建新笔记
  void _createNewNote() {
    // 在当前选中的文件夹中创建新笔记
    final folderPath = _selectedFolderPath ?? '';
    
    // 生成默认标题（包含时间戳避免重名）
    final now = DateTime.now();
    final defaultTitle = '新笔记 ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    // 通过 BLoC 创建新笔记
    if (kIsWeb) {
      context.read<WebNotesBloc>().add(CreateNoteEvent(
        title: defaultTitle,
        folderPath: folderPath.isEmpty ? null : folderPath,
        content: '# $defaultTitle\n\n开始写你的笔记...',
      ));
    } else {
      context.read<NotesBloc>().add(CreateNoteEvent(
        title: defaultTitle,
        folderPath: folderPath.isEmpty ? null : folderPath,
        content: '# $defaultTitle\n\n开始写你的笔记...',
      ));
    }
    
    // 在紧凑模式下切换到编辑器页面
    if (_isCompactMode) {
      setState(() {
        _currentPageIndex = 2;
      });
    }
  }

  /// 创建新文件夹
  void _createNewFolder() {
    // TODO: 实现创建新文件夹的逻辑
  }

  /// 保存当前笔记
  void _saveCurrentNote() {
    // TODO: 实现保存笔记的逻辑
    setState(() {
      _hasUnsavedChanges = false;
    });
  }

  /// 撤销操作
  void _undo() {
    // TODO: 实现撤销逻辑
  }

  /// 重做操作
  void _redo() {
    // TODO: 实现重做逻辑
  }

  /// 切换预览
  void _togglePreview() {
    setState(() {
      _showPreview = !_showPreview;
    });
  }

  /// 切换侧边栏
  void _toggleSidebar() {
    setState(() {
      _showSidebar = !_showSidebar;
    });
  }

  /// 开始同步
  void _startSync() {
    setState(() {
      _isSyncing = true;
    });
    
    // TODO: 实现同步逻辑
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    });
  }

  /// 打开设置
  void _openSettings() {
    context.push(AppRoutes.settings);
  }

  /// 显示关于对话框
  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Cherry Note',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.note, size: 48),
      children: [
        const Text('一个跨平台的Markdown笔记应用'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShortcutsWrapper(
      child: ResponsiveLayoutBuilder(
        builder: (context, constraints) {
          // 判断是否为紧凑模式
          _isCompactMode = constraints.maxWidth < 1024;
          
          return MultiBlocListener(
            listeners: [
              // 监听创建笔记成功事件
              if (kIsWeb)
                BlocListener<WebNotesBloc, NotesState>(
                  listener: (context, state) {
                    if (state is NoteOperationSuccess && state.operation == 'create') {
                      // 自动选中新创建的笔记
                      if (state.note != null) {
                        _onNoteSelected(state.note!);
                      }
                    }
                  },
                )
              else
                BlocListener<NotesBloc, NotesState>(
                  listener: (context, state) {
                    if (state is NoteOperationSuccess && state.operation == 'create') {
                      // 自动选中新创建的笔记
                      if (state.note != null) {
                        _onNoteSelected(state.note!);
                      }
                    }
                  },
                ),
            ],
            child: Scaffold(
              appBar: _isCompactMode ? _buildCompactAppBar() : null,
              body: Column(
                children: [
                  // 桌面端菜单栏和工具栏
                  if (!_isCompactMode) ...[
                    _buildMenuBar(),
                    if (_showToolbar) _buildToolbar(),
                  ],
                  
                  // 主要内容区域
                  Expanded(
                    child: _isCompactMode 
                        ? _buildCompactLayout()
                        : _buildDesktopLayout(),
                  ),
                ],
              ),
              floatingActionButton: _buildFloatingActionButton(),
              bottomNavigationBar: _isCompactMode 
                  ? _buildBottomNavigationBar()
                  : null,
            ),
          );
        },
      ),
    );
  }

  /// 构建桌面端三栏布局
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // 左侧面板：文件夹树 + 标签过滤
        AnimatedBuilder(
          animation: _panelAnimation,
          builder: (context, child) {
            return SizedBox(
              width: _leftPanelWidth,
              child: _buildLeftPanel(),
            );
          },
        ),
        
        // 左侧分割线
        _buildVerticalDivider(
          onPanUpdate: (details) => _onLeftPanelResize(details.delta.dx),
        ),
        
        // 中间面板：笔记列表
        AnimatedBuilder(
          animation: _panelAnimation,
          builder: (context, child) {
            return SizedBox(
              width: _middlePanelWidth,
              child: _buildMiddlePanel(),
            );
          },
        ),
        
        // 右侧分割线
        _buildVerticalDivider(
          onPanUpdate: (details) => _onMiddlePanelResize(details.delta.dx),
        ),
        
        // 右侧面板：编辑器
        Expanded(
          child: _buildRightPanel(),
        ),
      ],
    );
  }

  /// 构建紧凑模式布局（移动端/小屏幕）
  Widget _buildCompactLayout() {
    Widget currentPage;
    
    switch (_currentPageIndex) {
      case 0:
        currentPage = _buildLeftPanel();
        break;
      case 1:
        currentPage = _buildMiddlePanel();
        break;
      case 2:
        currentPage = _buildRightPanel();
        break;
      default:
        currentPage = _buildLeftPanel();
    }
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: currentPage,
    );
  }

  /// 构建左侧面板（文件夹树 + 标签过滤）
  Widget _buildLeftPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 文件夹树
          Expanded(
            flex: 3,
            child: FolderTreeWidget(
              onFolderSelected: _onFolderSelected,
              showContextMenu: true,
              enableDragDrop: true,
            ),
          ),
          
          // 分割线
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor,
          ),
          
          // 标签过滤
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: TagFilterWidget(
                onFilterChanged: _onTagFilterChanged,
                showSearch: true,
                showLogicSelector: true,
                maxDisplayTags: _isCompactMode ? 8 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建中间面板（笔记列表）
  Widget _buildMiddlePanel() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: NoteListWidget(
        folderPath: _selectedFolderPath,
        filterTags: _currentTagFilter.hasSelectedTags 
            ? _currentTagFilter.selectedTags.toList()
            : null,
        onNoteSelected: _onNoteSelected,
        onNoteEdit: _onNoteSelected,
        showSearch: true,
        showSortOptions: true,
        viewType: _isCompactMode 
            ? NoteListViewType.list 
            : NoteListViewType.list,
      ),
    );
  }

  /// 构建右侧面板（编辑器）
  Widget _buildRightPanel() {
    if (_selectedNote == null) {
      return _buildEmptyEditorState();
    }
    
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: NoteEditorPage(
        noteId: _selectedNote!.filePath,
      ),
    );
  }

  /// 构建空编辑器状态
  Widget _buildEmptyEditorState() {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '选择一个笔记开始编辑',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '或者创建一个新笔记',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewNote,
              icon: const Icon(Icons.add),
              label: const Text('创建新笔记'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建垂直分割线（可拖拽调整宽度）
  Widget _buildVerticalDivider({
    required Function(DragUpdateDetails) onPanUpdate,
  }) {
    return GestureDetector(
      onPanUpdate: onPanUpdate,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: Container(
          width: 8,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 1,
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建浮动操作按钮
  Widget? _buildFloatingActionButton() {
    // 在桌面模式下不显示浮动按钮
    if (!_isCompactMode) return null;
    
    return FloatingActionButton(
      onPressed: _createNewNote,
      tooltip: '创建新笔记',
      child: const Icon(Icons.add),
    );
  }

  /// 构建菜单栏
  Widget _buildMenuBar() {
    return AppMenuBar(
      onNewNote: _createNewNote,
      onNewFolder: _createNewFolder,
      onSave: _saveCurrentNote,
      onUndo: _undo,
      onRedo: _redo,
      onTogglePreview: _togglePreview,
      onToggleSidebar: _toggleSidebar,
      onSettings: _openSettings,
      onAbout: _showAbout,
    );
  }

  /// 构建工具栏
  Widget _buildToolbar() {
    return AppToolbar(
      onNewNote: _createNewNote,
      onNewFolder: _createNewFolder,
      onSave: _saveCurrentNote,
      onUndo: _undo,
      onRedo: _redo,
      onTogglePreview: _togglePreview,
      onToggleSidebar: _toggleSidebar,
      onSync: _startSync,
      onSettings: _openSettings,
      showSidebar: _showSidebar,
      showPreview: _showPreview,
      isSyncing: _isSyncing,
      hasUnsavedChanges: _hasUnsavedChanges,
    );
  }

  /// 构建紧凑模式应用栏
  PreferredSizeWidget _buildCompactAppBar() {
    return CompactAppToolbar(
      onNewNote: _createNewNote,
      onSync: _startSync,
      isSyncing: _isSyncing,
    );
  }

  /// 构建底部导航栏（紧凑模式）
  Widget? _buildBottomNavigationBar() {
    if (!_isCompactMode) return null;
    
    return BottomNavigationBar(
      currentIndex: _currentPageIndex,
      onTap: (index) {
        setState(() {
          _currentPageIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.folder),
          label: '文件夹',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: '笔记',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.edit),
          label: '编辑',
        ),
      ],
    );
  }
}