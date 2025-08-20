# Cherry Note API 参考文档

## 概述

Cherry Note API 提供了完整的笔记管理功能，包括笔记的创建、编辑、删除、同步等操作。API 采用面向对象的设计，通过Repository模式和Service层提供清晰的接口。

## 核心接口

### 1. 笔记管理 (Note Management)

#### NoteRepository

笔记仓库接口，提供笔记的CRUD操作。

```dart
abstract class NoteRepository {
  /// 获取所有笔记
  Future<List<Note>> getAllNotes();
  
  /// 根据ID获取笔记
  Future<Note?> getNoteById(String id);
  
  /// 根据文件夹获取笔记
  Future<List<Note>> getNotesByFolderId(String folderId);
  
  /// 根据标签获取笔记
  Future<List<Note>> getNotesByTags(List<String> tags, TagLogic logic);
  
  /// 搜索笔记
  Future<List<Note>> searchNotes(String query);
  
  /// 创建笔记
  Future<Note> createNote(Note note);
  
  /// 更新笔记
  Future<Note> updateNote(Note note);
  
  /// 删除笔记
  Future<void> deleteNote(String id);
  
  /// 批量操作
  Future<List<Note>> createMultipleNotes(List<Note> notes);
  Future<void> deleteMultipleNotes(List<String> ids);
  
  /// 监听笔记变化
  Stream<List<Note>> watchNotes();
  Stream<Note?> watchNoteById(String id);
}
```

#### Note 数据模型

```dart
class Note extends Equatable {
  /// 笔记唯一标识符
  final String id;
  
  /// 笔记标题
  final String title;
  
  /// 笔记内容 (Markdown格式)
  final String content;
  
  /// 所属文件夹ID
  final String folderId;
  
  /// 标签列表
  final List<String> tags;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后修改时间
  final DateTime updatedAt;
  
  /// 是否为便签
  final bool isSticky;
  
  /// 文件路径 (相对于根目录)
  final String filePath;
  
  /// 文件大小 (字节)
  final int fileSize;
  
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.folderId,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    this.isSticky = false,
    required this.filePath,
    this.fileSize = 0,
  });
  
  /// 从Markdown文件创建笔记
  factory Note.fromMarkdown(String filePath, String markdown) {
    // 解析Front Matter和内容
    final frontMatter = _parseFrontMatter(markdown);
    final content = _extractContent(markdown);
    
    return Note(
      id: frontMatter['id'] ?? _generateId(),
      title: frontMatter['title'] ?? _extractTitleFromContent(content),
      content: content,
      folderId: _extractFolderIdFromPath(filePath),
      tags: List<String>.from(frontMatter['tags'] ?? []),
      createdAt: DateTime.parse(frontMatter['created'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(frontMatter['updated'] ?? DateTime.now().toIso8601String()),
      isSticky: frontMatter['sticky'] ?? false,
      filePath: filePath,
      fileSize: markdown.length,
    );
  }
  
  /// 转换为Markdown格式
  String toMarkdown() {
    final frontMatter = {
      'id': id,
      'title': title,
      'tags': tags,
      'created': createdAt.toIso8601String(),
      'updated': updatedAt.toIso8601String(),
      'sticky': isSticky,
    };
    
    final yamlString = _generateYamlString(frontMatter);
    return '---\n$yamlString\n---\n\n$content';
  }
  
  /// 复制并修改属性
  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? folderId,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSticky,
    String? filePath,
    int? fileSize,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      folderId: folderId ?? this.folderId,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSticky: isSticky ?? this.isSticky,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
    );
  }
  
  @override
  List<Object?> get props => [
    id, title, content, folderId, tags, 
    createdAt, updatedAt, isSticky, filePath, fileSize
  ];
}
```

### 2. 文件夹管理 (Folder Management)

#### FolderRepository

文件夹仓库接口，提供文件夹的层级管理。

```dart
abstract class FolderRepository {
  /// 获取根文件夹
  Future<FolderNode> getRootFolder();
  
  /// 根据ID获取文件夹
  Future<FolderNode?> getFolderById(String id);
  
  /// 根据路径获取文件夹
  Future<FolderNode?> getFolderByPath(String path);
  
  /// 获取所有文件夹
  Future<List<FolderNode>> getAllFolders();
  
  /// 创建文件夹
  Future<FolderNode> createFolder(String name, String? parentId);
  
  /// 更新文件夹
  Future<FolderNode> updateFolder(FolderNode folder);
  
  /// 删除文件夹
  Future<void> deleteFolder(String id, {bool recursive = false});
  
  /// 移动文件夹
  Future<FolderNode> moveFolder(String folderId, String? newParentId);
  
  /// 获取文件夹树
  Future<FolderNode> getFolderTree();
  
  /// 监听文件夹变化
  Stream<List<FolderNode>> watchFolders();
  Stream<FolderNode> watchFolderTree();
}
```

