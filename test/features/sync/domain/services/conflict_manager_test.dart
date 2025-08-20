import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cherry_note/features/sync/domain/services/conflict_detection_service.dart';
import 'package:cherry_note/features/sync/domain/services/conflict_resolution_service.dart';
import 'package:cherry_note/features/sync/domain/services/sync_service.dart';
import 'package:cherry_note/features/sync/data/datasources/sqlite_cache_service.dart';

// 生成Mock类
@GenerateMocks([ConflictDetectionService, ConflictResolutionService])
import 'conflict_manager_test.mocks.dart';

void main() {
  late ConflictManager conflictManager;
  late MockConflictDetector mockDetector;
  late MockConflictResolver mockResolver;
  late SqliteCacheService cacheService;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    mockDetector = MockConflictDetector();
    mockResolver = MockConflictResolver();
    cacheService = SqliteCacheService(databasePath: ':memory:');
    await cacheService.initialize();

    conflictManager = ConflictManager(
      detector: mockDetector,
      resolver: mockResolver,
      cacheService: cacheService,
    );
  });

  tearDown(() async {
    conflictManager.dispose();
    await cacheService.close();
  });

  group('ConflictManager', () {
    group('冲突检测', () {
      test('应该能够检测单个文件的冲突', () async {
        // Arrange
        const filePath = '/test/file.md';
        final expectedConflict = EnhancedFileConflict(
          filePath: filePath,
          localModified: DateTime.now(),
          remoteModified: DateTime.now().add(const Duration(minutes: 1)),
          localContent: 'Local content',
          remoteContent: 'Remote content',
          type: ConflictType.contentConflict,
          severity: ConflictSeverity.medium,
          similarityScore: 0.8,
        );

        when(mockDetector.detectConflict(filePath))
            .thenAnswer((_) async => expectedConflict);

        // Act
        final conflict = await conflictManager.detectFileConflict(filePath);

        // Assert
        expect(conflict, isNotNull);
        expect(conflict!.filePath, equals(filePath));
        expect(conflictManager.pendingConflicts.length, equals(1));
        verify(mockDetector.detectConflict(filePath)).called(1);
      });

      test('应该能够检测所有冲突', () async {
        // Arrange
        final expectedConflicts = [
          EnhancedFileConflict(
            filePath: '/test/file1.md',
            localModified: DateTime.now(),
            remoteModified: DateTime.now().add(const Duration(minutes: 1)),
            localContent: 'Local content 1',
            remoteContent: 'Remote content 1',
            type: ConflictType.contentConflict,
            severity: ConflictSeverity.medium,
            similarityScore: 0.8,
          ),
          EnhancedFileConflict(
            filePath: '/test/file2.md',
            localModified: DateTime.now(),
            remoteModified: DateTime.now().add(const Duration(minutes: 2)),
            localContent: 'Local content 2',
            remoteContent: 'Remote content 2',
            type: ConflictType.contentConflict,
            severity: ConflictSeverity.high,
            similarityScore: 0.5,
          ),
        ];

        when(mockDetector.detectAllConflicts())
            .thenAnswer((_) async => expectedConflicts);

        // Act
        final conflicts = await conflictManager.detectAllConflicts();

        // Assert
        expect(conflicts.length, equals(2));
        expect(conflictManager.pendingConflicts.length, equals(2));
        verify(mockDetector.detectAllConflicts()).called(1);
      });

      test('没有冲突时应该返回null', () async {
        // Arrange
        const filePath = '/test/file.md';
        when(mockDetector.detectConflict(filePath))
            .thenAnswer((_) async => null);

        // Act
        final conflict = await conflictManager.detectFileConflict(filePath);

        // Assert
        expect(conflict, isNull);
        expect(conflictManager.pendingConflicts.length, equals(0));
      });
    });

    group('冲突解决', () {
      test('应该能够解决冲突', () async {
        // Arrange
        const filePath = '/test/file.md';
        final conflict = EnhancedFileConflict(
          filePath: filePath,
          localModified: DateTime.now(),
          remoteModified: DateTime.now().add(const Duration(minutes: 1)),
          localContent: 'Local content',
          remoteContent: 'Remote content',
          type: ConflictType.contentConflict,
          severity: ConflictSeverity.medium,
          similarityScore: 0.8,
        );

        final expectedResult = ResolutionResult(
          success: true,
          resolvedContent: 'Local content',
          appliedResolution: ConflictResolution.keepLocal,
        );

        // 先添加冲突到待处理列表
        when(mockDetector.detectConflict(filePath))
            .thenAnswer((_) async => conflict);
        await conflictManager.detectFileConflict(filePath);

        when(mockResolver.resolveConflict(
          conflict,
          ConflictResolution.keepLocal,
          mergeStrategy: anyNamed('mergeStrategy'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => expectedResult);

        // Act
        final result = await conflictManager.resolveConflict(
          filePath,
          ConflictResolution.keepLocal,
        );

        // Assert
        expect(result.success, isTrue);
        expect(result.appliedResolution, equals(ConflictResolution.keepLocal));
        expect(conflictManager.pendingConflicts.length, equals(0));
        expect(conflictManager.resolutionHistory.length, equals(1));
      });

      test('应该能够批量解决冲突', () async {
        // Arrange
        final conflicts = [
          EnhancedFileConflict(
            filePath: '/test/file1.md',
            localModified: DateTime.now(),
            remoteModified: DateTime.now().add(const Duration(minutes: 1)),
            localContent: 'Local content 1',
            remoteContent: 'Remote content 1',
            type: ConflictType.contentConflict,
            severity: ConflictSeverity.medium,
            similarityScore: 0.8,
          ),
          EnhancedFileConflict(
            filePath: '/test/file2.md',
            localModified: DateTime.now(),
            remoteModified: DateTime.now().add(const Duration(minutes: 2)),
            localContent: 'Local content 2',
            remoteContent: 'Remote content 2',
            type: ConflictType.contentConflict,
            severity: ConflictSeverity.high,
            similarityScore: 0.5,
          ),
        ];

        // 添加冲突到待处理列表
        when(mockDetector.detectAllConflicts())
            .thenAnswer((_) async => conflicts);
        await conflictManager.detectAllConflicts();

        // 设置解决结果
        for (final conflict in conflicts) {
          when(mockResolver.resolveConflict(
            conflict,
            any,
            mergeStrategy: anyNamed('mergeStrategy'),
            options: anyNamed('options'),
          )).thenAnswer((_) async => ResolutionResult(
            success: true,
            appliedResolution: ConflictResolution.keepLocal,
          ));
        }

        final resolutions = {
          '/test/file1.md': ConflictResolution.keepLocal,
          '/test/file2.md': ConflictResolution.keepRemote,
        };

        // Act
        final results = await conflictManager.resolveConflicts(resolutions);

        // Assert
        expect(results.length, equals(2));
        expect(results.every((r) => r.success), isTrue);
        expect(conflictManager.pendingConflicts.length, equals(0));
        expect(conflictManager.resolutionHistory.length, equals(2));
      });

      test('解决不存在的冲突应该抛出异常', () async {
        // Act & Assert
        await expectLater(
          conflictManager.resolveConflict('/nonexistent/file.md', ConflictResolution.keepLocal),
          throwsA(isA<SyncException>()),
        );
      });
    });

    group('自动解决', () {
      test('启用自动解决时应该自动解决低严重程度冲突', () async {
        // Arrange
        conflictManager.enableAutoResolve();
        
        const filePath = '/test/file.md';
        final conflict = EnhancedFileConflict(
          filePath: filePath,
          localModified: DateTime.now(),
          remoteModified: DateTime.now().add(const Duration(minutes: 1)),
          localContent: 'Local content',
          remoteContent: 'Remote content',
          type: ConflictType.contentConflict,
          severity: ConflictSeverity.low, // 低严重程度
          similarityScore: 0.9,
        );

        when(mockDetector.detectConflict(filePath))
            .thenAnswer((_) async => conflict);
        when(mockResolver.autoResolveConflict(conflict))
            .thenAnswer((_) async => ResolutionResult(
              success: true,
              appliedResolution: ConflictResolution.keepLocal,
            ));

        // Act
        await conflictManager.detectFileConflict(filePath);

        // 等待自动解决完成
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(conflictManager.pendingConflicts.length, equals(0));
        expect(conflictManager.resolutionHistory.length, equals(1));
        verify(mockResolver.autoResolveConflict(conflict)).called(1);
      });

      test('应该能够自动解决所有可能的冲突', () async {
        // Arrange
        final conflicts = [
          EnhancedFileConflict(
            filePath: '/test/file1.md',
            localModified: DateTime.now(),
            remoteModified: DateTime.now().add(const Duration(minutes: 1)),
            localContent: 'Local content 1',
            remoteContent: 'Remote content 1',
            type: ConflictType.contentConflict,
            severity: ConflictSeverity.low, // 可以自动解决
            similarityScore: 0.9,
          ),
          EnhancedFileConflict(
            filePath: '/test/file2.md',
            localModified: DateTime.now(),
            remoteModified: DateTime.now().add(const Duration(minutes: 2)),
            localContent: 'Local content 2',
            remoteContent: 'Remote content 2',
            type: ConflictType.contentConflict,
            severity: ConflictSeverity.critical, // 不能自动解决
            similarityScore: 0.1,
          ),
        ];

        // 手动添加冲突
        when(mockDetector.detectAllConflicts())
            .thenAnswer((_) async => conflicts);
        await conflictManager.detectAllConflicts();

        // 设置解决结果
        for (final conflict in conflicts) {
          when(mockResolver.autoResolveConflict(conflict))
              .thenAnswer((_) async => ResolutionResult(
                success: true,
                appliedResolution: ConflictResolution.keepLocal,
              ));
        }

        // Act
        final results = await conflictManager.autoResolveAllConflicts();

        // Assert
        expect(results.length, equals(1)); // 只有一个可以自动解决
        expect(results.first.success, isTrue);
        expect(conflictManager.pendingConflicts.length, equals(1)); // 还有一个不能自动解决
        expect(conflictManager.resolutionHistory.length, equals(1));
      });
    });

    group('事件流', () {
      test('检测到冲突时应该发出事件', () async {
        // Arrange
        const filePath = '/test/file.md';
        final conflict = EnhancedFileConflict(
          filePath: filePath,
          localModified: DateTime.now(),
          remoteModified: DateTime.now().add(const Duration(minutes: 1)),
          localContent: 'Local content',
          remoteContent: 'Remote content',
          type: ConflictType.contentConflict,
          severity: ConflictSeverity.medium,
          similarityScore: 0.8,
        );

        when(mockDetector.detectConflict(filePath))
            .thenAnswer((_) async => conflict);

        // Act
        final eventFuture = conflictManager.eventStream.first;
        await conflictManager.detectFileConflict(filePath);
        final event = await eventFuture;

        // Assert
        expect(event, isA<ConflictDetectedEvent>());
        final detectedEvent = event as ConflictDetectedEvent;
        expect(detectedEvent.conflict.filePath, equals(filePath));
      });

      test('解决冲突时应该发出事件', () async {
        // Arrange
        const filePath = '/test/file.md';
        final conflict = EnhancedFileConflict(
          filePath: filePath,
          localModified: DateTime.now(),
          remoteModified: DateTime.now().add(const Duration(minutes: 1)),
          localContent: 'Local content',
          remoteContent: 'Remote content',
          type: ConflictType.contentConflict,
          severity: ConflictSeverity.medium,
          similarityScore: 0.8,
        );

        final expectedResult = ResolutionResult(
          success: true,
          resolvedContent: 'Local content',
          appliedResolution: ConflictResolution.keepLocal,
        );

        // 先添加冲突
        when(mockDetector.detectConflict(filePath))
            .thenAnswer((_) async => conflict);
        await conflictManager.detectFileConflict(filePath);

        when(mockResolver.resolveConflict(
          conflict,
          ConflictResolution.keepLocal,
          mergeStrategy: anyNamed('mergeStrategy'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => expectedResult);

        // Act
        final eventFuture = conflictManager.eventStream
            .where((event) => event is ConflictResolvedEvent)
            .first;
        await conflictManager.resolveConflict(filePath, ConflictResolution.keepLocal);
        final event = await eventFuture;

        // Assert
        expect(event, isA<ConflictResolvedEvent>());
        final resolvedEvent = event as ConflictResolvedEvent;
        expect(resolvedEvent.conflict.filePath, equals(filePath));
        expect(resolvedEvent.result.success, isTrue);
      });
    });

    group('统计信息', () {
      test('应该正确统计冲突信息', () async {
        // Arrange
        final conflicts = [
          EnhancedFileConflict(
            filePath: '/test/file1.md',
            localModified: DateTime.now(),
            remoteModified: DateTime.now().add(const Duration(minutes: 1)),
            localContent: 'Local content 1',
            remoteContent: 'Remote content 1',
            type: ConflictType.contentConflict,
            severity: ConflictSeverity.low,
            similarityScore: 0.8,
          ),
          EnhancedFileConflict(
            filePath: '/test/file2.md',
            localModified: DateTime.now(),
            remoteModified: DateTime.now().add(const Duration(minutes: 2)),
            localContent: 'Local content 2',
            remoteContent: 'Remote content 2',
            type: ConflictType.createConflict,
            severity: ConflictSeverity.high,
            similarityScore: 0.5,
          ),
        ];

        when(mockDetector.detectAllConflicts())
            .thenAnswer((_) async => conflicts);
        await conflictManager.detectAllConflicts();

        // 解决一个冲突
        when(mockResolver.resolveConflict(
          conflicts[0],
          ConflictResolution.keepLocal,
          mergeStrategy: anyNamed('mergeStrategy'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => ResolutionResult(
          success: true,
          appliedResolution: ConflictResolution.keepLocal,
        ));

        await conflictManager.resolveConflict('/test/file1.md', ConflictResolution.keepLocal);

        // Act
        final stats = conflictManager.getConflictStats();

        // Assert
        expect(stats.totalConflicts, equals(2));
        expect(stats.resolvedConflicts, equals(1));
        expect(stats.pendingConflicts, equals(1));
        expect(stats.conflictsByType[ConflictType.contentConflict], equals(0)); // 已解决
        expect(stats.conflictsByType[ConflictType.createConflict], equals(1)); // 待处理
        expect(stats.resolutionsByType[ConflictResolution.keepLocal], equals(1));
      });
    });

    group('工具方法', () {
      test('应该能够检查文件是否有冲突', () async {
        // Arrange
        const filePath = '/test/file.md';
        final conflict = EnhancedFileConflict(
          filePath: filePath,
          localModified: DateTime.now(),
          remoteModified: DateTime.now().add(const Duration(minutes: 1)),
          localContent: 'Local content',
          remoteContent: 'Remote content',
          type: ConflictType.contentConflict,
          severity: ConflictSeverity.medium,
          similarityScore: 0.8,
        );

        when(mockDetector.detectConflict(filePath))
            .thenAnswer((_) async => conflict);

        // Act
        expect(conflictManager.hasConflict(filePath), isFalse);
        await conflictManager.detectFileConflict(filePath);
        expect(conflictManager.hasConflict(filePath), isTrue);
      });

      test('应该能够获取冲突详情', () async {
        // Arrange
        const filePath = '/test/file.md';
        final conflict = EnhancedFileConflict(
          filePath: filePath,
          localModified: DateTime.now(),
          remoteModified: DateTime.now().add(const Duration(minutes: 1)),
          localContent: 'Local content',
          remoteContent: 'Remote content',
          type: ConflictType.contentConflict,
          severity: ConflictSeverity.medium,
          similarityScore: 0.8,
          suggestedResolution: 'keep_local',
        );

        when(mockDetector.detectConflict(filePath))
            .thenAnswer((_) async => conflict);
        await conflictManager.detectFileConflict(filePath);

        // Act
        final details = conflictManager.getConflictDetails(filePath);
        final suggestion = conflictManager.getSuggestedResolution(filePath);

        // Assert
        expect(details, isNotNull);
        expect(details!.filePath, equals(filePath));
        expect(suggestion, equals(ConflictResolution.keepLocal));
      });

      test('应该能够清除历史记录', () async {
        // Arrange
        const filePath = '/test/file.md';
        final conflict = EnhancedFileConflict(
          filePath: filePath,
          localModified: DateTime.now(),
          remoteModified: DateTime.now().add(const Duration(minutes: 1)),
          localContent: 'Local content',
          remoteContent: 'Remote content',
          type: ConflictType.contentConflict,
          severity: ConflictSeverity.medium,
          similarityScore: 0.8,
        );

        when(mockDetector.detectConflict(filePath))
            .thenAnswer((_) async => conflict);
        when(mockResolver.resolveConflict(
          conflict,
          ConflictResolution.keepLocal,
          mergeStrategy: anyNamed('mergeStrategy'),
          options: anyNamed('options'),
        )).thenAnswer((_) async => ResolutionResult(
          success: true,
          appliedResolution: ConflictResolution.keepLocal,
        ));

        await conflictManager.detectFileConflict(filePath);
        await conflictManager.resolveConflict(filePath, ConflictResolution.keepLocal);

        expect(conflictManager.resolutionHistory.length, equals(1));

        // Act
        await conflictManager.clearResolutionHistory();

        // Assert
        expect(conflictManager.resolutionHistory.length, equals(0));
      });
    });
  });
}