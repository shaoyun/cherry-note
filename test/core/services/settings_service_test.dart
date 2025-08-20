import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cherry_note/core/services/settings_service.dart';
import 'package:cherry_note/features/sync/domain/entities/s3_config.dart';

void main() {
  group('SettingsService', () {
    late SettingsService settingsService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      settingsService = SettingsServiceImpl();
    });

    group('S3 Configuration', () {
      test('should save and retrieve S3 config', () async {
        final config = S3Config(
          endpoint: 'localhost',
          region: 'us-east-1',
          accessKeyId: 'test-access-key',
          secretAccessKey: 'test-secret-key',
          bucketName: 'test-bucket',
          useSSL: false,
          port: 9000,
        );

        await settingsService.saveS3Config(config);
        final retrievedConfig = await settingsService.getS3Config();

        expect(retrievedConfig, isNotNull);
        expect(retrievedConfig!.endpoint, equals(config.endpoint));
        expect(retrievedConfig.region, equals(config.region));
        expect(retrievedConfig.accessKeyId, equals(config.accessKeyId));
        expect(retrievedConfig.secretAccessKey, equals(config.secretAccessKey));
        expect(retrievedConfig.bucketName, equals(config.bucketName));
        expect(retrievedConfig.useSSL, equals(config.useSSL));
        expect(retrievedConfig.port, equals(config.port));
      });

      test('should return null when no S3 config exists', () async {
        final config = await settingsService.getS3Config();
        expect(config, isNull);
      });

      test('should clear S3 config', () async {
        final config = S3Config(
          endpoint: 'localhost',
          region: 'us-east-1',
          accessKeyId: 'test-access-key',
          secretAccessKey: 'test-secret-key',
          bucketName: 'test-bucket',
        );

        await settingsService.saveS3Config(config);
        expect(await settingsService.getS3Config(), isNotNull);

        await settingsService.clearS3Config();
        expect(await settingsService.getS3Config(), isNull);
      });
    });

    group('Theme Settings', () {
      test('should save and retrieve theme mode', () async {
        await settingsService.setThemeMode('dark');
        final themeMode = await settingsService.getThemeMode();
        expect(themeMode, equals('dark'));
      });

      test('should return default theme mode when not set', () async {
        final themeMode = await settingsService.getThemeMode();
        expect(themeMode, equals('system'));
      });
    });

    group('Editor Settings', () {
      test('should save and retrieve font size', () async {
        await settingsService.setFontSize(16.0);
        final fontSize = await settingsService.getFontSize();
        expect(fontSize, equals(16.0));
      });

      test('should return default font size when not set', () async {
        final fontSize = await settingsService.getFontSize();
        expect(fontSize, equals(14.0));
      });

      test('should save and retrieve show line numbers', () async {
        await settingsService.setShowLineNumbers(false);
        final showLineNumbers = await settingsService.getShowLineNumbers();
        expect(showLineNumbers, isFalse);
      });

      test('should save and retrieve word wrap', () async {
        await settingsService.setWordWrap(false);
        final wordWrap = await settingsService.getWordWrap();
        expect(wordWrap, isFalse);
      });

      test('should save and retrieve auto save', () async {
        await settingsService.setAutoSave(false);
        final autoSave = await settingsService.getAutoSave();
        expect(autoSave, isFalse);
      });

      test('should save and retrieve auto save interval', () async {
        await settingsService.setAutoSaveInterval(60);
        final interval = await settingsService.getAutoSaveInterval();
        expect(interval, equals(60));
      });
    });

    group('Sync Settings', () {
      test('should save and retrieve auto sync', () async {
        await settingsService.setAutoSync(false);
        final autoSync = await settingsService.getAutoSync();
        expect(autoSync, isFalse);
      });

      test('should save and retrieve sync interval', () async {
        await settingsService.setSyncInterval(10);
        final interval = await settingsService.getSyncInterval();
        expect(interval, equals(10));
      });

      test('should save and retrieve sync on startup', () async {
        await settingsService.setSyncOnStartup(false);
        final syncOnStartup = await settingsService.getSyncOnStartup();
        expect(syncOnStartup, isFalse);
      });

      test('should save and retrieve sync on close', () async {
        await settingsService.setSyncOnClose(false);
        final syncOnClose = await settingsService.getSyncOnClose();
        expect(syncOnClose, isFalse);
      });
    });

    group('Interface Settings', () {
      test('should save and retrieve show toolbar', () async {
        await settingsService.setShowToolbar(false);
        final showToolbar = await settingsService.getShowToolbar();
        expect(showToolbar, isFalse);
      });

      test('should save and retrieve show status bar', () async {
        await settingsService.setShowStatusBar(false);
        final showStatusBar = await settingsService.getShowStatusBar();
        expect(showStatusBar, isFalse);
      });

      test('should save and retrieve compact mode', () async {
        await settingsService.setCompactMode(true);
        final compactMode = await settingsService.getCompactMode();
        expect(compactMode, isTrue);
      });
    });

    group('Settings Management', () {
      test('should export settings', () async {
        await settingsService.setThemeMode('dark');
        await settingsService.setFontSize(16.0);
        await settingsService.setAutoSync(false);

        final exportedSettings = await settingsService.exportSettings();

        expect(exportedSettings, isNotEmpty);
        expect(exportedSettings['THEME_MODE'], equals('dark'));
        expect(exportedSettings['FONT_SIZE'], equals(16.0));
        expect(exportedSettings['AUTO_SYNC'], isFalse);
      });

      test('should import settings', () async {
        final settingsToImport = {
          'THEME_MODE': 'light',
          'FONT_SIZE': 18.0,
          'AUTO_SYNC': true,
          'SYNC_INTERVAL': 15,
        };

        await settingsService.importSettings(settingsToImport);

        expect(await settingsService.getThemeMode(), equals('light'));
        expect(await settingsService.getFontSize(), equals(18.0));
        expect(await settingsService.getAutoSync(), isTrue);
        expect(await settingsService.getSyncInterval(), equals(15));
      });

      test('should clear all settings', () async {
        await settingsService.setThemeMode('dark');
        await settingsService.setFontSize(16.0);
        await settingsService.setAutoSync(false);

        await settingsService.clearAllSettings();

        // Should return default values after clearing
        expect(await settingsService.getThemeMode(), equals('system'));
        expect(await settingsService.getFontSize(), equals(14.0));
        expect(await settingsService.getAutoSync(), isTrue);
      });
    });
  });
}