#### FolderNode 数据模型

```dart
class FolderNode extends Equatable {
  /// 文件夹唯一标识符
  final String id;
  
  /// 文件夹名称
  final String name;
  
  /// 父文件夹ID (null表示根文件夹)
  final String? parentId;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后修改时间
  final DateTime updatedAt;
  
  /// 文件夹描述
  final String? description;
  
  /// 文件夹颜色 (十六进制)
  final String? color;
  
  /// 子文件夹列表
  final List<FolderNode> children;
  
  /// 文件夹中的笔记列表
  final List<Note> notes;
  
  /// 文件夹路径
  final String path;
  
  /// 是否展开 (UI状态)
  final bool isExpanded;
  
  const FolderNode({
    required this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.color,
    this.children = const [],
    this.notes = const [],
    required this.path,
    this.isExpanded = false,
  });
  
  /// 从文件夹元数据创建
  factory FolderNode.fromMetadata(String folderPath, String? metadata) {
    final Map<String, dynamic> data = metadata != null 
        ? jsonDecode(metadata) 
        : <String, dynamic>{};
    
    return FolderNode(
      id: data['id'] ?? _generateId(),
      name: data['name'] ?? _extractNameFromPath(folderPath),
      parentId: data['parentId'],
      createdAt: DateTime.parse(data['created'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updated'] ?? DateTime.now().toIso8601String()),
      description: data['description'],
      color: data['color'],
      path: folderPath,
    );
  }
  
  /// 转换为元数据JSON
  String toMetadataJson() {
    final data = {
      'id': id,
      'name': name,
      'parentId': parentId,
      'created': createdAt.toIso8601String(),
      'updated': updatedAt.toIso8601String(),
      'description': description,
      'color': color,
    };
    
    return jsonEncode(data);
  }
  
  /// 获取所有子文件夹 (递归)
  List<FolderNode> get allChildren {
    final result = <FolderNode>[];
    for (final child in children) {
      result.add(child);
      result.addAll(child.allChildren);
    }
    return result;
  }
  
  /// 获取所有笔记 (包括子文件夹)
  List<Note> get allNotes {
    final result = <Note>[...notes];
    for (final child in children) {
      result.addAll(child.allNotes);
    }
    return result;
  }
  
  /// 获取文件夹深度
  int get depth => path.split('/').length - 1;
  
  /// 是否为根文件夹
  bool get isRoot => parentId == null;
  
  /// 是否为空文件夹
  bool get isEmpty => children.isEmpty && notes.isEmpty;
  
  @override
  List<Object?> get props => [
    id, name, parentId, createdAt, updatedAt, 
    description, color, path, isExpanded
  ];
}
```

### 3. 标签管理 (Tag Management)

#### TagRepository

标签仓库接口，提供标签的管理和过滤功能。

```dart
abstract class TagRepository {
  /// 获取所有标签
  Future<List<Tag>> getAllTags();
  
  /// 根据名称获取标签
  Future<Tag?> getTagByName(String name);
  
  /// 搜索标签
  Future<List<Tag>> searchTags(String query);
  
  /// 创建标签
  Future<Tag> createTag(String name, {String? color});
  
  /// 更新标签
  Future<Tag> updateTag(Tag tag);
  
  /// 删除标签
  Future<void> deleteTag(String name);
  
  /// 获取标签使用统计
  Future<Map<String, int>> getTagUsageStats();
  
  /// 获取标签建议
  Future<List<String>> getTagSuggestions(String input);
  
  /// 监听标签变化
  Stream<List<Tag>> watchTags();
}
```

#### Tag 数据模型

