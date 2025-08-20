import '../models/folder_node_model.dart';

/// 文件夹数据源接口
abstract class FolderDataSource {
  /// 加载文件夹列表
  Future<List<FolderNodeModel>> loadFolders({String? rootPath});

  /// 创建文件夹
  Future<FolderNodeModel> createFolder({
    required String parentPath,
    required String folderName,
    Map<String, dynamic>? metadata,
  });

  /// 获取文件夹
  Future<FolderNodeModel?> getFolder(String folderPath);

  /// 更新文件夹
  Future<FolderNodeModel> updateFolder(FolderNodeModel folder);

  /// 删除文件夹
  Future<void> deleteFolder(String folderPath, {bool recursive = false});

  /// 重命名文件夹
  Future<FolderNodeModel> renameFolder(String folderPath, String newName);

  /// 移动文件夹
  Future<FolderNodeModel> moveFolder(String folderPath, String newParentPath);

  /// 复制文件夹
  Future<FolderNodeModel> copyFolder(
    String folderPath,
    String newParentPath, {
    String? newName,
  });

  /// 搜索文件夹
  Future<List<FolderNodeModel>> searchFolders({
    required String query,
    String? rootPath,
  });

  /// 检查文件夹是否存在
  Future<bool> folderExists(String folderPath);

  /// 获取文件夹路径列表
  Future<List<String>> getFolderPaths({String? rootPath});

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
}