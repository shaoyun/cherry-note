import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/note_file.dart';
import '../../../../shared/utils/date_utils.dart';
import '../../../../shared/utils/string_utils.dart';
import '../../../../shared/constants/app_constants.dart';

part 'note_file_model.g.dart';

@JsonSerializable()
class NoteFileModel extends NoteFile {
  const NoteFileModel({
    required super.filePath,
    required super.title,
    required super.content,
    required super.tags,
    required super.created,
    required super.updated,
    super.isSticky = false,
  });

  /// Create NoteFileModel from JSON
  factory NoteFileModel.fromJson(Map<String, dynamic> json) =>
      _$NoteFileModelFromJson(json);

  /// Convert NoteFileModel to JSON
  Map<String, dynamic> toJson() => _$NoteFileModelToJson(this);

  /// Create NoteFileModel from Markdown content with Front Matter
  factory NoteFileModel.fromMarkdown(String filePath, String markdownContent) {
    final frontMatter = _extractFrontMatter(markdownContent);
    final content = _extractContent(markdownContent);
    
    // Extract title from front matter or content
    String title = frontMatter['title']?.toString() ?? 
                   StringUtils.extractTitleFromMarkdown(content);
    
    // Parse tags
    List<String> tags = [];
    if (frontMatter['tags'] != null) {
      if (frontMatter['tags'] is List) {
        tags = (frontMatter['tags'] as List).map((e) => e.toString()).toList();
      } else if (frontMatter['tags'] is String) {
        tags = [frontMatter['tags'].toString()];
      }
    }
    
    // Parse dates
    DateTime created = AppDateUtils.parseIsoString(frontMatter['created']?.toString()) ?? 
                      DateTime.now();
    DateTime updated = AppDateUtils.parseIsoString(frontMatter['updated']?.toString()) ?? 
                      created;
    
    // Parse sticky flag
    bool isSticky = frontMatter['sticky'] == true || 
                   frontMatter['sticky'] == 'true';
    
    return NoteFileModel(
      filePath: filePath,
      title: title,
      content: content,
      tags: tags,
      created: created,
      updated: updated,
      isSticky: isSticky,
    );
  }

  /// Convert to Markdown format with Front Matter
  String toMarkdown() {
    final buffer = StringBuffer();
    
    // Write Front Matter
    buffer.writeln('---');
    buffer.writeln('title: "${title.replaceAll('"', '\\"')}"');
    
    if (tags.isNotEmpty) {
      buffer.writeln('tags: [${tags.map((tag) => '"$tag"').join(', ')}]');
    }
    
    buffer.writeln('created: "${AppDateUtils.toIsoString(created)}"');
    buffer.writeln('updated: "${AppDateUtils.toIsoString(updated)}"');
    
    if (isSticky) {
      buffer.writeln('sticky: true');
    }
    
    buffer.writeln('---');
    buffer.writeln();
    
    // Write content
    buffer.write(content);
    
    return buffer.toString();
  }

  /// Create from NoteFile entity
  factory NoteFileModel.fromEntity(NoteFile entity) {
    return NoteFileModel(
      filePath: entity.filePath,
      title: entity.title,
      content: entity.content,
      tags: entity.tags,
      created: entity.created,
      updated: entity.updated,
      isSticky: entity.isSticky,
    );
  }

  /// Convert to NoteFile entity
  NoteFile toEntity() {
    return NoteFile(
      filePath: filePath,
      title: title,
      content: content,
      tags: tags,
      created: created,
      updated: updated,
      isSticky: isSticky,
    );
  }

  /// Extract Front Matter from markdown content
  static Map<String, dynamic> _extractFrontMatter(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') {
      return {};
    }

    final frontMatterLines = <String>[];
    int endIndex = -1;
    
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        endIndex = i;
        break;
      }
      frontMatterLines.add(lines[i]);
    }

    if (endIndex == -1) {
      return {};
    }

    final frontMatter = <String, dynamic>{};
    for (final line in frontMatterLines) {
      final colonIndex = line.indexOf(':');
      if (colonIndex == -1) continue;
      
      final key = line.substring(0, colonIndex).trim();
      final value = line.substring(colonIndex + 1).trim();
      
      // Parse different value types
      if (value.startsWith('[') && value.endsWith(']')) {
        // Parse array
        final arrayContent = value.substring(1, value.length - 1);
        final items = arrayContent.split(',')
            .map((item) => item.trim().replaceAll('"', ''))
            .where((item) => item.isNotEmpty)
            .toList();
        frontMatter[key] = items;
      } else if (value.startsWith('"') && value.endsWith('"')) {
        // Parse string
        frontMatter[key] = value.substring(1, value.length - 1);
      } else if (value.toLowerCase() == 'true') {
        frontMatter[key] = true;
      } else if (value.toLowerCase() == 'false') {
        frontMatter[key] = false;
      } else {
        // Default to string
        frontMatter[key] = value;
      }
    }

    return frontMatter;
  }

  /// Extract content (without Front Matter) from markdown
  static String _extractContent(String content) {
    final lines = content.split('\n');
    if (lines.isEmpty || lines.first.trim() != '---') {
      return content;
    }

    int endIndex = -1;
    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim() == '---') {
        endIndex = i;
        break;
      }
    }

    if (endIndex == -1) {
      return content;
    }

    // Return content after front matter, skipping empty line
    final contentLines = lines.sublist(endIndex + 1);
    if (contentLines.isNotEmpty && contentLines.first.trim().isEmpty) {
      contentLines.removeAt(0);
    }
    
    return contentLines.join('\n');
  }

  /// Generate file name from title and date
  static String generateFileName(String title, DateTime date, {bool isSticky = false}) {
    final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s-]'), '')
                               .replaceAll(RegExp(r'\s+'), '-')
                               .toLowerCase();
    
    if (isSticky) {
      final dateStr = AppDateUtils.formatForFileName(date);
      return '$dateStr-$sanitizedTitle${AppConstants.markdownExtension}';
    }
    
    return '$sanitizedTitle${AppConstants.markdownExtension}';
  }

  /// Validate note file content
  bool isValid() {
    return filePath.isNotEmpty &&
           title.isNotEmpty &&
           filePath.endsWith(AppConstants.markdownExtension);
  }
}