import 'package:equatable/equatable.dart';

/// 同步队列项
class SyncQueueItem extends Equatable {
  final String id;
  final String filePath;
  final String operation; // 'upload', 'download', 'delete'
  final DateTime createdAt;
  final int retryCount;

  const SyncQueueItem({
    required this.id,
    required this.filePath,
    required this.operation,
    required this.createdAt,
    this.retryCount = 0,
  });

  SyncQueueItem copyWith({
    String? id,
    String? filePath,
    String? operation,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      operation: operation ?? this.operation,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  List<Object> get props => [id, filePath, operation, createdAt, retryCount];

  @override
  String toString() {
    return 'SyncQueueItem(id: $id, filePath: $filePath, operation: $operation, '
        'createdAt: $createdAt, retryCount: $retryCount)';
  }
}