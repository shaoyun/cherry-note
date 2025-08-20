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
    group('单个文件冲突检测', () {
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

      test('相似内容应该检测到时间戳冲突', () async {
        // Arrange
        const filePath = '/test/file.md';
        const localContent = '# Test File\n\nThis is a test file.';
        const remoteContent = '# Test File\n\nThis is a test file!'; // 只有标点差异
        
        await cacheService.cacheFile(filePath, localContent);
        when(mockStorageRepository.downloadFile(filePath))
            .thenAnswer((_) async => remoteContent);

        // Act
        final result = await detectionService.detectFileConflict(filePath);

        // Assert
        expect(result, isNotNull);
        expect(result!.type, equals(ConflictType.timestampConflict));
      });
    });

    group('批量冲突检测', () {
      test('应该能够检测多个文件的冲突', () async {
        // Arrange
        const files = ['/test/file1.md', '/test/file2.md', '/test/file3.md'];
        const localContent = 'Local content';
        const remoteContent = 'Remote content';

        for (final file in files) {
          await cacheService.cacheFile(file, localContent);
          when(mockStorageRepository.downloadFile(file))
              .thenAnswer((_) async => remoteContent);
        }

        // Act
        final results = await detectionService.detectConflicts(files);

        // Assert
        expect(results.length, equals(3));
        expect(results.every((r) => r.type == ConflictType.contentConflict), isTrue);
      });

      test('应该能够检测所有冲突', () async {
        // Arrange
        const localFiles = ['/test/local1.md', '/test/local2.md'];
        const remoteFiles = ['/test/remote1.md', '/test/remote2.md'];
        const sharedFiles = ['/test/shared.md'];

        // 设置本地文件
        for (final file in [...localFiles, ...sharedFiles]) {
          await cacheService.cacheFile(file, 'Local content');
        }

        // 设置远程文件
        when(mockStorageRepository.listFiles(''))
            .thenAnswer((_) async => [...remoteFiles, ...sharedFiles]);

        for (final file in [...remoteFiles, ...sharedFiles]) {
          when(mockStorageRepository.downloadFile(file))
              .thenAnswer((_) async => 'Remote content');
        }

        // 本地独有文件在远程不存在
        for (final file in localFiles) {
          when(mockStorageRepository.downloadFile(file))
              .thenThrow(Exception('File not found'));
        }

        // Act
        final results = await detectionService.detectAllConflicts();

        // Assert
        expect(results.isNotEmpty, isTrue);
        // 应该检测到删除冲突和内容冲突
        expect(results.any((r) => r.type == ConflictType.deleteConflict), isTrue);
        expect(results.any((r) => r.type == ConflictType.contentConflict), isTrue);
      });
    });

    group('冲突严重程度分析', () {
      test('相似内容应该是低严重程度', () async {
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

      test('差异较大的内容应该是高严重程度', () async {
        // Arrange
        final conflict = FileConflict(
          filePath: '/test/file.md',
          localModified: DateTime(2024, 1, 1, 10, 0),
          remoteModified: DateTime(2024, 1, 2, 10, 0),
          localContent: 'This is the local version with completely different content.',
          remoteContent: 'Remote version has totally different text and structure.',
        );

        // Act
        final severity = detectionService.analyzeConflictSeverity(conflict);

        // Assert
        expect(severity, equals(ConflictSeverity.high));
      });
    });

    group('解决方案建议', () {
      test('内容冲突应该建议合并策略', () async {
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

      test('时间戳冲突应该建议保留策略', () async {
        // Arrange
        final result = ConflictDetectionResult(
          filePath: '/test/file.md',
          type: ConflictType.timestampConflict,
          severity: ConflictSeverity.low,
          description: 'Timestamp conflict detected',
        );

        // Act
        final suggestions = detectionService.getSuggestedResolutions(result);

        // Assert
        expect(suggestions, contains(ConflictResolution.keepLocal));
        expect(suggestions, contains(ConflictResolution.keepRemote));
        expect(suggestions.length, equals(2));
      });

      test('创建冲突应该建议创建两个版本', () async {
        // Arrange
        final result = ConflictDetectionResult(
          filePath: '/test/file.md',
          type: ConflictType.createConflict,
          severity: ConflictSeverity.medium,
          description: 'Create conflict detected',
        );

        // Act
        final suggestions = detectionService.getSuggestedResolutions(result);

        // Assert
        expect(suggestions, contains(ConflictResolution.createBoth));
        expect(suggestions.first, equals(ConflictResolution.createBoth));
      });
    });

    group('自动解决策略', () {
      test('低严重程度的时间戳冲突应该可以自动解决', () async {
        // Arrange
        final result = ConflictDetectionResult(
          filePath: '/test/file.md',
          type: ConflictType.timestampConflict,
          severity: ConflictSeverity.low,
          description: 'Timestamp conflict detected',
        );

        // Act
        final autoResolution = detectionService.getAutoResolution(result);

        // Assert
        expect(autoResolution, isNotNull);
        expect(autoResolution, equals(ConflictResolution.keepRemote));
      });

      test('高严重程度的冲突不应该自动解决', () async {
        // Arrange
        final result = ConflictDetectionResult(
          filePath: '/test/file.md',
          type: ConflictType.contentConflict,
          severity: ConflictSeverity.high,
          description: 'High severity content conflict',
        );

        // Act
        final autoResolution = detectionService.getAutoResolution(result);

        // Assert
        expect(autoResolution, isNull);
      });
    });

    group('冲突预览', () {
      test('应该能够预览保留本地版本的结果', () async {
        // Arrange
        const conflict = FileConflict(
          filePath: '/test/file.md',
          localModified: DateTime(2024, 1, 1),
          remoteModified: DateTime(2024, 1, 2),
          localContent: 'Local content',
          remoteContent: 'Remote content',
        );

        // Act
        final preview = await detectionService.previewResolution(
          conflict,
          ConflictResolution.keepLocal,
        );

        // Assert
        expect(preview, equals('Local content'));
      });

      test('应该能够预览保留远程版本的结果', () async {
        // Arrange
        const conflict = FileConflict(
          filePath: '/test/file.md',
          localModified: DateTime(2024, 1, 1),
          remoteModified: DateTime(2024, 1, 2),
          localContent: 'Local content',
          remoteContent: 'Remote content',
        );

        // Act
        final preview = await detectionService.previewResolution(
          conflict,
          ConflictResolution.keepRemote,
        );

        // Assert
        expect(preview, equals('Remote content'));
      });

      test('应该能够预览合并结果', () async {
        // Arrange
        const conflict = FileConflict(
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
  });
}