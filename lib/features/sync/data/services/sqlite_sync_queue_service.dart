import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';

import 'package:cherry_note/features/sync/domain/entities/sync_operation.dart';
import 'package:cherry_note/features/sync/domain/services/sync_queue_service.dart';
import 'package:cherry_note/features/sync/data/datasources/local_cache_service.dart';
import 'package:cherry_note/core/error/exceptions.dart';

/// SQLite实现的同步队列服务
class SqliteSyncQueueService implements SyncQueueService {
  final LocalCacheService _cacheService;
  final Uuid _uuid = const Uuid();
  final StreamController<SyncQueueEvent> _eventController = StreamController.broadcast();

  SqliteSyncQueueService(this._cacheService);

  @override
  Stream<SyncQueueEvent> get queueEvents => _eventController.stream;

  @override
  Future<void> enqueue(SyncOperation operation) async {
    try {
      // 检查是否已存在相同文件和操作类型的待执行操作
      final existingOps = await getOperationsForFile(operation.filePath);
      final duplicateOp = existingOps.where((op) => 
        op.type == operation.type && op.needsExecution).firstOrNull;

      if (duplicateOp != null) {
        // 如果存在重复操作，更新现有操作而不是创建新的
        final updatedOp = duplicateOp.copyWith(
          createdAt: operation.createdAt,
          metadata: operation.metadata,
        );
        await updateOperation(updatedOp);
        return;
      }

      // 将操作序列化为JSON并存储
      final operationJson = _serializeOperation(operation);
      await _cacheService.setSetting('sync_op_${operation.id}', operationJson);

      // 发送事件
      _eventController.add(OperationEnqueuedEvent(
        operation: operation,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      throw SyncException('Failed to enqueue operation: $e');
    }
  }

  @override
  Future<void> enqueueAll(List<SyncOperation> operations) async {
    for (final operation in operations) {
      await enqueue(operation);
    }
  }

  @override
  Future<SyncOperation?> dequeue() async {
    try {
      final pendingOps = await getPendingOperations();
      if (pendingOps.isEmpty) return null;

      // 按优先级排序：先处理删除操作，再处理上传，最后处理下载
      pendingOps.sort((a, b) {
        final priorityA = _getOperationPriority(a.type);
        final priorityB = _getOperationPriority(b.type);
        if (priorityA != priorityB) {
          return priorityA.compareTo(priorityB);
        }
        // 相同优先级按创建时间排序
        return a.createdAt.compareTo(b.createdAt);
      });

      final nextOp = pendingOps.first;
      
      // 标记为进行中
      final inProgressOp = nextOp.copyWith(status: SyncOperationStatus.inProgress);
      await updateOperation(inProgressOp);

      return inProgressOp;
    } catch (e) {
      throw SyncException('Failed to dequeue operation: $e');
    }
  }

  @override
  Future<List<SyncOperation>> getPendingOperations() async {
    try {
      final allOps = await _getAllOperations();
      return allOps.where((op) => op.needsExecution).toList();
    } catch (e) {
      throw SyncException('Failed to get pending operations: $e');
    }
  }

  @override
  Future<List<SyncOperation>> getOperationsForFile(String filePath) async {
    try {
      final allOps = await _getAllOperations();
      return allOps.where((op) => op.filePath == filePath).toList();
    } catch (e) {
      throw SyncException('Failed to get operations for file: $e');
    }
  }

  @override
  Future<void> updateOperation(SyncOperation operation) async {
    try {
      final operationJson = _serializeOperation(operation);
      await _cacheService.setSetting('sync_op_${operation.id}', operationJson);

      // 发送更新事件
      _eventController.add(OperationUpdatedEvent(
        operation: operation,
        previousStatus: operation.status, // 这里简化处理，实际应该传入之前的状态
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      throw SyncException('Failed to update operation: $e');
    }
  }

  @override
  Future<void> markAsCompleted(String operationId) async {
    try {
      final operation = await _getOperationById(operationId);
      if (operation == null) return;

      final completedOp = operation.copyWith(
        status: SyncOperationStatus.completed,
        completedAt: DateTime.now(),
      );
      
      await updateOperation(completedOp);

      _eventController.add(OperationCompletedEvent(
        operation: completedOp,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      throw SyncException('Failed to mark operation as completed: $e');
    }
  }

  @override
  Future<void> markAsFailed(String operationId, String errorMessage) async {
    try {
      final operation = await _getOperationById(operationId);
      if (operation == null) return;

      final failedOp = operation.copyWith(
        status: SyncOperationStatus.failed,
        retryCount: operation.retryCount + 1,
        errorMessage: errorMessage,
      );
      
      await updateOperation(failedOp);

      _eventController.add(OperationFailedEvent(
        operation: failedOp,
        errorMessage: errorMessage,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      throw SyncException('Failed to mark operation as failed: $e');
    }
  }

  @override
  Future<void> cancelOperation(String operationId) async {
    try {
      final operation = await _getOperationById(operationId);
      if (operation == null) return;

      final cancelledOp = operation.copyWith(
        status: SyncOperationStatus.cancelled,
        completedAt: DateTime.now(),
      );
      
      await updateOperation(cancelledOp);
    } catch (e) {
      throw SyncException('Failed to cancel operation: $e');
    }
  }

  @override
  Future<void> removeOperation(String operationId) async {
    try {
      await _cacheService.removeSetting('sync_op_$operationId');
    } catch (e) {
      throw SyncException('Failed to remove operation: $e');
    }
  }

  @override
  Future<void> clearQueue() async {
    try {
      final allOps = await _getAllOperations();
      for (final op in allOps) {
        await removeOperation(op.id);
      }
    } catch (e) {
      throw SyncException('Failed to clear queue: $e');
    }
  }

  @override
  Future<void> cleanupCompletedOperations({Duration? olderThan}) async {
    try {
      final cutoffTime = DateTime.now().subtract(olderThan ?? const Duration(days: 7));
      final allOps = await _getAllOperations();
      
      for (final op in allOps) {
        if (op.isFinished && op.createdAt.isBefore(cutoffTime)) {
          await removeOperation(op.id);
        }
      }
    } catch (e) {
      throw SyncException('Failed to cleanup completed operations: $e');
    }
  }

  @override
  Future<SyncQueueStats> getQueueStats() async {
    try {
      final allOps = await _getAllOperations();
      
      return SyncQueueStats(
        totalOperations: allOps.length,
        pendingOperations: allOps.where((op) => op.status == SyncOperationStatus.pending).length,
        inProgressOperations: allOps.where((op) => op.status == SyncOperationStatus.inProgress).length,
        completedOperations: allOps.where((op) => op.status == SyncOperationStatus.completed).length,
        failedOperations: allOps.where((op) => op.status == SyncOperationStatus.failed).length,
        cancelledOperations: allOps.where((op) => op.status == SyncOperationStatus.cancelled).length,
      );
    } catch (e) {
      throw SyncException('Failed to get queue stats: $e');
    }
  }

  @override
  Future<bool> hasPendingOperations() async {
    try {
      final pendingOps = await getPendingOperations();
      return pendingOps.isNotEmpty;
    } catch (e) {
      throw SyncException('Failed to check pending operations: $e');
    }
  }

  @override
  Future<List<SyncOperation>> getFailedOperations() async {
    try {
      final allOps = await _getAllOperations();
      return allOps.where((op) => op.status == SyncOperationStatus.failed).toList();
    } catch (e) {
      throw SyncException('Failed to get failed operations: $e');
    }
  }

  @override
  Future<void> retryFailedOperations() async {
    try {
      final failedOps = await getFailedOperations();
      for (final op in failedOps) {
        if (op.canRetry) {
          final retryOp = op.copyWith(
            status: SyncOperationStatus.pending,
            errorMessage: null,
          );
          await updateOperation(retryOp);
        }
      }
    } catch (e) {
      throw SyncException('Failed to retry failed operations: $e');
    }
  }

  /// 获取操作优先级（数字越小优先级越高）
  int _getOperationPriority(SyncOperationType type) {
    switch (type) {
      case SyncOperationType.delete:
        return 1;
      case SyncOperationType.upload:
        return 2;
      case SyncOperationType.download:
        return 3;
    }
  }

  /// 获取所有操作
  Future<List<SyncOperation>> _getAllOperations() async {
    try {
      final operationSettings = await _cacheService.getSettingsWithPrefix('sync_op_');
      final operations = <SyncOperation>[];
      
      for (final entry in operationSettings.entries) {
        try {
          final operation = _deserializeOperation(entry.value);
          operations.add(operation);
        } catch (e) {
          // 忽略无法反序列化的操作，可能是损坏的数据
          continue;
        }
      }
      
      return operations;
    } catch (e) {
      throw SyncException('Failed to get all operations: $e');
    }
  }

  /// 根据ID获取操作
  Future<SyncOperation?> _getOperationById(String operationId) async {
    try {
      final operationJson = await _cacheService.getSetting('sync_op_$operationId');
      if (operationJson == null) return null;
      
      return _deserializeOperation(operationJson);
    } catch (e) {
      return null;
    }
  }

  /// 序列化操作为JSON字符串
  String _serializeOperation(SyncOperation operation) {
    return jsonEncode({
      'id': operation.id,
      'filePath': operation.filePath,
      'type': operation.type.value,
      'status': operation.status.value,
      'createdAt': operation.createdAt.toIso8601String(),
      'scheduledAt': operation.scheduledAt?.toIso8601String(),
      'completedAt': operation.completedAt?.toIso8601String(),
      'retryCount': operation.retryCount,
      'maxRetries': operation.maxRetries,
      'errorMessage': operation.errorMessage,
      'metadata': operation.metadata,
    });
  }

  /// 从JSON字符串反序列化操作
  SyncOperation _deserializeOperation(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    
    return SyncOperation(
      id: data['id'] as String,
      filePath: data['filePath'] as String,
      type: SyncOperationType.fromString(data['type'] as String),
      status: SyncOperationStatus.fromString(data['status'] as String),
      createdAt: DateTime.parse(data['createdAt'] as String),
      scheduledAt: data['scheduledAt'] != null 
          ? DateTime.parse(data['scheduledAt'] as String) 
          : null,
      completedAt: data['completedAt'] != null 
          ? DateTime.parse(data['completedAt'] as String) 
          : null,
      retryCount: data['retryCount'] as int? ?? 0,
      maxRetries: data['maxRetries'] as int? ?? 3,
      errorMessage: data['errorMessage'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 释放资源
  void dispose() {
    _eventController.close();
  }
}