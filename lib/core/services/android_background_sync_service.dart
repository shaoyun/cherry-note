import 'dart:io';
import 'package:flutter/services.dart';
import '../di/injection.dart';
import '../../features/sync/domain/services/sync_service.dart';

/// Service for handling Android background sync operations
class AndroidBackgroundSyncService {
  static const MethodChannel _channel = MethodChannel('cherry_note/background_sync');
  
  final SyncService _syncService = getIt<SyncService>();
  
  /// Initialize background sync service
  Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    
    // Set up method call handler for background sync
    _channel.setMethodCallHandler(_handleMethodCall);
    
    try {
      await _channel.invokeMethod('initialize');
    } on PlatformException catch (e) {
      print('Error initializing background sync: ${e.message}');
    }
  }
  
  /// Schedule periodic background sync
  Future<void> schedulePeriodicSync({
    Duration interval = const Duration(hours: 1),
    bool requiresCharging = false,
    bool requiresWifi = false,
  }) async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('schedulePeriodicSync', {
        'intervalMinutes': interval.inMinutes,
        'requiresCharging': requiresCharging,
        'requiresWifi': requiresWifi,
      });
    } on PlatformException catch (e) {
      print('Error scheduling periodic sync: ${e.message}');
    }
  }
  
  /// Cancel scheduled background sync
  Future<void> cancelPeriodicSync() async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('cancelPeriodicSync');
    } on PlatformException catch (e) {
      print('Error canceling periodic sync: ${e.message}');
    }
  }
  
  /// Schedule one-time sync
  Future<void> scheduleOneTimeSync({
    Duration delay = Duration.zero,
    bool requiresCharging = false,
    bool requiresWifi = false,
  }) async {
    if (!Platform.isAndroid) return;
    
    try {
      await _channel.invokeMethod('scheduleOneTimeSync', {
        'delayMinutes': delay.inMinutes,
        'requiresCharging': requiresCharging,
        'requiresWifi': requiresWifi,
      });
    } on PlatformException catch (e) {
      print('Error scheduling one-time sync: ${e.message}');
    }
  }
  
  /// Handle method calls from native Android code
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'performBackgroundSync':
        return await _performBackgroundSync();
      case 'onSyncProgress':
        _handleSyncProgress(call.arguments);
        break;
      case 'onSyncComplete':
        _handleSyncComplete(call.arguments);
        break;
      case 'onSyncError':
        _handleSyncError(call.arguments);
        break;
      default:
        throw PlatformException(
          code: 'UNIMPLEMENTED',
          message: 'Method ${call.method} not implemented',
        );
    }
  }
  
  /// Perform background sync operation
  Future<bool> _performBackgroundSync() async {
    try {
      final result = await _syncService.fullSync();
      return result.success;
    } catch (e) {
      print('Background sync failed: $e');
      return false;
    }
  }
  
  /// Handle sync progress updates
  void _handleSyncProgress(dynamic arguments) {
    final progress = arguments['progress'] as double? ?? 0.0;
    final message = arguments['message'] as String? ?? '';
    
    // Update notification with progress
    _updateSyncNotification(
      title: 'Syncing Notes',
      message: message,
      progress: progress,
    );
  }
  
  /// Handle sync completion
  void _handleSyncComplete(dynamic arguments) {
    final syncedFiles = arguments['syncedFiles'] as int? ?? 0;
    
    _showSyncNotification(
      title: 'Sync Complete',
      message: 'Synced $syncedFiles files successfully',
      isSuccess: true,
    );
  }
  
  /// Handle sync errors
  void _handleSyncError(dynamic arguments) {
    final error = arguments['error'] as String? ?? 'Unknown error';
    
    _showSyncNotification(
      title: 'Sync Failed',
      message: error,
      isSuccess: false,
    );
  }
  
  /// Update sync progress notification
  Future<void> _updateSyncNotification({
    required String title,
    required String message,
    required double progress,
  }) async {
    try {
      await _channel.invokeMethod('updateSyncNotification', {
        'title': title,
        'message': message,
        'progress': (progress * 100).toInt(),
      });
    } on PlatformException catch (e) {
      print('Error updating sync notification: ${e.message}');
    }
  }
  
  /// Show sync result notification
  Future<void> _showSyncNotification({
    required String title,
    required String message,
    required bool isSuccess,
  }) async {
    try {
      await _channel.invokeMethod('showSyncNotification', {
        'title': title,
        'message': message,
        'isSuccess': isSuccess,
      });
    } on PlatformException catch (e) {
      print('Error showing sync notification: ${e.message}');
    }
  }
}