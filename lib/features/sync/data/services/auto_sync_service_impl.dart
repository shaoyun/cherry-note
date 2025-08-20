import 'dart:async';
import 'dart:convert';

import 'package:cherry_note/features/sync/domain/services/auto_sync_service.dart';
import 'package:cherry_note/features/sync/domain/services/sync_manager.dart';
import 'package:cherry_note/features/sync/data/datasources/local_cache_service.dart';
import 'package:cherry_note/core/error/exceptions.dart';

/// 自动同步服务实现
class AutoSyncServiceImpl implements AutoSyncService {
  final SyncManager _syncManager;
  final LocalCacheService _cacheService;

  AutoSyncConfig _config = const AutoSyncConfig();
  AutoSyncState _state = AutoSyncState.disabled;

  Timer? _periodicSyncTimer;
  Timer? _debounceTimer;
  final Set<String> _pendingFileChanges = {};

  final StreamController<AutoSyncEvent> _eventController = StreamController.broadcast();
  final StreamController<AutoSyncState> _stateController = StreamController.broadcast();

  // 统计信息
  int _totalSyncs = 0;
  int _successfulSyncs = 0;
  int _failedSyncs = 0;
  int _periodicSyncs = 0;
  int _fileChangeSyncs = 0;
  int _appStartSyncs = 0;
  DateTime? _lastSyncTime;
  DateTime? _lastSuccessfulSyncTime;
  String? _lastError;

  AutoSyncServiceImpl({
    required SyncManager syncManager,
    required LocalCacheService cacheService,
  })  : _syncManager = syncManager,
        _cacheService = cacheService;

  @override
  Stream<AutoSyncEvent> get eventStream => _eventController.stream;

  @override
  Stream<AutoSyncState> get stateStream => _stateController.stream;

  @override
  AutoSyncState get state => _state;

  @override
  bool get isEnabled => _state != AutoSyncState.disabled;

  @override
  bool get isPaused => _state == AutoSyncState.paused;

  @override
  bool get isSyncing => _state == AutoSyncState.syncing;

  // ========== 配置和控制 ==========

  @override
  Future<void> configure(AutoSyncConfig config) async {
    try {
      _config = config;
      
      // 保存配置到本地存储
      await _saveConfig();

      // 如果已启用，重新启动定时器
      if (isEnabled) {
        await _startPeriodicSync();
      }
    } catch (e) {
      throw SyncException('Failed to configure auto sync: $e');
    }
  }

  @override
  Future<AutoSyncConfig> getConfig() async {
    try {
      await _loadConfig();
      return _config;
    } catch (e) {
      return _config;
    }
  }

  @override
  Future<void> enable() async {
    if (_state == AutoSyncState.disabled) {
      await _loadConfig();
      await _loadStats();
      
      _setState(AutoSyncState.enabled);
      await _startPeriodicSync();

      // 如果配置了应用启动时同步，立即执行一次
      if (_config.syncOnAppStart) {
        await onAppStart();
      }
    }
  }

  @override
  Future<void> disable() async {
    await _stopPeriodicSync();
    await _stopDebounceTimer();
    _setState(AutoSyncState.disabled);
    await _saveStats();
  }

  @override
  Future<void> pause() async {
    if (isEnabled) {
      await _stopPeriodicSync();
      await _stopDebounceTimer();
      _setState(AutoSyncState.paused);
    }
  }

  @override
  Future<void> resume() async {
    if (_state == AutoSyncState.paused) {
      _setState(AutoSyncState.enabled);
      await _startPeriodicSync();
    }
  }

  // ========== 手动触发 ==========

  @override
  Future<void> triggerSync({String? reason}) async {
    if (!isEnabled || _state == AutoSyncState.syncing) {
      return;
    }

    await _performSync(reason: reason ?? 'manual');
  }

  @override
  Future<void> triggerFileSync(String filePath) async {
    if (!isEnabled) {
      return;
    }

    try {
      _setState(AutoSyncState.syncing);
      await _syncManager.syncFileNow(filePath);
      _recordSyncSuccess('file_sync');
    } catch (e) {
      _recordSyncFailure(e.toString());
    } finally {
      _setState(AutoSyncState.enabled);
    }
  }

  // ========== 文件变更监听 ==========

  @override
  void onFileCreated(String filePath) {
    if (_config.syncOnFileChange && !_isExcluded(filePath)) {
      _pendingFileChanges.add(filePath);
      _scheduleFileChangeSync('created', filePath);
    }
  }

  @override
  void onFileModified(String filePath) {
    if (_config.syncOnFileChange && !_isExcluded(filePath)) {
      _pendingFileChanges.add(filePath);
      _scheduleFileChangeSync('modified', filePath);
    }
  }

