import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import 'package:cherry_note/features/notes/data/services/sticky_note_service_impl.dart';
import 'package:cherry_note/features/notes/domain/entities/note_file.dart';

void main() {
  group('StickyNoteServiceImpl', () {
    late StickyNoteServiceImpl stickyNoteService;
    late Directory tempDir;
    late String notesDirectory;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sticky_note_test_');
      notesDirectory = tempDir.path;
      stickyNoteService = StickyNoteServiceImpl(notesDirectory: notesDirectory);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('createQuickStickyNote', () {
      test('should create sticky note with content', () async {
        // Arrange
        const content = '这是一个测试便签';
        const tags = ['测试', '便签'];

        // Act
        final result = await stickyNoteService.createQuickStickyNote(
          content: content,
          tags: tags,
        );

        // Assert
        expect(result.content, equals(content));
        expect(result.tags, equals(tags));
        expect(result.isSticky, isTrue);
        expect(result.title, equals(content)); // Should use content as title
        expect(result.filePath, contains('便签'));

        // Verify file was created
        final fullPath = path.join(notesDirectory, result.filePath);
        final file = File(fullPath);
        expect(await file.exists(), isTrue);
      });

      test('should create sticky note without content', () async {
        // Act
        final result = await stickyNoteService.createQuickStickyNote();

        // Assert
        expect(result.content, isEmpty);
        expect(result.tags, isEmpty);
        expect(result.isSticky, isTrue);
        expect(result.title, contains('便签')); // Should use date-time title
        expect(result.filePath, contains('便签'));
      });

      test('should create sticky note with long content', () async {
        // Arrange
        const longContent = '这是一个非常长的便签内容，超过了30个字符的限制，应该被截断并添加省略号';

        // Act
        final result = await stickyNoteService.createQuickStickyNote(
          content: longContent,
        );

        // Assert
        expect(result.content, equals(longContent));
        expect(result.title.length, lessThanOrEqualTo(33)); // 30 + "..."
        expect(result.title, endsWith('...'));
      });
    });

    group('getAllStickyNotes', () {
      test('should return empty list when no sticky notes exist', () async {
        // Act
        final result = await stickyNoteService.getAllStickyNotes();

        // Assert
        expect(result, isEmpty);
      });

      test('should return all sticky notes sorted by creation date', () async {
        // Arrange
        await stickyNoteService.createQuickStickyNote(content: '第一个便签');
        await Future.delayed(const Duration(milliseconds: 100));
        await stickyNoteService.createQuickStickyNote(content: '第二个便签');
        await Future.delayed(const Duration(milliseconds: 100));
        await stickyNoteService.createQuickStickyNote(content: '第三个便签');

        // Act
        final result = await stickyNoteService.getAllStickyNotes();

        // Assert
        expect(result, hasLength(3));
        expect(result[0].content, equals('第三个便签')); // Most recent first
        expect(result[1].content, equals('第二个便签'));
        expect(result[2].content, equals('第一个便签'));
      });
    });

    group('getRecentStickyNotes', () {
      test('should return limited number of recent sticky notes', () async {
        // Arrange
        for (int i = 1; i <= 15; i++) {
          await stickyNoteService.createQuickStickyNote(content: '便签 $i');
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // Act
        final result = await stickyNoteService.getRecentStickyNotes(limit: 5);

        // Assert
        expect(result, hasLength(5));
        expect(result[0].content, equals('便签 15')); // Most recent first
        expect(result[4].content, equals('便签 11'));
      });
    });

    group('getStickyNotesByTags', () {
      test('should return sticky notes with matching tags', () async {
        // Arrange
        await stickyNoteService.createQuickStickyNote(
          content: '工作便签',
          tags: ['工作', '重要'],
        );
        await Future.delayed(const Duration(milliseconds: 50));
        await stickyNoteService.createQuickStickyNote(
          content: '学习便签',
          tags: ['学习', '笔记'],
        );
        await Future.delayed(const Duration(milliseconds: 50));
        await stickyNoteService.createQuickStickyNote(
          content: '个人便签',
          tags: ['个人', '重要'],
        );

        // Act
        final result = await stickyNoteService.getStickyNotesByTags(['重要']);

        // Assert
        expect(result, hasLength(2));
        expect(result.any((note) => note.content == '工作便签'), isTrue);
        expect(result.any((note) => note.content == '个人便签'), isTrue);
      });
    });

    group('searchStickyNotes', () {
      test('should search sticky notes by title and content', () async {
        // Arrange
        await stickyNoteService.createQuickStickyNote(
          content: '这是关于Flutter的学习笔记',
          tags: ['Flutter', '学习'],
        );
        await Future.delayed(const Duration(milliseconds: 50));
        await stickyNoteService.createQuickStickyNote(
          content: '今天要完成的工作任务',
          tags: ['工作', '任务'],
        );
        await Future.delayed(const Duration(milliseconds: 50));
        await stickyNoteService.createQuickStickyNote(
          content: '购物清单：买菜、买水果',
          tags: ['生活', '购物'],
        );

        // Act
        final result = await stickyNoteService.searchStickyNotes('学习');

        // Assert
        expect(result, hasLength(1));
        expect(result[0].content, contains('Flutter'));
      });

      test('should search sticky notes by tags', () async {
        // Arrange
        await stickyNoteService.createQuickStickyNote(
          content: '工作便签',
          tags: ['工作任务', '重要'],
        );
        await Future.delayed(const Duration(milliseconds: 50));
        await stickyNoteService.createQuickStickyNote(
          content: '学习便签',
          tags: ['学习计划', '笔记'],
        );

        // Act
        final result = await stickyNoteService.searchStickyNotes('任务');

        // Assert
        expect(result, hasLength(1));
        expect(result[0].content, equals('工作便签'));
      });
    });

    group('updateStickyNote', () {
      test('should update sticky note successfully', () async {
        // Arrange
        final originalNote = await stickyNoteService.createQuickStickyNote(
          content: '原始内容',
          tags: ['原始标签'],
        );

        // Act
        final updatedNote = await stickyNoteService.updateStickyNote(
          filePath: originalNote.filePath,
          title: '新标题',
          content: '新内容',
          tags: ['新标签'],
        );

        // Assert
        expect(updatedNote.title, equals('新标题'));
        expect(updatedNote.content, equals('新内容'));
        expect(updatedNote.tags, equals(['新标签']));
        expect(updatedNote.updated.isAfter(originalNote.updated), isTrue);
      });
    });

    group('deleteStickyNote', () {
      test('should delete sticky note file', () async {
        // Arrange
        final stickyNote = await stickyNoteService.createQuickStickyNote(
          content: '要删除的便签',
        );
        final fullPath = path.join(notesDirectory, stickyNote.filePath);
        expect(await File(fullPath).exists(), isTrue);

        // Act
        await stickyNoteService.deleteStickyNote(stickyNote.filePath);

        // Assert
        expect(await File(fullPath).exists(), isFalse);
      });
    });

    group('generateStickyNoteTitle', () {
      test('should use content as title when content is short', () {
        // Act
        final title = stickyNoteService.generateStickyNoteTitle('短内容');

        // Assert
        expect(title, equals('短内容'));
      });

      test('should truncate long content for title', () {
        // Arrange
        const longContent = '这是一个非常长的内容，超过了30个字符的限制，应该被截断并添加省略号';

        // Act
        final title = stickyNoteService.generateStickyNoteTitle(longContent);

        // Assert
        expect(title.length, equals(33)); // 30 + "..."
        expect(title, endsWith('...'));
        expect(title, startsWith('这是一个非常长的内容'));
      });

      test('should use first line as title for multi-line content', () {
        // Arrange
        const multiLineContent = '第一行内容\n第二行内容\n第三行内容';

        // Act
        final title = stickyNoteService.generateStickyNoteTitle(multiLineContent);

        // Assert
        expect(title, equals('第一行内容'));
      });

      test('should generate date-time title when content is empty', () {
        // Act
        final title = stickyNoteService.generateStickyNoteTitle(null);

        // Assert
        expect(title, contains('便签'));
        expect(title, matches(RegExp(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}')));
      });
    });

    group('generateStickyNoteFileName', () {
      test('should generate filename with current date and time', () {
        // Act
        final fileName = stickyNoteService.generateStickyNoteFileName();

        // Assert
        expect(fileName, endsWith('-便签.md'));
        expect(fileName, matches(RegExp(r'\d{4}-\d{2}-\d{2}-\d{6}-\d{3}-便签\.md')));
      });
    });

    test('stickyNotesFolderPath should return correct folder name', () {
      // Act & Assert
      expect(stickyNoteService.stickyNotesFolderPath, equals('便签'));
    });
  });
}