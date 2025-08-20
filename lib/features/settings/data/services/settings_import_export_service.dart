import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../../../core/services/settings_service.dart';

/// Result of settings import/export operation
class SettingsImportExportResult {
  final bool success;
  final String? message;
  final String? error;
  final String? filePath;

  const SettingsImportExportResult({
    required this.success,
    this.message,
    this.error,
    this.filePath,
  });

  factory SettingsImportExportResult.success({
    String? message,
    String? filePath,
  }) {
    return SettingsImportExportResult(
      success: true,
      message: message,
      filePath: filePath,
    );
  }

  factory SettingsImportExportResult.failure({
    required String error,
  }) {
    return SettingsImportExportResult(
      success: false,
      error: error,
    );
  }
}

/// Service for importing and exporting settings
abstract class SettingsImportExportService {
  Future<SettingsImportExportResult> exportSettings();
  Future<SettingsImportExportResult> exportSettingsToFile(String filePath);
  Future<SettingsImportExportResult> importSettings();
  Future<SettingsImportExportResult> importSettingsFromFile(String filePath);
}

/// Implementation of SettingsImportExportService
@LazySingleton(as: SettingsImportExportService)
class SettingsImportExportServiceImpl implements SettingsImportExportService {
  final SettingsService _settingsService;

  SettingsImportExportServiceImpl(this._settingsService);

  @override
  Future<SettingsImportExportResult> exportSettings() async {
    try {
      // Get save location from user
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '导出设置',
        fileName: 'cherry_note_settings_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) {
        return SettingsImportExportResult.failure(error: '用户取消了导出操作');
      }

      return await exportSettingsToFile(result);
    } catch (e) {
      return SettingsImportExportResult.failure(error: '导出设置失败: ${e.toString()}');
    }
  }

  @override
  Future<SettingsImportExportResult> exportSettingsToFile(String filePath) async {
    try {
      // Get all settings
      final settings = await _settingsService.exportSettings();
      
      // Create export data with metadata
      final exportData = {
        'version': '1.0.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'appName': 'Cherry Note',
        'settings': settings,
      };

      // Write to file
      final file = File(filePath);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(exportData),
      );

      return SettingsImportExportResult.success(
        message: '设置已成功导出到: ${path.basename(filePath)}',
        filePath: filePath,
      );
    } catch (e) {
      return SettingsImportExportResult.failure(error: '导出设置失败: ${e.toString()}');
    }
  }

  @override
  Future<SettingsImportExportResult> importSettings() async {
    try {
      // Get file from user
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: '导入设置',
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return SettingsImportExportResult.failure(error: '用户取消了导入操作');
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        return SettingsImportExportResult.failure(error: '无法获取文件路径');
      }

      return await importSettingsFromFile(filePath);
    } catch (e) {
      return SettingsImportExportResult.failure(error: '导入设置失败: ${e.toString()}');
    }
  }

  @override
  Future<SettingsImportExportResult> importSettingsFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return SettingsImportExportResult.failure(error: '文件不存在: $filePath');
      }

      // Read and parse file
      final content = await file.readAsString();
      final data = json.decode(content) as Map<String, dynamic>;

      // Validate format
      if (!data.containsKey('settings')) {
        return SettingsImportExportResult.failure(error: '无效的设置文件格式');
      }

      final settings = data['settings'] as Map<String, dynamic>;
      
      // Validate settings data
      if (settings.isEmpty) {
        return SettingsImportExportResult.failure(error: '设置文件为空');
      }

      // Import settings
      await _settingsService.importSettings(settings);

      final version = data['version'] as String? ?? '未知版本';
      final exportedAt = data['exportedAt'] as String?;
      
      String message = '设置已成功导入';
      if (exportedAt != null) {
        try {
          final exportDate = DateTime.parse(exportedAt);
          message += ' (导出时间: ${exportDate.toLocal().toString().split('.')[0]})';
        } catch (e) {
          // Ignore date parsing errors
        }
      }

      return SettingsImportExportResult.success(
        message: message,
        filePath: filePath,
      );
    } catch (e) {
      if (e is FormatException) {
        return SettingsImportExportResult.failure(error: '设置文件格式错误，请确保是有效的JSON文件');
      }
      return SettingsImportExportResult.failure(error: '导入设置失败: ${e.toString()}');
    }
  }

  /// Create a backup of current settings
  Future<SettingsImportExportResult> createBackup() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(appDir.path, 'cherry_note_backups'));
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = path.join(
        backupDir.path,
        'settings_backup_$timestamp.json',
      );

      return await exportSettingsToFile(backupPath);
    } catch (e) {
      return SettingsImportExportResult.failure(error: '创建备份失败: ${e.toString()}');
    }
  }

  /// Get list of available backups
  Future<List<File>> getAvailableBackups() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(appDir.path, 'cherry_note_backups'));
      
      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.json'))
          .cast<File>()
          .toList();

      // Sort by modification time (newest first)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return files;
    } catch (e) {
      return [];
    }
  }
}