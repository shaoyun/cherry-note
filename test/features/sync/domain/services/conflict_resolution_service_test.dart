import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cherry_note/features/sync/domain/services/conflict_resolution_service.dart';
import 'package:cherry_note/features/sync/domain/services/conflict_detection_service.dart';
import 'package:cherry_note/features/sync/domain/services/sync_service.dart';
import 'package:cherry_note/features/sync/domain/repositories/s3_storage_repository.dart';
import 'package:cherry_note/features/sync/data/datasources/sqlite_cache_service.dart';

// 生成Mock类
@GenerateMocks([S3StorageRepository, ConflictDetectionService])
import 'conflict_resolution_service_test.mocks.dart';

void main() {
  late ConflictResolutionServiceImpl resolutionService;
  late MockS3StorageRepository mockStorageRepository;
  late MockConflictDetectionService mockDetectionService;
  late SqliteCacheService cacheService;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    mockStorageRepository = MockS3StorageRepository();
    mockDetectionService = MockConflictDetectionService();
    cacheService = SqliteCacheService(databasePath: ':memory:');
    await cacheService.initialize();

    resolutionService = ConflictResolutionServiceImpl(
      cacheService: cacheService,
      storageRepository: mockStorageRepository,
      detectionService: mockDetectionService,
    );
  });

  tearDown(() async {
    await cacheService.close();
  });

  group('ConflictResolutionServiceImpl', () {
    group('单个冲突解决', () {
      test('保留本地版本应该上传本地内容', () async {
        // Arrange
        const conflict = FileConflict(
          filePath: '/test/file.md',
          localModified: DateTime(2024, 1, 1),
          remoteModified: DateTime(2024, 1, 2),
          localContent: 'Local content',
          remoteContent: 'Remote content',
        );

        when(mockStorageRepository.uploadFile(conflict.filePath, conflict.localContent))
            .thenAnswer((_) async {});

        // Act
        final result = await resolutionService.resolveConflict(
          conflict,
          ConflictResolution.keepLocal,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.resolution, equals(ConflictResolution.keepLocal));
        expect(result.resultContent, equals(conflict.localContent));
        verify(mockStorageRepository.uploadFile(conflict.filePath, conflict.localContent)).called(1);
      });

      test('保留远程版本应该更新本地缓存', () async {
        // Arrange
        const conflict = FileConflict(
          filePath: '/test/file.md',
          localModified: DateTime(2024, 1, 1),
          remoteModified: DateTime(2024, 1, 2),
          localContent: 'Local content',
          remoteContent: 'Remote content',
        );

        // Act
        final result = await resolutionService.resolveConflict(
          conflict,
          ConflictResolution.keepRemote,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.resolution, equals(ConflictResolution.keepRemote));
        expect(result.resultContent, equals(conflict.remoteContent));
        
        final cachedContent = await cacheService.getCachedFile(conflict.filePath);
        expect(cachedContent, equals(conflict.remoteContent));
      });

      test('合并版本应该创建合并内容', () async {
        // Arrange
        const conflict = FileConflict(
          filePath: '/test/file.md',
          localModified: DateTime(2024, 1, 1),
          remoteModified: DateTime(2024, 1, 2),
          localContent: 'Line 1\nLocal line 2\nLine 3',
          remoteContent: 'Line 1\nRemote line 2\nLine 3',
        );

        when(mockStorageRepository.uploadFile(any, any)).thenAnswer((_) async {});

        // Act
        final result = await resolutionService.resolveConflict(
          conflict,
          ConflictResolution.merge,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.resolution, equals(ConflictResolution.merge));
        expect(result.resultContent, isNotNull);
        expect(result.resultContent!, contains('<<<<<<< LOCAL'));
        expect(result.resultContent!, contains('======='));
        expect(result.resultContent!, contains('>>>>>>> REMOTE'));
      });

      test('创建两个版本应该创建两个文件', () async {
        // Arrange
        const conflict = FileConflict(
          filePath: '/test/file.md',
          localModified: DateTime(2024, 1, 1),
          remoteModified: DateTime(2024, 1, 2),
          localContent: 'Local content',
          remoteContent: 'Remote content',
        );

        when(mockStorageRepository.uploadFile(any, any)).thenAnswer((_) async {});
        when(mockStorageRepository.deleteFile(conflict.filePath)).thenAnswer((_) async {});

        // Act
        final result = await resolutionService.resolveConflict(
          conflict,
          ConflictResolution.createBoth,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.resolution, equals(ConflictResolution.createBoth));
        expect(result.createdFiles.length, equals(2));
        expect(result.createdFiles, contains('${conflict.filePath}_local'));
        expect(result.createdFiles, contains('${conflict.filePath}_remote'));
        
        verify(mockStorageRepository.uploadFile('${conflict.filePath}_local', conflict.localContent)).called(1);
        verify(mockStorageRepository.uploadFile('${conflict.filePath}_remote', conflict.remoteContent)).called(1);
        verify(mockStorageRepository.deleteFile(conflict.filePath)).called(1);
      });
    });

    group('批量冲突解决', () {
      test('应该能够批量解决冲突', () async {
        // Arrange
        final conflicts = [
          const FileConflict(
            filePath: '/test/file1.md',
            localModified: DateTime(2024, 1, 1),
            remoteModified: DateTime(2024, 1, 2),
            localContent: 'Local content 1',
            remoteContent: 'Remote content 1',
          ),
          const FileConflict(
            filePath: '/test/file2.md',
            localModified: DateTime(2024, 1, 1),
            remoteModified: DateTime(2024, 1, 2),
            localContent: 'Local content 2',
            remoteContent: 'Remote content 2',
          ),
        ];

        const strategy = ConflictResolutionStrategy(
          defaultResolution: ConflictResolution.keepLocal,
          autoResolveWhenPossible: false,
          createBackups: false,
        );

        when(mockStorageRepository.uploadFile(any, any)).thenAnswer((_) async {});

        // Act
        final result = await resolutionService.resolveConflicts(conflicts, strategy);

        // Assert
        expect(result.allSuccessful, isTrue);
        expect(result.successCount, equals(2));
        expect(result.failureCount, equals(0));
        
        for (final conflict in conflicts) {
          verify(mockStorageRepository.uploadFile(conflict.filePath, conflict.localContent)).called(1);
        }
      });

      test('应该能够自动解决可自动处理的冲突', () async {
        // Arrange
        const detectionResult = ConflictDetectionResult(
          filePath: '/test/file.md',
          type: ConflictType.timestampConflict,
          severity: ConflictSeverity.low,
          conflict: FileConflict(
            filePath: '/test/file.md',
            localModified: DateTime(2024, 1, 1),
            remoteModified: DateTime(2024, 1, 2),
            localContent: 'Content',
            remoteContent: 'Content',
          ),
          description: 'Timestamp conflict',
          autoResolution: ConflictResolution.keepRemote,
        );

        // Act
        final result = await resolutionService.autoResolveConflicts([detectionResult]);

        // Assert
        expect(result.successCount, equals(1));
        expect(result.results.first.resolution, equals(ConflictResolution.keepRemote));
      });
    });

    group('备份管理', () {
      test('应该能够创建备份', () async {
        // Arrange
        const filePath = '/test/file.md';
        const content = 'File content';

        // Act
        final backupPath = await resolutionService.createBackup(filePath, content);

        // Assert
        expect(backupPath, contains('.backup.'));
        
        final backupContent = await cacheService.getCachedFile(backupPath);
        expect(backupContent, equals(content));
        
        final backupSetting = await cacheService.getSetting('backup_${filePath.replaceAll('/', '_')}');
        expect(backupSetting, equals(backupPath));
      });

      test('应该能够恢复备份', () async {
        // Arrange
        const originalPath = '/test/file.md';
        const backupContent = 'Backup content';
        
        final backupPath = await resolutionService.createBackup(originalPath, backupContent);
        when(mockStorageRepository.uploadFile(originalPath, backupContent)).thenAnswer((_) async {});

        // Act
        await resolutionService.restoreBackup(backupPath, originalPath);

        // Assert
        final restoredContent = await cacheService.getCachedFile(originalPath);
        expect(restoredContent, equals(backupContent));
        verify(mockStorageRepository.uploadFile(originalPath, backupContent)).called(1);
        
        // 备份应该被清理
        final backupExists = await cacheService.isCached(backupPath);
        expect(backupExists, isFalse);
      });

      test('应该能够清理旧备份', () async {
        // Arrange
        const filePath = '/test/file.md';
        const content = 'Content';
        
        // 创建一个"旧"备份（通过直接设置时间戳）
        final oldTimestamp = DateTime.now().subtract(const Duration(days: 10)).millisecondsSinceEpoch;
        final oldBackupPath = '$filePath.backup.$oldTimestamp';
        await cacheService.cacheFile(oldBackupPath, content);
        await cacheService.setSetting('backup_${filePath.replaceAll('/', '_')}', oldBackupPath);

        // Act
        await resolutionService.cleanupBackups(olderThan: const Duration(days: 7));

        // Assert
        final backupExists = await cacheService.isCached(oldBackupPath);
        expect(backupExists, isFalse);
        
        final backupSetting = await cacheService.getSetting('backup_${filePath.replaceAll('/', '_')}');
        expect(backupSetting, isNull);
      });
    });

    group('预览功能', () {
      test('应该能够预览解决结果', () async {
        // Arrange
        const conflict = FileConflict(
          filePath: '/test/file.md',
          localModified: DateTime(2024, 1, 1),
          remoteModified: DateTime(2024, 1, 2),
          localContent: 'Local content',
          remoteContent: 'Remote content',
        );

        when(mockDetectionService.previewResolution(conflict, ConflictResolution.keepLocal))
            .thenAnswer((_) async => conflict.localContent);

        // Act
        final preview = await resolutionService.previewResolution(
          conflict,
          ConflictResolution.keepLocal,
        );

        // Assert
        expect(preview, equals(conflict.localContent));
        verify(mockDetectionService.previewResolution(conflict, ConflictResolution.keepLocal)).called(1);
      });
    });

    group('错误处理', () {
      test('解决冲突失败时应该返回错误结果', () async {
        // Arrange
        const conflict = FileConflict(
          filePath: '/test/file.md',
          localModified: DateTime(2024, 1, 1),
          remoteModified: DateTime(2024, 1, 2),
          localContent: 'Local content',
          remoteContent: 'Remote content',
        );

        when(mockStorageRepository.uploadFile(any, any))
            .thenThrow(Exception('Upload failed'));

        // Act
        final result = await resolutionService.resolveConflict(
          conflict,
          ConflictResolution.keepLocal,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.error, isNotNull);
        expect(result.error, contains('Upload failed'));
      });
    });
  });
}