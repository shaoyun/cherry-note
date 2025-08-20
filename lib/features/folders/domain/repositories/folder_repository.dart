import '../entities/folder_node.dart';

/// 文件夹仓储接口
abstract class FolderRepository {
  /// 加载文件夹树
  Future<List<FolderNode>> loadFolders({String? rootPath});

  /// 创建文件夹
  Future<FolderNode> createFolder({
    required String parentPath,
    required String folderName,
    Map<String, dynamic>? metadata,
  });

  /// 获取文件夹
  Future<FolderNode?> getFolder(String folderPath);

  /// 更新文件夹
  Future<FolderNode> updateFolder(FolderNode folder);

  /// 删除文件夹
  Future<void> deleteFolder(String folderPath, {bool recursive = false});

  /// 重命名文件夹
  Future<FolderNode> renameFolder(String folderPath, String newName);

  /// 移动文件夹
  Future<FolderNode> moveFolder(String folderPath, String newParentPath);

  /// 复制文件夹
  Future<FolderNode> copyFolder(
    String folderPath,
    String newParentPath, {
    String? newName,
  });

  /// 搜索文件夹
  Future<List<FolderNode>> searchFolders({
    required String query,
    String? rootPath,
  });

  /// 检查文件夹是否存在
  Future<bool> folderExists(String folderPath);

  /// 获取文件夹统计信息
  Future<FolderStats> getFolderStats(String folderPath);

  /// 批量删除文件夹
  Future<Map<String, bool>> deleteFolders(
    List<String> folderPaths, {
    bool recursive = false,
  });

  /// 批量移动文件夹
  Future<Map<String, bool>> moveFolders(
    List<String> folderPaths,
    String newParentPath,
  );

  /// 批量复制文件夹
  Future<Map<String, bool>> copyFolders(
    List<String> folderPaths,
    String newParentPath,
  );

  /// 获取文件夹路径列表
  Future<List<String>> getFolderPaths({String? rootPath});

  /// 验证文件夹名称
  bool isValidFolderName(String name);

  /// 验证文件夹路径
  bool isValidFolderPath(String path);

  /// 生成唯一文件夹名称
  Future<String> generateUniqueFolderName(String parentPath, String baseName);
}