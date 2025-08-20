import 'dart:convert';
import 'dart:typed_data';
import 'package:aws_s3_api/s3-2006-03-01.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/s3_config.dart';
import '../../domain/entities/batch_operation_result.dart';
import '../../domain/entities/cancellation_token.dart';
import '../../domain/repositories/s3_storage_repository.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';

@LazySingleton(as: S3StorageRepository)
class S3StorageRepositoryImpl implements S3StorageRepository {
  final NetworkInfo _networkInfo;
  
  S3? _s3Client;
  S3Config? _config;

  S3StorageRepositoryImpl(this._networkInfo);

  @override
  Future<void> initialize(S3Config config) async {
    try {
      _config = config;
      
      // Create AWS credentials
      final credentials = AwsClientCredentials(
        accessKey: config.accessKeyId,
        secretKey: config.secretAccessKey,
      );

      // Create S3 client
      _s3Client = S3(
        region: config.region,
        credentials: credentials,
        endpointUrl: config.fullEndpoint,
      );

      // Test the connection
      await testConnection();
    } catch (e) {
      throw StorageException('Failed to initialize S3 client: ${e.toString()}');
    }
  }

  @override
  Future<bool> testConnection() async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('No internet connection');
    }

    if (_s3Client == null || _config == null) {
      throw StorageException('S3 client not initialized');
    }

    try {
      // Try to head the bucket to test connection
      await _s3Client!.headBucket(bucket: _config!.bucketName);
      return true;
    } catch (e) {
      if (e.toString().contains('NoSuchBucket')) {
        throw StorageException('Bucket "${_config!.bucketName}" does not exist');
      } else if (e.toString().contains('AccessDenied')) {
        throw StorageException('Access denied to bucket "${_config!.bucketName}"');
      } else {
        throw StorageException('Failed to connect to S3: ${e.toString()}');
      }
    }
  }

  @override
  Future<void> uploadFile(String key, String content) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('No internet connection');
    }
    
    await _ensureInitialized();

    try {
      final bytes = utf8.encode(content);
      await _s3Client!.putObject(
        bucket: _config!.bucketName,
        key: key,
        body: bytes,
        contentType: _getContentType(key),
      );
    } catch (e) {
      throw StorageException('Failed to upload file "$key": ${e.toString()}');
    }
  }

  @override
  Future<String> downloadFile(String key) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('No internet connection');
    }
    
    await _ensureInitialized();

    try {
      final response = await _s3Client!.getObject(
        bucket: _config!.bucketName,
        key: key,
      );
      
      if (response.body == null) {
        throw StorageException('File "$key" has no content');
      }
      
      return utf8.decode(response.body!);
    } catch (e) {
      if (e.toString().contains('NoSuchKey')) {
        throw StorageException('File "$key" not found');
      }
      throw StorageException('Failed to download file "$key": ${e.toString()}');
    }
  }

  @override
  Future<void> deleteFile(String key) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('No internet connection');
    }
    
    await _ensureInitialized();

    try {
      await _s3Client!.deleteObject(
        bucket: _config!.bucketName,
        key: key,
      );
    } catch (e) {
      throw StorageException('Failed to delete file "$key": ${e.toString()}');
    }
  }

  @override
  Future<bool> fileExists(String key) async {
    if (!await _networkInfo.isConnected) {
      throw NetworkException('No internet connection');
    }
    
    await _ensureInitialized();

    try {
      await _s3Client!.headObject(
        bucket: _config!.bucketName,
        key: key,
      );
      return true;
    } catch (e) {
      if (e.toString().contains('NotFound') || e.toString().contains('NoSuchKey')) {
        return false;
      }
      throw StorageException('Failed to check if file "$key" exists: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> listFiles(String prefix) async {
    await _ensureInitialized();
    
    if (!await _networkInfo.isConnected) {
      throw NetworkException('No internet connection');
    }

    try {
      final response = await _s3Client!.listObjectsV2(
        bucket: _config!.bucketName,
        prefix: prefix,
      );

      final files = <String>[];
      if (response.contents != null) {
        for (final object in response.contents!) {
          if (object.key != null && !object.key!.endsWith('/')) {
            files.add(object.key!);
          }
        }
      }

      return files;
    } catch (e) {
      throw StorageException('Failed to list files with prefix "$prefix": ${e.toString()}');
    }
  }

  @override
  Future<List<String>> listFolders(String prefix) async {
    await _ensureInitialized();
    
    if (!await _networkInfo.isConnected) {
      throw NetworkException('No internet connection');
    }

    try {
      final response = await _s3Client!.listObjectsV2(
        bucket: _config!.bucketName,
        prefix: prefix,
        delimiter: '/',
      );

      final folders = <String>[];
      if (response.commonPrefixes != null) {
        for (final commonPrefix in response.commonPrefixes!) {
          if (commonPrefix.prefix != null) {
            // Remove trailing slash
            final folderPath = commonPrefix.prefix!.replaceAll(RegExp(r'/$'), '');
            folders.add(folderPath);
          }
        }
      }

      return folders;
    } catch (e) {
      throw StorageException('Failed to list folders with prefix "$prefix": ${e.toString()}');
    }
  }

  @override
  Future<void> createFolder(String folderPath) async {
    await _ensureInitialized();
    
    if (!await _networkInfo.isConnected) {
      throw NetworkException('No internet connection');
    }

    try {
      // Create a marker object to represent the folder
      final folderKey = folderPath.endsWith('/') ? folderPath : '$folderPath/';
      await _s3Client!.putObject(
        bucket: _config!.bucketName,
        key: folderKey,
        body: Uint8List(0),
        contentType: 'application/x-directory',
      );
    } catch (e) {
      throw StorageException('Failed to create folder "$folderPath": ${e.toString()}');
    }
  }

  @override
  Future<void> deleteFolder(String folderPath) async {
    await _ensureInitialized();
    
    if (!await _networkInfo.isConnected) {
      throw NetworkException('No internet connection');
    }

    try {
      final prefix = folderPath.endsWith('/') ? folderPath : '$folderPath/';
      
      // List all objects with the folder prefix
      final response = await _s3Client!.listObjectsV2(
        bucket: _config!.bucketName,
        prefix: prefix,
      );

      if (response.contents != null && response.contents!.isNotEmpty) {
        // Delete all objects in the folder
        final objectsToDelete = response.contents!
            .where((obj) => obj.key != null)
            .map((obj) => ObjectIdentifier(key: obj.key!))
            .toList();

        if (objectsToDelete.isNotEmpty) {
          await _s3Client!.deleteObjects(
            bucket: _config!.bucketName,
            delete: Delete(objects: objectsToDelete),
          );
        }
      }
    } catch (e) {
      throw StorageException('Failed to delete folder "$folderPath": ${e.toString()}');
    }
  }

  @override
  Future<void> uploadMultipleFiles(Map<String, String> files) async {
    final result = await uploadMultipleFilesWithProgress(files);
    if (!result.success) {
      throw StorageException('Some files failed to upload:\n${result.errors.values.join('\n')}');
    }
  }

  @override
  Future<Map<String, String>> downloadMultipleFiles(List<String> keys) async {
    final result = await downloadMultipleFilesWithProgress(keys);
    if (result.isCompleteFailure && keys.isNotEmpty) {
      throw StorageException('All files failed to download:\n${result.errors.values.join('\n')}');
    }
    
    // Return successful downloads
    final downloads = <String, String>{};
    for (final key in result.successfulKeys) {
      try {
        downloads[key] = await downloadFile(key);
      } catch (e) {
        // This shouldn't happen since we already know it was successful
      }
    }
    return downloads;
  }

  @override
  Future<Map<String, dynamic>?> getFileMetadata(String key) async {
    await _ensureInitialized();
    
    if (!await _networkInfo.isConnected) {
      throw NetworkException('No internet connection');
    }

    try {
      final response = await _s3Client!.headObject(
        bucket: _config!.bucketName,
        key: key,
      );

      return {
        'contentLength': response.contentLength,
        'contentType': response.contentType,
        'lastModified': response.lastModified,
        'etag': response.eTag,
        'metadata': response.metadata,
      };
    } catch (e) {
      if (e.toString().contains('NotFound') || e.toString().contains('NoSuchKey')) {
        return null;
      }
      throw StorageException('Failed to get metadata for file "$key": ${e.toString()}');
    }
  }

  @override
  Future<int?> getFileSize(String key) async {
    final metadata = await getFileMetadata(key);
    return metadata?['contentLength'] as int?;
  }

  @override
  Future<DateTime?> getLastModified(String key) async {
    final metadata = await getFileMetadata(key);
    return metadata?['lastModified'] as DateTime?;
  }

  @override
  Future<void> syncToRemote() async {
    // TODO: Implement sync to remote logic
    // This will be implemented in a later task
    throw UnimplementedError('Sync to remote not yet implemented');
  }

  @override
  Future<void> syncFromRemote() async {
    // TODO: Implement sync from remote logic
    // This will be implemented in a later task
    throw UnimplementedError('Sync from remote not yet implemented');
  }

  @override
  S3Config? get currentConfig => _config;

  @override
  bool get isInitialized => _s3Client != null && _config != null;

  /// Ensure the client is initialized
  Future<void> _ensureInitialized() async {
    if (!isInitialized) {
      throw StorageException('S3 client not initialized. Call initialize() first.');
    }
  }

  @override
  Future<BatchOperationResult> uploadMultipleFilesWithProgress(
    Map<String, String> files, {
    void Function(BatchOperationProgress)? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    final startTime = DateTime.now();
    final totalFiles = files.length;
    final successfulKeys = <String>[];
    final errors = <String, String>{};
    
    // Check for cancellation before starting
    cancellationToken?.throwIfCancelled();
    
    // Handle empty operation
    if (files.isEmpty) {
      final duration = DateTime.now().difference(startTime);
      onProgress?.call(BatchOperationProgress(
        totalFiles: 0,
        processedFiles: 0,
        successfulFiles: 0,
        failedFiles: 0,
        elapsed: duration,
      ));
      return BatchOperationResult.success(
        totalFiles: 0,
        successfulKeys: [],
        duration: duration,
      );
    }
    
    // Check network and initialization, but handle errors gracefully
    bool canProceed = true;
    String? initError;
    
    try {
      if (!await _networkInfo.isConnected) {
        throw NetworkException('No internet connection');
      }
      await _ensureInitialized();
    } catch (e) {
      canProceed = false;
      initError = e.toString();
    }
    
    int processedFiles = 0;
    
    for (final entry in files.entries) {
      // Check for cancellation
      cancellationToken?.throwIfCancelled();
      
      final key = entry.key;
      final content = entry.value;
      
      // Report progress
      onProgress?.call(BatchOperationProgress(
        totalFiles: totalFiles,
        processedFiles: processedFiles,
        successfulFiles: successfulKeys.length,
        failedFiles: errors.length,
        currentFile: key,
        elapsed: DateTime.now().difference(startTime),
      ));
      
      if (!canProceed) {
        errors[key] = initError!;
      } else {
        try {
          await uploadFile(key, content);
          successfulKeys.add(key);
        } catch (e) {
          errors[key] = e.toString();
        }
      }
      
      processedFiles++;
    }
    
    final duration = DateTime.now().difference(startTime);
    
    // Final progress report
    onProgress?.call(BatchOperationProgress(
      totalFiles: totalFiles,
      processedFiles: processedFiles,
      successfulFiles: successfulKeys.length,
      failedFiles: errors.length,
      elapsed: duration,
    ));
    
    if (errors.isEmpty) {
      return BatchOperationResult.success(
        totalFiles: totalFiles,
        successfulKeys: successfulKeys,
        duration: duration,
      );
    } else if (successfulKeys.isNotEmpty) {
      return BatchOperationResult.partial(
        totalFiles: totalFiles,
        successfulKeys: successfulKeys,
        errors: errors,
        duration: duration,
      );
    } else {
      return BatchOperationResult.failure(
        totalFiles: totalFiles,
        errors: errors,
        duration: duration,
      );
    }
  }

  @override
  Future<BatchOperationResult> downloadMultipleFilesWithProgress(
    List<String> keys, {
    void Function(BatchOperationProgress)? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    final startTime = DateTime.now();
    final totalFiles = keys.length;
    final successfulKeys = <String>[];
    final errors = <String, String>{};
    
    // Check for cancellation before starting
    cancellationToken?.throwIfCancelled();
    
    // Handle empty operation
    if (keys.isEmpty) {
      final duration = DateTime.now().difference(startTime);
      onProgress?.call(BatchOperationProgress(
        totalFiles: 0,
        processedFiles: 0,
        successfulFiles: 0,
        failedFiles: 0,
        elapsed: duration,
      ));
      return BatchOperationResult.success(
        totalFiles: 0,
        successfulKeys: [],
        duration: duration,
      );
    }
    
    // Check network and initialization, but handle errors gracefully
    bool canProceed = true;
    String? initError;
    
    try {
      if (!await _networkInfo.isConnected) {
        throw NetworkException('No internet connection');
      }
      await _ensureInitialized();
    } catch (e) {
      canProceed = false;
      initError = e.toString();
    }
    
    int processedFiles = 0;
    
    for (final key in keys) {
      // Check for cancellation
      cancellationToken?.throwIfCancelled();
      
      // Report progress
      onProgress?.call(BatchOperationProgress(
        totalFiles: totalFiles,
        processedFiles: processedFiles,
        successfulFiles: successfulKeys.length,
        failedFiles: errors.length,
        currentFile: key,
        elapsed: DateTime.now().difference(startTime),
      ));
      
      if (!canProceed) {
        errors[key] = initError!;
      } else {
        try {
          await downloadFile(key); // Just test if download works
          successfulKeys.add(key);
        } catch (e) {
          errors[key] = e.toString();
        }
      }
      
      processedFiles++;
    }
    
    final duration = DateTime.now().difference(startTime);
    
    // Final progress report
    onProgress?.call(BatchOperationProgress(
      totalFiles: totalFiles,
      processedFiles: processedFiles,
      successfulFiles: successfulKeys.length,
      failedFiles: errors.length,
      elapsed: duration,
    ));
    
    if (errors.isEmpty) {
      return BatchOperationResult.success(
        totalFiles: totalFiles,
        successfulKeys: successfulKeys,
        duration: duration,
      );
    } else if (successfulKeys.isNotEmpty) {
      return BatchOperationResult.partial(
        totalFiles: totalFiles,
        successfulKeys: successfulKeys,
        errors: errors,
        duration: duration,
      );
    } else {
      return BatchOperationResult.failure(
        totalFiles: totalFiles,
        errors: errors,
        duration: duration,
      );
    }
  }

  @override
  Future<BatchOperationResult> deleteMultipleFilesWithProgress(
    List<String> keys, {
    void Function(BatchOperationProgress)? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    final startTime = DateTime.now();
    final totalFiles = keys.length;
    final successfulKeys = <String>[];
    final errors = <String, String>{};
    
    // Check for cancellation before starting
    cancellationToken?.throwIfCancelled();
    
    // Handle empty operation
    if (keys.isEmpty) {
      final duration = DateTime.now().difference(startTime);
      onProgress?.call(BatchOperationProgress(
        totalFiles: 0,
        processedFiles: 0,
        successfulFiles: 0,
        failedFiles: 0,
        elapsed: duration,
      ));
      return BatchOperationResult.success(
        totalFiles: 0,
        successfulKeys: [],
        duration: duration,
      );
    }
    
    // Check network and initialization, but handle errors gracefully
    bool canProceed = true;
    String? initError;
    
    try {
      if (!await _networkInfo.isConnected) {
        throw NetworkException('No internet connection');
      }
      await _ensureInitialized();
    } catch (e) {
      canProceed = false;
      initError = e.toString();
    }
    
    int processedFiles = 0;
    
    for (final key in keys) {
      // Check for cancellation
      cancellationToken?.throwIfCancelled();
      
      // Report progress
      onProgress?.call(BatchOperationProgress(
        totalFiles: totalFiles,
        processedFiles: processedFiles,
        successfulFiles: successfulKeys.length,
        failedFiles: errors.length,
        currentFile: key,
        elapsed: DateTime.now().difference(startTime),
      ));
      
      if (!canProceed) {
        errors[key] = initError!;
      } else {
        try {
          await deleteFile(key);
          successfulKeys.add(key);
        } catch (e) {
          errors[key] = e.toString();
        }
      }
      
      processedFiles++;
    }
    
    final duration = DateTime.now().difference(startTime);
    
    // Final progress report
    onProgress?.call(BatchOperationProgress(
      totalFiles: totalFiles,
      processedFiles: processedFiles,
      successfulFiles: successfulKeys.length,
      failedFiles: errors.length,
      elapsed: duration,
    ));
    
    if (errors.isEmpty) {
      return BatchOperationResult.success(
        totalFiles: totalFiles,
        successfulKeys: successfulKeys,
        duration: duration,
      );
    } else if (successfulKeys.isNotEmpty) {
      return BatchOperationResult.partial(
        totalFiles: totalFiles,
        successfulKeys: successfulKeys,
        errors: errors,
        duration: duration,
      );
    } else {
      return BatchOperationResult.failure(
        totalFiles: totalFiles,
        errors: errors,
        duration: duration,
      );
    }
  }

  @override
  Future<BatchOperationResult> uploadFolderRecursively(
    String folderPath,
    Map<String, String> files, {
    void Function(BatchOperationProgress)? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    // Check for cancellation before starting
    cancellationToken?.throwIfCancelled();
    
    // First create the folder marker
    try {
      await createFolder(folderPath);
    } catch (e) {
      // Ignore if folder already exists
    }
    
    // Then upload all files in the folder
    return uploadMultipleFilesWithProgress(
      files,
      onProgress: onProgress,
      cancellationToken: cancellationToken,
    );
  }

  @override
  Future<BatchOperationResult> downloadFolderRecursively(
    String folderPath, {
    void Function(BatchOperationProgress)? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    // Check for cancellation before starting
    cancellationToken?.throwIfCancelled();
    
    try {
      if (!await _networkInfo.isConnected) {
        throw NetworkException('No internet connection');
      }
      
      await _ensureInitialized();
      
      // List all files in the folder
      final files = await listFiles(folderPath);
      
      // Download all files
      return downloadMultipleFilesWithProgress(
        files,
        onProgress: onProgress,
        cancellationToken: cancellationToken,
      );
    } catch (e) {
      return BatchOperationResult.failure(
        totalFiles: 0,
        errors: {folderPath: e.toString()},
        duration: Duration.zero,
      );
    }
  }

  @override
  Future<BatchOperationResult> deleteFolderRecursively(
    String folderPath, {
    void Function(BatchOperationProgress)? onProgress,
    CancellationToken? cancellationToken,
  }) async {
    // Check for cancellation before starting
    cancellationToken?.throwIfCancelled();
    
    try {
      if (!await _networkInfo.isConnected) {
        throw NetworkException('No internet connection');
      }
      
      await _ensureInitialized();
      
      // List all files in the folder
      final files = await listFiles(folderPath);
      
      // Delete all files first
      final result = await deleteMultipleFilesWithProgress(
        files,
        onProgress: onProgress,
        cancellationToken: cancellationToken,
      );
      
      // Then delete the folder marker
      try {
        await deleteFolder(folderPath);
      } catch (e) {
        // Add folder deletion error if files were deleted successfully
        if (result.success) {
          return BatchOperationResult.partial(
            totalFiles: result.totalFiles + 1,
            successfulKeys: result.successfulKeys,
            errors: {folderPath: e.toString()},
            duration: result.duration,
          );
        }
      }
      
      return result;
    } catch (e) {
      return BatchOperationResult.failure(
        totalFiles: 0,
        errors: {folderPath: e.toString()},
        duration: Duration.zero,
      );
    }
  }

  /// Get content type based on file extension
  String _getContentType(String key) {
    if (key.endsWith('.md')) {
      return 'text/markdown';
    } else if (key.endsWith('.json')) {
      return 'application/json';
    } else if (key.endsWith('.txt')) {
      return 'text/plain';
    } else {
      return 'application/octet-stream';
    }
  }
}