  @override
  void onFileDeleted(String filePath) {
    if (_config.syncOnFileChange && !_isExcluded(filePath)) {
      _pendingFileChanges.add(filePath);
      _scheduleFileChangeSync('deleted', filePath);
    }
  }

  // ========== 应用生命周期 ==========

  @override
  Future<void> onAppStart() async {
    if (_config.syncOnAppStart && isEnabled) {
      _eventController.add(AppStartSyncEvent(timestamp: DateTime.now()));
      await _performSync(reason: 'app_start');
      _appStartSyncs++;
    }
  }

  @override
  Future<void> onAppResume() async {
    if (_config.syncOnAppResume && isEnabled) {
      _eventController.add(AppResumeSyncEvent(timestamp: DateTime.now()));
      await _performSync(reason: 'app_resume');
    }
  }

  @override
  Future<void> onAppPause() async {
    // 应用暂停时保存统计信息
    await _saveStats();
  }

  // ========== 统计和监控 ==========

  @override
  Future<AutoSyncStats> getStats() async {
    return AutoSyncStats(
      totalSyncs: _totalSyncs,
      successfulSyncs: _successfulSyncs,
      failedSyncs: _failedSyncs,
      periodicSyncs: _periodicSyncs,
      fileChangeSyncs: _fileChangeSyncs,
      appStartSyncs: _appStartSyncs,
      lastSyncTime: _lastSyncTime,
      lastSuccessfulSyncTime: _lastSuccessfulSyncTime,
      lastError: _lastError,
    );
  }

  @override
  Future<void> resetStats() async {
    _totalSyncs = 0;
    _successfulSyncs = 0;
    _failedSyncs = 0;
    _periodicSyncs = 0;
    _fileChangeSyncs = 0;
    _appStartSyncs = 0;
    _lastSyncTime = null;
    _lastSuccessfulSyncTime = null;
    _lastError = null;

    await _saveStats();
  }

  // ========== 清理和维护 ==========

  @override
  Future<void> cleanup() async {
    await _stopPeriodicSync();
    await _stopDebounceTimer();
    await _saveStats();
    await _saveConfig();
  }

  // ========== 私有方法 ==========

