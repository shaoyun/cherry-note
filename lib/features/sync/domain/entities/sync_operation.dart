import 'package:equatable/equatable.dart';

/// 同步操作类型
enum SyncOperationType {
  upload('upload'),
  download('download'),
  delete('delete');

  const SyncOperationType(this.value);
  final String value;

  static SyncOperationType fromString(String value) {
    return SyncOperationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SyncOperationType.upload,
    );
  }
}

/// 同步操作状态
enum SyncOperationStatus {
  pending('pending'),
  inProgress('in_progress'),
  completed('completed'),
  failed('failed'),
  cancelled('cancelled');

  const SyncOperationStatus(this.value);
  final String value;

  static SyncOperationStatus fromString(String value) {
    return SyncOperationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SyncOperationStatus.pending,
    );
  }
}

/// 同步操作实体
class SyncOperation extends Equatable {
  final String id;
  final String filePath;
  final SyncOperationType type;
  final SyncOperationStatus status;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final int retryCount;
  final int maxRetries;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const SyncOperation({
    required this.id,
    required this.filePath,
    required this.type,
    this.status = SyncOperationStatus.pending,
    required this.createdAt,
    this.scheduledAt,
    this.completedAt,
    this.retryCount = 0,
    this.maxRetries = 3,
    this.errorMessage,
    this.metadata,
  });

  SyncOperation copyWith({
    String? id,
    String? filePath,
    SyncOperationType? type,
    SyncOperationStatus? status,
    DateTime? createdAt,
    DateTime? scheduledAt,
    DateTime? completedAt,
    int? retryCount,
    int? maxRetries,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      completedAt: completedAt ?? this.completedAt,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  /// 是否可以重试
  bool get canRetry => retryCount < maxRetries && status == SyncOperationStatus.failed;

  /// 是否已完成（成功或失败且不能重试）
  bool get isFinished => status == SyncOperationStatus.completed || 
                        status == SyncOperationStatus.cancelled ||
                        (status == SyncOperationStatus.failed && !canRetry);

  /// 是否需要执行
  bool get needsExecution => status == SyncOperationStatus.pending ||
                            (status == SyncOperationStatus.failed && canRetry);

  @override
  List<Object?> get props => [
    id,
    filePath,
    type,
    status,
    createdAt,
    scheduledAt,
    completedAt,
    retryCount,
    maxRetries,
    errorMessage,
    metadata,
  ];

  @override
  String toString() {
    return 'SyncOperation(id: $id, filePath: $filePath, type: $type, '
        'status: $status, retryCount: $retryCount/$maxRetries)';
  }
}