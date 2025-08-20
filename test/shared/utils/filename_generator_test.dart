import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/shared/utils/filename_generator.dart';

void main() {
  group('FilenameGenerator', () {
    final testDate = DateTime(2024, 1, 15, 10, 30, 0);

    test('should generate filename from title', () {
      expect(FilenameGenerator.fromTitle('My Test Note'), 'my-test-note.md');
      expect(FilenameGenerator.fromTitle('Note with Special!@# Characters'), 'note-with-special-characters.md');
      expect(FilenameGenerator.fromTitle(''), 'untitled.md');
      expect(FilenameGenerator.fromTitle('   '), 'untitled.md');
    });

    test('should generate filename with timestamp', () {
      final filename = FilenameGenerator.withTimestamp('Test Note', testDate);
      expect(filename, '2024-01-15-103000-test-note.md');
      
      final filenameEmpty = FilenameGenerator.withTimestamp('', testDate);
      expect(filenameEmpty, '2024-01-15-103000.md');
    });

    test('should generate sticky note filename', () {
      final filename = FilenameGenerator.forStickyNote('Quick Idea', testDate);
      expect(filename, '2024-01-15-103000-quick-idea.md');
    });

    test('should generate regular note filename', () {
      expect(FilenameGenerator.forRegularNote('My Note'), 'my-note.md');
    });

    test('should make filename unique', () {
      final existing = ['note.md', 'note_1.md', 'note_2.md'];
      expect(FilenameGenerator.makeUnique('note.md', existing), 'note_3.md');
      expect(FilenameGenerator.makeUnique('newfile.md', existing), 'newfile.md');
      
      final existingNoExt = ['note', 'note_1'];
      expect(FilenameGenerator.makeUnique('note', existingNoExt), 'note_2');
    });

    test('should generate filename from content', () {
      const content = '''# My Title

This is the content of the note.''';
      expect(FilenameGenerator.fromContent(content), 'my-title.md');
      
      const contentNoTitle = '''This is content without a title.''';
      expect(FilenameGenerator.fromContent(contentNoTitle), 'this-is-content-without-a-title.md');
    });

    test('should generate filename for imported file', () {
      final filename = FilenameGenerator.forImportedFile('original.txt', testDate);
      expect(filename, 'imported-2024-01-15-103000-original.txt');
      
      final filenameNoExt = FilenameGenerator.forImportedFile('original', testDate);
      expect(filenameNoExt, 'imported-2024-01-15-103000-original.md');
    });

    test('should generate backup filename', () {
      final filename = FilenameGenerator.forBackup('document.md', testDate);
      expect(filename, 'document_backup_2024-01-15-103000.md');
    });

    test('should generate template filename', () {
      expect(FilenameGenerator.forTemplate('Meeting Notes'), 'template_meeting-notes.md');
    });

    test('should generate daily note filename', () {
      expect(FilenameGenerator.forDailyNote(testDate), 'daily_2024-01-15.md');
    });

    test('should generate weekly note filename', () {
      expect(FilenameGenerator.forWeeklyNote(testDate), 'weekly_2024_week_3.md');
    });

    test('should generate monthly note filename', () {
      expect(FilenameGenerator.forMonthlyNote(testDate), 'monthly_2024_01.md');
    });

    test('should validate filenames', () {
      expect(FilenameGenerator.isValidFilename('valid-file.md'), true);
      expect(FilenameGenerator.isValidFilename('invalid<file>.md'), false);
      expect(FilenameGenerator.isValidFilename('CON.md'), false);
      expect(FilenameGenerator.isValidFilename(''), false);
      expect(FilenameGenerator.isValidFilename('a' * 300), false); // Too long
    });

    test('should suggest valid filenames', () {
      expect(FilenameGenerator.suggestValidFilename('valid-file.md'), 'valid-file.md');
      expect(FilenameGenerator.suggestValidFilename('invalid<file>.md'), 'invalid_file_.md');
      expect(FilenameGenerator.suggestValidFilename('CON.md'), 'CON_file.md');
      expect(FilenameGenerator.suggestValidFilename(''), 'untitled.md');
      
      final longName = 'a' * 300 + '.md';
      final suggested = FilenameGenerator.suggestValidFilename(longName);
      expect(suggested.length, lessThanOrEqualTo(255));
      expect(suggested.endsWith('.md'), true);
    });

    test('should handle edge cases in title sanitization', () {
      expect(FilenameGenerator.fromTitle('!!!'), 'untitled.md');
      expect(FilenameGenerator.fromTitle('---'), 'untitled.md');
      expect(FilenameGenerator.fromTitle('Multiple   Spaces'), 'multiple-spaces.md');
      expect(FilenameGenerator.fromTitle('Trailing-'), 'trailing.md');
      expect(FilenameGenerator.fromTitle('-Leading'), 'leading.md');
    });

    test('should limit filename length', () {
      final longTitle = 'This is a very long title that should be truncated to fit within reasonable filename limits';
      final filename = FilenameGenerator.fromTitle(longTitle);
      expect(filename.length, lessThanOrEqualTo(53)); // 50 chars + .md
      expect(filename.endsWith('.md'), true);
    });

    test('should handle different extensions', () {
      expect(FilenameGenerator.fromTitle('Test', extension: '.txt'), 'test.txt');
      expect(FilenameGenerator.withTimestamp('Test', testDate, extension: '.json'), '2024-01-15-103000-test.json');
    });
  });
}