import '../entities/s3_config.dart';
import '../entities/batch_operation_result.dart';
import '../entities/cancellation_token.dart';
import '../../../../core/error/failures.dart';

abstract class S3StorageRepository {
  /// Initialize connection with S3 configuration
  Future<void> initialize(S3Config config);

  /// Test connection to S3
  Future<bool> testConnection();

  /// Upload a file to S3
  Future<void> uploadFile(String key, String content);

  /// Download a file from S3
  Future<String> downloadFile(String key);

  /// Delete a file from S3
  Future<void> deleteFile(String key);

  /// Check if a file exists in S3
  Future<bool> fileExists(String key);

  /// List files with a given prefix
  Future<List<String>> listFiles(String prefix);

  /// List folders (common prefixes) with a given prefix
  Future<List<String>> listFolders(String prefix);

  /// Create a folder (by creating a marker object)
  Future<void> createFolder(String folderPath);

  /// Delete a folder and all its contents
  Future<void> deleteFolder(String folderPath);

  /// Upload multiple files in batch
  Future<void> uploadMultipleFiles(Map<String, String> files);

  /// Download multiple files in batch
  Future<Map<String, String>> downloadMultipleFiles(List<String> keys);

  /// Upload multiple files with progress callback and cancellation support
  Future<BatchOperationResult> uploadMultipleFilesWithProgress(
    Map<String, String> files, {
    void Function(BatchOperationProgress)? onProgress,
    CancellationToken? cancellationToken,
  });

  /// Download multiple files with progress callback and cancellation support
  Future<BatchOperationResult> downloadMultipleFilesWithProgress(
    List<String> keys, {
    void Function(BatchOperationProgress)? onProgress,
    CancellationToken? cancellationToken,
  });

  /// Delete multiple files with progress callback and cancellation support
  Future<BatchOperationResult> deleteMultipleFilesWithProgress(
    List<String> keys, {
    void Function(BatchOperationProgress)? onProgress,
    CancellationToken? cancellationToken,
  });

  /// Recursively upload a folder structure
  Future<BatchOperationResult> uploadFolderRecursively(
    String folderPath,
    Map<String, String> files, {
    void Function(BatchOperationProgress)? onProgress,
    CancellationToken? cancellationToken,
  });

  /// Recursively download a folder structure
  Future<BatchOperationResult> downloadFolderRecursively(
    String folderPath, {
    void Function(BatchOperationProgress)? onProgress,
    CancellationToken? cancellationToken,
  });

  /// Recursively delete a folder and all its contents
  Future<BatchOperationResult> deleteFolderRecursively(
    String folderPath, {
    void Function(BatchOperationProgress)? onProgress,
    CancellationToken? cancellationToken,
  });

  /// Get file metadata
  Future<Map<String, dynamic>?> getFileMetadata(String key);

  /// Get file size
  Future<int?> getFileSize(String key);

  /// Get last modified date
  Future<DateTime?> getLastModified(String key);

  /// Sync local changes to remote
  Future<void> syncToRemote();

  /// Sync remote changes to local
  Future<void> syncFromRemote();

  /// Get current configuration
  S3Config? get currentConfig;

  /// Check if repository is initialized
  bool get isInitialized;
}