import 'package:equatable/equatable.dart';
import '../../../sync/domain/entities/s3_config.dart';
import '../../../../core/services/s3_connection_test_service.dart';

/// Base class for settings states
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Loading state
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// Loaded state with all settings
class SettingsLoaded extends SettingsState {
  // S3 Configuration
  final S3Config? s3Config;
  
  // Theme Settings
  final String themeMode;
  
  // Editor Settings
  final double fontSize;
  final bool showLineNumbers;
  final bool wordWrap;
  final bool autoSave;
  final int autoSaveInterval;
  
  // Sync Settings
  final bool autoSync;
  final int syncInterval;
  final bool syncOnStartup;
  final bool syncOnClose;
  
  // Interface Settings
  final bool showToolbar;
  final bool showStatusBar;
  final bool compactMode;

  const SettingsLoaded({
    this.s3Config,
    required this.themeMode,
    required this.fontSize,
    required this.showLineNumbers,
    required this.wordWrap,
    required this.autoSave,
    required this.autoSaveInterval,
    required this.autoSync,
    required this.syncInterval,
    required this.syncOnStartup,
    required this.syncOnClose,
    required this.showToolbar,
    required this.showStatusBar,
    required this.compactMode,
  });

  SettingsLoaded copyWith({
    S3Config? s3Config,
    bool clearS3Config = false,
    String? themeMode,
    double? fontSize,
    bool? showLineNumbers,
    bool? wordWrap,
    bool? autoSave,
    int? autoSaveInterval,
    bool? autoSync,
    int? syncInterval,
    bool? syncOnStartup,
    bool? syncOnClose,
    bool? showToolbar,
    bool? showStatusBar,
    bool? compactMode,
  }) {
    return SettingsLoaded(
      s3Config: clearS3Config ? null : (s3Config ?? this.s3Config),
      themeMode: themeMode ?? this.themeMode,
      fontSize: fontSize ?? this.fontSize,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      wordWrap: wordWrap ?? this.wordWrap,
      autoSave: autoSave ?? this.autoSave,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      autoSync: autoSync ?? this.autoSync,
      syncInterval: syncInterval ?? this.syncInterval,
      syncOnStartup: syncOnStartup ?? this.syncOnStartup,
      syncOnClose: syncOnClose ?? this.syncOnClose,
      showToolbar: showToolbar ?? this.showToolbar,
      showStatusBar: showStatusBar ?? this.showStatusBar,
      compactMode: compactMode ?? this.compactMode,
    );
  }

  @override
  List<Object?> get props => [
        s3Config,
        themeMode,
        fontSize,
        showLineNumbers,
        wordWrap,
        autoSave,
        autoSaveInterval,
        autoSync,
        syncInterval,
        syncOnStartup,
        syncOnClose,
        showToolbar,
        showStatusBar,
        compactMode,
      ];
}

/// S3 Connection Testing States
class S3ConnectionTesting extends SettingsState {
  final SettingsLoaded currentSettings;

  const S3ConnectionTesting(this.currentSettings);

  @override
  List<Object?> get props => [currentSettings];
}

class S3ConnectionTestSuccess extends SettingsState {
  final SettingsLoaded currentSettings;
  final S3ConnectionTestResult result;

  const S3ConnectionTestSuccess(this.currentSettings, this.result);

  @override
  List<Object?> get props => [currentSettings, result];
}

class S3ConnectionTestFailure extends SettingsState {
  final SettingsLoaded currentSettings;
  final S3ConnectionTestResult result;

  const S3ConnectionTestFailure(this.currentSettings, this.result);

  @override
  List<Object?> get props => [currentSettings, result];
}

/// Settings Operation States
class SettingsSaving extends SettingsState {
  final SettingsLoaded currentSettings;

  const SettingsSaving(this.currentSettings);

  @override
  List<Object?> get props => [currentSettings];
}

class SettingsSaved extends SettingsState {
  final SettingsLoaded settings;

  const SettingsSaved(this.settings);

  @override
  List<Object?> get props => [settings];
}

class SettingsExported extends SettingsState {
  final SettingsLoaded currentSettings;
  final Map<String, dynamic> exportedSettings;

  const SettingsExported(this.currentSettings, this.exportedSettings);

  @override
  List<Object?> get props => [currentSettings, exportedSettings];
}

class SettingsImported extends SettingsState {
  final SettingsLoaded settings;

  const SettingsImported(this.settings);

  @override
  List<Object?> get props => [settings];
}

/// Error state
class SettingsError extends SettingsState {
  final String message;
  final SettingsLoaded? currentSettings;

  const SettingsError(this.message, [this.currentSettings]);

  @override
  List<Object?> get props => [message, currentSettings];
}