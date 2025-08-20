import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

import '../models/folder_node_model.dart';
import 'folder_data_source.dart';
import '../../../../shared/constants/app_constants.dart';
import '../../../../shared/utils/path_utils.dart';
import '../../../../core/error/exceptions.dart';

/// 本地文件系统文件夹数据源实现
class LocalFolderDataSource implements FolderDataSource {
  final String _basePath;

  const LocalFolderDataSource({
    required String basePath,
  }) : _basePath = basePath;

  @override
  Future<List<FolderNodeModel>> loadFolders({String? rootPath}) async {
    try {
      final searchPath = rootPath != null 
          ? path.join(_basePath, rootPath)
          : _basePath;
      
      final directory = Directory(searchPath);
      if (!await directory.exists()) {
        return [];
      }

      final folderPaths = <String>[];
      final folderMetadata = <String, String>{};

      // 递归扫描文件夹
      await _scanDirectories(directory, folderPaths, folderMetadata);

      // 构建文件夹树
      final folders = FolderNodeModel.buildFolderTree(folderPaths, folderMetadata);
      
      return folders;
    } catch (e) {
      throw StorageException('Failed to load folders: ${e.toString()}');
    }
  }

  @override
  Future<FolderNodeModel> createFolder({
    required String parentPath,
    required String folderName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 生成文件夹路径
      final folderPath = FolderNodeModel.generateFolderPath(parentPath, folderName);
      final fullPath = path.join(_basePath, folderPath);

      // 检查是否已存在
      final directory = Directory(fullPath);
      if (await directory.exists()) {
        throw StorageException('Folder already exists: $folderPath');
      }

      // 创建目录
      await directory.create(recursive: true);

      // 创建文件夹模型
      final folder = FolderNodeModel(
        folderPath: folderPath,
        name: folderName,
        created: DateTime.now(),
        updated: DateTime.now(),
        description: metadata?['description']?.toString(),
        color: metadata?['color']?.toString(),
      );

      // 保存元数据
      await _saveFolderMetadata(folder);

      return folder;
    } catch (e) {
      throw StorageException('Failed to create folder: ${e.toString()}');
    }
  }

  @override
  Future<FolderNodeModel?> getFolder(String folderPath) async {
    try {
      final fullPath = path.join(_basePath, folderPath);
      final directory = Directory(fullPath);
      
      if (!await directory.exists()) {
        return null;
      }

      // 加载元数据
      final metadataPath = path.join(fullPath, AppConstants.metadataFileName);
      String? metadataJson;
      
      final metadataFile = File(metadataPath);
      if (await metadataFile.exists()) {
        metadataJson = await metadataFile.readAsString();
      }

      return FolderNodeModel.fromMetadata(folderPath, metadataJson);
    } catch (e) {
      throw StorageException('Failed to get folder: ${e.toString()}');
    }
  }