  /// 设置状态并通知
  void _setState(AutoSyncState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  /// 启动定时同步
  Future<void> _startPeriodicSync() async {
    await _stopPeriodicSync();
    
    _periodicSyncTimer = Timer.periodic(_config.syncInterval, (_) async {
      if (_state == AutoSyncState.enabled) {
        _eventController.add(PeriodicSyncEvent(timestamp: DateTime.now()));
        await _performSync(reason: 'periodic');
        _periodicSyncs++;
      }
    });
  }

  /// 停止定时同步
  Future<void> _stopPeriodicSync() async {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  /// 调度文件变更同步
  void _scheduleFileChangeSync(String changeType, String filePath) {
    _eventController.add(FileChangeSyncEvent(
      filePath: filePath,
      changeType: changeType,
      timestamp: DateTime.now(),
    ));

    // 使用防抖动机制，避免频繁同步
    _stopDebounceTimer();
    _debounceTimer = Timer(_config.debounceDelay, () async {
      if (_state == AutoSyncState.enabled && _pendingFileChanges.isNotEmpty) {
        await _performFileChangeSync();
      }
    });
  }

  /// 停止防抖动定时器
  void _stopDebounceTimer() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// 执行文件变更同步
  Future<void> _performFileChangeSync() async {
    if (_pendingFileChanges.isEmpty) return;

    try {
      _setState(AutoSyncState.syncing);
      
      // 同步所有待处理的文件
      for (final filePath in _pendingFileChanges) {
        await _syncManager.syncFileNow(filePath);
      }
      
      _recordSyncSuccess('file_change');
      _fileChangeSyncs++;
      _pendingFileChanges.clear();
    } catch (e) {
      _recordSyncFailure(e.toString());
    } finally {
      _setState(AutoSyncState.enabled);
    }
  }

  /// 执行同步
  Future<void> _performSync({required String reason}) async {
    if (_state == AutoSyncState.syncing) {
      return; // 避免并发同步
    }

    try {
      _setState(AutoSyncState.syncing);
      
      final result = await _syncManager.performFullSync();
      
      if (result.success) {
        _recordSyncSuccess(reason);
      } else {
        _recordSyncFailure(result.error ?? 'Unknown error');
      }
    } catch (e) {
      _recordSyncFailure(e.toString());
    } finally {
      _setState(AutoSyncState.enabled);
    }
  }

  /// 记录同步成功
  void _recordSyncSuccess(String reason) {
    _totalSyncs++;
    _successfulSyncs++;
    _lastSyncTime = DateTime.now();
    _lastSuccessfulSyncTime = _lastSyncTime;
    _lastError = null;
    _setState(AutoSyncState.enabled);
  }

  /// 记录同步失败
  void _recordSyncFailure(String error) {
    _totalSyncs++;
    _failedSyncs++;
    _lastSyncTime = DateTime.now();
    _lastError = error;
    _setState(AutoSyncState.error);
  }

  /// 检查文件是否被排除
  bool _isExcluded(String filePath) {
    for (final pattern in _config.excludePatterns) {
      if (filePath.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  /// 保存配置
  Future<void> _saveConfig() async {
    try {
      final configJson = jsonEncode({
        'syncInterval': _config.syncInterval.inMinutes,
        'debounceDelay': _config.debounceDelay.inSeconds,
        'syncOnFileChange': _config.syncOnFileChange,
        'syncOnAppStart': _config.syncOnAppStart,
        'syncOnAppResume': _config.syncOnAppResume,
        'maxRetries': _config.maxRetries,
        'retryDelay': _config.retryDelay.inMinutes,
        'excludePatterns': _config.excludePatterns,
      });
      
      await _cacheService.setSetting('auto_sync_config', configJson);
    } catch (e) {
      // 保存配置失败不影响功能
    }
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    try {
      final configJson = await _cacheService.getSetting('auto_sync_config');
      if (configJson == null) return;

      final configData = jsonDecode(configJson) as Map<String, dynamic>;
      _config = AutoSyncConfig(
        syncInterval: Duration(minutes: configData['syncInterval'] as int? ?? 5),
        debounceDelay: Duration(seconds: configData['debounceDelay'] as int? ?? 30),
        syncOnFileChange: configData['syncOnFileChange'] as bool? ?? true,
        syncOnAppStart: configData['syncOnAppStart'] as bool? ?? true,
        syncOnAppResume: configData['syncOnAppResume'] as bool? ?? true,
        maxRetries: configData['maxRetries'] as int? ?? 3,
        retryDelay: Duration(minutes: configData['retryDelay'] as int? ?? 1),
        excludePatterns: (configData['excludePatterns'] as List<dynamic>?)
            ?.cast<String>() ?? [],
      );
    } catch (e) {
      // 加载配置失败使用默认配置
      _config = const AutoSyncConfig();
    }
  }

  /// 保存统计信息
  Future<void> _saveStats() async {
    try {
      final statsJson = jsonEncode({
        'totalSyncs': _totalSyncs,
        'successfulSyncs': _successfulSyncs,
        'failedSyncs': _failedSyncs,
        'periodicSyncs': _periodicSyncs,
        'fileChangeSyncs': _fileChangeSyncs,
        'appStartSyncs': _appStartSyncs,
        'lastSyncTime': _lastSyncTime?.toIso8601String(),
        'lastSuccessfulSyncTime': _lastSuccessfulSyncTime?.toIso8601String(),
        'lastError': _lastError,
      });
      
      await _cacheService.setSetting('auto_sync_stats', statsJson);
    } catch (e) {
      // 保存统计失败不影响功能
    }
  }

  /// 加载统计信息
  Future<void> _loadStats() async {
    try {
      final statsJson = await _cacheService.getSetting('auto_sync_stats');
      if (statsJson == null) return;

      final statsData = jsonDecode(statsJson) as Map<String, dynamic>;
      _totalSyncs = statsData['totalSyncs'] as int? ?? 0;
      _successfulSyncs = statsData['successfulSyncs'] as int? ?? 0;
      _failedSyncs = statsData['failedSyncs'] as int? ?? 0;
      _periodicSyncs = statsData['periodicSyncs'] as int? ?? 0;
      _fileChangeSyncs = statsData['fileChangeSyncs'] as int? ?? 0;
      _appStartSyncs = statsData['appStartSyncs'] as int? ?? 0;
      
      final lastSyncStr = statsData['lastSyncTime'] as String?;
      _lastSyncTime = lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;
      
      final lastSuccessfulSyncStr = statsData['lastSuccessfulSyncTime'] as String?;
      _lastSuccessfulSyncTime = lastSuccessfulSyncStr != null 
          ? DateTime.parse(lastSuccessfulSyncStr) 
          : null;
      
      _lastError = statsData['lastError'] as String?;
    } catch (e) {
      // 加载统计失败不影响功能
    }
  }

  /// 释放资源
  void dispose() {
    _periodicSyncTimer?.cancel();
    _debounceTimer?.cancel();
    _eventController.close();
    _stateController.close();
  }
}