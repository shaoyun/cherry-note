import 'dart:async';

/// Export progress information
class ExportProgress {
  final int totalFiles;
  final int processedFiles;
  final String currentFile;
  final double percentage;

  const ExportProgress({
    required this.totalFiles,
    required this.processedFiles,
    required this.currentFile,
    required this.percentage,
  });
}

/// Export result information
class ExportResult {
  final bool success;
  final int exportedFiles;
  final int exportedFolders;
  final List<String> errors;
  final String? exportPath;

  const ExportResult({
    required this.success,
    required this.exportedFiles,
    required this.exportedFolders,
    required this.errors,
    this.exportPath,
  });
}

/// Export options configuration
class ExportOptions {
  final List<String>? selectedFolders;
  final bool includeMetadata;
  final bool includeHiddenFiles;
  final bool preserveStructure;

  const ExportOptions({
    this.selectedFolders,
    this.includeMetadata = true,
    this.includeHiddenFiles = false,
    this.preserveStructure = true,
  });
}

/// Abstract export service interface
abstract class ExportService {
  /// Export to local folder
  Future<ExportResult> exportToFolder(
    String localPath, {
    ExportOptions? options,
    StreamController<ExportProgress>? progressController,
  });

  /// Export to ZIP file
  Future<ExportResult> exportToZip(
    String zipPath, {
    ExportOptions? options,
    StreamController<ExportProgress>? progressController,
  });

  /// Export single folder
  Future<ExportResult> exportFolder(
    String folderPath,
    String localPath, {
    bool includeMetadata = true,
    StreamController<ExportProgress>? progressController,
  });

  /// Cancel ongoing export operation
  Future<void> cancelExport();

  /// Check if export operation is in progress
  bool get isExporting;
}