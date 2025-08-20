import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import '../../domain/services/import_service.dart';
import '../../domain/repositories/s3_storage_repository.dart';
import '../../../notes/domain/entities/note_file.dart';

class ImportServiceImpl implements ImportService {
  final S3StorageRepository _storageRepository;
  bool _isImporting = false;
  bool _isCancelled = false;
  final List<FileConflict> _pendingConflicts = [];

  ImportServiceImpl(this._storageRepository);

  @override
  bool get isImporting => _isImporting;

  @override
  Future<ImportResult> importFromFolder(
    String localPath, {
    ImportOptions? options,
    StreamController<ImportProgress>? progressController,
  }) async {
    if (_isImporting) {
      throw StateError('Import operation already in progress');
    }

    _isImporting = true;
    _isCancelled = false;
    _pendingConflicts.clear();

    try {
      final importOptions = options ?? const ImportOptions();
      final importDir = Directory(localPath);

      if (!await importDir.exists()) {
        throw ArgumentError('Import directory does not exist: $localPath');
      }

      // Validate structure if requested
      if (importOptions.validateStructure) {
        final validation = await validateImportStructure(localPath);
        if (!validation.isValid) {
          return ImportResult(
            success: false,
            importedFiles: 0,
            importedFolders: 0,
            skippedFiles: 0,
            errors: validation.errors,
            conflicts: [],
          );
        }
      }

      // Collect all files to import
      final allFiles = await _collectFilesToImport(localPath, importOptions);
      
      int processedFiles = 0;
      int importedFiles = 0;
      int importedFolders = 0;
      int skippedFiles = 0;
      final errors = <String>[];

      // Import files
      for (final fileInfo in allFiles) {
        if (_isCancelled) break;

        progressController?.add(ImportProgress(
          totalFiles: allFiles.length,
          processedFiles: processedFiles,
          currentFile: fileInfo.relativePath,
          percentage: allFiles.isEmpty ? 1.0 : processedFiles / allFiles.length,
        ));

        try {
          final result = await _importFile(fileInfo, importOptions);
          if (result == ImportFileResult.imported) {
            importedFiles++;
          } else if (result == ImportFileResult.skipped) {
            skippedFiles++;
          }
        } catch (e) {
          errors.add('Failed to import file ${fileInfo.relativePath}: $e');
          skippedFiles++;
        }

        processedFiles++;
      }

      // Import folder metadata
      final folderPaths = await _collectFoldersToImport(localPath, importOptions);
      for (final folderPath in folderPaths) {
        if (_isCancelled) break;

        try {
          await _importFolderMetadata(folderPath, localPath, importOptions);
          importedFolders++;
        } catch (e) {
          errors.add('Failed to import folder metadata for $folderPath: $e');
        }
      }

      return ImportResult(
        success: !_isCancelled,
        importedFiles: importedFiles,
        importedFolders: importedFolders,
        skippedFiles: skippedFiles,
        errors: errors,
        conflicts: List.from(_pendingConflicts),
      );
    } finally {
      _isImporting = false;
      _isCancelled = false;
    }
  }

  @override
  Future<ImportResult> importFromZip(
    String zipPath, {
    ImportOptions? options,
    StreamController<ImportProgress>? progressController,
  }) async {
    if (_isImporting) {
      throw StateError('Import operation already in progress');
    }

    _isImporting = true;
    _isCancelled = false;
    _pendingConflicts.clear();

    try {
      final importOptions = options ?? const ImportOptions();
      final zipFile = File(zipPath);

      if (!await zipFile.exists()) {
        throw ArgumentError('ZIP file does not exist: $zipPath');
      }

      // Extract ZIP file
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      int processedFiles = 0;
      int importedFiles = 0;
      int importedFolders = 0;
      int skippedFiles = 0;
      final errors = <String>[];

      // Filter files based on allowed extensions
      final filesToImport = archive.files.where((file) {
        if (file.isFile) {
          if (importOptions.allowedExtensions != null) {
            final extension = path.extension(file.name).toLowerCase();
            return importOptions.allowedExtensions!.contains(extension);
          }
          return true;
        }
        return false;
      }).toList();

      // Import files from archive
      for (final file in filesToImport) {
        if (_isCancelled) break;

        progressController?.add(ImportProgress(
          totalFiles: filesToImport.length,
          processedFiles: processedFiles,
          currentFile: file.name,
          percentage: filesToImport.isEmpty ? 1.0 : processedFiles / filesToImport.length,
        ));

        try {
          final content = utf8.decode(file.content as List<int>);
          final fileInfo = FileImportInfo(
            localPath: '', // Not used for ZIP import
            relativePath: file.name,
            content: content,
            lastModified: DateTime.now(), // ZIP doesn't preserve timestamps reliably
          );

          final result = await _importFile(fileInfo, importOptions);
          if (result == ImportFileResult.imported) {
            importedFiles++;
          } else if (result == ImportFileResult.skipped) {
            skippedFiles++;
          }
        } catch (e) {
          errors.add('Failed to import file ${file.name}: $e');
          skippedFiles++;
        }

        processedFiles++;
      }

      // Import folder metadata from archive
      final metadataFiles = archive.files.where((file) => 
        file.isFile && file.name.endsWith('.folder-meta.json')
      );

      for (final metadataFile in metadataFiles) {
        if (_isCancelled) break;

        try {
          final content = utf8.decode(metadataFile.content as List<int>);
          final folderPath = path.dirname(metadataFile.name);
          await _importFolderMetadataFromContent(folderPath, content, importOptions);
          importedFolders++;
        } catch (e) {
          errors.add('Failed to import folder metadata for ${metadataFile.name}: $e');
        }
      }

      return ImportResult(
        success: !_isCancelled,
        importedFiles: importedFiles,
        importedFolders: importedFolders,
        skippedFiles: skippedFiles,
        errors: errors,
        conflicts: List.from(_pendingConflicts),
      );
    } finally {
      _isImporting = false;
      _isCancelled = false;
    }
  }

