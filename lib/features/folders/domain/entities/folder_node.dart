import 'package:equatable/equatable.dart';
import '../../../notes/domain/entities/note_file.dart';

class FolderNode extends Equatable {
  final String folderPath;
  final String name;
  final DateTime created;
  final DateTime updated;
  final String? description;
  final String? color;
  final List<FolderNode> subFolders;
  final List<NoteFile> notes;

  const FolderNode({
    required this.folderPath,
    required this.name,
    required this.created,
    required this.updated,
    this.description,
    this.color,
    this.subFolders = const [],
    this.notes = const [],
  });

  /// Get parent folder path
  String? get parentPath {
    final lastSlash = folderPath.lastIndexOf('/');
    if (lastSlash <= 0) return null;
    return folderPath.substring(0, lastSlash);
  }

  /// Get folder depth level (root = 0)
  int get depth {
    if (folderPath.isEmpty || folderPath == '/') return 0;
    return folderPath.split('/').where((part) => part.isNotEmpty).length;
  }

  /// Check if this folder is a root folder
  bool get isRoot => parentPath == null;

  /// Get total number of notes (including in subfolders)
  int get totalNotesCount {
    int count = notes.length;
    for (final subfolder in subFolders) {
      count += subfolder.totalNotesCount;
    }
    return count;
  }

  /// Get all notes including from subfolders
  List<NoteFile> get allNotes {
    final allNotesList = <NoteFile>[...notes];
    for (final subfolder in subFolders) {
      allNotesList.addAll(subfolder.allNotes);
    }
    return allNotesList;
  }

  /// Find subfolder by path
  FolderNode? findSubfolder(String path) {
    if (folderPath == path) return this;
    
    for (final subfolder in subFolders) {
      final found = subfolder.findSubfolder(path);
      if (found != null) return found;
    }
    
    return null;
  }

  /// Find note by file path
  NoteFile? findNote(String filePath) {
    // Check direct notes
    for (final note in notes) {
      if (note.filePath == filePath) return note;
    }
    
    // Check in subfolders
    for (final subfolder in subFolders) {
      final found = subfolder.findNote(filePath);
      if (found != null) return found;
    }
    
    return null;
  }

  /// Add a subfolder
  FolderNode addSubfolder(FolderNode subfolder) {
    final updatedSubfolders = [...subFolders, subfolder];
    return copyWith(
      subFolders: updatedSubfolders,
      updated: DateTime.now(),
    );
  }

  /// Remove a subfolder
  FolderNode removeSubfolder(String subfolderPath) {
    final updatedSubfolders = subFolders
        .where((folder) => folder.folderPath != subfolderPath)
        .toList();
    return copyWith(
      subFolders: updatedSubfolders,
      updated: DateTime.now(),
    );
  }

  /// Add a note
  FolderNode addNote(NoteFile note) {
    final updatedNotes = [...notes, note];
    return copyWith(
      notes: updatedNotes,
      updated: DateTime.now(),
    );
  }

  /// Remove a note
  FolderNode removeNote(String filePath) {
    final updatedNotes = notes
        .where((note) => note.filePath != filePath)
        .toList();
    return copyWith(
      notes: updatedNotes,
      updated: DateTime.now(),
    );
  }

  /// Update a note
  FolderNode updateNote(NoteFile updatedNote) {
    final updatedNotes = notes.map((note) {
      return note.filePath == updatedNote.filePath ? updatedNote : note;
    }).toList();
    
    return copyWith(
      notes: updatedNotes,
      updated: DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  FolderNode copyWith({
    String? folderPath,
    String? name,
    DateTime? created,
    DateTime? updated,
    String? description,
    String? color,
    List<FolderNode>? subFolders,
    List<NoteFile>? notes,
  }) {
    return FolderNode(
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

  /// Get folder statistics
  FolderStats get stats {
    return FolderStats(
      totalFolders: _countSubfolders(),
      totalNotes: totalNotesCount,
      directNotes: notes.length,
      directSubfolders: subFolders.length,
      lastModified: _getLastModified(),
    );
  }

  int _countSubfolders() {
    int count = subFolders.length;
    for (final subfolder in subFolders) {
      count += subfolder._countSubfolders();
    }
    return count;
  }

  DateTime _getLastModified() {
    DateTime lastModified = updated;
    
    // Check notes
    for (final note in notes) {
      if (note.updated.isAfter(lastModified)) {
        lastModified = note.updated;
      }
    }
    
    // Check subfolders
    for (final subfolder in subFolders) {
      final subfolderLastModified = subfolder._getLastModified();
      if (subfolderLastModified.isAfter(lastModified)) {
        lastModified = subfolderLastModified;
      }
    }
    
    return lastModified;
  }

  @override
  List<Object?> get props => [
        folderPath,
        name,
        created,
        updated,
        description,
        color,
        subFolders,
        notes,
      ];

  @override
  String toString() {
    return 'FolderNode(path: $folderPath, name: $name, subFolders: ${subFolders.length}, notes: ${notes.length})';
  }
}

class FolderStats extends Equatable {
  final int totalFolders;
  final int totalNotes;
  final int directNotes;
  final int directSubfolders;
  final DateTime lastModified;

  const FolderStats({
    required this.totalFolders,
    required this.totalNotes,
    required this.directNotes,
    required this.directSubfolders,
    required this.lastModified,
  });

  @override
  List<Object?> get props => [
        totalFolders,
        totalNotes,
        directNotes,
        directSubfolders,
        lastModified,
      ];

  @override
  String toString() {
    return 'FolderStats(folders: $totalFolders, notes: $totalNotes, lastModified: $lastModified)';
  }
}