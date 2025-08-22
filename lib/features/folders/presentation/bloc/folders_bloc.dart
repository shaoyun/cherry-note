import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/folder_node.dart';
import '../../domain/repositories/folder_repository.dart';
import 'folders_event.dart';
import 'folders_state.dart';

/// 文件夹管理BLoC
@injectable
class FoldersBloc extends Bloc<FoldersEvent, FoldersState> {
  final FolderRepository _folderRepository;

  // 当前状态缓存
  List<FolderNode> _allFolders = [];
  String? _selectedFolderPath;
  Set<String> _expandedFolders = {};
  FolderSortBy _currentSortBy = FolderSortBy.name;
  bool _currentAscending = true;
  String? _currentSearchQuery;
  String? _currentRootPath;

  FoldersBloc({
    required FolderRepository folderRepository,
  })  : _folderRepository = folderRepository,
        super(const FoldersInitial()) {
    // 注册事件处理器
    on<LoadFoldersEvent>(_onLoadFolders);
    on<CreateFolderEvent>(_onCreateFolder);
    on<RenameFolderEvent>(_onRenameFolder);
    on<DeleteFolderEvent>(_onDeleteFolder);
    on<MoveFolderEvent>(_onMoveFolder);
    on<CopyFolderEvent>(_onCopyFolder);
    on<ExpandFolderEvent>(_onExpandFolder);
    on<CollapseFolderEvent>(_onCollapseFolder);
    on<ToggleFolderEvent>(_onToggleFolder);
    on<SelectFolderEvent>(_onSelectFolder);
    on<DeselectFolderEvent>(_onDeselectFolder);
    on<RefreshFolderEvent>(_onRefreshFolder);
    on<SearchFoldersEvent>(_onSearchFolders);
    on<ClearFolderSearchEvent>(_onClearFolderSearch);
    on<UpdateFolderMetadataEvent>(_onUpdateFolderMetadata);
    on<BatchFolderOperationEvent>(_onBatchFolderOperation);
    on<ExpandAllFoldersEvent>(_onExpandAllFolders);
    on<CollapseAllFoldersEvent>(_onCollapseAllFolders);
    on<SetFolderSortEvent>(_onSetFolderSort);
  }

