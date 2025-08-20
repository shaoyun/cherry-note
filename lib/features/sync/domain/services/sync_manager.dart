import 'dart:async';

import 'package:cherry_note/features/sync/domain/services/sync_service.dart';
import 'package:cherry_note/features/sync/domain/services/sync_queue_service.dart';
import 'package:cherry_note/features/sync/domain/entities/sync_operation.dart';
import 'package:cherry_note/features/sync/domain/entities/sync_operation_factory.dart';

/// 同步管理器
/// 协调同步服务和队列服务，提供统一的同步管理接口
class SyncManager {
  final SyncService _syncService;
  final SyncQueueService _queueService;

  Timer? _queueProcessorTimer;
  bool _isProcessingQueue = false;

  SyncManager({
    required SyncService syncService,
    required SyncQueueService queueService,
  })  : _syncService = syncService,
        _queueService = queueService;

  /// 启动同步管理器
  Future<void> start() async {
    // 启动队列处理器
    _startQueueProcessor();
    
    // 启动自动同步
    await _syncService.enableAutoSync();
  }

  /// 停止同步管理器
  Future<void> stop() async {
    // 停止队列处理器
    _stopQueueProcessor();
    
    // 停止自动同步
    await _syncService.disableAutoSync();
  }

  /// 添加文件到同步队列
  Future<void> scheduleFileUpload(String filePath, {Map<String, dynamic>? metadata}) async {
    final operation = SyncOperationFactory.createUploadOperation(
      filePath: filePath,
      metadata: metadata,
    );
    await _queueService.enqueue(operation);
  }

  /// 添加文件下载到同步队列
  Future<void> scheduleFileDownload(String filePath, {Map<String, dynamic>? metadata}) async {
    final operation = SyncOperationFactory.createDownloadOperation(
      filePath: filePath,
      metadata: metadata,
    );
    await _queueService.enqueue(operation);
  }

  /// 添加文件删除到同步队列
  Future<void> scheduleFileDelete(String filePath, {Map<String, dynamic>? metadata}) async {
    final operation = SyncOperationFactory.createDeleteOperation(
      filePath: filePath,
      metadata: metadata,
    );
    await _queueService.enqueue(operation);
  }

  /// 立即同步文件
  Future<SyncResult> syncFileNow(String filePath) async {
    return await _syncService.syncFile(filePath);
  }

  /// 执行完整同步
  Future<SyncResult> performFullSync() async {
    return await _syncService.fullSync();
  }

  /// 获取同步状态
  Future<SyncInfo> getSyncStatus() async {
    return await _syncService.getSyncInfo();
  }

  /// 获取队列统计
  Future<SyncQueueStats> getQueueStats() async {
    return await _queueService.getQueueStats();
  }

  /// 获取冲突列表
  Future<List<FileConflict>> getConflicts() async {
    return await _syncService.getConflicts();
  }

  /// 解决冲突
  Future<void> resolveConflict(String filePath, ConflictResolution resolution) async {
    await _syncService.handleConflict(filePath, resolution);
  }

  /// 暂停同步
  Future<void> pauseSync() async {
    await _syncService.pauseSync();
    _stopQueueProcessor();
  }

  /// 恢复同步
  Future<void> resumeSync() async {
    await _syncService.resumeSync();
    _startQueueProcessor();
  }

  /// 检查是否有待处理的操作
  Future<bool> hasPendingOperations() async {
    return await _queueService.hasPendingOperations();
  }

  /// 清理已完成的操作
  Future<void> cleanup() async {
    await _syncService.cleanup();
  }

  /// 重置同步状态
  Future<void> reset() async {
    _stopQueueProcessor();
    await _syncService.resetSync();
    await _queueService.clearQueue();
  }

  /// 同步状态流
  Stream<SyncStatus> get syncStatusStream => _syncService.syncStatusStream;

  /// 队列事件流
  Stream<SyncQueueEvent> get queueEventStream => _queueService.queueEvents;

  /// 启动队列处理器
  void _startQueueProcessor() {
    if (_queueProcessorTimer != null) return;

    _queueProcessorTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _processQueue(),
    );
  }

  /// 停止队列处理器
  void _stopQueueProcessor() {
    _queueProcessorTimer?.cancel();
    _queueProcessorTimer = null;
  }

  /// 处理队列中的操作
  Future<void> _processQueue() async {
    if (_isProcessingQueue || _syncService.isSyncPaused || !_syncService.isOnline) {
      return;
    }

    _isProcessingQueue = true;

    try {
      final operation = await _queueService.dequeue();
      if (operation == null) return;

      SyncResult result;
      switch (operation.type) {
        case SyncOperationType.upload:
          result = await _syncService.uploadFile(operation.filePath);
          break;
        case SyncOperationType.download:
          result = await _syncService.downloadFile(operation.filePath);
          break;
        case SyncOperationType.delete:
          result = await _syncService.deleteFile(operation.filePath);
          break;
      }

      if (result.success) {
        await _queueService.markAsCompleted(operation.id);
      } else {
        await _queueService.markAsFailed(operation.id, result.error ?? 'Unknown error');
      }
    } catch (e) {
      // 处理队列时出错，继续处理下一个
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// 释放资源
  void dispose() {
    _stopQueueProcessor();
  }
}