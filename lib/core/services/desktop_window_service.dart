import 'dart:io';
import 'package:flutter/services.dart';

/// Service for managing desktop window properties and behavior
class DesktopWindowService {
  static const MethodChannel _channel = MethodChannel('cherry_note/window');
  
  /// Initialize window service
  Future<void> initialize() async {
    if (!_isDesktop()) return;
    
    try {
      await _channel.invokeMethod('initialize');
    } on PlatformException catch (e) {
      print('Error initializing window service: ${e.message}');
    }
  }
  
  /// Set window title
  Future<void> setTitle(String title) async {
    if (!_isDesktop()) return;
    
    try {
      await _channel.invokeMethod('setTitle', {'title': title});
    } on PlatformException catch (e) {
      print('Error setting window title: ${e.message}');
    }
  }
  
  /// Set window size
  Future<void> setSize(double width, double height) async {
    if (!_isDesktop()) return;
    
    try {
      await _channel.invokeMethod('setSize', {
        'width': width,
        'height': height,
      });
    } on PlatformException catch (e) {
      print('Error setting window size: ${e.message}');
    }
  }
  
  /// Set minimum window size
  Future<void> setMinimumSize(double width, double height) async {
    if (!_isDesktop()) return;
    
    try {
      await _channel.invokeMethod('setMinimumSize', {
        'width': width,
        'height': height,
      });
    } on PlatformException catch (e) {
      print('Error setting minimum window size: ${e.message}');
    }
  }
  
  /// Set maximum window size
  Future<void> setMaximumSize(double width, double height) async {
    if (!_isDesktop()) return;
    
    try {
      await _channel.invokeMethod('setMaximumSize', {
        'width': width,
        'height': height,
      });
    } on PlatformException catch (e) {
      print('Error setting maximum window size: ${e.message}');
    }
  }
  
  /// Center window on screen
  Future<void> center() async {
    if (!_isDesktop()) return;
    
    try {
      await _channel.invokeMethod('center');
    } on PlatformException catch (e) {
      print('Error centering window: ${e.message}');
    }
  }
  
  /// Maximize window
  Future<void> maximize() async {
    if (!_isDesktop()) return;
    
    try {
      await _channel.invokeMethod('maximize');
    } on PlatformException catch (e) {
      print('Error maximizing window: ${e.message}');
    }
  }
  
  /// Minimize window
  Future<void> minimize() async {
    if (!_isDesktop()) return;
    
    try {
      await _channel.invokeMethod('minimize');
    } on PlatformException catch (e) {
      print('Error minimizing window: ${e.message}');
    }
  }
  
  /// Restore window from maximized/minimized state
  Future<void> restore() async {
    if (!_isDesktop()) return;
    
    try {
      await _channel.invokeMethod('restore');
    } on PlatformException catch (e) {
      print('Error restoring window: ${e.message}');
    }
  }
  
  /// Check if window is maximized
  Future<bool> isMaximized() async {
    if (!_isDesktop()) return false;
    
    try {
      final result = await _channel.invokeMethod('isMaximized');
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      print('Error checking if window is maximized: ${e.message}');
      return false;
    }
  }
  
  /// Check if window is minimized
  Future<bool> isMinimized() async {
    if (!_isDesktop()) return false;
    
    try {
      final result = await _channel.invokeMethod('isMinimized');
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      print('Error checking if window is minimized: ${e.message}');
      return false;
    }
  }
  
  /// Set window position
  Future<void> setPosition(double x, double y) async {
    if (!_isDesktop()) return;
    
    try {
      await _channel.invokeMethod('setPosition', {
        'x': x,
        'y': y,
      });
    } on PlatformException catch (e) {
      print('Error setting window position: ${e.message}');
    }
  }
  
