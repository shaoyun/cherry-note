import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import '../../domain/services/export_service.dart';
import '../../domain/repositories/s3_storage_repository.dart';
import '../../../folders/domain/entities/folder_node.dart';
import '../../../notes/domain/entities/note_file.dart';

class ExportServiceImpl implements ExportService {
  final S3StorageRepository _storageRepository;
  bool _isExporting = false;
  bool _isCancelled = false;

  ExportServiceImpl(this._storageRepository);

  @override
  bool get isExporting => _isExporting;

  @override
  Future<ExportResult> exportToFolder(
    String localPath, {
    ExportOptions? options,
    StreamController<ExportProgress>? progressController,
  }) async {
    if (_isExporting) {
      throw StateError('Export operation already in progress');
    }

    _isExporting = true;
    _isCancelled = false;
    
    try {
      final exportOptions = options ?? const ExportOptions();
      final exportDir = Directory(localPath);
      
      // Create export directory if it doesn't exist
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      // Get all folders and files to export
      final foldersToExport = await _getFoldersToExport(exportOptions.selectedFolders);
      final allFiles = <String>[];
      
      // Collect all files from selected folders
      for (final folderPath in foldersToExport) {
        final files = await _storageRepository.listFiles(folderPath);
        allFiles.addAll(files);
      }

      int processedFiles = 0;
      int exportedFiles = 0;
      int exportedFolders = 0;
      final errors = <String>[];

      // Export folders and files
      for (final folderPath in foldersToExport) {
        if (_isCancelled) break;

        try {
          await _exportFolderStructure(
            folderPath,
            localPath,
            exportOptions,
          );
          exportedFolders++;
        } catch (e) {
          errors.add('Failed to export folder $folderPath: $e');
        }
      }

      // Export files
      for (final filePath in allFiles) {
        if (_isCancelled) break;

        progressController?.add(ExportProgress(
          totalFiles: allFiles.length,
          processedFiles: processedFiles,
          currentFile: filePath,
          percentage: allFiles.isEmpty ? 1.0 : processedFiles / allFiles.length,
        ));

        try {
          await _exportFile(filePath, localPath, exportOptions);
          exportedFiles++;
        } catch (e) {
          errors.add('Failed to export file $filePath: $e');
        }

        processedFiles++;
      }

      // Export app metadata if requested
      if (exportOptions.includeMetadata && !_isCancelled) {
        try {
          await _exportAppMetadata(localPath);
        } catch (e) {
          errors.add('Failed to export app metadata: $e');
        }
      }

      return ExportResult(
        success: !_isCancelled,
        exportedFiles: exportedFiles,
        exportedFolders: exportedFolders,
        errors: errors,
        exportPath: localPath,
      );
    } finally {
      _isExporting = false;
      _isCancelled = false;
    }
  }

  @override
  Future<ExportResult> exportToZip(
    String zipPath, {
    ExportOptions? options,
    StreamController<ExportProgress>? progressController,
  }) async {
    if (_isExporting) {
      throw StateError('Export operation already in progress');
    }

    _isExporting = true;
    _isCancelled = false;

    try {
      final exportOptions = options ?? const ExportOptions();
      final archive = Archive();
      
      // Get all folders and files to export
      final foldersToExport = await _getFoldersToExport(exportOptions.selectedFolders);
      final allFiles = <String>[];
      
      // Collect all files from selected folders
      for (final folderPath in foldersToExport) {
        final files = await _storageRepository.listFiles(folderPath);
        allFiles.addAll(files);
      }

      int processedFiles = 0;
      int exportedFiles = 0;
      int exportedFolders = 0;
      final errors = <String>[];

      // Add folder structure to archive
      for (final folderPath in foldersToExport) {
        if (_isCancelled) break;

        try {
          await _addFolderToArchive(
            archive,
            folderPath,
            exportOptions,
          );
          exportedFolders++;
        } catch (e) {
          errors.add('Failed to add folder $folderPath to archive: $e');
        }
      }

      // Add files to archive
      for (final filePath in allFiles) {
        if (_isCancelled) break;

        progressController?.add(ExportProgress(
          totalFiles: allFiles.length,
          processedFiles: processedFiles,
          currentFile: filePath,
          percentage: allFiles.isEmpty ? 1.0 : processedFiles / allFiles.length,
        ));

        try {
          await _addFileToArchive(archive, filePath, exportOptions);
          exportedFiles++;
        } catch (e) {
          errors.add('Failed to add file $filePath to archive: $e');
        }

        processedFiles++;
      }

      // Add app metadata if requested
      if (exportOptions.includeMetadata && !_isCancelled) {
        try {
          await _addAppMetadataToArchive(archive);
        } catch (e) {
          errors.add('Failed to add app metadata to archive: $e');
        }
      }

      // Write archive to file
      if (!_isCancelled) {
        final zipFile = File(zipPath);
        final zipData = ZipEncoder().encode(archive);
        if (zipData != null) {
          await zipFile.writeAsBytes(zipData);
        }
      }

      return ExportResult(
        success: !_isCancelled,
        exportedFiles: exportedFiles,
        exportedFolders: exportedFolders,
        errors: errors,
        exportPath: zipPath,
      );
    } finally {
      _isExporting = false;
      _isCancelled = false;
    }
  }

