import 'dart:io';
import 'package:flutter/services.dart';

/// Service for handling native file dialogs on desktop platforms
class DesktopFileDialogService {
  static const MethodChannel _channel = MethodChannel('cherry_note/file_dialog');
  
  /// Show native file picker dialog
  Future<String?> pickFile({
    String? title,
    List<String>? allowedExtensions,
    String? initialDirectory,
  }) async {
    if (!_isDesktop()) return null;
    
    try {
      final result = await _channel.invokeMethod('pickFile', {
        'title': title ?? 'Select File',
        'allowedExtensions': allowedExtensions ?? ['md', 'txt'],
        'initialDirectory': initialDirectory,
      });
      return result as String?;
    } on PlatformException catch (e) {
      print('Error picking file: ${e.message}');
      return null;
    }
  }
  
  /// Show native file picker dialog for multiple files
  Future<List<String>?> pickFiles({
    String? title,
    List<String>? allowedExtensions,
    String? initialDirectory,
  }) async {
    if (!_isDesktop()) return null;
    
    try {
      final result = await _channel.invokeMethod('pickFiles', {
        'title': title ?? 'Select Files',
        'allowedExtensions': allowedExtensions ?? ['md', 'txt'],
        'initialDirectory': initialDirectory,
      });
      return List<String>.from(result ?? []);
    } on PlatformException catch (e) {
      print('Error picking files: ${e.message}');
      return null;
    }
  }
  
  /// Show native folder picker dialog
  Future<String?> pickFolder({
    String? title,
    String? initialDirectory,
  }) async {
    if (!_isDesktop()) return null;
    
    try {
      final result = await _channel.invokeMethod('pickFolder', {
        'title': title ?? 'Select Folder',
        'initialDirectory': initialDirectory,
      });
      return result as String?;
    } on PlatformException catch (e) {
      print('Error picking folder: ${e.message}');
      return null;
    }
  }
  
  /// Show native save file dialog
  Future<String?> saveFile({
    String? title,
    String? defaultName,
    List<String>? allowedExtensions,
    String? initialDirectory,
  }) async {
    if (!_isDesktop()) return null;
    
    try {
      final result = await _channel.invokeMethod('saveFile', {
        'title': title ?? 'Save File',
        'defaultName': defaultName ?? 'untitled.md',
        'allowedExtensions': allowedExtensions ?? ['md', 'txt'],
        'initialDirectory': initialDirectory,
      });
      return result as String?;
    } on PlatformException catch (e) {
      print('Error saving file: ${e.message}');
      return null;
    }
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
    
    try {
      final result = await _channel.invokeMethod('showMessageDialog', {
        'title': title,
        'message': message,
        'okButtonText': okButtonText ?? 'OK',
        'cancelButtonText': cancelButtonText ?? 'Cancel',
        'showCancel': showCancel,
      });
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      print('Error showing message dialog: ${e.message}');
      return false;
    }
  }
  
  /// Show native confirmation dialog
  Future<bool> showConfirmationDialog({
    required String title,
    required String message,
    String? yesButtonText,
    String? noButtonText,
  }) async {
    if (!_isDesktop()) return false;
    
    try {
      final result = await _channel.invokeMethod('showConfirmationDialog', {
        'title': title,
        'message': message,
        'yesButtonText': yesButtonText ?? 'Yes',
        'noButtonText': noButtonText ?? 'No',
      });
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      print('Error showing confirmation dialog: ${e.message}');
      return false;
    }
  }
  
  /// Open file in default system application
  Future<bool> openFileInDefaultApp(String filePath) async {
    if (!_isDesktop()) return false;
    
    try {
      final result = await _channel.invokeMethod('openFileInDefaultApp', {
        'filePath': filePath,
      });
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      print('Error opening file in default app: ${e.message}');
      return false;
    }
  }
  
  /// Show file in system file manager
  Future<bool> showFileInFileManager(String filePath) async {
    if (!_isDesktop()) return false;
    
    try {
      final result = await _channel.invokeMethod('showFileInFileManager', {
        'filePath': filePath,
      });
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      print('Error showing file in file manager: ${e.message}');
      return false;
    }
  }
  
  /// Get system documents directory
  Future<String?> getDocumentsDirectory() async {
    if (!_isDesktop()) return null;
    
    try {
      final result = await _channel.invokeMethod('getDocumentsDirectory');
      return result as String?;
    } on PlatformException catch (e) {
      print('Error getting documents directory: ${e.message}');
      return null;
    }
  }
  
  /// Get system downloads directory
  Future<String?> getDownloadsDirectory() async {
    if (!_isDesktop()) return null;
    
    try {
      final result = await _channel.invokeMethod('getDownloadsDirectory');
      return result as String?;
    } on PlatformException catch (e) {
      print('Error getting downloads directory: ${e.message}');
      return null;
    }
  }
  
  bool _isDesktop() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
}