  /// Get window position
  Future<Map<String, double>> getPosition() async {
    if (!_isDesktop()) return {'x': 0, 'y': 0};
    
    try {
      final result = await _channel.invokeMethod('getPosition');
      final map = Map<String, dynamic>.from(result);
      return {
        'x': (map['x'] as num?)?.toDouble() ?? 0,
        'y': (map['y'] as num?)?.toDouble() ?? 0,
      };
    } on PlatformException catch (e) {
      print('Error getting window position: ${e.message}');
      return {'x': 0, 'y': 0};
    }
  }
  
  /// Get window size
  Future<Map<String, double>> getSize() async {
    if (!_isDesktop()) return {'width': 800, 'height': 600};
    
    try {
      final result = await _channel.invokeMethod('getSize');
      final map = Map<String, dynamic>.from(result);
      return {
        'width': (map['width'] as num?)?.toDouble() ?? 800,
        'height': (map['height'] as num?)?.toDouble() ?? 600,
      };
    } on PlatformException catch (e) {
      print('Error getting window size: ${e.message}');
      return {'width': 800, 'height': 600};
    }
  }
  
  /// Set window resizable
  Future<void> setResizable(bool resizable) async {
    if (!_isDesktop()) return;
    
    try {
      await _channel.invokeMethod('setResizable', {'resizable': resizable});
    } on PlatformException catch (e) {
      print('Error setting window resizable: ${e.message}');
    }
  }
  
  /// Set window always on top
  Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    if (!_isDesktop()) return;
    
    try {
      await _channel.invokeMethod('setAlwaysOnTop', {'alwaysOnTop': alwaysOnTop});
    } on PlatformException catch (e) {
      print('Error setting window always on top: ${e.message}');
    }
  }
  
  /// Set window fullscreen
  Future<void> setFullscreen(bool fullscreen) async {
    if (!_isDesktop()) return;
    
    try {
      await _channel.invokeMethod('setFullscreen', {'fullscreen': fullscreen});
    } on PlatformException catch (e) {
      print('Error setting window fullscreen: ${e.message}');
    }
  }
  
  /// Check if window is fullscreen
  Future<bool> isFullscreen() async {
    if (!_isDesktop()) return false;
    
    try {
      final result = await _channel.invokeMethod('isFullscreen');
      return result as bool? ?? false;
    } on PlatformException catch (e) {
      print('Error checking if window is fullscreen: ${e.message}');
      return false;
    }
  }
  
  /// Save window state to preferences
  Future<void> saveWindowState() async {
    if (!_isDesktop()) return;
    
    try {
      final position = await getPosition();
      final size = await getSize();
      final isMaximized = await this.isMaximized();
      
      await _channel.invokeMethod('saveWindowState', {
        'x': position['x'],
        'y': position['y'],
        'width': size['width'],
        'height': size['height'],
        'isMaximized': isMaximized,
      });
    } on PlatformException catch (e) {
      print('Error saving window state: ${e.message}');
    }
  }
  
  /// Restore window state from preferences
  Future<void> restoreWindowState() async {
    if (!_isDesktop()) return;
    
    try {
      await _channel.invokeMethod('restoreWindowState');
    } on PlatformException catch (e) {
      print('Error restoring window state: ${e.message}');
    }
  }
  
  /// Set window icon
  Future<void> setIcon(String iconPath) async {
    if (!_isDesktop()) return;
    
    try {
      await _channel.invokeMethod('setIcon', {'iconPath': iconPath});
    } on PlatformException catch (e) {
      print('Error setting window icon: ${e.message}');
    }
  }
  
  /// Show window in taskbar
  Future<void> showInTaskbar(bool show) async {
    if (!_isDesktop()) return;
    
    try {
      await _channel.invokeMethod('showInTaskbar', {'show': show});
    } on PlatformException catch (e) {
      print('Error setting window taskbar visibility: ${e.message}');
    }
  }
  
  /// Request user attention (flash taskbar icon)
  Future<void> requestAttention() async {
    if (!_isDesktop()) return;
    
    try {
      await _channel.invokeMethod('requestAttention');
    } on PlatformException catch (e) {
      print('Error requesting attention: ${e.message}');
    }
  }
  
  bool _isDesktop() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
}