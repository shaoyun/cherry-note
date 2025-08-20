import 'package:equatable/equatable.dart';
import '../../domain/entities/folder_node.dart';
import 'folders_event.dart';

/// 文件夹管理状态基类
abstract class FoldersState extends Equatable {
  const FoldersState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class FoldersInitial extends FoldersState {
  const FoldersInitial();
}

/// 加载中状态
class FoldersLoading extends FoldersState {
  const FoldersLoading();
}

/// 文件夹已加载状态
class FoldersLoaded extends FoldersState {
  final List<FolderNode> folders;
  final String? selectedFolderPath;
  final Set<String> expandedFolders;
  final FolderSortBy sortBy;
  final bool ascending;
  final String? searchQuery;
  final List<FolderNode>? searchResults;
  final int totalFolders;
  final int totalNotes;

  const FoldersLoaded({
    required this.folders,
    this.selectedFolderPath,
    this.expandedFolders = const {},
    this.sortBy = FolderSortBy.name,
    this.ascending = true,
    this.searchQuery,
    this.searchResults,
    this.totalFolders = 0,
    this.totalNotes = 0,
  });

  /// 复制状态并更新指定字段
  FoldersLoaded copyWith({
    List<FolderNode>? folders,
    String? selectedFolderPath,
    Set<String>? expandedFolders,
    FolderSortBy? sortBy,
    bool? ascending,
    String? searchQuery,
    List<FolderNode>? searchResults,
    int? totalFolders,
    int? totalNotes,
    bool clearSelection = false,
    bool clearSearch = false,
  }) {
    return FoldersLoaded(
      folders: folders ?? this.folders,
      selectedFolderPath: clearSelection ? null : (selectedFolderPath ?? this.selectedFolderPath),
      expandedFolders: expandedFolders ?? this.expandedFolders,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      searchResults: clearSearch ? null : (searchResults ?? this.searchResults),
      totalFolders: totalFolders ?? this.totalFolders,
      totalNotes: totalNotes ?? this.totalNotes,
    );
  }

  /// 检查文件夹是否展开
  bool isFolderExpanded(String folderPath) {
    return expandedFolders.contains(folderPath);
  }

  /// 检查文件夹是否被选中
  bool isFolderSelected(String folderPath) {
    return selectedFolderPath == folderPath;
  }

  /// 获取当前显示的文件夹列表（搜索结果或全部文件夹）
  List<FolderNode> get displayedFolders {
    return searchResults ?? folders;
  }

  /// 检查是否在搜索模式
  bool get isSearching {
    return searchQuery != null && searchQuery!.isNotEmpty;
  }

  @override
  List<Object?> get props => [
        folders,
        selectedFolderPath,
        expandedFolders,
        sortBy,
        ascending,
        searchQuery,
        searchResults,
        totalFolders,
        totalNotes,
      ];
}

/// 文件夹操作进行中状态
class FolderOperationInProgress extends FoldersState {
  final String operation;
  final String? folderPath;
  final String? message;

  const FolderOperationInProgress({
    required this.operation,
    this.folderPath,
    this.message,
  });

  @override
  List<Object?> get props => [operation, folderPath, message];
}

/// 文件夹操作成功状态
class FolderOperationSuccess extends FoldersState {
  final String operation;
  final String message;
  final String? folderPath;
  final FolderNode? folder;

  const FolderOperationSuccess({
    required this.operation,
    required this.message,
    this.folderPath,
    this.folder,
  });

  @override
  List<Object?> get props => [operation, message, folderPath, folder];
}

/// 文件夹操作错误状态
class FolderOperationError extends FoldersState {
  final String operation;
  final String message;
  final String? folderPath;
  final Object? error;

  const FolderOperationError({
    required this.operation,
    required this.message,
    this.folderPath,
    this.error,
  });

  @override
  List<Object?> get props => [operation, message, folderPath, error];
}

/// 文件夹搜索中状态
class FoldersSearching extends FoldersState {
  final String query;
  final String? rootPath;

  const FoldersSearching({
    required this.query,
    this.rootPath,
  });

  @override
  List<Object?> get props => [query, rootPath];
}

/// 文件夹搜索结果状态
class FoldersSearchResults extends FoldersState {
  final String query;
  final List<FolderNode> results;
  final int totalResults;
  final String? rootPath;

  const FoldersSearchResults({
    required this.query,
    required this.results,
    required this.totalResults,
    this.rootPath,
  });

  @override
  List<Object?> get props => [query, results, totalResults, rootPath];
}

/// 批量操作进行中状态
class FoldersBatchOperation extends FoldersState {
  final String operation;
  final List<String> folderPaths;
  final int completed;
  final int total;
  final String? currentFolder;

  const FoldersBatchOperation({
    required this.operation,
    required this.folderPaths,
    required this.completed,
    required this.total,
    this.currentFolder,
  });

  /// 获取进度百分比
  double get progress {
    if (total == 0) return 0.0;
    return completed / total;
  }

  @override
  List<Object?> get props => [operation, folderPaths, completed, total, currentFolder];
}

/// 批量操作成功状态
class FoldersBatchOperationSuccess extends FoldersState {
  final String operation;
  final List<String> folderPaths;
  final int successCount;
  final int failureCount;
  final List<String> errors;

  const FoldersBatchOperationSuccess({
    required this.operation,
    required this.folderPaths,
    required this.successCount,
    required this.failureCount,
    this.errors = const [],
  });

  /// 检查是否有失败的操作
  bool get hasFailures => failureCount > 0;

  /// 检查是否全部成功
  bool get allSuccessful => failureCount == 0;

  @override
  List<Object?> get props => [operation, folderPaths, successCount, failureCount, errors];
}

/// 文件夹错误状态
class FoldersError extends FoldersState {
  final String message;
  final Object? error;

  const FoldersError({
    required this.message,
    this.error,
  });

  @override
  List<Object?> get props => [message, error];
}

