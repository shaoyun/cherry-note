import 'dart:io';
import 'package:flutter/material.dart';
import '../di/injection.dart';
import 'desktop_file_dialog_service.dart';
import 'desktop_keyboard_shortcuts_service.dart';
import 'desktop_window_service.dart';
import '../ui/desktop_ui_adaptations.dart';

/// Main service for desktop platform integration
class DesktopPlatformService {
  late final DesktopFileDialogService _fileDialogService;
  late final DesktopWindowService _windowService;
  
  bool _isInitialized = false;
  
  DesktopPlatformService() {
    if (_isDesktop()) {
      _fileDialogService = DesktopFileDialogService();
      _windowService = DesktopWindowService();
    }
  }
  
  /// Initialize all desktop platform services
  Future<void> initialize() async {
    if (!_isDesktop() || _isInitialized) return;
    
    try {
      // Configure system UI
      DesktopUIAdaptations.configureSystemUI();
      
      // Initialize services
      await _windowService.initialize();
      
      // Initialize keyboard shortcuts
      DesktopKeyboardShortcutsService.initialize();
      
      // Configure window properties
      await _configureWindow();
      
      // Restore window state
      await _windowService.restoreWindowState();
      
      _isInitialized = true;
      print('Desktop platform services initialized successfully');
    } catch (e) {
      print('Error initializing desktop platform services: $e');
    }
  }
  
  /// Configure initial window properties
  Future<void> _configureWindow() async {
    // Set minimum window size
    await _windowService.setMinimumSize(800, 600);
    
    // Set window title
    await _windowService.setTitle('Cherry Note');
    
    // Set window icon (if available)
    // await _windowService.setIcon('assets/icons/app_icon.ico');
    
    // Center window if it's the first launch
    await _windowService.center();
  }
  
  /// Show native file picker
  Future<String?> pickFile({
    String? title,
    List<String>? allowedExtensions,
    String? initialDirectory,
  }) async {
    if (!_isDesktop()) return null;
    
    return await _fileDialogService.pickFile(
      title: title,
      allowedExtensions: allowedExtensions,
      initialDirectory: initialDirectory,
    );
  }
  
  /// Show native file picker for multiple files
  Future<List<String>?> pickFiles({
    String? title,
    List<String>? allowedExtensions,
    String? initialDirectory,
  }) async {
    if (!_isDesktop()) return null;
    
    return await _fileDialogService.pickFiles(
      title: title,
      allowedExtensions: allowedExtensions,
      initialDirectory: initialDirectory,
    );
  }
  
  /// Show native folder picker
  Future<String?> pickFolder({
    String? title,
    String? initialDirectory,
  }) async {
    if (!_isDesktop()) return null;
    
    return await _fileDialogService.pickFolder(
      title: title,
      initialDirectory: initialDirectory,
    );
  }
  
  /// Show native save file dialog
  Future<String?> saveFile({
    String? title,
    String? defaultName,
    List<String>? allowedExtensions,
    String? initialDirectory,
  }) async {
    if (!_isDesktop()) return null;
    
    return await _fileDialogService.saveFile(
      title: title,
      defaultName: defaultName,
      allowedExtensions: allowedExtensions,
      initialDirectory: initialDirectory,
    );
  }
  
  /// Show native message dialog
  Future<bool> showMessageDialog({
    required String title,
    required String message,
    String? okButtonText,
    String? cancelButtonText,
    bool showCancel = true,
  }) async {
    if (!_isDesktop()) return false;
    
    return await _fileDialogService.showMessageDialog(
      title: title,
      message: message,
      okButtonText: okButtonText,
      cancelButtonText: cancelButtonText,
      showCancel: showCancel,
    );
  }
  
  /// Show native confirmation dialog
  Future<bool> showConfirmationDialog({
    required String title,
    required String message,
    String? yesButtonText,
    String? noButtonText,
  }) async {
    if (!_isDesktop()) return false;
    
    return await _fileDialogService.showConfirmationDialog(
      title: title,
      message: message,
      yesButtonText: yesButtonText,
      noButtonText: noButtonText,
    );
  }
  
  /// Open file in default system application
  Future<bool> openFileInDefaultApp(String filePath) async {
    if (!_isDesktop()) return false;
    
    return await _fileDialogService.openFileInDefaultApp(filePath);
  }
  
