import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/features/notes/data/models/note_file_model.dart';
import 'package:cherry_note/features/notes/domain/entities/note_file.dart';

void main() {
  group('NoteFileModel', () {
    final testDate = DateTime(2024, 1, 15, 10, 30, 0);
    final updatedDate = DateTime(2024, 1, 15, 15, 45, 0);
    
    final testNoteFileModel = NoteFileModel(
      filePath: 'work/project-notes.md',
      title: 'Project Notes',
      content: '# Project Notes\n\nThis is a test note.',
      tags: ['work', 'project'],
      created: testDate,
      updated: updatedDate,
      isSticky: false,
    );

    test('should create NoteFileModel with all properties', () {
      expect(testNoteFileModel.filePath, 'work/project-notes.md');
      expect(testNoteFileModel.title, 'Project Notes');
      expect(testNoteFileModel.content, '# Project Notes\n\nThis is a test note.');
      expect(testNoteFileModel.tags, ['work', 'project']);
      expect(testNoteFileModel.created, testDate);
      expect(testNoteFileModel.updated, updatedDate);
      expect(testNoteFileModel.isSticky, false);
    });

    test('should get correct relative path', () {
      expect(testNoteFileModel.relativePath, 'work/project-notes.md');
    });

    test('should get correct folder path', () {
      expect(testNoteFileModel.folderPath, 'work');
    });

    test('should get correct file name', () {
      expect(testNoteFileModel.fileName, 'project-notes');
    });

    test('should convert to markdown with front matter', () {
      final markdown = testNoteFileModel.toMarkdown();
      
      expect(markdown, contains('---'));
      expect(markdown, contains('title: "Project Notes"'));
      expect(markdown, contains('tags: ["work", "project"]'));
      expect(markdown, contains('created: "2024-01-15T10:30:00.000"'));
      expect(markdown, contains('updated: "2024-01-15T15:45:00.000"'));
      expect(markdown, contains('# Project Notes'));
      expect(markdown, contains('This is a test note.'));
    });

    test('should parse markdown with front matter', () {
      const markdownContent = '''---
title: "Test Note"
tags: ["test", "example"]
created: "2024-01-15T10:30:00.000"
updated: "2024-01-15T15:45:00.000"
sticky: true
---

# Test Note

This is test content.''';

      final noteFile = NoteFileModel.fromMarkdown('test.md', markdownContent);
      
      expect(noteFile.title, 'Test Note');
      expect(noteFile.tags, ['test', 'example']);
      expect(noteFile.created, DateTime.parse('2024-01-15T10:30:00.000'));
      expect(noteFile.updated, DateTime.parse('2024-01-15T15:45:00.000'));
      expect(noteFile.isSticky, true);
      expect(noteFile.content, '# Test Note\n\nThis is test content.');
    });

    test('should parse markdown without front matter', () {
      const markdownContent = '''# Simple Note

This is a simple note without front matter.''';

      final noteFile = NoteFileModel.fromMarkdown('simple.md', markdownContent);
      
      expect(noteFile.title, 'Simple Note');
      expect(noteFile.tags, isEmpty);
      expect(noteFile.isSticky, false);
      expect(noteFile.content, markdownContent);
    });

    test('should extract title from content when not in front matter', () {
      const markdownContent = '''# Extracted Title

Content without front matter title.''';

      final noteFile = NoteFileModel.fromMarkdown('test.md', markdownContent);
      
      expect(noteFile.title, 'Extracted Title');
    });

    test('should convert to and from entity', () {
      final entity = testNoteFileModel.toEntity();
      final model = NoteFileModel.fromEntity(entity);
      
      expect(model.filePath, testNoteFileModel.filePath);
      expect(model.title, testNoteFileModel.title);
      expect(model.content, testNoteFileModel.content);
      expect(model.tags, testNoteFileModel.tags);
      expect(model.created, testNoteFileModel.created);
      expect(model.updated, testNoteFileModel.updated);
      expect(model.isSticky, testNoteFileModel.isSticky);
    });

    test('should generate correct file name for regular note', () {
      final fileName = NoteFileModel.generateFileName('My Test Note', testDate);
      expect(fileName, 'my-test-note.md');
    });

    test('should generate correct file name for sticky note', () {
      final fileName = NoteFileModel.generateFileName('Quick Idea', testDate, isSticky: true);
      expect(fileName, '2024-01-15-103000-quick-idea.md');
    });

    test('should validate note file', () {
      expect(testNoteFileModel.isValid(), true);
      
      final invalidNote = NoteFileModel(
        filePath: '',
        title: '',
        content: '',
        tags: [],
        created: testDate,
        updated: testDate,
      );
      expect(invalidNote.isValid(), false);
    });

    test('should handle copyWith correctly', () {
      final updatedNote = testNoteFileModel.copyWith(
        title: 'Updated Title',
        tags: ['updated'],
      );
      
      expect(updatedNote.title, 'Updated Title');
      expect(updatedNote.tags, ['updated']);
      expect(updatedNote.filePath, testNoteFileModel.filePath);
      expect(updatedNote.content, testNoteFileModel.content);
    });

    test('should handle empty and malformed front matter', () {
      const malformedContent = '''---
invalid-yaml: [unclosed array
title: "Test"
---

Content here.''';

      final noteFile = NoteFileModel.fromMarkdown('test.md', malformedContent);
      
      expect(noteFile.title, 'Test');
      expect(noteFile.content, 'Content here.');
    });

    test('should handle special characters in title', () {
      const contentWithSpecialChars = '''---
title: "Note with \"quotes\" and special chars!"
---

Content.''';

      final noteFile = NoteFileModel.fromMarkdown('test.md', contentWithSpecialChars);
      final markdown = noteFile.toMarkdown();
      
      expect(noteFile.title, 'Note with "quotes" and special chars!');
      expect(markdown, contains('title: "Note with \\"quotes\\" and special chars!"'));
    });
  });
}