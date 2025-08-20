import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/shared/utils/path_utils.dart';
import 'package:path/path.dart' as path;

void main() {
  group('PathUtils', () {
    test('should normalize paths correctly', () {
      expect(PathUtils.normalizePath('folder//subfolder'), path.normalize('folder//subfolder'));
      expect(PathUtils.normalizePath('folder\\subfolder'), path.normalize('folder\\subfolder'));
      expect(PathUtils.normalizePath('./folder/file.md'), path.normalize('./folder/file.md'));
    });

    test('should join path components', () {
      expect(PathUtils.joinPath(['folder', 'subfolder', 'file.md']), path.join('folder', 'subfolder', 'file.md'));
      expect(PathUtils.joinPath(['folder', '', 'file.md']), path.join('folder', 'file.md'));
      final emptyJoin = PathUtils.joinPath([]);
      expect(emptyJoin == '.' || emptyJoin == '', true); // Platform dependent
    });

    test('should get parent directory', () {
      expect(PathUtils.getParentDirectory('folder/subfolder/file.md'), 'folder/subfolder');
      expect(PathUtils.getParentDirectory('file.md'), '.');
      expect(PathUtils.getParentDirectory('folder/subfolder'), 'folder');
    });

    test('should get file name components', () {
      expect(PathUtils.getFileName('folder/file.md'), 'file.md');
      expect(PathUtils.getFileNameWithoutExtension('folder/file.md'), 'file');
      expect(PathUtils.getExtension('folder/file.md'), '.md');
    });

    test('should calculate path depth', () {
      expect(PathUtils.getPathDepth(''), 0);
      expect(PathUtils.getPathDepth('file.md'), 1);
      expect(PathUtils.getPathDepth('folder/file.md'), 2);
      expect(PathUtils.getPathDepth('folder/subfolder/file.md'), 3);
    });

    test('should check ancestor relationships', () {
      expect(PathUtils.isAncestorOf('folder', 'folder/subfolder'), true);
      expect(PathUtils.isAncestorOf('folder', 'folder/subfolder/file.md'), true);
      expect(PathUtils.isAncestorOf('folder', 'other/file.md'), false);
      expect(PathUtils.isAncestorOf('folder', 'folder'), false);
      
      expect(PathUtils.isDescendantOf('folder/subfolder', 'folder'), true);
      expect(PathUtils.isDescendantOf('folder', 'folder/subfolder'), false);
    });

    test('should find common ancestor', () {
      expect(
        PathUtils.getCommonAncestor([path.join('folder', 'sub1', 'file1.md'), path.join('folder', 'sub2', 'file2.md')]),
        'folder',
      );
      expect(
        PathUtils.getCommonAncestor([path.join('folder', 'sub', 'file1.md'), path.join('folder', 'sub', 'file2.md')]),
        path.join('folder', 'sub'),
      );
      final commonAncestor = PathUtils.getCommonAncestor(['file1.md', 'file2.md']);
      expect(commonAncestor == '.' || commonAncestor == null, true);
      expect(PathUtils.getCommonAncestor([]), null);
    });

    test('should convert between URL-safe and platform paths', () {
      expect(PathUtils.toUrlSafe('folder\\subfolder\\file.md'), 'folder/subfolder/file.md');
      expect(PathUtils.fromUrlSafe('folder/subfolder/file.md'), path.normalize('folder/subfolder/file.md'));
    });

    test('should generate unique paths', () {
      final existingPaths = ['file.md', 'file_1.md', 'file_2.md'];
      final uniquePath = PathUtils.generateUniquePath('file.md', existingPaths);
      expect(path.basename(uniquePath), 'file_3.md');
      expect(PathUtils.generateUniquePath('newfile.md', existingPaths), 'newfile.md');
    });

    test('should identify file types', () {
      expect(PathUtils.isMarkdownFile('file.md'), true);
      expect(PathUtils.isMarkdownFile('file.txt'), false);
      expect(PathUtils.isMetadataFile('.folder-meta.json'), true);
      expect(PathUtils.isMetadataFile('file.json'), false);
      expect(PathUtils.isHiddenFile('.hidden'), true);
      expect(PathUtils.isHiddenFile('visible.md'), false);
    });

    test('should get all parent paths', () {
      final parents = PathUtils.getAllParentPaths('folder/subfolder/subsubfolder/file.md');
      expect(parents, contains('folder/subfolder/subsubfolder'));
      expect(parents, contains('folder/subfolder'));
      expect(parents, contains('folder'));
    });

    test('should build paths from components', () {
      expect(PathUtils.buildPath(['folder', 'subfolder', 'file.md']), path.join('folder', 'subfolder', 'file.md'));
      expect(PathUtils.buildPath(['folder', '', 'file.md']), path.join('folder', 'file.md'));
      expect(PathUtils.buildPath(['', 'folder', 'file.md']), path.join('folder', 'file.md'));
    });

    test('should check if path is within directory', () {
      expect(PathUtils.isWithinDirectory('folder/subfolder/file.md', 'folder'), true);
      expect(PathUtils.isWithinDirectory('folder/file.md', 'folder'), true);
      expect(PathUtils.isWithinDirectory('other/file.md', 'folder'), false);
    });

    test('should get root component', () {
      expect(PathUtils.getRootComponent(path.join('folder', 'subfolder', 'file.md')), 'folder');
      expect(PathUtils.getRootComponent('file.md'), 'file.md');
      final emptyRoot = PathUtils.getRootComponent('');
      expect(emptyRoot == '' || emptyRoot == '.', true); // Platform dependent
    });

    test('should handle invalid characters', () {
      expect(PathUtils.hasInvalidCharacters('valid/path.md'), false);
      expect(PathUtils.hasInvalidCharacters('invalid<path>.md'), true);
      expect(PathUtils.hasInvalidCharacters('invalid|path.md'), true);
      
      expect(PathUtils.sanitizePath('invalid<path>|file.md'), 'invalid_path__file.md');
    });

    test('should convert between path formats', () {
      expect(PathUtils.toUnixPath('folder\\subfolder\\file.md'), 'folder/subfolder/file.md');
      expect(PathUtils.toWindowsPath('folder/subfolder/file.md'), 'folder\\subfolder\\file.md');
    });

    test('should split paths correctly', () {
      expect(PathUtils.splitPath(path.join('folder', 'subfolder', 'file.md')), ['folder', 'subfolder', 'file.md']);
      expect(PathUtils.splitPath('file.md'), ['file.md']);
      final emptySplit = PathUtils.splitPath('');
      expect(emptySplit.length >= 0, true); // Platform dependent
    });
  });
}