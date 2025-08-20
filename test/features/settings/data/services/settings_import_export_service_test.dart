import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cherry_note/core/services/settings_service.dart';
import 'package:cherry_note/features/settings/data/services/settings_import_export_service.dart';

import 'settings_import_export_service_test.mocks.dart';

@GenerateMocks([SettingsService])
void main() {
  group('SettingsImportExportService', () {
    late MockSettingsService mockSettingsService;
    late SettingsImportExportService importExportService;

    setUp(() {
      mockSettingsService = MockSettingsService();
      importExportService = SettingsImportExportServiceImpl(mockSettingsService);
    });

    group('exportSettingsToFile', () {
      test('should export settings to file successfully', () async {
        // Arrange
        final testSettings = {
          'THEME_MODE': 'dark',
          'FONT_SIZE': 16.0,
          'AUTO_SYNC': true,
        };
        when(mockSettingsService.exportSettings()).thenAnswer((_) async => testSettings);

        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test_export.json');

        // Act
        final result = await importExportService.exportSettingsToFile(testFile.path);

        // Assert
        expect(result.success, isTrue);
        expect(result.message, contains('设置已成功导出'));
        expect(result.filePath, equals(testFile.path));

        // Verify file content
        expect(await testFile.exists(), isTrue);
        final content = await testFile.readAsString();
        final data = json.decode(content) as Map<String, dynamic>;
        
        expect(data['version'], equals('1.0.0'));
        expect(data['appName'], equals('Cherry Note'));
        expect(data['settings'], equals(testSettings));
        expect(data['exportedAt'], isNotNull);

        // Cleanup
        await tempDir.delete(recursive: true);
      });

      test('should handle export errors', () async {
        // Arrange
        when(mockSettingsService.exportSettings()).thenThrow(Exception('Export failed'));

        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test_export.json');

        // Act
        final result = await importExportService.exportSettingsToFile(testFile.path);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('导出设置失败'));

        // Cleanup
        await tempDir.delete(recursive: true);
      });
    });

    group('importSettingsFromFile', () {
      test('should import settings from file successfully', () async {
        // Arrange
        final testSettings = {
          'THEME_MODE': 'light',
          'FONT_SIZE': 18.0,
          'AUTO_SYNC': false,
        };

        final exportData = {
          'version': '1.0.0',
          'exportedAt': DateTime.now().toIso8601String(),
          'appName': 'Cherry Note',
          'settings': testSettings,
        };

        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test_import.json');
        await testFile.writeAsString(json.encode(exportData));

        when(mockSettingsService.importSettings(any)).thenAnswer((_) async {});

        // Act
        final result = await importExportService.importSettingsFromFile(testFile.path);

        // Assert
        expect(result.success, isTrue);
        expect(result.message, contains('设置已成功导入'));
        expect(result.filePath, equals(testFile.path));

        verify(mockSettingsService.importSettings(testSettings)).called(1);

        // Cleanup
        await tempDir.delete(recursive: true);
      });

      test('should handle non-existent file', () async {
        // Act
        final result = await importExportService.importSettingsFromFile('/non/existent/file.json');

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('文件不存在'));
      });

      test('should handle invalid JSON format', () async {
        // Arrange
        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/invalid.json');
        await testFile.writeAsString('invalid json content');

        // Act
        final result = await importExportService.importSettingsFromFile(testFile.path);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('设置文件格式错误'));

        // Cleanup
        await tempDir.delete(recursive: true);
      });

      test('should handle missing settings key', () async {
        // Arrange
        final invalidData = {
          'version': '1.0.0',
          'appName': 'Cherry Note',
          // Missing 'settings' key
        };

        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/invalid_format.json');
        await testFile.writeAsString(json.encode(invalidData));

        // Act
        final result = await importExportService.importSettingsFromFile(testFile.path);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('无效的设置文件格式'));

        // Cleanup
        await tempDir.delete(recursive: true);
      });

      test('should handle empty settings', () async {
        // Arrange
        final emptyData = {
          'version': '1.0.0',
          'appName': 'Cherry Note',
          'settings': <String, dynamic>{},
        };

        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/empty_settings.json');
        await testFile.writeAsString(json.encode(emptyData));

        // Act
        final result = await importExportService.importSettingsFromFile(testFile.path);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('设置文件为空'));

        // Cleanup
        await tempDir.delete(recursive: true);
      });

      test('should handle import service errors', () async {
        // Arrange
        final testSettings = {
          'THEME_MODE': 'light',
          'FONT_SIZE': 18.0,
        };

        final exportData = {
          'version': '1.0.0',
          'appName': 'Cherry Note',
          'settings': testSettings,
        };

        final tempDir = Directory.systemTemp.createTempSync();
        final testFile = File('${tempDir.path}/test_import.json');
        await testFile.writeAsString(json.encode(exportData));

        when(mockSettingsService.importSettings(any)).thenThrow(Exception('Import failed'));

        // Act
        final result = await importExportService.importSettingsFromFile(testFile.path);

        // Assert
        expect(result.success, isFalse);
        expect(result.error, contains('导入设置失败'));

        // Cleanup
        await tempDir.delete(recursive: true);
      });
    });
  });
}