  @override
  Future<ExportResult> exportFolder(
    String folderPath,
    String localPath, {
    bool includeMetadata = true,
    StreamController<ExportProgress>? progressController,
  }) async {
    final options = ExportOptions(
      selectedFolders: [folderPath],
      includeMetadata: includeMetadata,
    );

    return exportToFolder(
      localPath,
      options: options,
      progressController: progressController,
    );
  }

  @override
  Future<void> cancelExport() async {
    _isCancelled = true;
  }

  // Private helper methods

  Future<List<String>> _getFoldersToExport(List<String>? selectedFolders) async {
    if (selectedFolders != null && selectedFolders.isNotEmpty) {
      return selectedFolders;
    }
    
    // If no specific folders selected, export all folders plus root
    final folders = await _storageRepository.listFolders('');
    return ['', ...folders]; // Include root folder
  }

  Future<void> _exportFolderStructure(
    String folderPath,
    String localPath,
    ExportOptions options,
  ) async {
    final localFolderPath = path.join(localPath, folderPath);
    final localFolder = Directory(localFolderPath);
    
    if (!await localFolder.exists()) {
      await localFolder.create(recursive: true);
    }

    // Export folder metadata if requested
    if (options.includeMetadata) {
      try {
        final metadataPath = path.join(folderPath, '.folder-meta.json');
        if (await _storageRepository.fileExists(metadataPath)) {
          final metadata = await _storageRepository.downloadFile(metadataPath);
          final localMetadataFile = File(path.join(localFolderPath, '.folder-meta.json'));
          await localMetadataFile.writeAsString(metadata);
        }
      } catch (e) {
        // Metadata is optional, continue if it fails
      }
    }
  }

  Future<void> _exportFile(
    String filePath,
    String localPath,
    ExportOptions options,
  ) async {
    final content = await _storageRepository.downloadFile(filePath);
    final localFilePath = path.join(localPath, filePath);
    final localFile = File(localFilePath);
    
    // Create parent directory if it doesn't exist
    final parentDir = localFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }
    
    await localFile.writeAsString(content);
  }

  Future<void> _exportAppMetadata(String localPath) async {
    try {
      if (await _storageRepository.fileExists('.app-meta.json')) {
        final metadata = await _storageRepository.downloadFile('.app-meta.json');
        final localMetadataFile = File(path.join(localPath, '.app-meta.json'));
        await localMetadataFile.writeAsString(metadata);
      }
    } catch (e) {
      // App metadata is optional
    }
  }

  Future<void> _addFolderToArchive(
    Archive archive,
    String folderPath,
    ExportOptions options,
  ) async {
    // Add folder metadata if requested
    if (options.includeMetadata) {
      try {
        final metadataPath = path.join(folderPath, '.folder-meta.json');
        if (await _storageRepository.fileExists(metadataPath)) {
          final metadata = await _storageRepository.downloadFile(metadataPath);
          final archiveFile = ArchiveFile(
            metadataPath,
            metadata.length,
            utf8.encode(metadata),
          );
          archive.addFile(archiveFile);
        }
      } catch (e) {
        // Metadata is optional, continue if it fails
      }
    }
  }

  Future<void> _addFileToArchive(
    Archive archive,
    String filePath,
    ExportOptions options,
  ) async {
    final content = await _storageRepository.downloadFile(filePath);
    final archiveFile = ArchiveFile(
      filePath,
      content.length,
      utf8.encode(content),
    );
    archive.addFile(archiveFile);
  }

  Future<void> _addAppMetadataToArchive(Archive archive) async {
    try {
      if (await _storageRepository.fileExists('.app-meta.json')) {
        final metadata = await _storageRepository.downloadFile('.app-meta.json');
        final archiveFile = ArchiveFile(
          '.app-meta.json',
          metadata.length,
          utf8.encode(metadata),
        );
        archive.addFile(archiveFile);
      }
    } catch (e) {
      // App metadata is optional
    }
  }
}