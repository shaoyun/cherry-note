import 'package:equatable/equatable.dart';

class NoteFile extends Equatable {
  final String filePath;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime created;
  final DateTime updated;
  final bool isSticky;

  const NoteFile({
    required this.filePath,
    required this.title,
    required this.content,
    required this.tags,
    required this.created,
    required this.updated,
    this.isSticky = false,
  });

  /// Get relative path from absolute file path
  String get relativePath {
    // Remove base path and normalize separators
    return filePath.replaceAll('\\', '/');
  }

  /// Get folder path containing this note
  String get folderPath {
    final lastSlash = filePath.lastIndexOf('/');
    if (lastSlash == -1) return '';
    return filePath.substring(0, lastSlash);
  }

  /// Get file name without extension
  String get fileName {
    final lastSlash = filePath.lastIndexOf('/');
    final lastDot = filePath.lastIndexOf('.');
    final start = lastSlash == -1 ? 0 : lastSlash + 1;
    final end = lastDot == -1 ? filePath.length : lastDot;
    return filePath.substring(start, end);
  }

  /// Create a copy with updated fields
  NoteFile copyWith({
    String? filePath,
    String? title,
    String? content,
    List<String>? tags,
    DateTime? created,
    DateTime? updated,
    bool? isSticky,
  }) {
    return NoteFile(
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      isSticky: isSticky ?? this.isSticky,
    );
  }

  @override
  List<Object?> get props => [
        filePath,
        title,
        content,
        tags,
        created,
        updated,
        isSticky,
      ];

  /// Create NoteFile from Markdown content
  factory NoteFile.fromMarkdown({
    required String filePath,
    required String content,
  }) {
    // Simple front matter parsing
    final lines = content.split('\n');
    String title = '';
    List<String> tags = [];
    DateTime? created;
    DateTime? updated;
    bool isSticky = false;
    String noteContent = content;

    // Check for front matter
    if (lines.isNotEmpty && lines.first.trim() == '---') {
      int endIndex = -1;
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim() == '---') {
          endIndex = i;
          break;
        }
      }

      if (endIndex > 0) {
        // Parse front matter
        for (int i = 1; i < endIndex; i++) {
          final line = lines[i];
          if (line.startsWith('title:')) {
            title = line.substring(6).trim().replaceAll('"', '');
          } else if (line.startsWith('tags:')) {
            final tagString = line.substring(5).trim();
            if (tagString.startsWith('[') && tagString.endsWith(']')) {
              tags = tagString
                  .substring(1, tagString.length - 1)
                  .split(',')
                  .map((tag) => tag.trim().replaceAll('"', ''))
                  .where((tag) => tag.isNotEmpty)
                  .toList();
            }
          } else if (line.startsWith('created:')) {
            final dateString = line.substring(8).trim().replaceAll('"', '');
            created = DateTime.tryParse(dateString);
          } else if (line.startsWith('updated:')) {
            final dateString = line.substring(8).trim().replaceAll('"', '');
            updated = DateTime.tryParse(dateString);
          } else if (line.startsWith('sticky:')) {
            isSticky = line.substring(7).trim().toLowerCase() == 'true';
          }
        }

        // Extract content after front matter
        noteContent = lines.skip(endIndex + 1).join('\n').trim();
      }
    }

    // If no title in front matter, extract from first line or filename
    if (title.isEmpty) {
      if (noteContent.isNotEmpty) {
        final firstLine = noteContent.split('\n').first.trim();
        if (firstLine.startsWith('#')) {
          title = firstLine.replaceFirst('#', '').trim();
        } else {
          title = firstLine.length > 50 
              ? '${firstLine.substring(0, 50)}...' 
              : firstLine;
        }
      }
      
      if (title.isEmpty) {
        // Use filename as title
        final lastSlash = filePath.lastIndexOf('/');
        final lastDot = filePath.lastIndexOf('.');
        final start = lastSlash == -1 ? 0 : lastSlash + 1;
        final end = lastDot == -1 ? filePath.length : lastDot;
        title = filePath.substring(start, end);
      }
    }

    final now = DateTime.now();
    return NoteFile(
      filePath: filePath,
      title: title,
      content: noteContent,
      tags: tags,
      created: created ?? now,
      updated: updated ?? now,
      isSticky: isSticky,
    );
  }

  /// Convert NoteFile to Markdown content with front matter
  String toMarkdown() {
    final buffer = StringBuffer();
    
    // Write front matter
    buffer.writeln('---');
    buffer.writeln('title: "$title"');
    if (tags.isNotEmpty) {
      buffer.writeln('tags: [${tags.map((tag) => '"$tag"').join(', ')}]');
    }
    buffer.writeln('created: "${created.toIso8601String()}"');
    buffer.writeln('updated: "${updated.toIso8601String()}"');
    buffer.writeln('sticky: $isSticky');
    buffer.writeln('---');
    buffer.writeln();
    
    // Write content
    buffer.write(content);
    
    return buffer.toString();
  }

  @override
  String toString() {
    return 'NoteFile(filePath: $filePath, title: $title, tags: $tags, isSticky: $isSticky)';
  }
}