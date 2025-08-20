import 'package:cherry_note/features/sync/domain/entities/sync_operation.dart';

/// 同步队列服务接口
abstract class SyncQueueService {
  /// 添加同步操作到队列
  Future<void> enqueue(SyncOperation operation);

  /// 批量添加同步操作
  Future<void> enqueueAll(List<SyncOperation> operations);

  /// 获取下一个待执行的操作
  Future<SyncOperation?> dequeue();

  /// 获取所有待执行的操作
  Future<List<SyncOperation>> getPendingOperations();

  /// 获取指定文件的操作
  Future<List<SyncOperation>> getOperationsForFile(String filePath);

  /// 更新操作状态
  Future<void> updateOperation(SyncOperation operation);

  /// 标记操作为完成
  Future<void> markAsCompleted(String operationId);

  /// 标记操作为失败并增加重试次数
  Future<void> markAsFailed(String operationId, String errorMessage);

  /// 取消操作
  Future<void> cancelOperation(String operationId);

  /// 删除操作
  Future<void> removeOperation(String operationId);

  /// 清空队列
  Future<void> clearQueue();

  /// 清理已完成的操作
  Future<void> cleanupCompletedOperations({Duration? olderThan});

  /// 获取队列统计信息
  Future<SyncQueueStats> getQueueStats();

  /// 检查是否有待执行的操作
  Future<bool> hasPendingOperations();

  /// 获取失败的操作列表
  Future<List<SyncOperation>> getFailedOperations();

  /// 重置失败的操作以便重试
  Future<void> retryFailedOperations();

  /// 监听队列变化
  Stream<SyncQueueEvent> get queueEvents;
}

/// 同步队列统计信息
class SyncQueueStats {
  final int totalOperations;
  final int pendingOperations;
  final int inProgressOperations;
  final int completedOperations;
  final int failedOperations;
  final int cancelledOperations;

  const SyncQueueStats({
    required this.totalOperations,
    required this.pendingOperations,
    required this.inProgressOperations,
    required this.completedOperations,
    required this.failedOperations,
    required this.cancelledOperations,
  });

  @override
  String toString() {
    return 'SyncQueueStats(total: $totalOperations, pending: $pendingOperations, '
        'inProgress: $inProgressOperations, completed: $completedOperations, '
        'failed: $failedOperations, cancelled: $cancelledOperations)';
  }
}

/// 同步队列事件
abstract class SyncQueueEvent {
  final DateTime timestamp;

  const SyncQueueEvent({required this.timestamp});
}

/// 操作添加事件
class OperationEnqueuedEvent extends SyncQueueEvent {
  final SyncOperation operation;

  const OperationEnqueuedEvent({
    required this.operation,
    required DateTime timestamp,
  }) : super(timestamp: timestamp);
}

/// 操作状态更新事件
class OperationUpdatedEvent extends SyncQueueEvent {
  final SyncOperation operation;
  final SyncOperationStatus previousStatus;

  const OperationUpdatedEvent({
    required this.operation,
    required this.previousStatus,
    required DateTime timestamp,
  }) : super(timestamp: timestamp);
}

/// 操作完成事件
class OperationCompletedEvent extends SyncQueueEvent {
  final SyncOperation operation;

  const OperationCompletedEvent({
    required this.operation,
    required DateTime timestamp,
  }) : super(timestamp: timestamp);
}

/// 操作失败事件
class OperationFailedEvent extends SyncQueueEvent {
  final SyncOperation operation;
  final String errorMessage;

  const OperationFailedEvent({
    required this.operation,
    required this.errorMessage,
    required DateTime timestamp,
  }) : super(timestamp: timestamp);
}