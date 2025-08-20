import 'package:equatable/equatable.dart';
import '../../../sync/domain/entities/s3_config.dart';

/// Base class for settings events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all settings
class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

/// S3 Configuration Events
class UpdateS3Config extends SettingsEvent {
  final S3Config config;

  const UpdateS3Config(this.config);

  @override
  List<Object?> get props => [config];
}

class TestS3Connection extends SettingsEvent {
  final S3Config config;

  const TestS3Connection(this.config);

  @override
  List<Object?> get props => [config];
}

class ClearS3Config extends SettingsEvent {
  const ClearS3Config();
}

/// Theme Settings Events
class UpdateThemeMode extends SettingsEvent {
  final String themeMode;

  const UpdateThemeMode(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

/// Editor Settings Events
class UpdateFontSize extends SettingsEvent {
  final double fontSize;

  const UpdateFontSize(this.fontSize);

  @override
  List<Object?> get props => [fontSize];
}

class UpdateShowLineNumbers extends SettingsEvent {
  final bool show;

  const UpdateShowLineNumbers(this.show);

  @override
  List<Object?> get props => [show];
}

class UpdateWordWrap extends SettingsEvent {
  final bool wrap;

  const UpdateWordWrap(this.wrap);

  @override
  List<Object?> get props => [wrap];
}

class UpdateAutoSave extends SettingsEvent {
  final bool autoSave;

  const UpdateAutoSave(this.autoSave);

  @override
  List<Object?> get props => [autoSave];
}

class UpdateAutoSaveInterval extends SettingsEvent {
  final int interval;

  const UpdateAutoSaveInterval(this.interval);

  @override
  List<Object?> get props => [interval];
}

/// Sync Settings Events
class UpdateAutoSync extends SettingsEvent {
  final bool autoSync;

  const UpdateAutoSync(this.autoSync);

  @override
  List<Object?> get props => [autoSync];
}

class UpdateSyncInterval extends SettingsEvent {
  final int interval;

  const UpdateSyncInterval(this.interval);

  @override
  List<Object?> get props => [interval];
}

class UpdateSyncOnStartup extends SettingsEvent {
  final bool sync;

  const UpdateSyncOnStartup(this.sync);

  @override
  List<Object?> get props => [sync];
}

class UpdateSyncOnClose extends SettingsEvent {
  final bool sync;

  const UpdateSyncOnClose(this.sync);

  @override
  List<Object?> get props => [sync];
}

/// Interface Settings Events
class UpdateShowToolbar extends SettingsEvent {
  final bool show;

  const UpdateShowToolbar(this.show);

  @override
  List<Object?> get props => [show];
}

class UpdateShowStatusBar extends SettingsEvent {
  final bool show;

  const UpdateShowStatusBar(this.show);

  @override
  List<Object?> get props => [show];
}

class UpdateCompactMode extends SettingsEvent {
  final bool compact;

  const UpdateCompactMode(this.compact);

  @override
  List<Object?> get props => [compact];
}

/// Settings Management Events
class SaveAllSettings extends SettingsEvent {
  const SaveAllSettings();
}

class ExportSettings extends SettingsEvent {
  const ExportSettings();
}

class ImportSettings extends SettingsEvent {
  const ImportSettings();
}

class ResetAllSettings extends SettingsEvent {
  const ResetAllSettings();
}