```dart
class Tag extends Equatable {
  /// 标签名称 (唯一标识符)
  final String name;
  
  /// 标签颜色 (十六进制)
  final String color;
  
  /// 使用次数
  final int usageCount;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后使用时间
  final DateTime lastUsedAt;
  
  const Tag({
    required this.name,
    required this.color,
    this.usageCount = 0,
    required this.createdAt,
    required this.lastUsedAt,
  });
  
  /// 创建默认标签
  factory Tag.create(String name) {
    return Tag(
      name: name,
      color: _generateRandomColor(),
      createdAt: DateTime.now(),
      lastUsedAt: DateTime.now(),
    );
  }
  
  /// 复制并修改属性
  Tag copyWith({
    String? name,
    String? color,
    int? usageCount,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return Tag(
      name: name ?? this.name,
      color: color ?? this.color,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
  
  @override
  List<Object?> get props => [name, color, usageCount, createdAt, lastUsedAt];
}

/// 标签过滤逻辑
enum TagLogic {
  /// 包含所有标签 (AND)
  and,
  /// 包含任一标签 (OR)
  or,
}

/// 标签过滤器
class TagFilter extends Equatable {
  /// 选中的标签列表
  final List<String> selectedTags;
  
  /// 过滤逻辑
  final TagLogic logic;
  
  const TagFilter({
    this.selectedTags = const [],
    this.logic = TagLogic.or,
  });
  
  /// 是否有活动过滤器
  bool get hasActiveFilter => selectedTags.isNotEmpty;
  
  /// 检查笔记是否匹配过滤器
  bool matches(Note note) {
    if (!hasActiveFilter) return true;
    
    switch (logic) {
      case TagLogic.and:
        return selectedTags.every((tag) => note.tags.contains(tag));
      case TagLogic.or:
        return selectedTags.any((tag) => note.tags.contains(tag));
    }
  }
  
  @override
  List<Object?> get props => [selectedTags, logic];
}
```

### 4. 同步管理 (Sync Management)

#### SyncService

同步服务接口，管理本地和远程数据的同步。

```dart
abstract class SyncService {
  /// 同步本地数据到远程
  Future<SyncResult> syncToRemote({
    List<String>? specificFiles,
    CancellationToken? cancellationToken,
  });
  
  /// 从远程同步数据到本地
  Future<SyncResult> syncFromRemote({
    List<String>? specificFiles,
    CancellationToken? cancellationToken,
  });
  
  /// 执行完整双向同步
  Future<SyncResult> fullSync({
    CancellationToken? cancellationToken,
  });
  
  /// 启用自动同步
  Future<void> enableAutoSync({
    Duration interval = const Duration(minutes: 5),
  });
  
  /// 禁用自动同步
  Future<void> disableAutoSync();
  
  /// 获取同步状态
  SyncStatus get currentStatus;
  
  /// 同步状态流
  Stream<SyncStatus> get syncStatusStream;
  
  /// 获取同步信息
  Future<SyncInfo> getSyncInfo();
  
  /// 获取待同步文件列表
  Future<List<String>> getPendingSyncFiles();
  
  /// 清除同步队列
  Future<void> clearSyncQueue();
  
  /// 强制同步指定文件
  Future<void> forceSyncFile(String filePath);
}
```

#### 同步相关数据模型