  @override
  Future<FolderNodeModel> updateFolder(FolderNodeModel folder) async {
    try {
      final fullPath = path.join(_basePath, folder.folderPath);
      final directory = Directory(fullPath);
      
      if (!await directory.exists()) {
        throw StorageException('Folder not found: ${folder.folderPath}');
      }

      // 更新时间戳
      final updatedFolder = folder.copyWith(updated: DateTime.now());

      // 保存元数据
      await _saveFolderMetadata(updatedFolder);

      return updatedFolder;
    } catch (e) {
      throw StorageException('Failed to update folder: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteFolder(String folderPath, {bool recursive = false}) async {
    try {
      final fullPath = path.join(_basePath, folderPath);
      final directory = Directory(fullPath);
      
      if (!await directory.exists()) {
        return; // 文件夹不存在，视为删除成功
      }

      if (recursive) {
        await directory.delete(recursive: true);
      } else {
        // 检查是否为空文件夹
        final contents = await directory.list().toList();
        final nonMetadataContents = contents.where((entity) => 
            !path.basename(entity.path).startsWith('.')
        ).toList();
        
        if (nonMetadataContents.isNotEmpty) {
          throw StorageException('Folder is not empty: $folderPath');
        }
        
        await directory.delete(recursive: true);
      }
    } catch (e) {
      throw StorageException('Failed to delete folder: ${e.toString()}');
    }
  }

  @override
  Future<FolderNodeModel> renameFolder(String folderPath, String newName) async {
    try {
      final oldFullPath = path.join(_basePath, folderPath);
      final directory = Directory(oldFullPath);
      
      if (!await directory.exists()) {
        throw StorageException('Folder not found: $folderPath');
      }

      // 生成新路径
      final parentPath = path.dirname(folderPath);
      final newFolderPath = FolderNodeModel.generateFolderPath(
        parentPath == '.' ? '' : parentPath, 
        newName,
      );
      final newFullPath = path.join(_basePath, newFolderPath);

      // 检查新路径是否已存在
      if (await Directory(newFullPath).exists()) {
        throw StorageException('Target folder already exists: $newFolderPath');
      }

      // 重命名目录
      await directory.rename(newFullPath);

      // 创建新的文件夹模型
      final renamedFolder = FolderNodeModel(
        folderPath: newFolderPath,
        name: newName,
        created: DateTime.now(), // 这里应该保留原创建时间，但需要从元数据读取
        updated: DateTime.now(),
      );

      // 保存元数据
      await _saveFolderMetadata(renamedFolder);

      return renamedFolder;
    } catch (e) {
      throw StorageException('Failed to rename folder: ${e.toString()}');
    }
  }

  @override
  Future<FolderNodeModel> moveFolder(String folderPath, String newParentPath) async {
    try {
      final oldFullPath = path.join(_basePath, folderPath);
      final directory = Directory(oldFullPath);
      
      if (!await directory.exists()) {
        throw StorageException('Folder not found: $folderPath');
      }

      // 获取文件夹名称
      final folderName = FolderNodeModel.extractFolderName(folderPath);
      
      // 生成新路径
      final newFolderPath = FolderNodeModel.generateFolderPath(newParentPath, folderName);
      final newFullPath = path.join(_basePath, newFolderPath);

      // 检查新路径是否已存在
      if (await Directory(newFullPath).exists()) {
        throw StorageException('Target folder already exists: $newFolderPath');
      }

      // 确保目标父目录存在
      final newParentFullPath = path.join(_basePath, newParentPath);
      await Directory(newParentFullPath).create(recursive: true);

      // 移动目录
      await directory.rename(newFullPath);

      // 创建新的文件夹模型
      final movedFolder = FolderNodeModel(
        folderPath: newFolderPath,
        name: folderName,
        created: DateTime.now(), // 应该保留原创建时间
        updated: DateTime.now(),
      );

      // 保存元数据
      await _saveFolderMetadata(movedFolder);

      return movedFolder;
    } catch (e) {
      throw StorageException('Failed to move folder: ${e.toString()}');
    }
  }

  @override
  Future<FolderNodeModel> copyFolder(
    String folderPath,
    String newParentPath, {
    String? newName,
  }) async {
    try {
      final sourceFullPath = path.join(_basePath, folderPath);
      final sourceDirectory = Directory(sourceFullPath);
      
      if (!await sourceDirectory.exists()) {
        throw StorageException('Source folder not found: $folderPath');
      }

      // 获取文件夹名称
      final folderName = newName ?? FolderNodeModel.extractFolderName(folderPath);
      
      // 生成新路径
      final newFolderPath = FolderNodeModel.generateFolderPath(newParentPath, folderName);
      final newFullPath = path.join(_basePath, newFolderPath);

      // 检查新路径是否已存在
      if (await Directory(newFullPath).exists()) {
        throw StorageException('Target folder already exists: $newFolderPath');
      }

      // 确保目标父目录存在
      final newParentFullPath = path.join(_basePath, newParentPath);
      await Directory(newParentFullPath).create(recursive: true);

      // 递归复制目录
      await _copyDirectory(sourceDirectory, Directory(newFullPath));

      // 创建新的文件夹模型
      final copiedFolder = FolderNodeModel(
        folderPath: newFolderPath,
        name: folderName,
        created: DateTime.now(),
        updated: DateTime.now(),
      );

      // 保存元数据
      await _saveFolderMetadata(copiedFolder);

      return copiedFolder;
    } catch (e) {
      throw StorageException('Failed to copy folder: ${e.toString()}');
    }
  }

  @override
  Future<List<FolderNodeModel>> searchFolders({
    required String query,
    String? rootPath,
  }) async {
    try {
      final allFolders = await loadFolders(rootPath: rootPath);
      final lowerQuery = query.toLowerCase();

      // 递归搜索文件夹
      final results = <FolderNodeModel>[];
      
      void searchInFolders(List<FolderNodeModel> folders) {
        for (final folder in folders) {
          if (folder.name.toLowerCase().contains(lowerQuery) ||
              (folder.description?.toLowerCase().contains(lowerQuery) ?? false)) {
            results.add(folder);
          }
          
          // 递归搜索子文件夹
          if (folder.subFolders.isNotEmpty) {
            searchInFolders(folder.subFolders.cast<FolderNodeModel>());
          }
        }
      }

      searchInFolders(allFolders);
      return results;
    } catch (e) {
      throw StorageException('Failed to search folders: ${e.toString()}');
    }
  }

  @override
  Future<bool> folderExists(String folderPath) async {
    try {
      final fullPath = path.join(_basePath, folderPath);
      return await Directory(fullPath).exists();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<String>> getFolderPaths({String? rootPath}) async {
    try {
      final folders = await loadFolders(rootPath: rootPath);
      return FolderNodeModel.flattenFolderTree(folders);
    } catch (e) {
      throw StorageException('Failed to get folder paths: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, bool>> deleteFolders(
    List<String> folderPaths, {
    bool recursive = false,
  }) async {
    final results = <String, bool>{};
    
    for (final folderPath in folderPaths) {
      try {
        await deleteFolder(folderPath, recursive: recursive);
        results[folderPath] = true;
      } catch (e) {
        results[folderPath] = false;
      }
    }
    
    return results;
  }

  @override
  Future<Map<String, bool>> moveFolders(
    List<String> folderPaths,
    String newParentPath,
  ) async {
    final results = <String, bool>{};
    
    for (final folderPath in folderPaths) {
      try {
        await moveFolder(folderPath, newParentPath);
        results[folderPath] = true;
      } catch (e) {
        results[folderPath] = false;
      }
    }
    
    return results;
  }

  @override
  Future<Map<String, bool>> copyFolders(
    List<String> folderPaths,
    String newParentPath,
  ) async {
    final results = <String, bool>{};
    
    for (final folderPath in folderPaths) {
      try {
        await copyFolder(folderPath, newParentPath);
        results[folderPath] = true;
      } catch (e) {
        results[folderPath] = false;
      }
    }
    
    return results;
  }

  /// 递归扫描目录
  Future<void> _scanDirectories(
    Directory directory,
    List<String> folderPaths,
    Map<String, String> folderMetadata,
  ) async {
    try {
      final relativePath = PathUtils.toRelativePath(directory.path, _basePath);
      if (relativePath.isNotEmpty) {
        folderPaths.add(relativePath);
        
        // 尝试加载元数据
        final metadataPath = path.join(directory.path, AppConstants.metadataFileName);
        final metadataFile = File(metadataPath);
        if (await metadataFile.exists()) {
          try {
            folderMetadata[relativePath] = await metadataFile.readAsString();
          } catch (e) {
            // 忽略元数据读取错误
          }
        }
      }

      // 递归扫描子目录
      await for (final entity in directory.list()) {
        if (entity is Directory) {
          // 跳过隐藏目录和系统目录
          final dirName = path.basename(entity.path);
          if (!dirName.startsWith('.') && !dirName.startsWith('__')) {
            await _scanDirectories(entity, folderPaths, folderMetadata);
          }
        }
      }
    } catch (e) {
      // 忽略无法访问的目录
    }
  }

  /// 保存文件夹元数据
  Future<void> _saveFolderMetadata(FolderNodeModel folder) async {
    try {
      final fullPath = path.join(_basePath, folder.folderPath);
      final metadataPath = path.join(fullPath, AppConstants.metadataFileName);
      final metadataFile = File(metadataPath);
      
      final metadataJson = folder.toMetadataJson();
      await metadataFile.writeAsString(metadataJson);
    } catch (e) {
      // 元数据保存失败不应该影响主要操作
      // 可以记录日志但不抛出异常
    }
  }

  /// 递归复制目录
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    
    await for (final entity in source.list()) {
      final newPath = path.join(destination.path, path.basename(entity.path));
      
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }
}