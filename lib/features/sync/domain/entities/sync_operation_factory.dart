import 'package:uuid/uuid.dart';
import 'package:cherry_note/features/sync/domain/entities/sync_operation.dart';

/// 同步操作工厂类
class SyncOperationFactory {
  static const Uuid _uuid = Uuid();

  /// 创建上传操作
  static SyncOperation createUploadOperation({
    required String filePath,
    Map<String, dynamic>? metadata,
    int maxRetries = 3,
  }) {
    return SyncOperation(
      id: _uuid.v4(),
      filePath: filePath,
      type: SyncOperationType.upload,
      createdAt: DateTime.now(),
      maxRetries: maxRetries,
      metadata: metadata,
    );
  }

  /// 创建下载操作
  static SyncOperation createDownloadOperation({
    required String filePath,
    Map<String, dynamic>? metadata,
    int maxRetries = 3,
  }) {
    return SyncOperation(
      id: _uuid.v4(),
      filePath: filePath,
      type: SyncOperationType.download,
      createdAt: DateTime.now(),
      maxRetries: maxRetries,
      metadata: metadata,
    );
  }

  /// 创建删除操作
  static SyncOperation createDeleteOperation({
    required String filePath,
    Map<String, dynamic>? metadata,
    int maxRetries = 3,
  }) {
    return SyncOperation(
      id: _uuid.v4(),
      filePath: filePath,
      type: SyncOperationType.delete,
      createdAt: DateTime.now(),
      maxRetries: maxRetries,
      metadata: metadata,
    );
  }

  /// 创建延迟执行的操作
  static SyncOperation createScheduledOperation({
    required String filePath,
    required SyncOperationType type,
    required DateTime scheduledAt,
    Map<String, dynamic>? metadata,
    int maxRetries = 3,
  }) {
    return SyncOperation(
      id: _uuid.v4(),
      filePath: filePath,
      type: type,
      createdAt: DateTime.now(),
      scheduledAt: scheduledAt,
      maxRetries: maxRetries,
      metadata: metadata,
    );
  }

  /// 从现有操作创建重试操作
  static SyncOperation createRetryOperation(SyncOperation originalOperation) {
    return SyncOperation(
      id: _uuid.v4(),
      filePath: originalOperation.filePath,
      type: originalOperation.type,
      status: SyncOperationStatus.pending,
      createdAt: DateTime.now(),
      scheduledAt: null,
      completedAt: null,
      retryCount: 0,
      maxRetries: originalOperation.maxRetries,
      errorMessage: null,
      metadata: originalOperation.metadata,
    );
  }
}