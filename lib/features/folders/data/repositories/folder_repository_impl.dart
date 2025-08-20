import '../../domain/entities/folder_node.dart';
import '../../domain/repositories/folder_repository.dart';
import '../datasources/folder_data_source.dart';
import '../models/folder_node_model.dart';

/// 文件夹仓储实现
class FolderRepositoryImpl implements FolderRepository {
  final FolderDataSource _dataSource;

  const FolderRepositoryImpl({
    required FolderDataSource dataSource,
  }) : _dataSource = dataSource;

  @override
  Future<List<FolderNode>> loadFolders({String? rootPath}) async {
    final folderModels = await _dataSource.loadFolders(rootPath: rootPath);
    return folderModels.map((model) => model.toEntity()).toList();
  }

  @override
  Future<FolderNode> createFolder({
    required String parentPath,
    required String folderName,
    Map<String, dynamic>? metadata,
  }) async {
    final folderModel = await _dataSource.createFolder(
      parentPath: parentPath,
      folderName: folderName,
      metadata: metadata,
    );
    return folderModel.toEntity();
  }

  @override
  Future<FolderNode?> getFolder(String folderPath) async {
    final folderModel = await _dataSource.getFolder(folderPath);
    return folderModel?.toEntity();
  }

  @override
  Future<FolderNode> updateFolder(FolderNode folder) async {
    final folderModel = FolderNodeModel.fromEntity(folder);
    final updatedModel = await _dataSource.updateFolder(folderModel);
    return updatedModel.toEntity();
  }

  @override
  Future<void> deleteFolder(String folderPath, {bool recursive = false}) async {
    await _dataSource.deleteFolder(folderPath, recursive: recursive);
  }

  @override
  Future<FolderNode> renameFolder(String folderPath, String newName) async {
    final renamedModel = await _dataSource.renameFolder(folderPath, newName);
    return renamedModel.toEntity();
  }

  @override
  Future<FolderNode> moveFolder(String folderPath, String newParentPath) async {
    final movedModel = await _dataSource.moveFolder(folderPath, newParentPath);
    return movedModel.toEntity();
  }

  @override
  Future<FolderNode> copyFolder(
    String folderPath,
    String newParentPath, {
    String? newName,
  }) async {
    final copiedModel = await _dataSource.copyFolder(
      folderPath,
      newParentPath,
      newName: newName,
    );
    return copiedModel.toEntity();
  }

  @override
  Future<List<FolderNode>> searchFolders({
    required String query,
    String? rootPath,
  }) async {
    final searchResults = await _dataSource.searchFolders(
      query: query,
      rootPath: rootPath,
    );
    return searchResults.map((model) => model.toEntity()).toList();
  }

  @override
  Future<bool> folderExists(String folderPath) async {
    return await _dataSource.folderExists(folderPath);
  }

  @override
  Future<FolderStats> getFolderStats(String folderPath) async {
    final folder = await getFolder(folderPath);
    if (folder == null) {
      throw Exception('Folder not found: $folderPath');
    }
    return folder.stats;
  }

  @override
  Future<Map<String, bool>> deleteFolders(
    List<String> folderPaths, {
    bool recursive = false,
  }) async {
    return await _dataSource.deleteFolders(
      folderPaths,
      recursive: recursive,
    );
  }

  @override
  Future<Map<String, bool>> moveFolders(
    List<String> folderPaths,
    String newParentPath,
  ) async {
    return await _dataSource.moveFolders(folderPaths, newParentPath);
  }

  @override
  Future<Map<String, bool>> copyFolders(
    List<String> folderPaths,
    String newParentPath,
  ) async {
    return await _dataSource.copyFolders(folderPaths, newParentPath);
  }

  @override
  Future<List<String>> getFolderPaths({String? rootPath}) async {
    return await _dataSource.getFolderPaths(rootPath: rootPath);
  }

  @override
  bool isValidFolderName(String name) {
    if (name.isEmpty || name.trim().isEmpty) return false;
    
    // 检查无效字符
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(name)) return false;
    
    // 检查保留名称
    final reservedNames = ['CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 
                          'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9', 
                          'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 
                          'LPT7', 'LPT8', 'LPT9'];
    if (reservedNames.contains(name.toUpperCase())) return false;
    
    // 检查长度
    if (name.length > 255) return false;
    
    // 检查是否以点或空格开头/结尾
    if (name.startsWith('.') || name.startsWith(' ') || 
        name.endsWith('.') || name.endsWith(' ')) return false;
    
    return true;
  }

  @override
  bool isValidFolderPath(String path) {
    return FolderNodeModel.isValidPath(path);
  }

  @override
  Future<String> generateUniqueFolderName(String parentPath, String baseName) async {
    String candidateName = baseName;
    int counter = 1;
    
    while (true) {
      final candidatePath = FolderNodeModel.generateFolderPath(parentPath, candidateName);
      final exists = await folderExists(candidatePath);
      
      if (!exists) {
        return candidateName;
      }
      
      candidateName = '$baseName ($counter)';
      counter++;
      
      // 防止无限循环
      if (counter > 1000) {
        throw Exception('Unable to generate unique folder name for: $baseName');
      }
    }
  }
}