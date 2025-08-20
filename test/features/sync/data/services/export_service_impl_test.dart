import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:path/path.dart' as path;

import 'package:cherry_note/features/sync/data/services/export_service_impl.dart';
import 'package:cherry_note/features/sync/domain/services/export_service.dart';
import 'package:cherry_note/features/sync/domain/repositories/s3_storage_repository.dart';

import 'export_service_impl_test.mocks.dart';

@GenerateMocks([S3StorageRepository])
void main() {
  group('ExportServiceImpl', () {
    late ExportServiceImpl exportService;
    late MockS3StorageRepository mockStorageRepository;
    late Directory tempDir;

    setUp(() async {
      mockStorageRepository = MockS3StorageRepository();
      exportService = ExportServiceImpl(mockStorageRepository);
      
      // Create temporary directory for tests
      tempDir = await Directory.systemTemp.createTemp('export_test_');
    });

    tearDown(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('exportToFolder', () {
      test('should export files and folders successfully', () async {
        // Arrange
        const folderPath = 'test-folder';
        const filePath = 'test-folder/test-file.md';
        const fileContent = '# Test Note\n\nThis is a test note.';
        const folderMetadata = '{"name": "Test Folder", "created": "2024-01-15T10:30:00Z"}';
        
        when(mockStorageRepository.listFolders('')).thenAnswer((_) async => [folderPath]);
        when(mockStorageRepository.listFiles('')).thenAnswer((_) async => []);
        when(mockStorageRepository.listFiles(folderPath)).thenAnswer((_) async => [filePath]);
        when(mockStorageRepository.downloadFile(filePath)).thenAnswer((_) async => fileContent);
        when(mockStorageRepository.fileExists('$folderPath/.folder-meta.json')).thenAnswer((_) async => true);
        when(mockStorageRepository.downloadFile('$folderPath/.folder-meta.json')).thenAnswer((_) async => folderMetadata);
        when(mockStorageRepository.fileExists('.app-meta.json')).thenAnswer((_) async => false);

        final exportPath = tempDir.path;

        // Act
        final result = await exportService.exportToFolder(exportPath);

        // Assert
        expect(result.success, isTrue);
        expect(result.exportedFiles, equals(1));
        expect(result.exportedFolders, equals(2)); // Root folder + test-folder
        expect(result.errors, isEmpty);

        // Verify files were created
        final exportedFile = File(path.join(exportPath, filePath));
        expect(await exportedFile.exists(), isTrue);
        expect(await exportedFile.readAsString(), equals(fileContent));

        final metadataFile = File(path.join(exportPath, folderPath, '.folder-meta.json'));
        expect(await metadataFile.exists(), isTrue);
        expect(await metadataFile.readAsString(), equals(folderMetadata));
      });

      test('should handle export with progress updates', () async {
        // Arrange
        const filePath = 'test-file.md';
        const fileContent = '# Test Note';
        
        when(mockStorageRepository.listFolders('')).thenAnswer((_) async => []);
        when(mockStorageRepository.listFiles('')).thenAnswer((_) async => [filePath]);
        when(mockStorageRepository.downloadFile(filePath)).thenAnswer((_) async => fileContent);
        when(mockStorageRepository.fileExists('.app-meta.json')).thenAnswer((_) async => false);

        final progressController = StreamController<ExportProgress>();
        final progressUpdates = <ExportProgress>[];
        progressController.stream.listen(progressUpdates.add);

        // Act
        final result = await exportService.exportToFolder(
          tempDir.path,
          progressController: progressController,
        );

        // Wait a bit for progress updates to be processed
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(result.success, isTrue);
        expect(progressUpdates, isNotEmpty);
        expect(progressUpdates.first.currentFile, equals(filePath));
        
        await progressController.close();
      });

      test('should handle export with selected folders only', () async {
        // Arrange
        const selectedFolder = 'selected-folder';
        const filePath = 'selected-folder/test-file.md';
        const fileContent = '# Test Note';
        
        when(mockStorageRepository.listFiles(selectedFolder)).thenAnswer((_) async => [filePath]);
        when(mockStorageRepository.downloadFile(filePath)).thenAnswer((_) async => fileContent);
        when(mockStorageRepository.fileExists('$selectedFolder/.folder-meta.json')).thenAnswer((_) async => false);
        when(mockStorageRepository.fileExists('.app-meta.json')).thenAnswer((_) async => false);

        final options = ExportOptions(selectedFolders: [selectedFolder]);

        // Act
        final result = await exportService.exportToFolder(
          tempDir.path,
          options: options,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.exportedFiles, equals(1));
        
        // Verify only selected folder was processed
        verify(mockStorageRepository.listFiles(selectedFolder)).called(1);
        verifyNever(mockStorageRepository.listFolders(''));
      });

      test('should handle export errors gracefully', () async {
        // Arrange
        const filePath = 'error-file.md';
        
        when(mockStorageRepository.listFolders('')).thenAnswer((_) async => []);
        when(mockStorageRepository.listFiles('')).thenAnswer((_) async => [filePath]);
        when(mockStorageRepository.downloadFile(filePath)).thenThrow(Exception('Download failed'));
        when(mockStorageRepository.fileExists('.app-meta.json')).thenAnswer((_) async => false);

        // Act
        final result = await exportService.exportToFolder(tempDir.path);

        // Assert
        expect(result.success, isTrue); // Success is true if not cancelled, even with errors
        expect(result.exportedFiles, equals(0));
        expect(result.errors, isNotEmpty);
        expect(result.errors.first, contains('Download failed'));
      });

      test('should prevent concurrent exports', () async {
        // Arrange
        when(mockStorageRepository.listFolders('')).thenAnswer((_) async => []);
        when(mockStorageRepository.listFiles('')).thenAnswer((_) async => []);
        when(mockStorageRepository.fileExists('.app-meta.json')).thenAnswer((_) async => false);

        // Act & Assert
        final future1 = exportService.exportToFolder(tempDir.path);
        
        expect(
          () => exportService.exportToFolder(tempDir.path),
          throwsA(isA<StateError>()),
        );

        await future1;
      });
    });

    group('exportToZip', () {
      test('should create ZIP file with exported content', () async {
        // Arrange
        const filePath = 'test-file.md';
        const fileContent = '# Test Note';
        
        when(mockStorageRepository.listFolders('')).thenAnswer((_) async => []);
        when(mockStorageRepository.listFiles('')).thenAnswer((_) async => [filePath]);
        when(mockStorageRepository.downloadFile(filePath)).thenAnswer((_) async => fileContent);
        when(mockStorageRepository.fileExists('.app-meta.json')).thenAnswer((_) async => false);

        final zipPath = path.join(tempDir.path, 'export.zip');

        // Act
        final result = await exportService.exportToZip(zipPath);

        // Assert
        expect(result.success, isTrue);
        expect(result.exportedFiles, equals(1));
        
        // Verify ZIP file was created
        final zipFile = File(zipPath);
        expect(await zipFile.exists(), isTrue);
        expect(await zipFile.length(), greaterThan(0));
      });
    });

    group('exportFolder', () {
      test('should export single folder successfully', () async {
        // Arrange
        const folderPath = 'single-folder';
        const filePath = 'single-folder/test-file.md';
        const fileContent = '# Test Note';
        
        when(mockStorageRepository.listFiles(folderPath)).thenAnswer((_) async => [filePath]);
        when(mockStorageRepository.downloadFile(filePath)).thenAnswer((_) async => fileContent);
        when(mockStorageRepository.fileExists('$folderPath/.folder-meta.json')).thenAnswer((_) async => false);
        when(mockStorageRepository.fileExists('.app-meta.json')).thenAnswer((_) async => false);

        // Act
        final result = await exportService.exportFolder(
          folderPath,
          tempDir.path,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.exportedFiles, equals(1));
        
        // Verify file was exported
        final exportedFile = File(path.join(tempDir.path, filePath));
        expect(await exportedFile.exists(), isTrue);
      });
    });

    group('cancelExport', () {
      test('should cancel ongoing export', () async {
        // Arrange
        when(mockStorageRepository.listFolders('')).thenAnswer((_) async {
          // Simulate slow operation
          await Future.delayed(const Duration(milliseconds: 100));
          return [];
        });
        when(mockStorageRepository.listFiles('')).thenAnswer((_) async => []);
        when(mockStorageRepository.fileExists('.app-meta.json')).thenAnswer((_) async => false);

        // Act
        final exportFuture = exportService.exportToFolder(tempDir.path);
        
        // Cancel after a short delay
        Future.delayed(const Duration(milliseconds: 50), () {
          exportService.cancelExport();
        });

        final result = await exportFuture;

        // Assert
        expect(result.success, isFalse);
      });
    });

    test('should report isExporting status correctly', () async {
      // Arrange
      when(mockStorageRepository.listFolders('')).thenAnswer((_) async => []);
      when(mockStorageRepository.listFiles('')).thenAnswer((_) async => []);
      when(mockStorageRepository.fileExists('.app-meta.json')).thenAnswer((_) async => false);

      // Act & Assert
      expect(exportService.isExporting, isFalse);
      
      final exportFuture = exportService.exportToFolder(tempDir.path);
      expect(exportService.isExporting, isTrue);
      
      await exportFuture;
      expect(exportService.isExporting, isFalse);
    });
  });
}