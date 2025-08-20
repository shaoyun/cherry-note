class AppConstants {
  // App Information
  static const String appName = 'Cherry Note';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String s3ConfigKey = 'S3_CONFIG';
  static const String userPreferencesKey = 'USER_PREFERENCES';
  static const String themeKey = 'THEME_MODE';
  static const String fontSizeKey = 'FONT_SIZE';
  static const String autoSyncKey = 'AUTO_SYNC';
  
  // File Extensions
  static const String markdownExtension = '.md';
  static const String metadataExtension = '.json';
  
  // Folder Names
  static const String stickyNotesFolder = '便签';
  static const String metadataFileName = '.folder-meta.json';
  static const String appMetadataFileName = '.app-meta.json';
  static const String syncInfoFileName = '.sync-info.json';
  
  // Sync Settings
  static const Duration defaultSyncInterval = Duration(minutes: 5);
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 30);
  
  // UI Constants
  static const double defaultFontSize = 14.0;
  static const double minFontSize = 10.0;
  static const double maxFontSize = 24.0;
  
  // File Size Limits
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int maxFileNameLength = 255;
  
  // Database
  static const String databaseName = 'cherry_note.db';
  static const int databaseVersion = 1;
}