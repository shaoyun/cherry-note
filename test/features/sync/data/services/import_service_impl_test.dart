import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:path/path.dart' as path;

import 'package:cherry_note/features/sync/data/services/import_service_impl.dart';
import 'package:cherry_note/features/sync/domain/services/import_service.dart';
import 'package:cherry_note/features/sync/domain/repositories/s3_storage_repository.dart';

import 'import_service_impl_test.mocks.dart';

@GenerateMocks([S3StorageRepository])
void main() {
  group('ImportServiceImpl', () {
    late ImportServiceImpl importService;
    late MockS3StorageRepository mockStorageRepository;
    late Directory tempDir;

    setUp(() async {
      mockStorageRepository = MockS3StorageRepository();
      importService = ImportServiceImpl(mockStorageRepository);
      
      // Create temporary directory for tests
      tempDir = await Directory.systemTemp.createTemp('import_test_');
    });

    tearDown(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('validateImportStructure', () {
      test('should validate valid import structure', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test.md'));
        await testFile.writeAsString('# Test Note\n\nThis is a test note.');

        // Act
        final result = await importService.validateImportStructure(tempDir.path);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.detectedFiles, equals(1));
        expect(result.detectedFolders, equals(0));
        expect(result.errors, isEmpty);
      });

      test('should detect invalid import path', () async {
        // Act
        final result = await importService.validateImportStructure('/nonexistent/path');

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, isNotEmpty);
        expect(result.errors.first, contains('does not exist'));
      });

      test('should warn about unsupported file types', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test.pdf'));
        await testFile.writeAsString('dummy content');

        // Act
        final result = await importService.validateImportStructure(tempDir.path);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.warnings, isNotEmpty);
        expect(result.warnings.first, contains('Unsupported file type'));
      });

      test('should warn about empty markdown files', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'empty.md'));
        await testFile.writeAsString('');

        // Act
        final result = await importService.validateImportStructure(tempDir.path);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.warnings, isNotEmpty);
        expect(result.warnings.first, contains('Empty markdown file'));
      });
    });

    group('importFromFolder', () {
      test('should import files successfully', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test.md'));
        const fileContent = '# Test Note\n\nThis is a test note.';
        await testFile.writeAsString(fileContent);

        when(mockStorageRepository.fileExists('test.md')).thenAnswer((_) async => false);
        when(mockStorageRepository.uploadFile('test.md', fileContent)).thenAnswer((_) async {});

        // Act
        final result = await importService.importFromFolder(tempDir.path);

        // Assert
        expect(result.success, isTrue);
        expect(result.importedFiles, equals(1));
        expect(result.skippedFiles, equals(0));
        expect(result.errors, isEmpty);
        expect(result.conflicts, isEmpty);

        verify(mockStorageRepository.uploadFile('test.md', fileContent)).called(1);
      });

      test('should handle import with progress updates', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test.md'));
        const fileContent = '# Test Note';
        await testFile.writeAsString(fileContent);

        when(mockStorageRepository.fileExists('test.md')).thenAnswer((_) async => false);
        when(mockStorageRepository.uploadFile('test.md', fileContent)).thenAnswer((_) async {});

        final progressController = StreamController<ImportProgress>();
        final progressUpdates = <ImportProgress>[];
        progressController.stream.listen(progressUpdates.add);

        // Act
        final result = await importService.importFromFolder(
          tempDir.path,
          progressController: progressController,
        );

        // Wait a bit for progress updates to be processed
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(result.success, isTrue);
        expect(progressUpdates, isNotEmpty);
        expect(progressUpdates.first.currentFile, equals('test.md'));
        
        await progressController.close();
      });

      test('should detect and handle file conflicts with skip strategy', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test.md'));
        const newContent = '# New Test Note';
        const existingContent = '# Existing Test Note';
        await testFile.writeAsString(newContent);

        when(mockStorageRepository.fileExists('test.md')).thenAnswer((_) async => true);
        when(mockStorageRepository.downloadFile('test.md')).thenAnswer((_) async => existingContent);

        final options = ImportOptions(conflictStrategy: ConflictStrategy.skip);

        // Act
        final result = await importService.importFromFolder(
          tempDir.path,
          options: options,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.importedFiles, equals(0));
        expect(result.skippedFiles, equals(1));
        expect(result.conflicts, isEmpty);

        verifyNever(mockStorageRepository.uploadFile(any, any));
      });

      test('should detect and handle file conflicts with overwrite strategy', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test.md'));
        const newContent = '# New Test Note';
        const existingContent = '# Existing Test Note';
        await testFile.writeAsString(newContent);

        when(mockStorageRepository.fileExists('test.md')).thenAnswer((_) async => true);
        when(mockStorageRepository.downloadFile('test.md')).thenAnswer((_) async => existingContent);
        when(mockStorageRepository.uploadFile('test.md', newContent)).thenAnswer((_) async {});

        final options = ImportOptions(conflictStrategy: ConflictStrategy.overwrite);

        // Act
        final result = await importService.importFromFolder(
          tempDir.path,
          options: options,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.importedFiles, equals(1));
        expect(result.skippedFiles, equals(0));
        expect(result.conflicts, isEmpty);

        verify(mockStorageRepository.uploadFile('test.md', newContent)).called(1);
      });

      test('should detect conflicts with ask strategy', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test.md'));
        const newContent = '# New Test Note';
        const existingContent = '# Existing Test Note';
        await testFile.writeAsString(newContent);

        when(mockStorageRepository.fileExists('test.md')).thenAnswer((_) async => true);
        when(mockStorageRepository.downloadFile('test.md')).thenAnswer((_) async => existingContent);

        final options = ImportOptions(conflictStrategy: ConflictStrategy.ask);

        // Act
        final result = await importService.importFromFolder(
          tempDir.path,
          options: options,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.importedFiles, equals(0));
        expect(result.skippedFiles, equals(0));
        expect(result.conflicts, hasLength(1));
        expect(result.conflicts.first.filePath, equals('test.md'));
        expect(result.conflicts.first.newContent, equals(newContent));
        expect(result.conflicts.first.existingContent, equals(existingContent));

        verifyNever(mockStorageRepository.uploadFile(any, any));
      });

      test('should import to target folder when specified', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test.md'));
        const fileContent = '# Test Note';
        await testFile.writeAsString(fileContent);

        const targetFolder = 'imported';
        const expectedPath = 'imported/test.md';

        when(mockStorageRepository.fileExists(expectedPath)).thenAnswer((_) async => false);
        when(mockStorageRepository.uploadFile(expectedPath, fileContent)).thenAnswer((_) async {});

        final options = ImportOptions(targetFolder: targetFolder);

        // Act
        final result = await importService.importFromFolder(
          tempDir.path,
          options: options,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.importedFiles, equals(1));

        verify(mockStorageRepository.uploadFile(expectedPath, fileContent)).called(1);
      });

      test('should handle import errors gracefully', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test.md'));
        const fileContent = '# Test Note';
        await testFile.writeAsString(fileContent);

        when(mockStorageRepository.fileExists('test.md')).thenAnswer((_) async => false);
        when(mockStorageRepository.uploadFile('test.md', fileContent))
            .thenThrow(Exception('Upload failed'));

        // Act
        final result = await importService.importFromFolder(tempDir.path);

        // Assert
        expect(result.success, isTrue); // Success is true if not cancelled
        expect(result.importedFiles, equals(0));
        expect(result.skippedFiles, equals(1));
        expect(result.errors, isNotEmpty);
        expect(result.errors.first, contains('Upload failed'));
      });

      test('should prevent concurrent imports', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test.md'));
        await testFile.writeAsString('# Test Note');

        when(mockStorageRepository.fileExists('test.md')).thenAnswer((_) async => false);
        when(mockStorageRepository.uploadFile(any, any)).thenAnswer((_) async {
          // Simulate slow operation
          await Future.delayed(const Duration(milliseconds: 100));
        });

        // Act & Assert
        final future1 = importService.importFromFolder(tempDir.path);
        
        expect(
          () => importService.importFromFolder(tempDir.path),
          throwsA(isA<StateError>()),
        );

        await future1;
      });

      test('should import folder metadata', () async {
        // Arrange
        final subDir = Directory(path.join(tempDir.path, 'subfolder'));
        await subDir.create();
        
        final metadataFile = File(path.join(subDir.path, '.folder-meta.json'));
        const metadataContent = '{"name": "Test Folder", "created": "2024-01-15T10:30:00Z"}';
        await metadataFile.writeAsString(metadataContent);

        when(mockStorageRepository.uploadFile('subfolder/.folder-meta.json', metadataContent))
            .thenAnswer((_) async {});

        // Act
        final result = await importService.importFromFolder(tempDir.path);

        // Assert
        expect(result.success, isTrue);
        expect(result.importedFolders, equals(1));

        verify(mockStorageRepository.uploadFile('subfolder/.folder-meta.json', metadataContent)).called(1);
      });
    });

    group('resolveConflict', () {
      test('should resolve conflict with overwrite strategy', () async {
        // Arrange
        const filePath = 'test.md';
        const newContent = '# New Content';
        const existingContent = '# Existing Content';

        // Create a test file and simulate conflict
        final testFile = File(path.join(tempDir.path, filePath));
        await testFile.writeAsString(newContent);

        when(mockStorageRepository.fileExists(filePath)).thenAnswer((_) async => true);
        when(mockStorageRepository.downloadFile(filePath)).thenAnswer((_) async => existingContent);

        // First import with ask strategy to create conflict
        final options = ImportOptions(conflictStrategy: ConflictStrategy.ask);
        await importService.importFromFolder(tempDir.path, options: options);

        when(mockStorageRepository.uploadFile(filePath, newContent)).thenAnswer((_) async {});

        // Act
        await importService.resolveConflict(filePath, ConflictStrategy.overwrite);

        // Assert
        verify(mockStorageRepository.uploadFile(filePath, newContent)).called(1);
        expect(await importService.getPendingConflicts(), isEmpty);
      });

      test('should resolve conflict with skip strategy', () async {
        // Arrange
        const filePath = 'test.md';
        const newContent = '# New Content';
        const existingContent = '# Existing Content';

        // Create a test file and simulate conflict
        final testFile = File(path.join(tempDir.path, filePath));
        await testFile.writeAsString(newContent);

        when(mockStorageRepository.fileExists(filePath)).thenAnswer((_) async => true);
        when(mockStorageRepository.downloadFile(filePath)).thenAnswer((_) async => existingContent);

        // First import with ask strategy to create conflict
        final options = ImportOptions(conflictStrategy: ConflictStrategy.ask);
        await importService.importFromFolder(tempDir.path, options: options);

        // Act
        await importService.resolveConflict(filePath, ConflictStrategy.skip);

        // Assert
        expect(await importService.getPendingConflicts(), isEmpty);
      });

      test('should throw error for non-existent conflict', () async {
        // Act & Assert
        expect(
          () => importService.resolveConflict('nonexistent.md', ConflictStrategy.overwrite),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('cancelImport', () {
      test('should cancel ongoing import', () async {
        // Arrange
        final testFile = File(path.join(tempDir.path, 'test.md'));
        await testFile.writeAsString('# Test Note');

        when(mockStorageRepository.fileExists('test.md')).thenAnswer((_) async {
          // Simulate slow operation
          await Future.delayed(const Duration(milliseconds: 100));
          return false;
        });
        when(mockStorageRepository.uploadFile(any, any)).thenAnswer((_) async {});

        // Act
        final importFuture = importService.importFromFolder(tempDir.path);
        
        // Cancel after a short delay
        Future.delayed(const Duration(milliseconds: 50), () {
          importService.cancelImport();
        });

        final result = await importFuture;

        // Assert
        expect(result.success, isFalse);
      });
    });

    test('should report isImporting status correctly', () async {
      // Arrange
      final testFile = File(path.join(tempDir.path, 'test.md'));
      await testFile.writeAsString('# Test Note');

      when(mockStorageRepository.fileExists('test.md')).thenAnswer((_) async => false);
      when(mockStorageRepository.uploadFile(any, any)).thenAnswer((_) async {});

      // Act & Assert
      expect(importService.isImporting, isFalse);
      
      final importFuture = importService.importFromFolder(tempDir.path);
      expect(importService.isImporting, isTrue);
      
      await importFuture;
      expect(importService.isImporting, isFalse);
    });
  });
}