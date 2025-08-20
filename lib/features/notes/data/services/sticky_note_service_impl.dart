import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:cherry_note/features/notes/domain/entities/note_file.dart';
import 'package:cherry_note/features/notes/domain/services/sticky_note_service.dart';
import 'package:cherry_note/shared/utils/path_utils.dart';

/// 便签服务实现
class StickyNoteServiceImpl implements StickyNoteService {
  final String _notesDirectory;
  static const String _stickyFolderName = '便签';

  StickyNoteServiceImpl({
    required String notesDirectory,
  }) : _notesDirectory = notesDirectory;

  @override
  String get stickyNotesFolderPath => _stickyFolderName;

  @override
  Future<NoteFile> createQuickStickyNote({
    String? content,
    List<String>? tags,
  }) async {
    final now = DateTime.now();
    final title = generateStickyNoteTitle(content);
    final fileName = generateStickyNoteFileName();
    final fullPath = path.join(_notesDirectory, _stickyFolderName, fileName);

    // 确保便签目录存在
    final directory = Directory(path.dirname(fullPath));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // 创建便签文件
    final stickyNote = NoteFile(
      filePath: PathUtils.toRelativePath(fullPath, _notesDirectory),
      title: title,
      content: content ?? '',
      tags: tags ?? [],
      created: now,
      updated: now,
      isSticky: true,
    );

    // 写入文件
    await _writeNoteFile(fullPath, stickyNote);

    return stickyNote;
  }

  @override
  Future<List<NoteFile>> getAllStickyNotes() async {
    final stickyNotes = <NoteFile>[];
    final stickyDir = Directory(path.join(_notesDirectory, _stickyFolderName));

    if (!await stickyDir.exists()) {
      return stickyNotes;
    }

    await for (final entity in stickyDir.list()) {
      if (entity is File && entity.path.endsWith('.md')) {
        try {
          final noteFile = await _readNoteFile(entity.path);
          if (noteFile.isSticky) {
            stickyNotes.add(noteFile);
          }
        } catch (e) {
          // 跳过无法读取的文件
          continue;
        }
      }
    }

    // 按创建时间倒序排序
    stickyNotes.sort((a, b) => b.created.compareTo(a.created));
    return stickyNotes;
  }

  @override
  Future<List<NoteFile>> getRecentStickyNotes({int limit = 10}) async {
    final allStickyNotes = await getAllStickyNotes();
    return allStickyNotes.take(limit).toList();
  }

  @override
  Future<List<NoteFile>> getStickyNotesByTags(List<String> tags) async {
    final allStickyNotes = await getAllStickyNotes();
    return allStickyNotes.where((note) {
      return tags.any((tag) => note.tags.contains(tag));
    }).toList();
  }

  @override
  Future<List<NoteFile>> searchStickyNotes(String query) async {
    final allStickyNotes = await getAllStickyNotes();
    final lowerQuery = query.toLowerCase();

    return allStickyNotes.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
             note.content.toLowerCase().contains(lowerQuery) ||
             note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  @override
  Future<void> deleteStickyNote(String filePath) async {
    final fullPath = path.join(_notesDirectory, filePath);
    final file = File(fullPath);

    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<NoteFile> updateStickyNote({
    required String filePath,
    String? title,
    String? content,
    List<String>? tags,
  }) async {
    final fullPath = path.join(_notesDirectory, filePath);
    final existingNote = await _readNoteFile(fullPath);

    final updatedNote = existingNote.copyWith(
      title: title ?? existingNote.title,
      content: content ?? existingNote.content,
      tags: tags ?? existingNote.tags,
      updated: DateTime.now(),
    );

    await _writeNoteFile(fullPath, updatedNote);
    return updatedNote;
  }

  @override
  String generateStickyNoteTitle(String? content) {
    // 如果有内容，使用内容的前几个字符作为标题
    if (content != null && content.trim().isNotEmpty) {
      final firstLine = content.trim().split('\n').first;
      if (firstLine.length <= 30) {
        return firstLine;
      } else {
        return '${firstLine.substring(0, 30)}...';
      }
    }
    
    // 否则使用日期时间作为标题
    final now = DateTime.now();
    return '便签 ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  String generateStickyNoteFileName() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}-${now.millisecond.toString().padLeft(3, '0')}-便签.md';
  }

  /// 读取笔记文件
  Future<NoteFile> _readNoteFile(String fullPath) async {
    final file = File(fullPath);
    final content = await file.readAsString();
    final relativePath = PathUtils.toRelativePath(fullPath, _notesDirectory);
    
    return NoteFile.fromMarkdown(
      filePath: relativePath,
      content: content,
    );
  }

  /// 写入笔记文件
  Future<void> _writeNoteFile(String fullPath, NoteFile noteFile) async {
    final file = File(fullPath);
    final markdownContent = noteFile.toMarkdown();
    await file.writeAsString(markdownContent);
  }
}