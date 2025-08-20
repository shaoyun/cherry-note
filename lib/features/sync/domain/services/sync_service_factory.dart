import 'package:cherry_note/features/sync/domain/services/sync_service.dart';
import 'package:cherry_note/features/sync/data/services/sync_service_impl.dart';
import 'package:cherry_note/features/sync/domain/services/sync_queue_service.dart';
import 'package:cherry_note/features/sync/domain/repositories/s3_storage_repository.dart';
import 'package:cherry_note/features/sync/data/datasources/local_cache_service.dart';

/// 同步服务工厂
class SyncServiceFactory {
  /// 创建同步服务实例
  static SyncService create({
    required S3StorageRepository storageRepository,
    required LocalCacheService cacheService,
    required SyncQueueService queueService,
  }) {
    return SyncServiceImpl(
      storageRepository: storageRepository,
      cacheService: cacheService,
      queueService: queueService,
    );
  }
}