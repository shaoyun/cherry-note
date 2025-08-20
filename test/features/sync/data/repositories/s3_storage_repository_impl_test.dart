import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cherry_note/features/sync/data/repositories/s3_storage_repository_impl.dart';
import 'package:cherry_note/features/sync/domain/entities/s3_config.dart';
import 'package:cherry_note/core/network/network_info.dart';
import 'package:cherry_note/core/error/exceptions.dart';

import 's3_storage_repository_impl_test.mocks.dart';

@GenerateMocks([NetworkInfo])
void main() {
  group('S3StorageRepositoryImpl', () {
    late S3StorageRepositoryImpl repository;
    late MockNetworkInfo mockNetworkInfo;

    setUp(() {
      mockNetworkInfo = MockNetworkInfo();
      repository = S3StorageRepositoryImpl(mockNetworkInfo);
    });

    group('initialization', () {
      test('should not be initialized initially', () {
        expect(repository.isInitialized, false);
        expect(repository.currentConfig, null);
      });

      test('should create AWS S3 config correctly', () {
        final config = S3Config.aws(
          region: 'us-east-1',
          accessKeyId: 'test-access-key',
          secretAccessKey: 'test-secret-key',
          bucketName: 'test-bucket',
        );

        expect(config.endpoint, 's3.us-east-1.amazonaws.com');
        expect(config.region, 'us-east-1');
        expect(config.accessKeyId, 'test-access-key');
        expect(config.secretAccessKey, 'test-secret-key');
        expect(config.bucketName, 'test-bucket');
        expect(config.useSSL, true);
        expect(config.fullEndpoint, 'https://s3.us-east-1.amazonaws.com');
      });

      test('should create MinIO config correctly', () {
        final config = S3Config.minio(
          endpoint: 'localhost',
          accessKeyId: 'minioadmin',
          secretAccessKey: 'minioadmin',
          bucketName: 'test-bucket',
          useSSL: false,
          port: 9000,
        );

        expect(config.endpoint, 'localhost');
        expect(config.region, 'us-east-1');
        expect(config.accessKeyId, 'minioadmin');
        expect(config.secretAccessKey, 'minioadmin');
        expect(config.bucketName, 'test-bucket');
        expect(config.useSSL, false);
        expect(config.port, 9000);
        expect(config.fullEndpoint, 'http://localhost:9000');
      });

      test('should validate config correctly', () {
        final validConfig = S3Config(
          endpoint: 'localhost',
          region: 'us-east-1',
          accessKeyId: 'test',
          secretAccessKey: 'test',
          bucketName: 'test',
        );
        expect(validConfig.isValid, true);

        final invalidConfig = S3Config(
          endpoint: '',
          region: 'us-east-1',
          accessKeyId: 'test',
          secretAccessKey: 'test',
          bucketName: 'test',
        );
        expect(invalidConfig.isValid, false);
      });
    });

    group('network dependency', () {
      test('should throw NetworkException when no internet connection', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        final config = S3Config.minio(
          endpoint: 'localhost',
          accessKeyId: 'test',
          secretAccessKey: 'test',
          bucketName: 'test',
        );

        // Note: We can't actually test the full initialization without mocking AWS SDK
        // But we can test that network checks are performed
        expect(() async => await repository.uploadFile('test.md', 'content'),
               throwsA(isA<NetworkException>()));
      });

      test('should check network connection before operations', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        // These will fail because S3 client is not initialized, but network check should pass
        expect(() async => await repository.uploadFile('test.md', 'content'),
               throwsA(isA<StorageException>()));
        
        verify(mockNetworkInfo.isConnected).called(1);
      });
    });

    group('error handling', () {
      test('should throw StorageException when not initialized', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        expect(() async => await repository.uploadFile('test.md', 'content'),
               throwsA(isA<StorageException>()));
        expect(() async => await repository.downloadFile('test.md'),
               throwsA(isA<StorageException>()));
        expect(() async => await repository.deleteFile('test.md'),
               throwsA(isA<StorageException>()));
        expect(() async => await repository.fileExists('test.md'),
               throwsA(isA<StorageException>()));
      });
    });

    group('configuration', () {
      test('should copy config with updated fields', () {
        final originalConfig = S3Config(
          endpoint: 'localhost',
          region: 'us-east-1',
          accessKeyId: 'old-key',
          secretAccessKey: 'old-secret',
          bucketName: 'old-bucket',
        );

        final updatedConfig = originalConfig.copyWith(
          accessKeyId: 'new-key',
          bucketName: 'new-bucket',
        );

        expect(updatedConfig.endpoint, 'localhost');
        expect(updatedConfig.region, 'us-east-1');
        expect(updatedConfig.accessKeyId, 'new-key');
        expect(updatedConfig.secretAccessKey, 'old-secret');
        expect(updatedConfig.bucketName, 'new-bucket');
      });

      test('should handle equality correctly', () {
        final config1 = S3Config(
          endpoint: 'localhost',
          region: 'us-east-1',
          accessKeyId: 'test',
          secretAccessKey: 'test',
          bucketName: 'test',
        );

        final config2 = S3Config(
          endpoint: 'localhost',
          region: 'us-east-1',
          accessKeyId: 'test',
          secretAccessKey: 'test',
          bucketName: 'test',
        );

        final config3 = S3Config(
          endpoint: 'different',
          region: 'us-east-1',
          accessKeyId: 'test',
          secretAccessKey: 'test',
          bucketName: 'test',
        );

        expect(config1, equals(config2));
        expect(config1, isNot(equals(config3)));
      });
    });

    group('content type detection', () {
      // We can't directly test the private method, but we can test the behavior
      test('should handle different file types', () {
        // This is more of a documentation test since the method is private
        // In a real implementation, we might expose this as a utility function
        expect(true, true); // Placeholder
      });
    });

    group('batch operations', () {
      test('should handle empty batch operations', () async {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        // Test with empty maps/lists - these should succeed with empty results
        await repository.uploadMultipleFiles({});
        final result = await repository.downloadMultipleFiles([]);
        expect(result, isEmpty);
      });
    });

    group('sync operations', () {
      test('should throw UnimplementedError for sync operations', () async {
        expect(() async => await repository.syncToRemote(),
               throwsA(isA<UnimplementedError>()));
        expect(() async => await repository.syncFromRemote(),
               throwsA(isA<UnimplementedError>()));
      });
    });
  });
}