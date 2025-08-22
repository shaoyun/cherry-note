import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/folder_node_model.dart';
import 'folder_data_source.dart';
import '../../../../core/error/exceptions.dart';

/// Web-compatible folder data source implementation using SharedPreferences
class WebFolderDataSource implements FolderDataSource {
  static const String _foldersKey = 'cherry_note_folders';
  static const String _folderMetadataPrefix = 'cherry_note_folder_meta_';

  @override
  Future<List<FolderNodeModel>> loadFolders({String? rootPath}) async {
    try {
      if (!kIsWeb) {
        throw UnsupportedError('WebFolderDataSource is only for web platform');
      }

      final prefs = await SharedPreferences.getInstance();
      final foldersJson = prefs.getString(_foldersKey);
      
      if (foldersJson == null) {
        // Create default folders if none exist
        await _createDefaultFolders();
        return await loadFolders(rootPath: rootPath);
      }

      final List<dynamic> foldersList = json.decode(foldersJson);
      final List<FolderNodeModel> folders = foldersList
          .map((json) => FolderNodeModel.fromJson(json))
          .toList();

      // Filter by root path if specified
      if (rootPath != null && rootPath.isNotEmpty) {
        return folders.where((folder) => 
            folder.folderPath.startsWith(rootPath)).toList();
      }

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
      final folderPath = _generateFolderPath(parentPath, folderName);
      
      // Check if folder already exists
      if (await folderExists(folderPath)) {
        throw StorageException('Folder already exists: $folderPath');
      }

      final now = DateTime.now();
      final folder = FolderNodeModel(
        folderPath: folderPath,
        name: folderName,
        created: now,
        updated: now,
        description: metadata?['description']?.toString(),
        color: metadata?['color']?.toString(),
      );

      // Add to folders list
      final folders = await loadFolders();
      folders.add(folder);
      await _saveFolders(folders);

      return folder;
    } catch (e) {
      throw StorageException('Failed to create folder: ${e.toString()}');
    }
  }

  @override
  Future<FolderNodeModel?> getFolder(String folderPath) async {
    try {
      final folders = await loadFolders();
      try {
        return folders.firstWhere((folder) => folder.folderPath == folderPath);
      } catch (e) {
        return null;
      }
    } catch (e) {
      throw StorageException('Failed to get folder: ${e.toString()}');
    }
  }