```dart
/// 同步状态
enum SyncStatus {
  /// 空闲状态
  idle,
  /// 正在同步
  syncing,
  /// 同步成功
  success,
  /// 同步失败
  error,
  /// 存在冲突
  conflict,
  /// 离线状态
  offline,
}

/// 同步结果
class SyncResult extends Equatable {
  /// 是否成功
  final bool success;
  
  /// 同步的文件列表
  final List<String> syncedFiles;
  
  /// 跳过的文件列表
  final List<String> skippedFiles;
  
  /// 冲突文件列表
  final List<FileConflict> conflicts;
  
  /// 错误信息
  final String? error;
  
  /// 同步开始时间
  final DateTime startTime;
  
  /// 同步结束时间
  final DateTime endTime;
  
  /// 传输的字节数
  final int bytesTransferred;
  
  const SyncResult({
    required this.success,
    this.syncedFiles = const [],
    this.skippedFiles = const [],
    this.conflicts = const [],
    this.error,
    required this.startTime,
    required this.endTime,
    this.bytesTransferred = 0,
  });
  
  /// 同步耗时
  Duration get duration => endTime.difference(startTime);
  
  /// 是否有冲突
  bool get hasConflicts => conflicts.isNotEmpty;
  
  /// 同步文件总数
  int get totalFiles => syncedFiles.length + skippedFiles.length + conflicts.length;
  
  @override
  List<Object?> get props => [
    success, syncedFiles, skippedFiles, conflicts, 
    error, startTime, endTime, bytesTransferred
  ];
}

/// 文件冲突
class FileConflict extends Equatable {
  /// 文件路径
  final String filePath;
  
  /// 本地修改时间
  final DateTime localModified;
  
  /// 远程修改时间
  final DateTime remoteModified;
  
  /// 本地内容
  final String localContent;
  
  /// 远程内容
  final String remoteContent;
  
  /// 冲突类型
  final ConflictType type;
  
  const FileConflict({
    required this.filePath,
    required this.localModified,
    required this.remoteModified,
    required this.localContent,
    required this.remoteContent,
    required this.type,
  });
  
  /// 是否为内容冲突
  bool get isContentConflict => type == ConflictType.content;
  
  /// 是否为删除冲突
  bool get isDeleteConflict => type == ConflictType.delete;
  
  @override
  List<Object?> get props => [
    filePath, localModified, remoteModified, 
    localContent, remoteContent, type
  ];
}

/// 冲突类型
enum ConflictType {
  /// 内容冲突
  content,
  /// 删除冲突
  delete,
  /// 移动冲突
  move,
}

/// 冲突解决策略
enum ConflictResolution {
  /// 保留本地版本
  keepLocal,
  /// 保留远程版本
  keepRemote,
  /// 合并内容
  merge,
  /// 创建两个副本
  createBoth,
  /// 跳过此文件
  skip,
}

/// 同步信息
class SyncInfo extends Equatable {
  /// 最后同步时间
  final DateTime? lastSyncTime;
  
  /// 下次自动同步时间
  final DateTime? nextAutoSyncTime;
  
  /// 是否启用自动同步
  final bool autoSyncEnabled;
  
  /// 自动同步间隔
  final Duration autoSyncInterval;
  
  /// 待同步文件数量
  final int pendingFilesCount;
  
  /// 冲突文件数量
  final int conflictFilesCount;
  
  /// 本地文件总数
  final int localFilesCount;
  
  /// 远程文件总数
  final int remoteFilesCount;
  
  const SyncInfo({
    this.lastSyncTime,
    this.nextAutoSyncTime,
    this.autoSyncEnabled = false,
    this.autoSyncInterval = const Duration(minutes: 5),
    this.pendingFilesCount = 0,
    this.conflictFilesCount = 0,
    this.localFilesCount = 0,
    this.remoteFilesCount = 0,
  });
  
  @override
  List<Object?> get props => [
    lastSyncTime, nextAutoSyncTime, autoSyncEnabled, autoSyncInterval,
    pendingFilesCount, conflictFilesCount, localFilesCount, remoteFilesCount
  ];
}
```

### 5. 存储管理 (Storage Management)

#### S3StorageRepository

S3存储仓库接口，提供与S3兼容存储的交互。

```dart
abstract class S3StorageRepository {
  /// 上传文件
  Future<void> uploadFile(
    String path, 
    String content, {
    Map<String, String>? metadata,
    ProgressCallback? onProgress,
  });
  
  /// 下载文件
  Future<String> downloadFile(
    String path, {
    ProgressCallback? onProgress,
  });
  
  /// 删除文件
  Future<void> deleteFile(String path);
  
  /// 检查文件是否存在
  Future<bool> fileExists(String path);
  
  /// 获取文件信息
  Future<FileInfo?> getFileInfo(String path);
  
  /// 列出文件
  Future<List<String>> listFiles(
    String prefix, {
    int? maxKeys,
    String? continuationToken,
  });
  
  /// 列出文件夹
  Future<List<String>> listFolders(String prefix);
  
  /// 创建文件夹
  Future<void> createFolder(String path);
  
  /// 删除文件夹
  Future<void> deleteFolder(String path, {bool recursive = false});
  
  /// 批量上传
  Future<BatchOperationResult> uploadMultipleFiles(
    Map<String, String> files, {
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  });
  
  /// 批量下载
  Future<Map<String, String>> downloadMultipleFiles(
    List<String> paths, {
    ProgressCallback? onProgress,
    CancellationToken? cancellationToken,
  });
  
  /// 批量删除
  Future<BatchOperationResult> deleteMultipleFiles(List<String> paths);
  
  /// 测试连接
  Future<bool> testConnection();
  
  /// 获取存储使用情况
  Future<StorageUsage> getStorageUsage();
}
```

