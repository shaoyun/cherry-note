import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cherry_note/features/sync/domain/services/conflict_detection_service.dart';
import 'package:cherry_note/features/sync/domain/services/sync_service.dart';
import 'package:cherry_note/features/sync/domain/repositories/s3_storage_repository.dart';
import 'package:cherry_note/features/sync/data/datasources/sqlite_cache_service.dart';

// 生成Mock类
@GenerateMocks([S3StorageRepository])
import 'conflict_detection_service_test.mocks.dart';

void main() {
  late ConflictDetectionServiceImpl detectionService;
  late MockS3StorageRepository mockStorageRepository;
  late SqliteCacheService cacheService;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    mockStorageRepository = MockS3StorageRepository();
    cacheService = SqliteCacheService(databasePath: ':memory:');
    await cacheService.initialize();

    detectionService = ConflictDetectionServiceImpl(
      cacheService: cacheService,
      storageRepository: mockStorageRepository,
    );
  });

  tearDown(() async {
    await cacheService.close();
  });

  group('ConflictDetectionServiceImpl', () {
    test('相同内容应该没有冲突', () async {
      // Arrange
      const filePath = '/test/file.md';
      const content = '# Test File\n\nThis is a test.';
      
      await cacheService.cacheFile(filePath, content);
      when(mockStorageRepository.downloadFile(filePath))
          .thenAnswer((_) async => content);

      // Act
      final result = await detectionService.detectFileConflict(filePath);

      // Assert
      expect(result, isNull);
    });

    test('不同内容应该检测到内容冲突', () async {
      // Arrange
      const filePath = '/test/file.md';
      const localContent = '# Test File\n\nLocal version.';
      const remoteContent = '# Test File\n\nRemote version.';
      
      await cacheService.cacheFile(filePath, localContent);
      when(mockStorageRepository.downloadFile(filePath))
          .thenAnswer((_) async => remoteContent);

      // Act
      final result = await detectionService.detectFileConflict(filePath);

      // Assert
      expect(result, isNotNull);
      expect(result!.type, equals(ConflictType.contentConflict));
      expect(result.conflict, isNotNull);
      expect(result.conflict!.localContent, equals(localContent));
      expect(result.conflict!.remoteContent, equals(remoteContent));
    });

    test('本地存在远程不存在应该检测到删除冲突', () async {
      // Arrange
      const filePath = '/test/file.md';
      const localContent = '# Test File';
      
      await cacheService.cacheFile(filePath, localContent);
      when(mockStorageRepository.downloadFile(filePath))
          .thenThrow(Exception('File not found'));

      // Act
      final result = await detectionService.detectFileConflict(filePath);

      // Assert
      expect(result, isNotNull);
      expect(result!.type, equals(ConflictType.deleteConflict));
    });

    test('应该能够分析冲突严重程度', () async {
      // Arrange
      final conflict = FileConflict(
        filePath: '/test/file.md',
        localModified: DateTime(2024, 1, 1, 10, 0),
        remoteModified: DateTime(2024, 1, 1, 10, 5),
        localContent: 'This is a test file.',
        remoteContent: 'This is a test file!', // 只有标点差异
      );

      // Act
      final severity = detectionService.analyzeConflictSeverity(conflict);

      // Assert
      expect(severity, equals(ConflictSeverity.low));
    });

    test('应该能够获取建议的解决方案', () async {
      // Arrange
      final result = ConflictDetectionResult(
        filePath: '/test/file.md',
        type: ConflictType.contentConflict,
        severity: ConflictSeverity.medium,
        description: 'Content conflict detected',
      );

      // Act
      final suggestions = detectionService.getSuggestedResolutions(result);

      // Assert
      expect(suggestions, contains(ConflictResolution.merge));
      expect(suggestions, contains(ConflictResolution.keepLocal));
      expect(suggestions, contains(ConflictResolution.keepRemote));
      expect(suggestions, contains(ConflictResolution.createBoth));
    });

    test('应该能够预览合并结果', () async {
      // Arrange
      final conflict = FileConflict(
        filePath: '/test/file.md',
        localModified: DateTime(2024, 1, 1),
        remoteModified: DateTime(2024, 1, 2),
        localContent: 'Line 1\nLocal line 2\nLine 3',
        remoteContent: 'Line 1\nRemote line 2\nLine 3',
      );

      // Act
      final preview = await detectionService.previewResolution(
        conflict,
        ConflictResolution.merge,
      );

      // Assert
      expect(preview, contains('<<<<<<< LOCAL'));
      expect(preview, contains('======='));
      expect(preview, contains('>>>>>>> REMOTE'));
      expect(preview, contains('Local line 2'));
      expect(preview, contains('Remote line 2'));
    });
  });
}