  @override
  Future<FolderNodeModel> updateFolder(FolderNodeModel folder) async {
    try {
      final folders = await loadFolders();
      final index = folders.indexWhere((f) => f.folderPath == folder.folderPath);
      
      if (index == -1) {
        throw StorageException('Folder not found: ${folder.folderPath}');
      }

      final updatedFolder = folder.copyWith(updated: DateTime.now());
      folders[index] = updatedFolder;
      await _saveFolders(folders);

      return updatedFolder;
    } catch (e) {
      throw StorageException('Failed to update folder: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteFolder(String folderPath, {bool recursive = false}) async {
    try {
      final folders = await loadFolders();
      
      if (!recursive) {
        // Check if folder has subfolders
        final hasSubfolders = folders.any((folder) =>
            folder.folderPath.startsWith('$folderPath/') && 
            folder.folderPath != folderPath);
        
        if (hasSubfolders) {
          throw StorageException('Folder is not empty: $folderPath');
        }
      }

      // Remove folder and all subfolders if recursive
      folders.removeWhere((folder) {
        if (recursive) {
          return folder.folderPath == folderPath || 
                 folder.folderPath.startsWith('$folderPath/');
        } else {
          return folder.folderPath == folderPath;
        }
      });
      
      await _saveFolders(folders);
    } catch (e) {
      throw StorageException('Failed to delete folder: ${e.toString()}');
    }
  }

  @override
  Future<FolderNodeModel> renameFolder(String folderPath, String newName) async {
    try {
      final folder = await getFolder(folderPath);
      if (folder == null) {
        throw StorageException('Folder not found: $folderPath');
      }

      final parentPath = _getParentPath(folderPath);
      final newFolderPath = _generateFolderPath(parentPath, newName);

      // Check if new path already exists
      if (await folderExists(newFolderPath)) {
        throw StorageException('Target folder already exists: $newFolderPath');
      }

      final folders = await loadFolders();
      
      // Update the folder and all its subfolders
      for (int i = 0; i < folders.length; i++) {
        if (folders[i].folderPath == folderPath) {
          folders[i] = folders[i].copyWith(
            folderPath: newFolderPath,
            name: newName,
            updated: DateTime.now(),
          );
        } else if (folders[i].folderPath.startsWith('$folderPath/')) {
          final relativePath = folders[i].folderPath.substring(folderPath.length + 1);
          folders[i] = folders[i].copyWith(
            folderPath: '$newFolderPath/$relativePath',
            updated: DateTime.now(),
          );
        }
      }

      await _saveFolders(folders);
      
      return folders.firstWhere((f) => f.folderPath == newFolderPath);
    } catch (e) {
      throw StorageException('Failed to rename folder: ${e.toString()}');
    }
  }

  @override
  Future<FolderNodeModel> moveFolder(String folderPath, String newParentPath) async {
    try {
      final folder = await getFolder(folderPath);
      if (folder == null) {
        throw StorageException('Folder not found: $folderPath');
      }

      final newFolderPath = _generateFolderPath(newParentPath, folder.name);
      
      // Check if new path already exists
      if (await folderExists(newFolderPath)) {
        throw StorageException('Target folder already exists: $newFolderPath');
      }

      final folders = await loadFolders();
      
      // Update the folder and all its subfolders
      for (int i = 0; i < folders.length; i++) {
        if (folders[i].folderPath == folderPath) {
          folders[i] = folders[i].copyWith(
            folderPath: newFolderPath,
            updated: DateTime.now(),
          );
        } else if (folders[i].folderPath.startsWith('$folderPath/')) {
          final relativePath = folders[i].folderPath.substring(folderPath.length + 1);
          folders[i] = folders[i].copyWith(
            folderPath: '$newFolderPath/$relativePath',
            updated: DateTime.now(),
          );
        }
      }

      await _saveFolders(folders);
      
      return folders.firstWhere((f) => f.folderPath == newFolderPath);
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
      final sourceFolder = await getFolder(folderPath);
      if (sourceFolder == null) {
        throw StorageException('Source folder not found: $folderPath');
      }

      final folderName = newName ?? sourceFolder.name;
      final newFolderPath = _generateFolderPath(newParentPath, folderName);
      
      // Check if new path already exists
      if (await folderExists(newFolderPath)) {
        throw StorageException('Target folder already exists: $newFolderPath');
      }

      final folders = await loadFolders();
      final foldersToAdd = <FolderNodeModel>[];
      
      // Copy the folder and all its subfolders
      for (final folder in folders) {
        if (folder.folderPath == folderPath) {
          foldersToAdd.add(folder.copyWith(
            folderPath: newFolderPath,
            name: folderName,
            created: DateTime.now(),
            updated: DateTime.now(),
          ));
        } else if (folder.folderPath.startsWith('$folderPath/')) {
          final relativePath = folder.folderPath.substring(folderPath.length + 1);
          foldersToAdd.add(folder.copyWith(
            folderPath: '$newFolderPath/$relativePath',
            created: DateTime.now(),
            updated: DateTime.now(),
          ));
        }
      }

      folders.addAll(foldersToAdd);
      await _saveFolders(folders);
      
      return foldersToAdd.first;
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
      final folders = await loadFolders(rootPath: rootPath);
      final lowerQuery = query.toLowerCase();

      return folders.where((folder) {
        return folder.name.toLowerCase().contains(lowerQuery) ||
               (folder.description?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    } catch (e) {
      throw StorageException('Failed to search folders: ${e.toString()}');
    }
  }

  @override
  Future<bool> folderExists(String folderPath) async {
    try {
      final folder = await getFolder(folderPath);
      return folder != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<String>> getFolderPaths({String? rootPath}) async {
    try {
      final folders = await loadFolders(rootPath: rootPath);
      return folders.map((folder) => folder.folderPath).toList();
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

  /// Create default folders on first run
  Future<void> _createDefaultFolders() async {
    final defaultFolders = [
      FolderNodeModel(
        folderPath: 'Notes',
        name: 'Notes',
        created: DateTime.now(),
        updated: DateTime.now(),
        description: 'Default notes folder',
      ),
      FolderNodeModel(
        folderPath: 'Drafts',
        name: 'Drafts',
        created: DateTime.now(),
        updated: DateTime.now(),
        description: 'Draft notes',
      ),
    ];

    await _saveFolders(defaultFolders);
  }

  /// Save folders to storage
  Future<void> _saveFolders(List<FolderNodeModel> folders) async {
    final prefs = await SharedPreferences.getInstance();
    final foldersJson = json.encode(folders.map((f) => f.toJson()).toList());
    await prefs.setString(_foldersKey, foldersJson);
  }

  /// Generate folder path
  String _generateFolderPath(String parentPath, String folderName) {
    if (parentPath.isEmpty) {
      return folderName;
    }
    return '$parentPath/$folderName';
  }

  /// Get parent path from folder path
  String _getParentPath(String folderPath) {
    final lastSlash = folderPath.lastIndexOf('/');
    if (lastSlash == -1) {
      return '';
    }
    return folderPath.substring(0, lastSlash);
  }
}