#### 存储相关数据模型

```dart
/// 文件信息
class FileInfo extends Equatable {
  /// 文件路径
  final String path;
  
  /// 文件大小 (字节)
  final int size;
  
  /// 最后修改时间
  final DateTime lastModified;
  
  /// ETag (用于版本控制)
  final String etag;
  
  /// 内容类型
  final String contentType;
  
  /// 元数据
  final Map<String, String> metadata;
  
  const FileInfo({
    required this.path,
    required this.size,
    required this.lastModified,
    required this.etag,
    this.contentType = 'text/markdown',
    this.metadata = const {},
  });
  
  @override
  List<Object?> get props => [path, size, lastModified, etag, contentType, metadata];
}

/// 批量操作结果
class BatchOperationResult extends Equatable {
  /// 是否成功
  final bool success;
  
  /// 成功处理的文件列表
  final List<String> successfulFiles;
  
  /// 失败的文件列表
  final List<String> failedFiles;
  
  /// 错误信息映射
  final Map<String, String> errors;
  
  /// 总处理时间
  final Duration duration;
  
  /// 传输的字节数
  final int bytesTransferred;
  
  const BatchOperationResult({
    required this.success,
    this.successfulFiles = const [],
    this.failedFiles = const [],
    this.errors = const {},
    required this.duration,
    this.bytesTransferred = 0,
  });
  
  /// 成功率
  double get successRate {
    final total = successfulFiles.length + failedFiles.length;
    return total > 0 ? successfulFiles.length / total : 0.0;
  }
  
  @override
  List<Object?> get props => [
    success, successfulFiles, failedFiles, 
    errors, duration, bytesTransferred
  ];
}

/// 存储使用情况
class StorageUsage extends Equatable {
  /// 已使用空间 (字节)
  final int usedBytes;
  
  /// 总空间 (字节, null表示无限制)
  final int? totalBytes;
  
  /// 文件数量
  final int fileCount;
  
  /// 文件夹数量
  final int folderCount;
  
  const StorageUsage({
    required this.usedBytes,
    this.totalBytes,
    required this.fileCount,
    required this.folderCount,
  });
  
  /// 使用率 (0.0 - 1.0)
  double get usageRatio {
    if (totalBytes == null) return 0.0;
    return usedBytes / totalBytes!;
  }
  
  /// 剩余空间 (字节)
  int? get remainingBytes {
    if (totalBytes == null) return null;
    return totalBytes! - usedBytes;
  }
  
  /// 格式化已使用空间
  String get formattedUsedSpace => _formatBytes(usedBytes);
  
  /// 格式化总空间
  String get formattedTotalSpace => 
      totalBytes != null ? _formatBytes(totalBytes!) : '无限制';
  
  @override
  List<Object?> get props => [usedBytes, totalBytes, fileCount, folderCount];
}

/// 进度回调函数类型
typedef ProgressCallback = void Function(int transferred, int total);

/// 取消令牌
class CancellationToken {
  bool _isCancelled = false;
  
  /// 是否已取消
  bool get isCancelled => _isCancelled;
  
  /// 取消操作
  void cancel() => _isCancelled = true;
  
  /// 检查是否取消，如果取消则抛出异常
  void throwIfCancelled() {
    if (_isCancelled) {
      throw OperationCancelledException();
    }
  }
}

/// 操作取消异常
class OperationCancelledException implements Exception {
  final String message;
  
  const OperationCancelledException([this.message = 'Operation was cancelled']);
  
  @override
  String toString() => 'OperationCancelledException: $message';
}
```

## 使用示例

### 创建和管理笔记

```dart
// 获取笔记仓库实例
final noteRepository = GetIt.instance<NoteRepository>();

// 创建新笔记
final newNote = Note(
  id: uuid.v4(),
  title: '我的第一篇笔记',
  content: '# 标题\n\n这是笔记内容...',
  folderId: 'folder-1',
  tags: ['工作', '重要'],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  filePath: '工作笔记/我的第一篇笔记.md',
);

final createdNote = await noteRepository.createNote(newNote);

// 搜索笔记
final searchResults = await noteRepository.searchNotes('Flutter');

// 根据标签过滤笔记
final workNotes = await noteRepository.getNotesByTags(
  ['工作'], 
  TagLogic.and,
);

// 监听笔记变化
noteRepository.watchNotes().listen((notes) {
  print('笔记列表已更新，共 ${notes.length} 篇笔记');
});
```

