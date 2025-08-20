import 'package:cherry_note/features/sync/domain/entities/sync_queue_item.dart';

/// 本地缓存服务接口
abstract class LocalCacheService {
  /// 初始化数据库
  Future<void> initialize();

  /// 缓存管理
  Future<void> cacheFile(String path, String content);
  Future<String?> getCachedFile(String path);
  Future<void> clearCache();
  Future<List<String>> getCachedFiles();
  Future<void> removeCachedFile(String path);
  Future<bool> isCached(String path);
  Future<DateTime?> getCacheTimestamp(String path);

  /// 文件夹缓存
  Future<void> cacheFolderMetadata(String folderPath, String metadata);
  Future<String?> getCachedFolderMetadata(String folderPath);
  Future<void> removeCachedFolder(String folderPath);

  /// 离线支持 - 同步队列管理
  Future<void> markForSync(String path, String operation);
  Future<List<SyncQueueItem>> getPendingSyncItems();
  Future<void> clearSyncQueue();
  Future<void> removeSyncItem(String id);
  Future<void> updateSyncItemRetryCount(String id, int retryCount);

  /// 应用设置
  Future<void> setSetting(String key, String value);
  Future<String?> getSetting(String key);
  Future<void> removeSetting(String key);
  Future<List<String>> getSettingKeys({String? prefix});
  Future<Map<String, String>> getSettingsWithPrefix(String prefix);

  /// 数据库维护
  Future<void> vacuum();
  Future<int> getDatabaseSize();
  Future<void> close();
}