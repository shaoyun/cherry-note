import 'dart:async';

/// Import progress information
class ImportProgress {
  final int totalFiles;
  final int processedFiles;
  final String currentFile;
  final double percentage;

  const ImportProgress({
    required this.totalFiles,
    required this.processedFiles,
    required this.currentFile,
    required this.percentage,
  });
}

/// Import result information
class ImportResult {
  final bool success;
  final int importedFiles;
  final int importedFolders;
  final int skippedFiles;
  final List<String> errors;
  final List<FileConflict> conflicts;

  const ImportResult({
    required this.success,
    required this.importedFiles,
    required this.importedFolders,
    required this.skippedFiles,
    required this.errors,
    required this.conflicts,
  });
}

/// File conflict information
class FileConflict {
  final String filePath;
  final String existingContent;
  final String newContent;
  final DateTime existingModified;
  final DateTime newModified;

  const FileConflict({
    required this.filePath,
    required this.existingContent,
    required this.newContent,
    required this.existingModified,
    required this.newModified,
  });
}

/// Conflict resolution strategy
enum ConflictStrategy {
  ask,        // Ask user for each conflict
  skip,       // Skip conflicting files
  overwrite,  // Overwrite existing files
  rename,     // Rename new files
  keepBoth,   // Keep both versions
}

/// Import options configuration
class ImportOptions {
  final String? targetFolder;
  final ConflictStrategy conflictStrategy;
  final bool validateStructure;
  final bool preserveTimestamps;
  final List<String>? allowedExtensions;

  const ImportOptions({
    this.targetFolder,
    this.conflictStrategy = ConflictStrategy.ask,
    this.validateStructure = true,
    this.preserveTimestamps = true,
    this.allowedExtensions,
  });
}

/// Validation result information
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final int detectedFiles;
  final int detectedFolders;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.detectedFiles,
    required this.detectedFolders,
  });
}

/// Abstract import service interface
abstract class ImportService {
  /// Import from local folder
  Future<ImportResult> importFromFolder(
    String localPath, {
    ImportOptions? options,
    StreamController<ImportProgress>? progressController,
  });

  /// Import from ZIP file
  Future<ImportResult> importFromZip(
    String zipPath, {
    ImportOptions? options,
    StreamController<ImportProgress>? progressController,
  });

  /// Validate import structure
  Future<ValidationResult> validateImportStructure(String path);

  /// Resolve file conflict
  Future<void> resolveConflict(
    String filePath,
    ConflictStrategy strategy,
  );

  /// Get pending conflicts
  Future<List<FileConflict>> getPendingConflicts();

  /// Cancel ongoing import operation
  Future<void> cancelImport();

  /// Check if import operation is in progress
  bool get isImporting;
}