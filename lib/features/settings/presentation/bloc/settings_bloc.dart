import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/s3_connection_test_service.dart';
import '../../data/services/settings_import_export_service.dart';
import 'settings_event.dart';
import 'settings_state.dart';

/// BLoC for managing application settings
@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsService _settingsService;
  final S3ConnectionTestService _s3TestService;
  final SettingsImportExportService _importExportService;

  SettingsBloc(
    this._settingsService,
    this._s3TestService,
    this._importExportService,
  ) : super(const SettingsInitial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateS3Config>(_onUpdateS3Config);
    on<TestS3Connection>(_onTestS3Connection);
    on<ClearS3Config>(_onClearS3Config);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateFontSize>(_onUpdateFontSize);
    on<UpdateShowLineNumbers>(_onUpdateShowLineNumbers);
    on<UpdateWordWrap>(_onUpdateWordWrap);
    on<UpdateAutoSave>(_onUpdateAutoSave);
    on<UpdateAutoSaveInterval>(_onUpdateAutoSaveInterval);
    on<UpdateAutoSync>(_onUpdateAutoSync);
    on<UpdateSyncInterval>(_onUpdateSyncInterval);
    on<UpdateSyncOnStartup>(_onUpdateSyncOnStartup);
    on<UpdateSyncOnClose>(_onUpdateSyncOnClose);
    on<UpdateShowToolbar>(_onUpdateShowToolbar);
    on<UpdateShowStatusBar>(_onUpdateShowStatusBar);
    on<UpdateCompactMode>(_onUpdateCompactMode);
    on<SaveAllSettings>(_onSaveAllSettings);
    on<ExportSettings>(_onExportSettings);
    on<ImportSettings>(_onImportSettings);
    on<ResetAllSettings>(_onResetAllSettings);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());

    try {
      final s3Config = await _settingsService.getS3Config();
      final themeMode = await _settingsService.getThemeMode();
      final fontSize = await _settingsService.getFontSize();
      final showLineNumbers = await _settingsService.getShowLineNumbers();
      final wordWrap = await _settingsService.getWordWrap();
      final autoSave = await _settingsService.getAutoSave();
      final autoSaveInterval = await _settingsService.getAutoSaveInterval();
      final autoSync = await _settingsService.getAutoSync();
      final syncInterval = await _settingsService.getSyncInterval();
      final syncOnStartup = await _settingsService.getSyncOnStartup();
      final syncOnClose = await _settingsService.getSyncOnClose();
      final showToolbar = await _settingsService.getShowToolbar();
      final showStatusBar = await _settingsService.getShowStatusBar();
      final compactMode = await _settingsService.getCompactMode();

      emit(SettingsLoaded(
        s3Config: s3Config,
        themeMode: themeMode,
        fontSize: fontSize,
        showLineNumbers: showLineNumbers,
        wordWrap: wordWrap,
        autoSave: autoSave,
        autoSaveInterval: autoSaveInterval,
        autoSync: autoSync,
        syncInterval: syncInterval,
        syncOnStartup: syncOnStartup,
        syncOnClose: syncOnClose,
        showToolbar: showToolbar,
        showStatusBar: showStatusBar,
        compactMode: compactMode,
      ));
    } catch (e) {
      emit(SettingsError('Failed to load settings: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateS3Config(
    UpdateS3Config event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      await _settingsService.saveS3Config(event.config);
      emit(currentState.copyWith(s3Config: event.config));
    } catch (e) {
      emit(SettingsError('Failed to save S3 configuration: ${e.toString()}', currentState));
    }
  }

  Future<void> _onTestS3Connection(
    TestS3Connection event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    emit(S3ConnectionTesting(currentState));

    try {
      final result = await _s3TestService.testWritePermissions(event.config);
      
      if (result.success) {
        emit(S3ConnectionTestSuccess(currentState, result));
      } else {
        emit(S3ConnectionTestFailure(currentState, result));
      }
    } catch (e) {
      final result = S3ConnectionTestResult.failure(
        error: 'Connection test failed: ${e.toString()}',
      );
      emit(S3ConnectionTestFailure(currentState, result));
    }
  }

  Future<void> _onClearS3Config(
    ClearS3Config event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      await _settingsService.clearS3Config();
      emit(currentState.copyWith(clearS3Config: true));
    } catch (e) {
      emit(SettingsError('Failed to clear S3 configuration: ${e.toString()}', currentState));
    }
  }

  Future<void> _onUpdateThemeMode(
    UpdateThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      await _settingsService.setThemeMode(event.themeMode);
      emit(currentState.copyWith(themeMode: event.themeMode));
    } catch (e) {
      emit(SettingsError('Failed to update theme mode: ${e.toString()}', currentState));
    }
  }

  Future<void> _onUpdateFontSize(
    UpdateFontSize event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      await _settingsService.setFontSize(event.fontSize);
      emit(currentState.copyWith(fontSize: event.fontSize));
    } catch (e) {
      emit(SettingsError('Failed to update font size: ${e.toString()}', currentState));
    }
  }

  Future<void> _onUpdateShowLineNumbers(
    UpdateShowLineNumbers event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      await _settingsService.setShowLineNumbers(event.show);
      emit(currentState.copyWith(showLineNumbers: event.show));
    } catch (e) {
      emit(SettingsError('Failed to update line numbers setting: ${e.toString()}', currentState));
    }
  }

  Future<void> _onUpdateWordWrap(
    UpdateWordWrap event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      await _settingsService.setWordWrap(event.wrap);
      emit(currentState.copyWith(wordWrap: event.wrap));
    } catch (e) {
      emit(SettingsError('Failed to update word wrap setting: ${e.toString()}', currentState));
    }
  }

  Future<void> _onUpdateAutoSave(
    UpdateAutoSave event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      await _settingsService.setAutoSave(event.autoSave);
      emit(currentState.copyWith(autoSave: event.autoSave));
    } catch (e) {
      emit(SettingsError('Failed to update auto save setting: ${e.toString()}', currentState));
    }
  }

  Future<void> _onUpdateAutoSaveInterval(
    UpdateAutoSaveInterval event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      await _settingsService.setAutoSaveInterval(event.interval);
      emit(currentState.copyWith(autoSaveInterval: event.interval));
    } catch (e) {
      emit(SettingsError('Failed to update auto save interval: ${e.toString()}', currentState));
    }
  }

  Future<void> _onUpdateAutoSync(
    UpdateAutoSync event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      await _settingsService.setAutoSync(event.autoSync);
      emit(currentState.copyWith(autoSync: event.autoSync));
    } catch (e) {
      emit(SettingsError('Failed to update auto sync setting: ${e.toString()}', currentState));
    }
  }

  Future<void> _onUpdateSyncInterval(
    UpdateSyncInterval event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      await _settingsService.setSyncInterval(event.interval);
      emit(currentState.copyWith(syncInterval: event.interval));
    } catch (e) {
      emit(SettingsError('Failed to update sync interval: ${e.toString()}', currentState));
    }
  }

  Future<void> _onUpdateSyncOnStartup(
    UpdateSyncOnStartup event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      await _settingsService.setSyncOnStartup(event.sync);
      emit(currentState.copyWith(syncOnStartup: event.sync));
    } catch (e) {
      emit(SettingsError('Failed to update sync on startup setting: ${e.toString()}', currentState));
    }
  }

  Future<void> _onUpdateSyncOnClose(
    UpdateSyncOnClose event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      await _settingsService.setSyncOnClose(event.sync);
      emit(currentState.copyWith(syncOnClose: event.sync));
    } catch (e) {
      emit(SettingsError('Failed to update sync on close setting: ${e.toString()}', currentState));
    }
  }

  Future<void> _onUpdateShowToolbar(
    UpdateShowToolbar event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      await _settingsService.setShowToolbar(event.show);
      emit(currentState.copyWith(showToolbar: event.show));
    } catch (e) {
      emit(SettingsError('Failed to update toolbar setting: ${e.toString()}', currentState));
    }
  }

  Future<void> _onUpdateShowStatusBar(
    UpdateShowStatusBar event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      await _settingsService.setShowStatusBar(event.show);
      emit(currentState.copyWith(showStatusBar: event.show));
    } catch (e) {
      emit(SettingsError('Failed to update status bar setting: ${e.toString()}', currentState));
    }
  }

  Future<void> _onUpdateCompactMode(
    UpdateCompactMode event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      await _settingsService.setCompactMode(event.compact);
      emit(currentState.copyWith(compactMode: event.compact));
    } catch (e) {
      emit(SettingsError('Failed to update compact mode setting: ${e.toString()}', currentState));
    }
  }

  Future<void> _onSaveAllSettings(
    SaveAllSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    emit(SettingsSaving(currentState));

    try {
      // All settings are already saved individually, so just emit success
      emit(SettingsSaved(currentState));
    } catch (e) {
      emit(SettingsError('Failed to save settings: ${e.toString()}', currentState));
    }
  }

  Future<void> _onExportSettings(
    ExportSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    emit(SettingsSaving(currentState));

    try {
      final result = await _importExportService.exportSettings();
      if (result.success) {
        emit(SettingsExported(currentState, {'message': result.message, 'filePath': result.filePath}));
      } else {
        emit(SettingsError(result.error ?? 'Export failed', currentState));
      }
    } catch (e) {
      emit(SettingsError('Failed to export settings: ${e.toString()}', currentState));
    }
  }

  Future<void> _onImportSettings(
    ImportSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    emit(SettingsSaving(currentState));

    try {
      final result = await _importExportService.importSettings();
      if (result.success) {
        // Reload settings after import
        add(const LoadSettings());
        emit(SettingsImported(currentState));
      } else {
        emit(SettingsError(result.error ?? 'Import failed', currentState));
      }
    } catch (e) {
      emit(SettingsError('Failed to import settings: ${e.toString()}', currentState));
    }
  }

  Future<void> _onResetAllSettings(
    ResetAllSettings event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SettingsLoaded) return;

    try {
      await _settingsService.clearAllSettings();
      
      // Reload settings after reset
      add(const LoadSettings());
    } catch (e) {
      emit(SettingsError('Failed to reset settings: ${e.toString()}', currentState));
    }
  }
}