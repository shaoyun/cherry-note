import 'package:injectable/injectable.dart';
import '../../features/sync/domain/entities/s3_config.dart';
import '../../features/sync/domain/repositories/s3_storage_repository.dart';

/// Result of S3 connection test
class S3ConnectionTestResult {
  final bool success;
  final String? error;
  final String? message;
  final Duration? responseTime;

  const S3ConnectionTestResult({
    required this.success,
    this.error,
    this.message,
    this.responseTime,
  });

  factory S3ConnectionTestResult.success({
    String? message,
    Duration? responseTime,
  }) {
    return S3ConnectionTestResult(
      success: true,
      message: message ?? 'Connection successful',
      responseTime: responseTime,
    );
  }

  factory S3ConnectionTestResult.failure({
    required String error,
  }) {
    return S3ConnectionTestResult(
      success: false,
      error: error,
    );
  }
}

/// Service for testing S3 connections
abstract class S3ConnectionTestService {
  Future<S3ConnectionTestResult> testConnection(S3Config config);
  Future<S3ConnectionTestResult> testBucketAccess(S3Config config);
  Future<S3ConnectionTestResult> testWritePermissions(S3Config config);
}

/// Implementation of S3ConnectionTestService
@LazySingleton(as: S3ConnectionTestService)
class S3ConnectionTestServiceImpl implements S3ConnectionTestService {
  final S3StorageRepository _s3Repository;

  S3ConnectionTestServiceImpl(this._s3Repository);

  @override
  Future<S3ConnectionTestResult> testConnection(S3Config config) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Validate config first
      if (!config.isValid) {
        return S3ConnectionTestResult.failure(
          error: 'Invalid S3 configuration. Please check all required fields.',
        );
      }

      // Initialize repository with config
      await _s3Repository.initialize(config);
      
      // Test basic connection
      final isConnected = await _s3Repository.testConnection();
      stopwatch.stop();
      
      if (isConnected) {
        return S3ConnectionTestResult.success(
          message: 'Successfully connected to S3 endpoint',
          responseTime: stopwatch.elapsed,
        );
      } else {
        return S3ConnectionTestResult.failure(
          error: 'Failed to connect to S3 endpoint. Please check your configuration.',
        );
      }
    } catch (e) {
      stopwatch.stop();
      return S3ConnectionTestResult.failure(
        error: 'Connection failed: ${e.toString()}',
      );
    }
  }

  @override
  Future<S3ConnectionTestResult> testBucketAccess(S3Config config) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // First test basic connection
      final connectionResult = await testConnection(config);
      if (!connectionResult.success) {
        return connectionResult;
      }

      // Test bucket access by listing objects
      await _s3Repository.listFiles('');
      stopwatch.stop();
      
      return S3ConnectionTestResult.success(
        message: 'Successfully accessed bucket: ${config.bucketName}',
        responseTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      String errorMessage = 'Bucket access failed: ${e.toString()}';
      
      if (e.toString().contains('NoSuchBucket')) {
        errorMessage = 'Bucket "${config.bucketName}" does not exist or is not accessible.';
      } else if (e.toString().contains('AccessDenied')) {
        errorMessage = 'Access denied to bucket "${config.bucketName}". Please check your credentials.';
      }
      
      return S3ConnectionTestResult.failure(error: errorMessage);
    }
  }

  @override
  Future<S3ConnectionTestResult> testWritePermissions(S3Config config) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // First test bucket access
      final bucketResult = await testBucketAccess(config);
      if (!bucketResult.success) {
        return bucketResult;
      }

      // Test write permissions by uploading a test file
      const testFileName = '.cherry_note_connection_test';
      const testContent = 'Cherry Note connection test - you can safely delete this file';
      
      await _s3Repository.uploadFile(testFileName, testContent);
      
      // Verify the file was uploaded
      final exists = await _s3Repository.fileExists(testFileName);
      if (!exists) {
        return S3ConnectionTestResult.failure(
          error: 'Failed to verify uploaded test file',
        );
      }
      
      // Clean up test file
      try {
        await _s3Repository.deleteFile(testFileName);
      } catch (e) {
        // Ignore cleanup errors
      }
      
      stopwatch.stop();
      
      return S3ConnectionTestResult.success(
        message: 'Successfully tested write permissions to bucket: ${config.bucketName}',
        responseTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      String errorMessage = 'Write permission test failed: ${e.toString()}';
      
      if (e.toString().contains('AccessDenied')) {
        errorMessage = 'Write access denied to bucket "${config.bucketName}". Please check your credentials have write permissions.';
      }
      
      return S3ConnectionTestResult.failure(error: errorMessage);
    }
  }
}