  /// 加载文件夹树
  Future<void> _onLoadFolders(LoadFoldersEvent event, Emitter<FoldersState> emit) async {
    try {
      emit(const FoldersLoading());

      // 更新当前状态
      _currentRootPath = event.rootPath;

      // 如果不是强制刷新且已有数据，直接使用缓存
      if (!event.forceRefresh && _allFolders.isNotEmpty) {
        final sortedFolders = _applySorting(_allFolders);
        emit(_buildLoadedState(sortedFolders));
        return;
      }

      // 从仓储加载文件夹
      final folders = await _folderRepository.loadFolders(rootPath: event.rootPath);
      _allFolders = folders;

      // 应用排序
      final sortedFolders = _applySorting(folders);

      // 计算统计信息
      final stats = _calculateStats(folders);

      emit(FoldersLoaded(
        folders: sortedFolders,
        selectedFolderPath: _selectedFolderPath,
        expandedFolders: _expandedFolders,
        sortBy: _currentSortBy,
        ascending: _currentAscending,
        searchQuery: _currentSearchQuery,
        totalFolders: stats.totalFolders,
        totalNotes: stats.totalNotes,
      ));
    } catch (e) {
      emit(FoldersError(
        message: 'Failed to load folders: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 创建文件夹
  Future<void> _onCreateFolder(CreateFolderEvent event, Emitter<FoldersState> emit) async {
    try {
      emit(FolderOperationInProgress(
        operation: 'create',
        message: 'Creating folder "${event.folderName}"...',
      ));

      // 验证文件夹名称
      if (!_folderRepository.isValidFolderName(event.folderName)) {
        throw Exception('Invalid folder name: ${event.folderName}');
      }

      // 创建文件夹
      final newFolder = await _folderRepository.createFolder(
        parentPath: event.parentPath,
        folderName: event.folderName,
        metadata: event.metadata,
      );

      // 更新缓存
      _addFolderToCache(newFolder);

      // 自动展开父文件夹
      if (event.parentPath.isNotEmpty) {
        _expandedFolders.add(event.parentPath);
      }

      // 自动选择新创建的文件夹
      _selectedFolderPath = newFolder.folderPath;

      emit(FolderOperationSuccess(
        operation: 'create',
        message: 'Folder "${event.folderName}" created successfully',
        folderPath: newFolder.folderPath,
        folder: newFolder,
      ));

      // 立即更新列表状态
      final sortedFolders = _applySorting(_allFolders);
      final stats = _calculateStats(_allFolders);
      emit(_buildLoadedState(sortedFolders, stats: stats));
    } catch (e) {
      emit(FolderOperationError(
        operation: 'create',
        message: 'Failed to create folder: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 重命名文件夹
  Future<void> _onRenameFolder(RenameFolderEvent event, Emitter<FoldersState> emit) async {
    try {
      emit(FolderOperationInProgress(
        operation: 'rename',
        folderPath: event.folderPath,
        message: 'Renaming folder to "${event.newName}"...',
      ));

      // 验证新名称
      if (!_folderRepository.isValidFolderName(event.newName)) {
        throw Exception('Invalid folder name: ${event.newName}');
      }

      // 重命名文件夹
      final updatedFolder = await _folderRepository.renameFolder(
        event.folderPath,
        event.newName,
      );

      // 更新缓存
      _updateFolderInCache(updatedFolder);

      // 更新选中状态（如果重命名的是当前选中的文件夹）
      if (_selectedFolderPath == event.folderPath) {
        _selectedFolderPath = updatedFolder.folderPath;
      }

      // 更新展开状态
      if (_expandedFolders.contains(event.folderPath)) {
        _expandedFolders.remove(event.folderPath);
        _expandedFolders.add(updatedFolder.folderPath);
      }

      emit(FolderOperationSuccess(
        operation: 'rename',
        message: 'Folder renamed to "${event.newName}" successfully',
        folderPath: updatedFolder.folderPath,
        folder: updatedFolder,
      ));

      // 立即更新列表状态
      final sortedFolders = _applySorting(_allFolders);
      final stats = _calculateStats(_allFolders);
      emit(_buildLoadedState(sortedFolders, stats: stats));
    } catch (e) {
      emit(FolderOperationError(
        operation: 'rename',
        message: 'Failed to rename folder: ${e.toString()}',
        folderPath: event.folderPath,
        error: e,
      ));
    }
  }

  /// 删除文件夹
  Future<void> _onDeleteFolder(DeleteFolderEvent event, Emitter<FoldersState> emit) async {
    try {
      emit(FolderOperationInProgress(
        operation: 'delete',
        folderPath: event.folderPath,
        message: 'Deleting folder...',
      ));

      // 删除文件夹
      await _folderRepository.deleteFolder(
        event.folderPath,
        recursive: event.recursive,
      );

      // 从缓存中移除
      _removeFolderFromCache(event.folderPath);

      // 清除相关状态
      if (_selectedFolderPath == event.folderPath) {
        _selectedFolderPath = null;
      }
      _expandedFolders.remove(event.folderPath);

      emit(FolderOperationSuccess(
        operation: 'delete',
        message: 'Folder deleted successfully',
        folderPath: event.folderPath,
      ));

      // 立即更新列表状态
      final sortedFolders = _applySorting(_allFolders);
      final stats = _calculateStats(_allFolders);
      emit(_buildLoadedState(sortedFolders, stats: stats));
    } catch (e) {
      emit(FolderOperationError(
        operation: 'delete',
        message: 'Failed to delete folder: ${e.toString()}',
        folderPath: event.folderPath,
        error: e,
      ));
    }
  }

  /// 移动文件夹
  Future<void> _onMoveFolder(MoveFolderEvent event, Emitter<FoldersState> emit) async {
    try {
      emit(FolderOperationInProgress(
        operation: 'move',
        folderPath: event.folderPath,
        message: 'Moving folder...',
      ));

      // 移动文件夹
      final movedFolder = await _folderRepository.moveFolder(
        event.folderPath,
        event.newParentPath,
      );

      // 更新缓存
      _removeFolderFromCache(event.folderPath);
      _addFolderToCache(movedFolder);

      // 更新选中状态
      if (_selectedFolderPath == event.folderPath) {
        _selectedFolderPath = movedFolder.folderPath;
      }

      // 更新展开状态
      if (_expandedFolders.contains(event.folderPath)) {
        _expandedFolders.remove(event.folderPath);
        _expandedFolders.add(movedFolder.folderPath);
      }

      // 展开目标父文件夹
      if (event.newParentPath.isNotEmpty) {
        _expandedFolders.add(event.newParentPath);
      }

      emit(FolderOperationSuccess(
        operation: 'move',
        message: 'Folder moved successfully',
        folderPath: movedFolder.folderPath,
        folder: movedFolder,
      ));

      // 立即更新列表状态
      final sortedFolders = _applySorting(_allFolders);
      final stats = _calculateStats(_allFolders);
      emit(_buildLoadedState(sortedFolders, stats: stats));
    } catch (e) {
      emit(FolderOperationError(
        operation: 'move',
        message: 'Failed to move folder: ${e.toString()}',
        folderPath: event.folderPath,
        error: e,
      ));
    }
  }

  /// 复制文件夹
  Future<void> _onCopyFolder(CopyFolderEvent event, Emitter<FoldersState> emit) async {
    try {
      emit(FolderOperationInProgress(
        operation: 'copy',
        folderPath: event.folderPath,
        message: 'Copying folder...',
      ));

      // 复制文件夹
      final copiedFolder = await _folderRepository.copyFolder(
        event.folderPath,
        event.newParentPath,
        newName: event.newName,
      );

      // 添加到缓存
      _addFolderToCache(copiedFolder);

      // 展开目标父文件夹
      if (event.newParentPath.isNotEmpty) {
        _expandedFolders.add(event.newParentPath);
      }

      // 选择复制的文件夹
      _selectedFolderPath = copiedFolder.folderPath;

      emit(FolderOperationSuccess(
        operation: 'copy',
        message: 'Folder copied successfully',
        folderPath: copiedFolder.folderPath,
        folder: copiedFolder,
      ));

      // 立即更新列表状态
      final sortedFolders = _applySorting(_allFolders);
      final stats = _calculateStats(_allFolders);
      emit(_buildLoadedState(sortedFolders, stats: stats));
    } catch (e) {
      emit(FolderOperationError(
        operation: 'copy',
        message: 'Failed to copy folder: ${e.toString()}',
        folderPath: event.folderPath,
        error: e,
      ));
    }
  }

  /// 展开文件夹
  Future<void> _onExpandFolder(ExpandFolderEvent event, Emitter<FoldersState> emit) async {
    _expandedFolders.add(event.folderPath);
    
    if (state is FoldersLoaded) {
      final currentState = state as FoldersLoaded;
      emit(currentState.copyWith(expandedFolders: _expandedFolders));
    }
  }

  /// 折叠文件夹
  Future<void> _onCollapseFolder(CollapseFolderEvent event, Emitter<FoldersState> emit) async {
    _expandedFolders.remove(event.folderPath);
    
    if (state is FoldersLoaded) {
      final currentState = state as FoldersLoaded;
      emit(currentState.copyWith(expandedFolders: _expandedFolders));
    }
  }

  /// 切换文件夹展开状态
  Future<void> _onToggleFolder(ToggleFolderEvent event, Emitter<FoldersState> emit) async {
    if (_expandedFolders.contains(event.folderPath)) {
      _expandedFolders.remove(event.folderPath);
    } else {
      _expandedFolders.add(event.folderPath);
    }
    
    if (state is FoldersLoaded) {
      final currentState = state as FoldersLoaded;
      emit(currentState.copyWith(expandedFolders: _expandedFolders));
    }
  }

  /// 选择文件夹
  Future<void> _onSelectFolder(SelectFolderEvent event, Emitter<FoldersState> emit) async {
    _selectedFolderPath = event.folderPath;
    
    if (state is FoldersLoaded) {
      final currentState = state as FoldersLoaded;
      emit(currentState.copyWith(selectedFolderPath: _selectedFolderPath));
    }
  }

  /// 取消选择文件夹
  Future<void> _onDeselectFolder(DeselectFolderEvent event, Emitter<FoldersState> emit) async {
    _selectedFolderPath = null;
    
    if (state is FoldersLoaded) {
      final currentState = state as FoldersLoaded;
      emit(currentState.copyWith(clearSelection: true));
    }
  }

  /// 刷新文件夹
  Future<void> _onRefreshFolder(RefreshFolderEvent event, Emitter<FoldersState> emit) async {
    add(LoadFoldersEvent(
      rootPath: event.folderPath ?? _currentRootPath,
      forceRefresh: true,
    ));
  }

  /// 搜索文件夹
  Future<void> _onSearchFolders(SearchFoldersEvent event, Emitter<FoldersState> emit) async {
    try {
      emit(FoldersSearching(
        query: event.query,
        rootPath: event.rootPath,
      ));

      _currentSearchQuery = event.query;

      // 执行搜索
      final searchResults = await _folderRepository.searchFolders(
        query: event.query,
        rootPath: event.rootPath,
      );

      emit(FoldersSearchResults(
        query: event.query,
        results: searchResults,
        totalResults: searchResults.length,
        rootPath: event.rootPath,
      ));

      // 更新主状态以包含搜索结果
      if (state is FoldersLoaded || _allFolders.isNotEmpty) {
        final sortedFolders = _applySorting(_allFolders);
        final stats = _calculateStats(_allFolders);
        emit(_buildLoadedState(
          sortedFolders,
          searchResults: searchResults,
          stats: stats,
        ));
      }
    } catch (e) {
      emit(FoldersError(
        message: 'Search failed: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 清除搜索
  Future<void> _onClearFolderSearch(ClearFolderSearchEvent event, Emitter<FoldersState> emit) async {
    _currentSearchQuery = null;
    
    if (state is FoldersLoaded) {
      final currentState = state as FoldersLoaded;
      emit(currentState.copyWith(clearSearch: true));
    }
  }

  /// 更新文件夹元数据
  Future<void> _onUpdateFolderMetadata(UpdateFolderMetadataEvent event, Emitter<FoldersState> emit) async {
    try {
      emit(FolderOperationInProgress(
        operation: 'update_metadata',
        folderPath: event.folderPath,
        message: 'Updating folder metadata...',
      ));

      // 获取现有文件夹
      final existingFolder = await _folderRepository.getFolder(event.folderPath);
      if (existingFolder == null) {
        throw Exception('Folder not found: ${event.folderPath}');
      }

      // 更新元数据
      final updatedFolder = existingFolder.copyWith(
        description: event.metadata['description']?.toString(),
        color: event.metadata['color']?.toString(),
        updated: DateTime.now(),
      );

      // 保存更新
      final savedFolder = await _folderRepository.updateFolder(updatedFolder);

      // 更新缓存
      _updateFolderInCache(savedFolder);

      emit(FolderOperationSuccess(
        operation: 'update_metadata',
        message: 'Folder metadata updated successfully',
        folderPath: savedFolder.folderPath,
        folder: savedFolder,
      ));

      // 立即更新列表状态
      final sortedFolders = _applySorting(_allFolders);
      final stats = _calculateStats(_allFolders);
      emit(_buildLoadedState(sortedFolders, stats: stats));
    } catch (e) {
      emit(FolderOperationError(
        operation: 'update_metadata',
        message: 'Failed to update folder metadata: ${e.toString()}',
        folderPath: event.folderPath,
        error: e,
      ));
    }
  }

  /// 批量操作文件夹
  Future<void> _onBatchFolderOperation(BatchFolderOperationEvent event, Emitter<FoldersState> emit) async {
    try {
      emit(FoldersBatchOperation(
        operation: event.operation.name,
        folderPaths: event.folderPaths,
        completed: 0,
        total: event.folderPaths.length,
      ));

      Map<String, bool> results = {};
      int completed = 0;
      final errors = <String>[];

      for (final folderPath in event.folderPaths) {
        try {
          emit(FoldersBatchOperation(
            operation: event.operation.name,
            folderPaths: event.folderPaths,
            completed: completed,
            total: event.folderPaths.length,
            currentFolder: folderPath,
          ));

          bool success = false;
          switch (event.operation) {
            case FolderBatchOperation.delete:
              await _folderRepository.deleteFolder(folderPath, recursive: true);
              _removeFolderFromCache(folderPath);
              success = true;
              break;
            case FolderBatchOperation.move:
              if (event.targetPath != null) {
                await _folderRepository.moveFolder(folderPath, event.targetPath!);
                success = true;
              }
              break;
            case FolderBatchOperation.copy:
              if (event.targetPath != null) {
                await _folderRepository.copyFolder(folderPath, event.targetPath!);
                success = true;
              }
              break;
          }

          results[folderPath] = success;
          if (success) completed++;
        } catch (e) {
          results[folderPath] = false;
          errors.add('$folderPath: ${e.toString()}');
        }
      }

      final failureCount = event.folderPaths.length - completed;

      emit(FoldersBatchOperationSuccess(
        operation: event.operation.name,
        folderPaths: event.folderPaths,
        successCount: completed,
        failureCount: failureCount,
        errors: errors,
      ));

      // 立即更新列表状态
      final sortedFolders = _applySorting(_allFolders);
      final stats = _calculateStats(_allFolders);
      emit(_buildLoadedState(sortedFolders, stats: stats));
    } catch (e) {
      emit(FoldersError(
        message: 'Batch operation failed: ${e.toString()}',
        error: e,
      ));
    }
  }

  /// 展开所有文件夹
  Future<void> _onExpandAllFolders(ExpandAllFoldersEvent event, Emitter<FoldersState> emit) async {
    // 获取所有文件夹路径
    final allPaths = _getAllFolderPaths(_allFolders, event.rootPath);
    _expandedFolders.addAll(allPaths);
    
    if (state is FoldersLoaded) {
      final currentState = state as FoldersLoaded;
      emit(currentState.copyWith(expandedFolders: _expandedFolders));
    }
  }

  /// 折叠所有文件夹
  Future<void> _onCollapseAllFolders(CollapseAllFoldersEvent event, Emitter<FoldersState> emit) async {
    if (event.rootPath != null) {
      // 只折叠指定根路径下的文件夹
      final pathsToRemove = _expandedFolders
          .where((path) => path.startsWith(event.rootPath!))
          .toList();
      for (final path in pathsToRemove) {
        _expandedFolders.remove(path);
      }
    } else {
      // 折叠所有文件夹
      _expandedFolders.clear();
    }
    
    if (state is FoldersLoaded) {
      final currentState = state as FoldersLoaded;
      emit(currentState.copyWith(expandedFolders: _expandedFolders));
    }
  }

  /// 设置文件夹排序
  Future<void> _onSetFolderSort(SetFolderSortEvent event, Emitter<FoldersState> emit) async {
    _currentSortBy = event.sortBy;
    _currentAscending = event.ascending;

    final sortedFolders = _applySorting(_allFolders);

    if (state is FoldersLoaded) {
      final currentState = state as FoldersLoaded;
      emit(currentState.copyWith(
        folders: sortedFolders,
        sortBy: _currentSortBy,
        ascending: _currentAscending,
      ));
    }
  }

  /// 应用排序
  List<FolderNode> _applySorting(List<FolderNode> folders) {
    final sortedFolders = List<FolderNode>.from(folders);
    
    sortedFolders.sort((a, b) {
      int comparison = 0;
      
      switch (_currentSortBy) {
        case FolderSortBy.name:
          comparison = a.name.compareTo(b.name);
          break;
        case FolderSortBy.createdDate:
          comparison = a.created.compareTo(b.created);
          break;
        case FolderSortBy.modifiedDate:
          comparison = a.updated.compareTo(b.updated);
          break;
        case FolderSortBy.noteCount:
          comparison = a.totalNotesCount.compareTo(b.totalNotesCount);
          break;
        case FolderSortBy.size:
          // 按子文件夹数量排序
          comparison = a.subFolders.length.compareTo(b.subFolders.length);
          break;
      }

      return _currentAscending ? comparison : -comparison;
    });

    return sortedFolders;
  }

  /// 构建已加载状态
  FoldersLoaded _buildLoadedState(
    List<FolderNode> folders, {
    List<FolderNode>? searchResults,
    FolderStats? stats,
  }) {
    final calculatedStats = stats ?? _calculateStats(folders);
    
    return FoldersLoaded(
      folders: folders,
      selectedFolderPath: _selectedFolderPath,
      expandedFolders: _expandedFolders,
      sortBy: _currentSortBy,
      ascending: _currentAscending,
      searchQuery: _currentSearchQuery,
      searchResults: searchResults,
      totalFolders: calculatedStats.totalFolders,
      totalNotes: calculatedStats.totalNotes,
    );
  }

  /// 计算统计信息
  FolderStats _calculateStats(List<FolderNode> folders) {
    int totalFolders = 0;
    int totalNotes = 0;

    void countFolder(FolderNode folder) {
      totalFolders++;
      totalNotes += folder.notes.length;
      
      for (final subfolder in folder.subFolders) {
        countFolder(subfolder);
      }
    }

    for (final folder in folders) {
      countFolder(folder);
    }

    return FolderStats(
      totalFolders: totalFolders,
      totalNotes: totalNotes,
      directNotes: 0,
      directSubfolders: folders.length,
      lastModified: DateTime.now(),
    );
  }

  /// 获取所有文件夹路径
  List<String> _getAllFolderPaths(List<FolderNode> folders, String? rootPath) {
    final paths = <String>[];
    
    void addPaths(FolderNode folder) {
      if (rootPath == null || folder.folderPath.startsWith(rootPath)) {
        paths.add(folder.folderPath);
      }
      
      for (final subfolder in folder.subFolders) {
        addPaths(subfolder);
      }
    }

    for (final folder in folders) {
      addPaths(folder);
    }

    return paths;
  }

  /// 添加文件夹到缓存
  void _addFolderToCache(FolderNode folder) {
    // 简化实现：直接添加到列表
    // 在实际实现中，需要正确维护树结构
    _allFolders.add(folder);
  }

  /// 从缓存中移除文件夹
  void _removeFolderFromCache(String folderPath) {
    _allFolders.removeWhere((folder) => folder.folderPath == folderPath);
  }

  /// 更新缓存中的文件夹
  void _updateFolderInCache(FolderNode updatedFolder) {
    final index = _allFolders.indexWhere(
      (folder) => folder.folderPath == updatedFolder.folderPath,
    );
    
    if (index != -1) {
      _allFolders[index] = updatedFolder;
    }
  }

  /// 获取当前选中的文件夹
  String? get selectedFolderPath => _selectedFolderPath;

  /// 获取当前展开的文件夹集合
  Set<String> get expandedFolders => Set.from(_expandedFolders);

  /// 检查文件夹是否展开
  bool isFolderExpanded(String folderPath) {
    return _expandedFolders.contains(folderPath);
  }

  /// 检查文件夹是否被选中
  bool isFolderSelected(String folderPath) {
    return _selectedFolderPath == folderPath;
  }
}