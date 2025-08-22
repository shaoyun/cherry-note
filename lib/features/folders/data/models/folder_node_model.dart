import 'dart:convert';
import '../../domain/entities/folder_node.dart';
import '../../../notes/domain/entities/note_file.dart';
import '../../../notes/data/models/note_file_model.dart';
import '../../../../shared/utils/date_utils.dart';
import '../../../../shared/constants/app_constants.dart';

class FolderNodeModel extends FolderNode {
  const FolderNodeModel({
    required super.folderPath,
    required super.name,
    required super.created,
    required super.updated,
    super.description,
    super.color,
    super.subFolders = const [],
    super.notes = const [],
  });

  /// Create from folder metadata JSON string
  factory FolderNodeModel.fromMetadata(String folderPath, String? metadataJson) {
    Map<String, dynamic> metadata = {};
    
    if (metadataJson != null && metadataJson.isNotEmpty) {
      try {
        metadata = json.decode(metadataJson) as Map<String, dynamic>;
      } catch (e) {
        // If JSON parsing fails, use defaults
      }
    }
    
    // Extract folder name from path
    final pathParts = folderPath.split('/').where((part) => part.isNotEmpty).toList();
    final defaultName = pathParts.isNotEmpty ? pathParts.last : 'Root';
    
    return FolderNodeModel(
      folderPath: folderPath,
      name: metadata['name']?.toString() ?? defaultName,
      created: AppDateUtils.parseIsoString(metadata['created']?.toString()) ?? DateTime.now(),
      updated: AppDateUtils.parseIsoString(metadata['updated']?.toString()) ?? DateTime.now(),
      description: metadata['description']?.toString(),
      color: metadata['color']?.toString(),
    );
  }

