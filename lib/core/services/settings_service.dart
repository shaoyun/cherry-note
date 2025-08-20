import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/sync/domain/entities/s3_config.dart';
import '../../shared/constants/app_constants.dart';

/// Service for managing application settings
abstract class SettingsService {
  /// S3 Configuration
  Future<S3Config?> getS3Config();
  Future<void> saveS3Config(S3Config config);
  Future<void> clearS3Config();
  
  /// Theme Settings
  Future<String> getThemeMode();
  Future<void> setThemeMode(String themeMode);
  
  /// Editor Settings
  Future<double> getFontSize();
  Future<void> setFontSize(double fontSize);
  Future<bool> getShowLineNumbers();
  Future<void> setShowLineNumbers(bool show);
  Future<bool> getWordWrap();
  Future<void> setWordWrap(bool wrap);
  Future<bool> getAutoSave();
  Future<void> setAutoSave(bool autoSave);
  Future<int> getAutoSaveInterval();
  Future<void> setAutoSaveInterval(int interval);
  
  /// Sync Settings
  Future<bool> getAutoSync();
  Future<void> setAutoSync(bool autoSync);
  Future<int> getSyncInterval();
  Future<void> setSyncInterval(int interval);
  Future<bool> getSyncOnStartup();
  Future<void> setSyncOnStartup(bool sync);
  Future<bool> getSyncOnClose();
  Future<void> setSyncOnClose(bool sync);
  
  /// Interface Settings
  Future<bool> getShowToolbar();
  Future<void> setShowToolbar(bool show);
  Future<bool> getShowStatusBar();
  Future<void> setShowStatusBar(bool show);
  Future<bool> getCompactMode();
  Future<void> setCompactMode(bool compact);
  
  /// Export/Import Settings
  Future<Map<String, dynamic>> exportSettings();
  Future<void> importSettings(Map<String, dynamic> settings);
  
  /// Clear all settings
  Future<void> clearAllSettings();
}

/// Implementation of SettingsService using SharedPreferences
@LazySingleton(as: SettingsService)
class SettingsServiceImpl implements SettingsService {
  static const String _s3ConfigKey = 'S3_CONFIG';
  static const String _themeModeKey = 'THEME_MODE';
  static const String _fontSizeKey = 'FONT_SIZE';
  static const String _showLineNumbersKey = 'SHOW_LINE_NUMBERS';
  static const String _wordWrapKey = 'WORD_WRAP';
  static const String _autoSaveKey = 'AUTO_SAVE';
  static const String _autoSaveIntervalKey = 'AUTO_SAVE_INTERVAL';
  static const String _autoSyncKey = 'AUTO_SYNC';
  static const String _syncIntervalKey = 'SYNC_INTERVAL';
  static const String _syncOnStartupKey = 'SYNC_ON_STARTUP';
  static const String _syncOnCloseKey = 'SYNC_ON_CLOSE';
  static const String _showToolbarKey = 'SHOW_TOOLBAR';
  static const String _showStatusBarKey = 'SHOW_STATUS_BAR';
  static const String _compactModeKey = 'COMPACT_MODE';

  @override
  Future<S3Config?> getS3Config() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_s3ConfigKey);
    if (configJson == null) return null;
    
    try {
      final configMap = json.decode(configJson) as Map<String, dynamic>;
      return S3Config(
        endpoint: configMap['endpoint'] as String,
        region: configMap['region'] as String,
        accessKeyId: configMap['accessKeyId'] as String,
        secretAccessKey: configMap['secretAccessKey'] as String,
        bucketName: configMap['bucketName'] as String,
        useSSL: configMap['useSSL'] as bool? ?? true,
        port: configMap['port'] as int?,
      );
    } catch (e) {
      // If parsing fails, return null
      return null;
    }
  }

  @override
  Future<void> saveS3Config(S3Config config) async {
    final prefs = await SharedPreferences.getInstance();
    final configMap = {
      'endpoint': config.endpoint,
      'region': config.region,
      'accessKeyId': config.accessKeyId,
      'secretAccessKey': config.secretAccessKey,
      'bucketName': config.bucketName,
      'useSSL': config.useSSL,
      'port': config.port,
    };
    await prefs.setString(_s3ConfigKey, json.encode(configMap));
  }

  @override
  Future<void> clearS3Config() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_s3ConfigKey);
  }

  @override
  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey) ?? 'system';
  }

  @override
  Future<void> setThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, themeMode);
  }

  @override
  Future<double> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_fontSizeKey) ?? 14.0;
  }

  @override
  Future<void> setFontSize(double fontSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, fontSize);
  }

  @override
  Future<bool> getShowLineNumbers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showLineNumbersKey) ?? true;
  }

  @override
  Future<void> setShowLineNumbers(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showLineNumbersKey, show);
  }

  @override
  Future<bool> getWordWrap() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_wordWrapKey) ?? true;
  }

  @override
  Future<void> setWordWrap(bool wrap) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wordWrapKey, wrap);
  }

  @override
  Future<bool> getAutoSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSaveKey) ?? true;
  }

  @override
  Future<void> setAutoSave(bool autoSave) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSaveKey, autoSave);
  }

  @override
  Future<int> getAutoSaveInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_autoSaveIntervalKey) ?? 30;
  }

  @override
  Future<void> setAutoSaveInterval(int interval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_autoSaveIntervalKey, interval);
  }

  @override
  Future<bool> getAutoSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoSyncKey) ?? true;
  }

  @override
  Future<void> setAutoSync(bool autoSync) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, autoSync);
  }

  @override
  Future<int> getSyncInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_syncIntervalKey) ?? 5;
  }

  @override
  Future<void> setSyncInterval(int interval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_syncIntervalKey, interval);
  }

  @override
  Future<bool> getSyncOnStartup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncOnStartupKey) ?? true;
  }

  @override
  Future<void> setSyncOnStartup(bool sync) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncOnStartupKey, sync);
  }

  @override
  Future<bool> getSyncOnClose() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncOnCloseKey) ?? true;
  }

  @override
  Future<void> setSyncOnClose(bool sync) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncOnCloseKey, sync);
  }

  @override
  Future<bool> getShowToolbar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showToolbarKey) ?? true;
  }

  @override
  Future<void> setShowToolbar(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showToolbarKey, show);
  }

  @override
  Future<bool> getShowStatusBar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showStatusBarKey) ?? true;
  }

  @override
  Future<void> setShowStatusBar(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showStatusBarKey, show);
  }

  @override
  Future<bool> getCompactMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_compactModeKey) ?? false;
  }

  @override
  Future<void> setCompactMode(bool compact) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_compactModeKey, compact);
  }

  @override
  Future<Map<String, dynamic>> exportSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = <String, dynamic>{};
    
    // Export all settings
    for (final key in prefs.getKeys()) {
      final value = prefs.get(key);
      if (value != null) {
        settings[key] = value;
      }
    }
    
    return settings;
  }

  @override
  Future<void> importSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    
    for (final entry in settings.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is String) {
        await prefs.setString(key, value);
      } else if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(key, value);
      }
    }
  }

  @override
  Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}