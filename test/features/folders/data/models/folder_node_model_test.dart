import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/features/folders/data/models/folder_node_model.dart';
import 'package:cherry_note/features/folders/domain/entities/folder_node.dart';
import 'package:cherry_note/features/notes/data/models/note_file_model.dart';

void main() {
  group('FolderNodeModel', () {
    final testDate = DateTime(2024, 1, 15, 10, 30, 0);
    final updatedDate = DateTime(2024, 1, 15, 15, 45, 0);
    
    late FolderNodeModel testFolderModel;
    
    setUp(() {
      testFolderModel = FolderNodeModel(
        folderPath: 'work/projects',
        name: 'Projects',
        created: testDate,
        updated: updatedDate,
        description: 'Work projects folder',
        color: '#2196F3',
      );
    });

    test('should create FolderNodeModel with all properties', () {
      expect(testFolderModel.folderPath, 'work/projects');
      expect(testFolderModel.name, 'Projects');
      expect(testFolderModel.created, testDate);
      expect(testFolderModel.updated, updatedDate);
      expect(testFolderModel.description, 'Work projects folder');
      expect(testFolderModel.color, '#2196F3');
      expect(testFolderModel.subFolders, isEmpty);
      expect(testFolderModel.notes, isEmpty);
    });

    test('should get correct parent path', () {
      expect(testFolderModel.parentPath, 'work');
      
      final rootFolder = FolderNodeModel(
        folderPath: 'root',
        name: 'Root',
        created: testDate,
        updated: testDate,
      );
      expect(rootFolder.parentPath, null);
    });

    test('should calculate correct depth', () {
      expect(testFolderModel.depth, 2);
      
      final rootFolder = FolderNodeModel(
        folderPath: 'root',
        name: 'Root',
        created: testDate,
        updated: testDate,
      );
      expect(rootFolder.depth, 1);
    });

    test('should identify root folder correctly', () {
      expect(testFolderModel.isRoot, false);
      
      final rootFolder = FolderNodeModel(
        folderPath: 'root',
        name: 'Root',
        created: testDate,
        updated: testDate,
      );
      expect(rootFolder.isRoot, true);
    });

    test('should convert to and from metadata JSON', () {
      final metadataJson = testFolderModel.toMetadataJson();
      final metadata = json.decode(metadataJson) as Map<String, dynamic>;
      
      expect(metadata['name'], 'Projects');
      expect(metadata['description'], 'Work projects folder');
      expect(metadata['color'], '#2196F3');
      expect(metadata['created'], isNotNull);
      expect(metadata['updated'], isNotNull);
      
      final recreatedFolder = FolderNodeModel.fromMetadata('work/projects', metadataJson);
      expect(recreatedFolder.name, testFolderModel.name);
      expect(recreatedFolder.description, testFolderModel.description);
      expect(recreatedFolder.color, testFolderModel.color);
    });

    test('should handle missing metadata gracefully', () {
      final folder = FolderNodeModel.fromMetadata('work/projects', null);
      expect(folder.name, 'projects');
      expect(folder.folderPath, 'work/projects');
      expect(folder.description, null);
      expect(folder.color, null);
    });

    test('should handle malformed metadata JSON', () {
      const malformedJson = '{"name": "Test", "invalid": }';
      final folder = FolderNodeModel.fromMetadata('test', malformedJson);
      expect(folder.name, 'test');
      expect(folder.folderPath, 'test');
    });

    test('should convert to and from entity', () {
      final entity = testFolderModel.toEntity();
      final model = FolderNodeModel.fromEntity(entity);
      
      expect(model.folderPath, testFolderModel.folderPath);
      expect(model.name, testFolderModel.name);
      expect(model.created, testFolderModel.created);
      expect(model.updated, testFolderModel.updated);
      expect(model.description, testFolderModel.description);
      expect(model.color, testFolderModel.color);
    });

    test('should build folder tree from flat paths', () {
      final paths = [
        'work',
        'work/projects',
        'work/projects/app',
        'personal',
        'personal/notes',
      ];
      
      final metadata = <String, String>{
        'work': '{"name": "Work", "description": "Work folder"}',
        'work/projects': '{"name": "Projects"}',
        'work/projects/app': '{"name": "App Project"}',
        'personal': '{"name": "Personal"}',
        'personal/notes': '{"name": "Notes"}',
      };
      
      final tree = FolderNodeModel.buildFolderTree(paths, metadata);
      
      expect(tree.length, 2); // work and personal
      
      final workFolder = tree.firstWhere((f) => f.name == 'Work');
      expect(workFolder.subFolders.length, 1);
      
      final projectsFolder = workFolder.subFolders.first;
      expect(projectsFolder.name, 'Projects');
      expect(projectsFolder.subFolders.length, 1);
      expect(projectsFolder.subFolders.first.name, 'App Project');
      
      final personalFolder = tree.firstWhere((f) => f.name == 'Personal');
      expect(personalFolder.subFolders.length, 1);
      expect(personalFolder.subFolders.first.name, 'Notes');
    });

    test('should flatten folder tree to paths', () {
      final subFolder = FolderNodeModel(
        folderPath: 'work/projects/app',
        name: 'App',
        created: testDate,
        updated: testDate,
      );
      
      final projectsFolder = FolderNodeModel(
        folderPath: 'work/projects',
        name: 'Projects',
        created: testDate,
        updated: testDate,
        subFolders: [subFolder],
      );
      
      final workFolder = FolderNodeModel(
        folderPath: 'work',
        name: 'Work',
        created: testDate,
        updated: testDate,
        subFolders: [projectsFolder],
      );
      
      final paths = FolderNodeModel.flattenFolderTree([workFolder]);
      
      expect(paths, containsAll([
        'work',
        'work/projects',
        'work/projects/app',
      ]));
    });

    test('should get correct metadata file path', () {
      expect(testFolderModel.metadataFilePath, 'work/projects/.folder-meta.json');
      
      final rootFolder = FolderNodeModel(
        folderPath: '',
        name: 'Root',
        created: testDate,
        updated: testDate,
      );
      expect(rootFolder.metadataFilePath, '.app-meta.json');
    });

    test('should validate folder structure', () {
      expect(testFolderModel.isValid(), true);
      
      final invalidFolder = FolderNodeModel(
        folderPath: '',
        name: '',
        created: testDate,
        updated: testDate,
      );
      expect(invalidFolder.isValid(), false);
      
      final invalidNameFolder = FolderNodeModel(
        folderPath: 'test',
        name: 'invalid<name>',
        created: testDate,
        updated: testDate,
      );
      expect(invalidNameFolder.isValid(), false);
    });

    test('should generate valid folder path', () {
      expect(FolderNodeModel.generateFolderPath('work', 'projects'), 'work/projects');
      expect(FolderNodeModel.generateFolderPath(null, 'root'), 'root');
      expect(FolderNodeModel.generateFolderPath('', 'root'), 'root');
      expect(FolderNodeModel.generateFolderPath('work', 'invalid<name>'), 'work/invalid_name_');
    });

    test('should extract folder name from path', () {
      expect(FolderNodeModel.extractFolderName('work/projects/app'), 'app');
      expect(FolderNodeModel.extractFolderName('root'), 'root');
      expect(FolderNodeModel.extractFolderName(''), 'Root');
      expect(FolderNodeModel.extractFolderName('/'), 'Root');
    });

    test('should validate folder paths', () {
      expect(FolderNodeModel.isValidPath('work/projects'), true);
      expect(FolderNodeModel.isValidPath('root'), true);
      expect(FolderNodeModel.isValidPath(''), false);
      expect(FolderNodeModel.isValidPath('work\\projects'), false);
      expect(FolderNodeModel.isValidPath('work//projects'), false);
      expect(FolderNodeModel.isValidPath('/work'), false);
      expect(FolderNodeModel.isValidPath('work/invalid<name>'), false);
    });

    test('should handle folder operations', () {
      final note = NoteFileModel(
        filePath: 'work/projects/note.md',
        title: 'Test Note',
        content: 'Content',
        tags: [],
        created: testDate,
        updated: testDate,
      );
      
      final subfolder = FolderNodeModel(
        folderPath: 'work/projects/app',
        name: 'App',
        created: testDate,
        updated: testDate,
      );
      
      // Test adding note
      final folderWithNote = testFolderModel.addNote(note) as FolderNodeModel;
      expect(folderWithNote.notes.length, 1);
      expect(folderWithNote.notes.first.title, 'Test Note');
      
      // Test adding subfolder
      final folderWithSubfolder = testFolderModel.addSubfolder(subfolder) as FolderNodeModel;
      expect(folderWithSubfolder.subFolders.length, 1);
      expect(folderWithSubfolder.subFolders.first.name, 'App');
      
      // Test removing note
      final folderWithoutNote = folderWithNote.removeNote('work/projects/note.md') as FolderNodeModel;
      expect(folderWithoutNote.notes.length, 0);
      
      // Test removing subfolder
      final folderWithoutSubfolder = folderWithSubfolder.removeSubfolder('work/projects/app') as FolderNodeModel;
      expect(folderWithoutSubfolder.subFolders.length, 0);
    });

    test('should calculate folder statistics', () {
      final note1 = NoteFileModel(
        filePath: 'work/projects/note1.md',
        title: 'Note 1',
        content: 'Content 1',
        tags: [],
        created: testDate,
        updated: testDate,
      );
      
      final note2 = NoteFileModel(
        filePath: 'work/projects/app/note2.md',
        title: 'Note 2',
        content: 'Content 2',
        tags: [],
        created: testDate,
        updated: updatedDate,
      );
      
      final subfolder = FolderNodeModel(
        folderPath: 'work/projects/app',
        name: 'App',
        created: testDate,
        updated: testDate,
        notes: [note2],
      );
      
      final folder = testFolderModel.copyWith(
        notes: [note1],
        subFolders: [subfolder],
      ) as FolderNodeModel;
      
      final stats = folder.stats;
      expect(stats.totalNotes, 2);
      expect(stats.directNotes, 1);
      expect(stats.totalFolders, 1);
      expect(stats.directSubfolders, 1);
      expect(stats.lastModified, updatedDate);
    });
  });
}