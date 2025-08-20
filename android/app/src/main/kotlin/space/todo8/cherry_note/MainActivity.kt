package space.todo8.cherry_note

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    
    private val PERMISSIONS_CHANNEL = "cherry_note/permissions"
    private val BACKGROUND_SYNC_CHANNEL = "cherry_note/background_sync"
    private val NOTIFICATIONS_CHANNEL = "cherry_note/notifications"
    private val PERFORMANCE_CHANNEL = "cherry_note/performance"
    
    private val STORAGE_PERMISSION_REQUEST = 1001
    private val NOTIFICATION_PERMISSION_REQUEST = 1002
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        setupPermissionsChannel(flutterEngine)
        setupBackgroundSyncChannel(flutterEngine)
        setupNotificationsChannel(flutterEngine)
        setupPerformanceChannel(flutterEngine)
    }
    
    private fun setupPermissionsChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasStoragePermissions" -> {
                        result.success(hasStoragePermissions())
                    }
                    "requestStoragePermissions" -> {
                        requestStoragePermissions()
                        result.success(true)
                    }
                    "hasNotificationPermissions" -> {
                        result.success(hasNotificationPermissions())
                    }
                    "requestNotificationPermissions" -> {
                        requestNotificationPermissions()
                        result.success(true)
                    }
                    "canRunInBackground" -> {
                        result.success(canRunInBackground())
                    }
                    "requestDisableBatteryOptimization" -> {
                        requestDisableBatteryOptimization()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
    
    private fun setupBackgroundSyncChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKGROUND_SYNC_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialize" -> {
                        initializeBackgroundSync()
                        result.success(null)
                    }
                    "schedulePeriodicSync" -> {
                        val intervalMinutes = call.argument<Int>("intervalMinutes") ?: 60
                        val requiresCharging = call.argument<Boolean>("requiresCharging") ?: false
                        val requiresWifi = call.argument<Boolean>("requiresWifi") ?: false
                        schedulePeriodicSync(intervalMinutes, requiresCharging, requiresWifi)
                        result.success(null)
                    }
                    "cancelPeriodicSync" -> {
                        cancelPeriodicSync()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
    
    private fun setupNotificationsChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATIONS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialize" -> {
                        initializeNotifications()
                        result.success(null)
                    }
                    "showNotification" -> {
                        val title = call.argument<String>("title") ?: ""
                        val message = call.argument<String>("message") ?: ""
                        val channelId = call.argument<String>("channelId") ?: "default"
                        val notificationId = call.argument<Int>("notificationId") ?: 1
                        showNotification(title, message, channelId, notificationId)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
    
    private fun setupPerformanceChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERFORMANCE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "initialize" -> {
                        initializePerformance()
                        result.success(null)
                    }
                    "getMemoryUsage" -> {
                        result.success(getMemoryUsage())
                    }
                    "isLowMemoryDevice" -> {
                        result.success(isLowMemoryDevice())
                    }
                    else -> result.notImplemented()
                }
            }
    }
    
    // Permission methods
    private fun hasStoragePermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            android.os.Environment.isExternalStorageManager()
        } else {
            ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
        }
    }
    
    private fun requestStoragePermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        } else {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                STORAGE_PERMISSION_REQUEST
            )
        }
    }
    
    private fun hasNotificationPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }
    
    private fun requestNotificationPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                NOTIFICATION_PERMISSION_REQUEST
            )
        }
    }
    
    private fun canRunInBackground(): Boolean {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            powerManager.isIgnoringBatteryOptimizations(packageName)
        } else {
            true
        }
    }
    
    private fun requestDisableBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        }
    }
    
    // Background sync methods
    private fun initializeBackgroundSync() {
        val intent = Intent(this, BackgroundSyncService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
    
    private fun schedulePeriodicSync(intervalMinutes: Int, requiresCharging: Boolean, requiresWifi: Boolean) {
        // Implementation would use WorkManager to schedule periodic sync
    }
    
    private fun cancelPeriodicSync() {
        // Implementation would cancel WorkManager tasks
    }
    
    // Notification methods
    private fun initializeNotifications() {
        // Create notification channels
    }
    
    private fun showNotification(title: String, message: String, channelId: String, notificationId: Int) {
        // Show notification implementation
    }
    
    // Performance methods
    private fun initializePerformance() {
        // Initialize performance monitoring
    }
    
    private fun getMemoryUsage(): Map<String, Any> {
        val runtime = Runtime.getRuntime()
        return mapOf(
            "totalMemory" to runtime.totalMemory(),
            "freeMemory" to runtime.freeMemory(),
            "maxMemory" to runtime.maxMemory(),
            "usedMemory" to (runtime.totalMemory() - runtime.freeMemory())
        )
    }
    
    private fun isLowMemoryDevice(): Boolean {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
        return activityManager.isLowRamDevice
    }
}