### 文件夹管理

```dart
// 获取文件夹仓库实例
final folderRepository = GetIt.instance<FolderRepository>();

// 创建文件夹
final newFolder = await folderRepository.createFolder('新项目', 'parent-folder-id');

// 获取文件夹树
final folderTree = await folderRepository.getFolderTree();

// 移动文件夹
await folderRepository.moveFolder('folder-id', 'new-parent-id');

// 监听文件夹变化
folderRepository.watchFolderTree().listen((tree) {
  print('文件夹结构已更新');
});
```

### 同步操作

```dart
// 获取同步服务实例
final syncService = GetIt.instance<SyncService>();

// 执行完整同步
final result = await syncService.fullSync();

if (result.success) {
  print('同步成功，处理了 ${result.totalFiles} 个文件');
} else {
  print('同步失败：${result.error}');
}

// 处理冲突
if (result.hasConflicts) {
  for (final conflict in result.conflicts) {
    // 显示冲突解决界面
    final resolution = await showConflictResolutionDialog(conflict);
    
    // 应用解决策略
    await conflictResolutionService.resolveConflict(
      conflict.filePath, 
      resolution,
    );
  }
}

// 监听同步状态
syncService.syncStatusStream.listen((status) {
  switch (status) {
    case SyncStatus.syncing:
      showSyncingIndicator();
      break;
    case SyncStatus.success:
      showSyncSuccessMessage();
      break;
    case SyncStatus.error:
      showSyncErrorMessage();
      break;
    case SyncStatus.conflict:
      showConflictNotification();
      break;
    default:
      hideSyncIndicator();
  }
});
```

### 标签管理

```dart
// 获取标签仓库实例
final tagRepository = GetIt.instance<TagRepository>();

// 创建标签
final newTag = await tagRepository.createTag('新标签', color: '#FF5722');

// 获取标签建议
final suggestions = await tagRepository.getTagSuggestions('工');
// 返回: ['工作', '工具', '工程']

// 获取标签使用统计
final stats = await tagRepository.getTagUsageStats();
// 返回: {'工作': 15, '学习': 8, '生活': 5}
```

## 错误处理

### 异常类型

```dart
/// 基础应用异常
abstract class AppException implements Exception {
  final String message;
  final String? code;
  
  const AppException(this.message, [this.code]);
  
  @override
  String toString() => 'AppException: $message';
}

/// 网络异常
class NetworkException extends AppException {
  const NetworkException(String message) : super(message, 'NETWORK_ERROR');
}

/// 存储异常
class StorageException extends AppException {
  const StorageException(String message) : super(message, 'STORAGE_ERROR');
}

/// 同步异常
class SyncException extends AppException {
  const SyncException(String message) : super(message, 'SYNC_ERROR');
}

/// 验证异常
class ValidationException extends AppException {
  final Map<String, String> fieldErrors;
  
  const ValidationException(String message, this.fieldErrors) 
      : super(message, 'VALIDATION_ERROR');
}
```

### 错误处理示例

```dart
try {
  final note = await noteRepository.createNote(newNote);
  print('笔记创建成功');
} on ValidationException catch (e) {
  // 处理验证错误
  for (final entry in e.fieldErrors.entries) {
    print('字段 ${entry.key} 错误: ${entry.value}');
  }
} on StorageException catch (e) {
  // 处理存储错误
  print('存储错误: ${e.message}');
  showErrorDialog('保存失败，请检查存储配置');
} on NetworkException catch (e) {
  // 处理网络错误
  print('网络错误: ${e.message}');
  showErrorDialog('网络连接失败，请检查网络设置');
} catch (e) {
  // 处理其他未知错误
  print('未知错误: $e');
  showErrorDialog('操作失败，请稍后重试');
}
```

## 最佳实践

### 1. 资源管理
- 使用 `Stream` 时记得取消订阅
- 大文件操作时使用进度回调
- 批量操作时使用取消令牌

### 2. 错误处理
- 总是处理可能的异常
- 为用户提供友好的错误信息
- 记录详细的错误日志

### 3. 性能优化
- 使用分页加载大量数据
- 缓存频繁访问的数据
- 避免在UI线程执行耗时操作

### 4. 数据一致性
- 使用事务处理相关操作
- 及时同步本地和远程数据
- 正确处理并发访问

---

更多详细信息请参考项目源代码和单元测试。