  /// Show file in system file manager
  Future<bool> showFileInFileManager(String filePath) async {
    if (!_isDesktop()) return false;
    
    return await _fileDialogService.showFileInFileManager(filePath);
  }
  
  /// Set window title
  Future<void> setWindowTitle(String title) async {
    if (!_isDesktop()) return;
    
    await _windowService.setTitle(title);
  }
  
  /// Maximize window
  Future<void> maximizeWindow() async {
    if (!_isDesktop()) return;
    
    await _windowService.maximize();
  }
  
  /// Minimize window
  Future<void> minimizeWindow() async {
    if (!_isDesktop()) return;
    
    await _windowService.minimize();
  }
  
  /// Restore window
  Future<void> restoreWindow() async {
    if (!_isDesktop()) return;
    
    await _windowService.restore();
  }
  
  /// Toggle window fullscreen
  Future<void> toggleFullscreen() async {
    if (!_isDesktop()) return;
    
    final isFullscreen = await _windowService.isFullscreen();
    await _windowService.setFullscreen(!isFullscreen);
  }
  
  /// Center window on screen
  Future<void> centerWindow() async {
    if (!_isDesktop()) return;
    
    await _windowService.center();
  }
  
  /// Save current window state
  Future<void> saveWindowState() async {
    if (!_isDesktop()) return;
    
    await _windowService.saveWindowState();
  }
  
  /// Register keyboard shortcut
  void registerKeyboardShortcut({
    required String id,
    required List<String> keys,
    required VoidCallback callback,
  }) {
    if (!_isDesktop()) return;
    
    // This would need to be implemented with proper key parsing
    // DesktopKeyboardShortcutsService.registerShortcut(
    //   id: id,
    //   keySet: LogicalKeySet.fromSet(parsedKeys),
    //   callback: callback,
    // );
  }
  
  /// Create desktop-specific UI wrapper
  Widget createDesktopUI({
    required Widget child,
    required BuildContext context,
    Map<String, VoidCallback>? shortcuts,
  }) {
    if (!_isDesktop()) return child;
    
    return DesktopKeyboardShortcutsService.createShortcutsWrapper(
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            DesktopUIAdaptations.getDesktopTextScaleFactor(context),
          ),
        ),
        child: child,
      ),
    );
  }
  
  /// Create desktop-specific app bar
  PreferredSizeWidget createDesktopAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool showWindowControls = true,
  }) {
    if (!_isDesktop()) {
      return AppBar(
        title: Text(title),
        actions: actions,
        leading: leading,
      );
    }
    
    return DesktopUIAdaptations.createDesktopAppBar(
      title: title,
      actions: actions,
      leading: leading,
      showWindowControls: showWindowControls,
    );
  }
  
  /// Get system directories
  Future<Map<String, String?>> getSystemDirectories() async {
    if (!_isDesktop()) return {};
    
    final documents = await _fileDialogService.getDocumentsDirectory();
    final downloads = await _fileDialogService.getDownloadsDirectory();
    
    return {
      'documents': documents,
      'downloads': downloads,
    };
  }
  
  /// Get desktop platform information
  Future<Map<String, dynamic>> getPlatformInfo() async {
    if (!_isDesktop()) return {};
    
    final windowSize = await _windowService.getSize();
    final windowPosition = await _windowService.getPosition();
    final isMaximized = await _windowService.isMaximized();
    final isFullscreen = await _windowService.isFullscreen();
    final systemDirs = await getSystemDirectories();
    
    return {
      'platform': Platform.operatingSystem,
      'windowSize': windowSize,
      'windowPosition': windowPosition,
      'isMaximized': isMaximized,
      'isFullscreen': isFullscreen,
      'systemDirectories': systemDirs,
      'keyboardShortcuts': DesktopKeyboardShortcutsService.getShortcuts().length,
    };
  }
  
  /// Handle application exit
  Future<bool> handleApplicationExit() async {
    if (!_isDesktop()) return true;
    
    // Save window state before exit
    await saveWindowState();
    
    // Show confirmation dialog if needed
    final shouldExit = await showConfirmationDialog(
      title: 'Exit Application',
      message: 'Are you sure you want to exit Cherry Note?',
      yesButtonText: 'Exit',
      noButtonText: 'Cancel',
    );
    
    return shouldExit;
  }
  
  /// Dispose resources
  void dispose() {
    _isInitialized = false;
  }
  
  bool _isDesktop() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
}