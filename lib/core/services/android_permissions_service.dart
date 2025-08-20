import 'dart:io';
import 'package:flutter/services.dart';

/// Service for handling Android-specific permissions
class AndroidPermissionsService {
  static const MethodChannel _channel = MethodChannel('cherry_note/permissions');
  
  /// Check if storage permissions are granted
  Future<bool> hasStoragePermissions() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final bool hasPermission = await _channel.invokeMethod('hasStoragePermissions');
      return hasPermission;
    } on PlatformException catch (e) {
      print('Error checking storage permissions: ${e.message}');
      return false;
    }
  }
  
  /// Request storage permissions
  Future<bool> requestStoragePermissions() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final bool granted = await _channel.invokeMethod('requestStoragePermissions');
      return granted;
    } on PlatformException catch (e) {
      print('Error requesting storage permissions: ${e.message}');
      return false;
    }
  }
  
  /// Check if notification permissions are granted (Android 13+)
  Future<bool> hasNotificationPermissions() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final bool hasPermission = await _channel.invokeMethod('hasNotificationPermissions');
      return hasPermission;
    } on PlatformException catch (e) {
      print('Error checking notification permissions: ${e.message}');
      return false;
    }
  }
  
  /// Request notification permissions (Android 13+)
  Future<bool> requestNotificationPermissions() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final bool granted = await _channel.invokeMethod('requestNotificationPermissions');
      return granted;
    } on PlatformException catch (e) {
      print('Error requesting notification permissions: ${e.message}');
      return false;
    }
  }
  
  /// Check if background app refresh is enabled
  Future<bool> canRunInBackground() async {
    if (!Platform.isAndroid) return true;
    
    try {
      final bool canRun = await _channel.invokeMethod('canRunInBackground');
      return canRun;
    } on PlatformException catch (e) {
      print('Error checking background permissions: ${e.message}');
      return false;
    }
  }
  
  /// Request to disable battery optimization for the app
  Future<void> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('requestDisableBatteryOptimization');
    } on PlatformException catch (e) {
      print('Error requesting battery optimization disable: ${e.message}');
    }
  }
}