  /// Convert to metadata JSON string
  String toMetadataJson() {
    final metadata = {
      'name': name,
      'created': AppDateUtils.toIsoString(created),
      'updated': AppDateUtils.toIsoString(updated),
      if (description != null) 'description': description,
      if (color != null) 'color': color,
    };
    
    return json.encode(metadata);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'folderPath': folderPath,
      'name': name,
      'created': AppDateUtils.toIsoString(created),
      'updated': AppDateUtils.toIsoString(updated),
      if (description != null) 'description': description,
      if (color != null) 'color': color,
      'subFolders': subFolders.map((folder) => 
          folder is FolderNodeModel ? folder.toJson() : {}
      ).toList(),
      'notes': notes.map((note) => note is NoteFile ? (note as NoteFile).toJson() : {}).toList(),
    };
  }

  /// Create from JSON
  factory FolderNodeModel.fromJson(Map<String, dynamic> json) {
    return FolderNodeModel(
      folderPath: json['folderPath'] as String,
      name: json['name'] as String,
      created: AppDateUtils.parseIsoString(json['created'] as String) ?? DateTime.now(),
      updated: AppDateUtils.parseIsoString(json['updated'] as String) ?? DateTime.now(),
      description: json['description'] as String?,
      color: json['color'] as String?,
      subFolders: (json['subFolders'] as List?)
          ?.map((subfolder) => FolderNodeModel.fromJson(subfolder as Map<String, dynamic>))
          .toList() ?? [],
      notes: (json['notes'] as List?)
          ?.map((note) => NoteFile.fromJson(note as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// Create from FolderNode entity
  factory FolderNodeModel.fromEntity(FolderNode entity) {
    return FolderNodeModel(
      folderPath: entity.folderPath,
      name: entity.name,
      created: entity.created,
      updated: entity.updated,
      description: entity.description,
      color: entity.color,
      subFolders: entity.subFolders.map((folder) => 
          folder is FolderNodeModel ? folder : FolderNodeModel.fromEntity(folder)
      ).toList(),
      notes: entity.notes.map((note) => 
          note is NoteFileModel ? note : NoteFileModel.fromEntity(note)
      ).toList(),
    );
  }

  /// Convert to FolderNode entity
  FolderNode toEntity() {
    return FolderNode(
      folderPath: folderPath,
      name: name,
      created: created,
      updated: updated,
      description: description,
      color: color,
      subFolders: subFolders.map((folder) => folder is FolderNodeModel 
          ? folder.toEntity() 
          : folder
      ).toList(),
      notes: notes.map((note) => note is NoteFileModel 
          ? note.toEntity() 
          : note
      ).toList(),
    );
  }

  /// Build folder tree from flat list of folder paths
  static List<FolderNodeModel> buildFolderTree(
    List<String> folderPaths,
    Map<String, String> folderMetadata,
  ) {
    final folderMap = <String, FolderNodeModel>{};
    
    // Sort paths to ensure parents are processed before children
    final sortedPaths = [...folderPaths]..sort();
    
    // Create all folder nodes
    for (final path in sortedPaths) {
      final metadata = folderMetadata[path];
      final folder = FolderNodeModel.fromMetadata(path, metadata);
      folderMap[path] = folder;
    }
    
    // Build tree structure by processing children after parents
    for (final path in sortedPaths.reversed) {
      final folder = folderMap[path]!;
      final parentPath = folder.parentPath;
      
      if (parentPath != null && folderMap.containsKey(parentPath)) {
        // Add this folder to its parent
        final parent = folderMap[parentPath]!;
        final updatedSubFolders = [...parent.subFolders, folder];
        final updatedParent = FolderNodeModel(
          folderPath: parent.folderPath,
          name: parent.name,
          created: parent.created,
          updated: parent.updated,
          description: parent.description,
          color: parent.color,
          subFolders: updatedSubFolders,
          notes: parent.notes,
        );
        folderMap[parentPath] = updatedParent;
      }
    }
    
    // Return only root folders (those without parents or whose parents are not in the map)
    return folderMap.values.where((folder) => 
        folder.parentPath == null || !folderMap.containsKey(folder.parentPath!)
    ).toList();
  }

  /// Flatten folder tree to list of paths
  static List<String> flattenFolderTree(List<FolderNode> folders) {
    final paths = <String>[];
    
    void addFolderPaths(FolderNode folder) {
      paths.add(folder.folderPath);
      for (final subfolder in folder.subFolders) {
        addFolderPaths(subfolder);
      }
    }
    
    for (final folder in folders) {
      addFolderPaths(folder);
    }
    
    return paths;
  }

  /// Get metadata file path for this folder
  String get metadataFilePath {
    if (folderPath.isEmpty || folderPath == '/') {
      return AppConstants.appMetadataFileName;
    }
    return '$folderPath/${AppConstants.metadataFileName}';
  }

  /// Validate folder structure
  bool isValid() {
    // Check basic properties
    if (folderPath.isEmpty || name.isEmpty) return false;
    
    // Check path format
    if (folderPath.contains('\\') || folderPath.contains('//')) return false;
    
    // Check for invalid characters in name
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(name)) return false;
    
    return true;
  }

  /// Create a new folder with updated properties
  @override
  FolderNodeModel copyWith({
    String? folderPath,
    String? name,
    DateTime? created,
    DateTime? updated,
    String? description,
    String? color,
    List<FolderNode>? subFolders,
    List<NoteFile>? notes,
  }) {
    return FolderNodeModel(
      folderPath: folderPath ?? this.folderPath,
      name: name ?? this.name,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      description: description ?? this.description,
      color: color ?? this.color,
      subFolders: subFolders ?? this.subFolders,
      notes: notes ?? this.notes,
    );
  }

  /// Generate folder path from parent and name
  static String generateFolderPath(String? parentPath, String folderName) {
    final sanitizedName = folderName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .trim();
    
    if (parentPath == null || parentPath.isEmpty || parentPath == '/') {
      return sanitizedName;
    }
    
    return '$parentPath/$sanitizedName';
  }

  /// Extract folder name from path
  static String extractFolderName(String folderPath) {
    if (folderPath.isEmpty || folderPath == '/') return 'Root';
    
    final parts = folderPath.split('/').where((part) => part.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.last : 'Root';
  }

  /// Check if folder path is valid
  static bool isValidPath(String path) {
    if (path.isEmpty) return false;
    if (path.contains('\\') || path.contains('//')) return false;
    if (path.startsWith('/') && path.length > 1) return false;
    
    final parts = path.split('/').where((part) => part.isNotEmpty);
    for (final part in parts) {
      if (part.contains(RegExp(r'[<>:"/\\|?*]'))) return false;
    }
    
    return true;
  }
}