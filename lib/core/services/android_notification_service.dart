import 'dart:io';
import 'package:flutter/services.dart';

/// Service for handling Android notifications
class AndroidNotificationService {
  static const MethodChannel _channel = MethodChannel('cherry_note/notifications');
  
  /// Initialize notification service
  Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('initialize');
    } on PlatformException catch (e) {
      print('Error initializing notifications: ${e.message}');
    }
  }
  
  /// Show a simple notification
  Future<void> showNotification({
    required String title,
    required String message,
    String? channelId,
    int? notificationId,
  }) async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('showNotification', {
        'title': title,
        'message': message,
        'channelId': channelId ?? 'default',
        'notificationId': notificationId ?? DateTime.now().millisecondsSinceEpoch,
      });
    } on PlatformException catch (e) {
      print('Error showing notification: ${e.message}');
    }
  }
  
  /// Show a progress notification
  Future<void> showProgressNotification({
    required String title,
    required String message,
    required int progress,
    required int maxProgress,
    String? channelId,
    int? notificationId,
  }) async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('showProgressNotification', {
        'title': title,
        'message': message,
        'progress': progress,
        'maxProgress': maxProgress,
        'channelId': channelId ?? 'sync',
        'notificationId': notificationId ?? 1001,
      });
    } on PlatformException catch (e) {
      print('Error showing progress notification: ${e.message}');
    }
  }
  
  /// Update an existing notification
  Future<void> updateNotification({
    required int notificationId,
    required String title,
    required String message,
    int? progress,
    int? maxProgress,
  }) async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('updateNotification', {
        'notificationId': notificationId,
        'title': title,
        'message': message,
        'progress': progress,
        'maxProgress': maxProgress,
      });
    } on PlatformException catch (e) {
      print('Error updating notification: ${e.message}');
    }
  }
  
  /// Cancel a notification
  Future<void> cancelNotification(int notificationId) async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('cancelNotification', {
        'notificationId': notificationId,
      });
    } on PlatformException catch (e) {
      print('Error canceling notification: ${e.message}');
    }
  }
  
  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('cancelAllNotifications');
    } on PlatformException catch (e) {
      print('Error canceling all notifications: ${e.message}');
    }
  }
  
  /// Create notification channels
  Future<void> createNotificationChannels() async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('createNotificationChannels', {
        'channels': [
          {
            'id': 'default',
            'name': 'General Notifications',
            'description': 'General app notifications',
            'importance': 'DEFAULT',
          },
          {
            'id': 'sync',
            'name': 'Sync Notifications',
            'description': 'File synchronization notifications',
            'importance': 'LOW',
          },
          {
            'id': 'error',
            'name': 'Error Notifications',
            'description': 'Error and warning notifications',
            'importance': 'HIGH',
          },
        ],
      });
    } on PlatformException catch (e) {
      print('Error creating notification channels: ${e.message}');
    }
  }
}