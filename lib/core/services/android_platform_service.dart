import 'dart:io';
import 'package:flutter/material.dart';
import '../di/injection.dart';
import 'android_permissions_service.dart';
import 'android_background_sync_service.dart';
import 'android_notification_service.dart';
import '../performance/android_performance_service.dart';
import '../ui/android_ui_adaptations.dart';

/// Main service for Android platform integration
class AndroidPlatformService {
  late final AndroidPermissionsService _permissionsService;
  late final AndroidBackgroundSyncService _backgroundSyncService;
  late final AndroidNotificationService _notificationService;
  late final AndroidPerformanceService _performanceService;
  
  bool _isInitialized = false;
  
  AndroidPlatformService() {
    if (Platform.isAndroid) {
      _permissionsService = AndroidPermissionsService();
      _backgroundSyncService = AndroidBackgroundSyncService();
      _notificationService = AndroidNotificationService();
      _performanceService = AndroidPerformanceService();
    }
  }
  
  /// Initialize all Android platform services
  Future<void> initialize() async {
    if (!Platform.isAndroid || _isInitialized) return;
    
    try {
      // Configure system UI
      AndroidUIAdaptations.configureSystemUI();
      
      // Initialize services
      await _notificationService.initialize();
      await _notificationService.createNotificationChannels();
      
      await _backgroundSyncService.initialize();
      await _performanceService.initialize();
      
      // Request necessary permissions
      await _requestInitialPermissions();
      
      // Configure performance optimizations
      await _configurePerformanceOptimizations();
      
      _isInitialized = true;
      print('Android platform services initialized successfully');
    } catch (e) {
      print('Error initializing Android platform services: $e');
    }
  }
  
  /// Request initial permissions required by the app
  Future<void> _requestInitialPermissions() async {
    // Check and request storage permissions
    if (!await _permissionsService.hasStoragePermissions()) {
      await _permissionsService.requestStoragePermissions();
    }
    
    // Check and request notification permissions
    if (!await _permissionsService.hasNotificationPermissions()) {
      await _permissionsService.requestNotificationPermissions();
    }
    
    // Request battery optimization exemption
    if (!await _permissionsService.canRunInBackground()) {
      await _permissionsService.requestDisableBatteryOptimization();
    }
  }
  
  /// Configure performance optimizations based on device capabilities
  Future<void> _configurePerformanceOptimizations() async {
    final isLowMemoryDevice = await _performanceService.isLowMemoryDevice();
    final performanceClass = await _performanceService.getDevicePerformanceClass();
    
    if (isLowMemoryDevice) {
      await _performanceService.optimizeForLowMemory();
    }
    
    await _performanceService.configureForPerformanceClass(performanceClass);
  }
  
  /// Start background sync with appropriate settings
  Future<void> startBackgroundSync({
    Duration interval = const Duration(hours: 1),
    bool requiresCharging = false,
    bool requiresWifi = false,
  }) async {
    if (!Platform.isAndroid) return;
    
    await _backgroundSyncService.schedulePeriodicSync(
      interval: interval,
      requiresCharging: requiresCharging,
      requiresWifi: requiresWifi,
    );
  }
  
  /// Stop background sync
  Future<void> stopBackgroundSync() async {
    if (!Platform.isAndroid) return;
    
    await _backgroundSyncService.cancelPeriodicSync();
  }
  
  /// Show a notification
  Future<void> showNotification({
    required String title,
    required String message,
    String? channelId,
  }) async {
    if (!Platform.isAndroid) return;
    
    await _notificationService.showNotification(
      title: title,
      message: message,
      channelId: channelId,
    );
  }
  
  /// Handle Android back button
  Future<bool> handleBackButton(BuildContext context) async {
    if (!Platform.isAndroid) return false;
    
    return await AndroidUIAdaptations.handleAndroidBackButton(context);
  }
  
  /// Get Android-specific UI adaptations
  Widget adaptUI(Widget child, BuildContext context) {
    if (!Platform.isAndroid) return child;
    
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: AndroidUIAdaptations.getAndroidTextScaler(context),
      ),
      child: Padding(
        padding: AndroidUIAdaptations.getAndroidSafeAreaPadding(context),
        child: child,
      ),
    );
  }
  
  /// Get current memory usage information
  Future<Map<String, dynamic>> getMemoryUsage() async {
    if (!Platform.isAndroid) return {};
    
    return await _performanceService.getMemoryUsage();
  }
  
  /// Force garbage collection (for debugging/testing)
  Future<void> forceGarbageCollection() async {
    if (!Platform.isAndroid) return;
    
    await _performanceService.forceGarbageCollection();
  }
  
  /// Check if all required permissions are granted
  Future<bool> hasAllRequiredPermissions() async {
    if (!Platform.isAndroid) return true;
    
    final hasStorage = await _permissionsService.hasStoragePermissions();
    final hasNotifications = await _permissionsService.hasNotificationPermissions();
    
    return hasStorage && hasNotifications;
  }
  
  /// Get Android platform information
  Future<Map<String, dynamic>> getPlatformInfo() async {
    if (!Platform.isAndroid) return {};
    
    final memoryUsage = await getMemoryUsage();
    final performanceClass = await _performanceService.getDevicePerformanceClass();
    final isLowMemory = await _performanceService.isLowMemoryDevice();
    final canRunInBackground = await _permissionsService.canRunInBackground();
    
    return {
      'platform': 'android',
      'memoryUsage': memoryUsage,
      'performanceClass': performanceClass,
      'isLowMemoryDevice': isLowMemory,
      'canRunInBackground': canRunInBackground,
      'hasAllPermissions': await hasAllRequiredPermissions(),
    };
  }
  
  /// Dispose resources
  void dispose() {
    _isInitialized = false;
  }
}