  @override
  Future<ValidationResult> validateImportStructure(String importPath) async {
    final errors = <String>[];
    final warnings = <String>[];
    int detectedFiles = 0;
    int detectedFolders = 0;

    try {
      final importDir = Directory(importPath);
      if (!await importDir.exists()) {
        errors.add('Import path does not exist: $importPath');
        return ValidationResult(
          isValid: false,
          errors: errors,
          warnings: warnings,
          detectedFiles: 0,
          detectedFolders: 0,
        );
      }

      // Recursively scan directory
      await for (final entity in importDir.list(recursive: true)) {
        if (entity is File) {
          detectedFiles++;
          
          // Check file extension
          final extension = path.extension(entity.path).toLowerCase();
          if (!['.md', '.txt', '.json'].contains(extension)) {
            warnings.add('Unsupported file type: ${entity.path}');
          }

          // Validate markdown files
          if (extension == '.md') {
            try {
              final content = await entity.readAsString();
              _validateMarkdownFile(content, entity.path, warnings);
            } catch (e) {
              errors.add('Cannot read file: ${entity.path}');
            }
          }
        } else if (entity is Directory) {
          detectedFolders++;
        }
      }

      // Check for minimum requirements
      if (detectedFiles == 0) {
        warnings.add('No files found to import');
      }

    } catch (e) {
      errors.add('Error validating import structure: $e');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      detectedFiles: detectedFiles,
      detectedFolders: detectedFolders,
    );
  }

  @override
  Future<void> resolveConflict(String filePath, ConflictStrategy strategy) async {
    final conflictIndex = _pendingConflicts.indexWhere((c) => c.filePath == filePath);
    if (conflictIndex == -1) {
      throw ArgumentError('No pending conflict found for file: $filePath');
    }

    final conflict = _pendingConflicts[conflictIndex];
    
    switch (strategy) {
      case ConflictStrategy.overwrite:
        await _storageRepository.uploadFile(filePath, conflict.newContent);
        break;
      case ConflictStrategy.skip:
        // Do nothing, keep existing file
        break;
      case ConflictStrategy.rename:
        final newPath = _generateUniqueFileName(filePath);
        await _storageRepository.uploadFile(newPath, conflict.newContent);
        break;
      case ConflictStrategy.keepBoth:
        final backupPath = _generateBackupFileName(filePath);
        await _storageRepository.uploadFile(backupPath, conflict.existingContent);
        await _storageRepository.uploadFile(filePath, conflict.newContent);
        break;
      case ConflictStrategy.ask:
        // This should be handled by the UI layer
        throw UnsupportedError('Ask strategy should be handled by UI layer');
    }

    _pendingConflicts.removeAt(conflictIndex);
  }

  @override
  Future<List<FileConflict>> getPendingConflicts() async {
    return List.from(_pendingConflicts);
  }

  @override
  Future<void> cancelImport() async {
    _isCancelled = true;
  }

  // Private helper methods

  Future<List<FileImportInfo>> _collectFilesToImport(
    String localPath,
    ImportOptions options,
  ) async {
    final files = <FileImportInfo>[];
    final importDir = Directory(localPath);

    await for (final entity in importDir.list(recursive: true)) {
      if (entity is File) {
        final extension = path.extension(entity.path).toLowerCase();
        
        // Filter by allowed extensions
        if (options.allowedExtensions != null && 
            !options.allowedExtensions!.contains(extension)) {
          continue;
        }

        // Skip hidden files and metadata files
        final fileName = path.basename(entity.path);
        if (fileName.startsWith('.') && fileName != '.folder-meta.json') {
          continue;
        }

        try {
          final content = await entity.readAsString();
          final relativePath = path.relative(entity.path, from: localPath);
          final stats = await entity.stat();

          files.add(FileImportInfo(
            localPath: entity.path,
            relativePath: relativePath,
            content: content,
            lastModified: stats.modified,
          ));
        } catch (e) {
          // Skip files that cannot be read
          continue;
        }
      }
    }

    return files;
  }

