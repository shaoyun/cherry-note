import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cherry_note/core/services/settings_service.dart';
import 'package:cherry_note/core/services/s3_connection_test_service.dart';
import 'package:cherry_note/features/settings/data/services/settings_import_export_service.dart';
import 'package:cherry_note/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:cherry_note/features/settings/presentation/bloc/settings_event.dart';
import 'package:cherry_note/features/settings/presentation/bloc/settings_state.dart';
import 'package:cherry_note/features/sync/domain/entities/s3_config.dart';

import 'settings_bloc_test.mocks.dart';

@GenerateMocks([SettingsService, S3ConnectionTestService, SettingsImportExportService])
void main() {
  group('SettingsBloc', () {
    late MockSettingsService mockSettingsService;
    late MockS3ConnectionTestService mockS3TestService;
    late MockSettingsImportExportService mockImportExportService;
    late SettingsBloc settingsBloc;

    setUp(() {
      mockSettingsService = MockSettingsService();
      mockS3TestService = MockS3ConnectionTestService();
      mockImportExportService = MockSettingsImportExportService();
      settingsBloc = SettingsBloc(mockSettingsService, mockS3TestService, mockImportExportService);
    });

    tearDown(() {
      settingsBloc.close();
    });

    test('initial state is SettingsInitial', () {
      expect(settingsBloc.state, equals(const SettingsInitial()));
    });

    group('LoadSettings', () {
      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoading, SettingsLoaded] when settings are loaded successfully',
        build: () {
          when(mockSettingsService.getS3Config()).thenAnswer((_) async => null);
          when(mockSettingsService.getThemeMode()).thenAnswer((_) async => 'system');
          when(mockSettingsService.getFontSize()).thenAnswer((_) async => 14.0);
          when(mockSettingsService.getShowLineNumbers()).thenAnswer((_) async => true);
          when(mockSettingsService.getWordWrap()).thenAnswer((_) async => true);
          when(mockSettingsService.getAutoSave()).thenAnswer((_) async => true);
          when(mockSettingsService.getAutoSaveInterval()).thenAnswer((_) async => 30);
          when(mockSettingsService.getAutoSync()).thenAnswer((_) async => true);
          when(mockSettingsService.getSyncInterval()).thenAnswer((_) async => 5);
          when(mockSettingsService.getSyncOnStartup()).thenAnswer((_) async => true);
          when(mockSettingsService.getSyncOnClose()).thenAnswer((_) async => true);
          when(mockSettingsService.getShowToolbar()).thenAnswer((_) async => true);
          when(mockSettingsService.getShowStatusBar()).thenAnswer((_) async => true);
          when(mockSettingsService.getCompactMode()).thenAnswer((_) async => false);
          return settingsBloc;
        },
        act: (bloc) => bloc.add(const LoadSettings()),
        expect: () => [
          const SettingsLoading(),
          const SettingsLoaded(
            s3Config: null,
            themeMode: 'system',
            fontSize: 14.0,
            showLineNumbers: true,
            wordWrap: true,
            autoSave: true,
            autoSaveInterval: 30,
            autoSync: true,
            syncInterval: 5,
            syncOnStartup: true,
            syncOnClose: true,
            showToolbar: true,
            showStatusBar: true,
            compactMode: false,
          ),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits [SettingsLoading, SettingsError] when loading settings fails',
        build: () {
          when(mockSettingsService.getS3Config()).thenThrow(Exception('Failed to load'));
          return settingsBloc;
        },
        act: (bloc) => bloc.add(const LoadSettings()),
        expect: () => [
          const SettingsLoading(),
          const SettingsError('Failed to load settings: Exception: Failed to load'),
        ],
      );
    });

    group('UpdateS3Config', () {
      const testConfig = S3Config(
        endpoint: 'localhost',
        region: 'us-east-1',
        accessKeyId: 'test-key',
        secretAccessKey: 'test-secret',
        bucketName: 'test-bucket',
      );

      blocTest<SettingsBloc, SettingsState>(
        'updates S3 config when current state is SettingsLoaded',
        build: () {
          when(mockSettingsService.saveS3Config(any)).thenAnswer((_) async {});
          return settingsBloc;
        },
        seed: () => const SettingsLoaded(
          s3Config: null,
          themeMode: 'system',
          fontSize: 14.0,
          showLineNumbers: true,
          wordWrap: true,
          autoSave: true,
          autoSaveInterval: 30,
          autoSync: true,
          syncInterval: 5,
          syncOnStartup: true,
          syncOnClose: true,
          showToolbar: true,
          showStatusBar: true,
          compactMode: false,
        ),
        act: (bloc) => bloc.add(const UpdateS3Config(testConfig)),
        expect: () => [
          const SettingsLoaded(
            s3Config: testConfig,
            themeMode: 'system',
            fontSize: 14.0,
            showLineNumbers: true,
            wordWrap: true,
            autoSave: true,
            autoSaveInterval: 30,
            autoSync: true,
            syncInterval: 5,
            syncOnStartup: true,
            syncOnClose: true,
            showToolbar: true,
            showStatusBar: true,
            compactMode: false,
          ),
        ],
        verify: (_) {
          verify(mockSettingsService.saveS3Config(testConfig)).called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits error when saving S3 config fails',
        build: () {
          when(mockSettingsService.saveS3Config(any)).thenThrow(Exception('Save failed'));
          return settingsBloc;
        },
        seed: () => const SettingsLoaded(
          s3Config: null,
          themeMode: 'system',
          fontSize: 14.0,
          showLineNumbers: true,
          wordWrap: true,
          autoSave: true,
          autoSaveInterval: 30,
          autoSync: true,
          syncInterval: 5,
          syncOnStartup: true,
          syncOnClose: true,
          showToolbar: true,
          showStatusBar: true,
          compactMode: false,
        ),
        act: (bloc) => bloc.add(const UpdateS3Config(testConfig)),
        expect: () => [
          const SettingsError(
            'Failed to save S3 configuration: Exception: Save failed',
            SettingsLoaded(
              s3Config: null,
              themeMode: 'system',
              fontSize: 14.0,
              showLineNumbers: true,
              wordWrap: true,
              autoSave: true,
              autoSaveInterval: 30,
              autoSync: true,
              syncInterval: 5,
              syncOnStartup: true,
              syncOnClose: true,
              showToolbar: true,
              showStatusBar: true,
              compactMode: false,
            ),
          ),
        ],
      );
    });

    group('TestS3Connection', () {
      const testConfig = S3Config(
        endpoint: 'localhost',
        region: 'us-east-1',
        accessKeyId: 'test-key',
        secretAccessKey: 'test-secret',
        bucketName: 'test-bucket',
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits success when connection test passes',
        build: () {
          when(mockS3TestService.testWritePermissions(any)).thenAnswer(
            (_) async => S3ConnectionTestResult.success(message: 'Connection successful'),
          );
          return settingsBloc;
        },
        seed: () => const SettingsLoaded(
          s3Config: null,
          themeMode: 'system',
          fontSize: 14.0,
          showLineNumbers: true,
          wordWrap: true,
          autoSave: true,
          autoSaveInterval: 30,
          autoSync: true,
          syncInterval: 5,
          syncOnStartup: true,
          syncOnClose: true,
          showToolbar: true,
          showStatusBar: true,
          compactMode: false,
        ),
        act: (bloc) => bloc.add(const TestS3Connection(testConfig)),
        expect: () => [
          isA<S3ConnectionTesting>(),
          isA<S3ConnectionTestSuccess>(),
        ],
        verify: (_) {
          verify(mockS3TestService.testWritePermissions(testConfig)).called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'emits failure when connection test fails',
        build: () {
          when(mockS3TestService.testWritePermissions(any)).thenAnswer(
            (_) async => S3ConnectionTestResult.failure(error: 'Connection failed'),
          );
          return settingsBloc;
        },
        seed: () => const SettingsLoaded(
          s3Config: null,
          themeMode: 'system',
          fontSize: 14.0,
          showLineNumbers: true,
          wordWrap: true,
          autoSave: true,
          autoSaveInterval: 30,
          autoSync: true,
          syncInterval: 5,
          syncOnStartup: true,
          syncOnClose: true,
          showToolbar: true,
          showStatusBar: true,
          compactMode: false,
        ),
        act: (bloc) => bloc.add(const TestS3Connection(testConfig)),
        expect: () => [
          isA<S3ConnectionTesting>(),
          isA<S3ConnectionTestFailure>(),
        ],
      );
    });

    group('UpdateThemeMode', () {
      blocTest<SettingsBloc, SettingsState>(
        'updates theme mode successfully',
        build: () {
          when(mockSettingsService.setThemeMode(any)).thenAnswer((_) async {});
          return settingsBloc;
        },
        seed: () => const SettingsLoaded(
          s3Config: null,
          themeMode: 'system',
          fontSize: 14.0,
          showLineNumbers: true,
          wordWrap: true,
          autoSave: true,
          autoSaveInterval: 30,
          autoSync: true,
          syncInterval: 5,
          syncOnStartup: true,
          syncOnClose: true,
          showToolbar: true,
          showStatusBar: true,
          compactMode: false,
        ),
        act: (bloc) => bloc.add(const UpdateThemeMode('dark')),
        expect: () => [
          const SettingsLoaded(
            s3Config: null,
            themeMode: 'dark',
            fontSize: 14.0,
            showLineNumbers: true,
            wordWrap: true,
            autoSave: true,
            autoSaveInterval: 30,
            autoSync: true,
            syncInterval: 5,
            syncOnStartup: true,
            syncOnClose: true,
            showToolbar: true,
            showStatusBar: true,
            compactMode: false,
          ),
        ],
        verify: (_) {
          verify(mockSettingsService.setThemeMode('dark')).called(1);
        },
      );
    });

    group('ClearS3Config', () {
      blocTest<SettingsBloc, SettingsState>(
        'clears S3 config successfully',
        build: () {
          when(mockSettingsService.clearS3Config()).thenAnswer((_) async {});
          return settingsBloc;
        },
        seed: () => const SettingsLoaded(
          s3Config: S3Config(
            endpoint: 'localhost',
            region: 'us-east-1',
            accessKeyId: 'test-key',
            secretAccessKey: 'test-secret',
            bucketName: 'test-bucket',
          ),
          themeMode: 'system',
          fontSize: 14.0,
          showLineNumbers: true,
          wordWrap: true,
          autoSave: true,
          autoSaveInterval: 30,
          autoSync: true,
          syncInterval: 5,
          syncOnStartup: true,
          syncOnClose: true,
          showToolbar: true,
          showStatusBar: true,
          compactMode: false,
        ),
        act: (bloc) => bloc.add(const ClearS3Config()),
        expect: () => [
          const SettingsLoaded(
            s3Config: null,
            themeMode: 'system',
            fontSize: 14.0,
            showLineNumbers: true,
            wordWrap: true,
            autoSave: true,
            autoSaveInterval: 30,
            autoSync: true,
            syncInterval: 5,
            syncOnStartup: true,
            syncOnClose: true,
            showToolbar: true,
            showStatusBar: true,
            compactMode: false,
          ),
        ],
        verify: (_) {
          verify(mockSettingsService.clearS3Config()).called(1);
        },
      );
    });
  });
}