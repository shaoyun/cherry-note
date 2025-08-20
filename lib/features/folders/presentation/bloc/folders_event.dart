import 'package:equatable/equatable.dart';

/// 文件夹管理事件基类
abstract class FoldersEvent extends Equatable {
  const FoldersEvent();

  @override
  List<Object?> get props => [];
}

/// 加载文件夹树事件
class LoadFoldersEvent extends FoldersEvent {
  final String? rootPath;
  final bool forceRefresh;

  const LoadFoldersEvent({
    this.rootPath,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [rootPath, forceRefresh];
}

/// 创建文件夹事件
class CreateFolderEvent extends FoldersEvent {
  final String parentPath;
  final String folderName;
  final Map<String, dynamic>? metadata;

  const CreateFolderEvent({
    required this.parentPath,
    required this.folderName,
    this.metadata,
  });

  @override
  List<Object?> get props => [parentPath, folderName, metadata];
}

/// 重命名文件夹事件
class RenameFolderEvent extends FoldersEvent {
  final String folderPath;
  final String newName;

  const RenameFolderEvent({
    required this.folderPath,
    required this.newName,
  });

  @override
  List<Object?> get props => [folderPath, newName];
}

/// 删除文件夹事件
class DeleteFolderEvent extends FoldersEvent {
  final String folderPath;
  final bool recursive;

  const DeleteFolderEvent({
    required this.folderPath,
    this.recursive = false,
  });

  @override
  List<Object?> get props => [folderPath, recursive];
}

/// 移动文件夹事件
class MoveFolderEvent extends FoldersEvent {
  final String folderPath;
  final String newParentPath;

  const MoveFolderEvent({
    required this.folderPath,
    required this.newParentPath,
  });

  @override
  List<Object?> get props => [folderPath, newParentPath];
}

/// 复制文件夹事件
class CopyFolderEvent extends FoldersEvent {
  final String folderPath;
  final String newParentPath;
  final String? newName;

  const CopyFolderEvent({
    required this.folderPath,
    required this.newParentPath,
    this.newName,
  });

  @override
  List<Object?> get props => [folderPath, newParentPath, newName];
}

/// 展开文件夹事件
class ExpandFolderEvent extends FoldersEvent {
  final String folderPath;

  const ExpandFolderEvent({required this.folderPath});

  @override
  List<Object?> get props => [folderPath];
}

/// 折叠文件夹事件
class CollapseFolderEvent extends FoldersEvent {
  final String folderPath;

  const CollapseFolderEvent({required this.folderPath});

  @override
  List<Object?> get props => [folderPath];
}

/// 切换文件夹展开状态事件
class ToggleFolderEvent extends FoldersEvent {
  final String folderPath;

  const ToggleFolderEvent({required this.folderPath});

  @override
  List<Object?> get props => [folderPath];
}

/// 选择文件夹事件
class SelectFolderEvent extends FoldersEvent {
  final String folderPath;

  const SelectFolderEvent({required this.folderPath});

  @override
  List<Object?> get props => [folderPath];
}

/// 取消选择文件夹事件
class DeselectFolderEvent extends FoldersEvent {
  const DeselectFolderEvent();
}

/// 刷新文件夹事件
class RefreshFolderEvent extends FoldersEvent {
  final String? folderPath;

  const RefreshFolderEvent({this.folderPath});

  @override
  List<Object?> get props => [folderPath];
}

/// 搜索文件夹事件
class SearchFoldersEvent extends FoldersEvent {
  final String query;
  final String? rootPath;

  const SearchFoldersEvent({
    required this.query,
    this.rootPath,
  });

  @override
  List<Object?> get props => [query, rootPath];
}

/// 清除搜索事件
class ClearFolderSearchEvent extends FoldersEvent {
  const ClearFolderSearchEvent();
}

/// 更新文件夹元数据事件
class UpdateFolderMetadataEvent extends FoldersEvent {
  final String folderPath;
  final Map<String, dynamic> metadata;

  const UpdateFolderMetadataEvent({
    required this.folderPath,
    required this.metadata,
  });

  @override
  List<Object?> get props => [folderPath, metadata];
}

/// 批量操作文件夹事件
class BatchFolderOperationEvent extends FoldersEvent {
  final List<String> folderPaths;
  final FolderBatchOperation operation;
  final String? targetPath;

  const BatchFolderOperationEvent({
    required this.folderPaths,
    required this.operation,
    this.targetPath,
  });

  @override
  List<Object?> get props => [folderPaths, operation, targetPath];
}

/// 展开所有文件夹事件
class ExpandAllFoldersEvent extends FoldersEvent {
  final String? rootPath;

  const ExpandAllFoldersEvent({this.rootPath});

  @override
  List<Object?> get props => [rootPath];
}

/// 折叠所有文件夹事件
class CollapseAllFoldersEvent extends FoldersEvent {
  final String? rootPath;

  const CollapseAllFoldersEvent({this.rootPath});

  @override
  List<Object?> get props => [rootPath];
}

/// 设置文件夹排序事件
class SetFolderSortEvent extends FoldersEvent {
  final FolderSortBy sortBy;
  final bool ascending;

  const SetFolderSortEvent({
    required this.sortBy,
    this.ascending = true,
  });

  @override
  List<Object?> get props => [sortBy, ascending];
}

/// 文件夹批量操作类型
enum FolderBatchOperation {
  delete,
  move,
  copy,
}

/// 文件夹排序方式
enum FolderSortBy {
  name,
  createdDate,
  modifiedDate,
  size,
  noteCount,
}