  Future<List<String>> _collectFoldersToImport(
    String localPath,
    ImportOptions options,
  ) async {
    final folders = <String>[];
    final importDir = Directory(localPath);

    await for (final entity in importDir.list(recursive: true)) {
      if (entity is Directory) {
        final relativePath = path.relative(entity.path, from: localPath);
        
        // Check if folder has metadata file
        final metadataFile = File(path.join(entity.path, '.folder-meta.json'));
        if (await metadataFile.exists()) {
          folders.add(relativePath);
        }
      }
    }

    return folders;
  }

  Future<ImportFileResult> _importFile(
    FileImportInfo fileInfo,
    ImportOptions options,
  ) async {
    final targetPath = options.targetFolder != null
        ? path.join(options.targetFolder!, fileInfo.relativePath)
        : fileInfo.relativePath;

    // Check for conflicts
    if (await _storageRepository.fileExists(targetPath)) {
      final existingContent = await _storageRepository.downloadFile(targetPath);
      
      if (existingContent != fileInfo.content) {
        final conflict = FileConflict(
          filePath: targetPath,
          existingContent: existingContent,
          newContent: fileInfo.content,
          existingModified: DateTime.now(), // We don't have this info from S3
          newModified: fileInfo.lastModified,
        );

        switch (options.conflictStrategy) {
          case ConflictStrategy.ask:
            _pendingConflicts.add(conflict);
            return ImportFileResult.conflict;
          case ConflictStrategy.skip:
            return ImportFileResult.skipped;
          case ConflictStrategy.overwrite:
            await _storageRepository.uploadFile(targetPath, fileInfo.content);
            return ImportFileResult.imported;
          case ConflictStrategy.rename:
            final newPath = _generateUniqueFileName(targetPath);
            await _storageRepository.uploadFile(newPath, fileInfo.content);
            return ImportFileResult.imported;
          case ConflictStrategy.keepBoth:
            final backupPath = _generateBackupFileName(targetPath);
            await _storageRepository.uploadFile(backupPath, existingContent);
            await _storageRepository.uploadFile(targetPath, fileInfo.content);
            return ImportFileResult.imported;
        }
      }
    }

    // No conflict, import the file
    await _storageRepository.uploadFile(targetPath, fileInfo.content);
    return ImportFileResult.imported;
  }

  Future<void> _importFolderMetadata(
    String folderPath,
    String localBasePath,
    ImportOptions options,
  ) async {
    final localMetadataPath = path.join(localBasePath, folderPath, '.folder-meta.json');
    final metadataFile = File(localMetadataPath);

    if (await metadataFile.exists()) {
      final content = await metadataFile.readAsString();
      await _importFolderMetadataFromContent(folderPath, content, options);
    }
  }

  Future<void> _importFolderMetadataFromContent(
    String folderPath,
    String content,
    ImportOptions options,
  ) async {
    final targetPath = options.targetFolder != null
        ? path.join(options.targetFolder!, folderPath, '.folder-meta.json')
        : path.join(folderPath, '.folder-meta.json');

    await _storageRepository.uploadFile(targetPath, content);
  }

  void _validateMarkdownFile(String content, String filePath, List<String> warnings) {
    // Basic validation for markdown files
    if (content.trim().isEmpty) {
      warnings.add('Empty markdown file: $filePath');
      return;
    }

    // Check for front matter
    if (content.startsWith('---')) {
      final lines = content.split('\n');
      var frontMatterEnd = -1;
      
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim() == '---') {
          frontMatterEnd = i;
          break;
        }
      }

      if (frontMatterEnd == -1) {
        warnings.add('Invalid front matter in file: $filePath');
      }
    }
  }

  String _generateUniqueFileName(String originalPath) {
    final dir = path.dirname(originalPath);
    final name = path.basenameWithoutExtension(originalPath);
    final ext = path.extension(originalPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    return path.join(dir, '${name}_$timestamp$ext');
  }

  String _generateBackupFileName(String originalPath) {
    final dir = path.dirname(originalPath);
    final name = path.basenameWithoutExtension(originalPath);
    final ext = path.extension(originalPath);
    
    return path.join(dir, '${name}_backup$ext');
  }
}

class FileImportInfo {
  final String localPath;
  final String relativePath;
  final String content;
  final DateTime lastModified;

  const FileImportInfo({
    required this.localPath,
    required this.relativePath,
    required this.content,
    required this.lastModified,
  });
}

enum ImportFileResult {
  imported,
  skipped,
  conflict,
}