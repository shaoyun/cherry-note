import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:cherry_note/features/sync/data/datasources/local_cache_service.dart';
import 'package:cherry_note/features/sync/domain/entities/sync_queue_item.dart';
import 'package:cherry_note/core/error/exceptions.dart';

/// SQLite实现的本地缓存服务
class SqliteCacheService implements LocalCacheService {
  static const String _databaseName = 'cherry_note_cache.db';
  static const int _databaseVersion = 1;
  
  Database? _database;
  final Uuid _uuid = const Uuid();
  final String? _databasePath;

  /// 构造函数，可选择指定数据库路径（主要用于测试）
  SqliteCacheService({String? databasePath}) : _databasePath = databasePath;

  /// 获取数据库实例
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  @override
  Future<void> initialize() async {
    await database; // 确保数据库已初始化
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    try {
      String path;
      if (_databasePath != null) {
        // 测试模式：使用指定路径或内存数据库
        path = _databasePath!;
      } else {
        // 生产模式：使用应用文档目录
        final documentsDirectory = await getApplicationDocumentsDirectory();
        path = join(documentsDirectory.path, _databaseName);
      }
      
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      throw StorageException('Failed to initialize database: $e');
    }
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE file_cache (
        file_path TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        last_modified INTEGER NOT NULL,
        synced_at INTEGER,
        is_dirty INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE folder_cache (
        folder_path TEXT PRIMARY KEY,
        metadata TEXT,
        last_modified INTEGER NOT NULL,
        synced_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        file_path TEXT NOT NULL,
        operation TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 创建索引以提升查询性能
    await db.execute('CREATE INDEX idx_file_cache_modified ON file_cache(last_modified)');
    await db.execute('CREATE INDEX idx_sync_queue_created ON sync_queue(created_at)');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级时的处理逻辑
  }

  // ========== 文件缓存管理 ==========

  @override
  Future<void> cacheFile(String path, String content) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await db.insert(
        'file_cache',
        {
          'file_path': path,
          'content': content,
          'last_modified': now,
          'is_dirty': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw StorageException('Failed to cache file: $e');
    }
  }

  @override
  Future<String?> getCachedFile(String path) async {
    try {
      final db = await database;
      final result = await db.query(
        'file_cache',
        columns: ['content'],
        where: 'file_path = ?',
        whereArgs: [path],
      );
      
      return result.isNotEmpty ? result.first['content'] as String : null;
    } catch (e) {
      throw StorageException('Failed to get cached file: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final db = await database;
      await db.delete('file_cache');
      await db.delete('folder_cache');
    } catch (e) {
      throw StorageException('Failed to clear cache: $e');
    }
  }

  @override
  Future<List<String>> getCachedFiles() async {
    try {
      final db = await database;
      final result = await db.query(
        'file_cache',
        columns: ['file_path'],
        orderBy: 'last_modified DESC',
      );
      
      return result.map((row) => row['file_path'] as String).toList();
    } catch (e) {
      throw StorageException('Failed to get cached files: $e');
    }
  }

  @override
  Future<void> removeCachedFile(String path) async {
    try {
      final db = await database;
      await db.delete(
        'file_cache',
        where: 'file_path = ?',
        whereArgs: [path],
      );
    } catch (e) {
      throw StorageException('Failed to remove cached file: $e');
    }
  }

  @override
  Future<bool> isCached(String path) async {
    try {
      final db = await database;
      final result = await db.query(
        'file_cache',
        columns: ['file_path'],
        where: 'file_path = ?',
        whereArgs: [path],
      );
      
      return result.isNotEmpty;
    } catch (e) {
      throw StorageException('Failed to check cache status: $e');
    }
  }

  @override
  Future<DateTime?> getCacheTimestamp(String path) async {
    try {
      final db = await database;
      final result = await db.query(
        'file_cache',
        columns: ['last_modified'],
        where: 'file_path = ?',
        whereArgs: [path],
      );
      
      if (result.isNotEmpty) {
        final timestamp = result.first['last_modified'] as int;
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      throw StorageException('Failed to get cache timestamp: $e');
    }
  }

  // ========== 文件夹缓存管理 ==========

  @override
  Future<void> cacheFolderMetadata(String folderPath, String metadata) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await db.insert(
        'folder_cache',
        {
          'folder_path': folderPath,
          'metadata': metadata,
          'last_modified': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw StorageException('Failed to cache folder metadata: $e');
    }
  }

  @override
  Future<String?> getCachedFolderMetadata(String folderPath) async {
    try {
      final db = await database;
      final result = await db.query(
        'folder_cache',
        columns: ['metadata'],
        where: 'folder_path = ?',
        whereArgs: [folderPath],
      );
      
      return result.isNotEmpty ? result.first['metadata'] as String? : null;
    } catch (e) {
      throw StorageException('Failed to get cached folder metadata: $e');
    }
  }

  @override
  Future<void> removeCachedFolder(String folderPath) async {
    try {
      final db = await database;
      await db.delete(
        'folder_cache',
        where: 'folder_path = ?',
        whereArgs: [folderPath],
      );
    } catch (e) {
      throw StorageException('Failed to remove cached folder: $e');
    }
  }

  // ========== 同步队列管理 ==========

  @override
  Future<void> markForSync(String path, String operation) async {
    try {
      final db = await database;
      final id = _uuid.v4();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await db.insert(
        'sync_queue',
        {
          'id': id,
          'file_path': path,
          'operation': operation,
          'created_at': now,
          'retry_count': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw StorageException('Failed to mark file for sync: $e');
    }
  }

  @override
  Future<List<SyncQueueItem>> getPendingSyncItems() async {
    try {
      final db = await database;
      final result = await db.query(
        'sync_queue',
        orderBy: 'created_at ASC',
      );
      
      return result.map((row) => SyncQueueItem(
        id: row['id'] as String,
        filePath: row['file_path'] as String,
        operation: row['operation'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        retryCount: row['retry_count'] as int,
      )).toList();
    } catch (e) {
      throw StorageException('Failed to get pending sync items: $e');
    }
  }

  @override
  Future<void> clearSyncQueue() async {
    try {
      final db = await database;
      await db.delete('sync_queue');
    } catch (e) {
      throw StorageException('Failed to clear sync queue: $e');
    }
  }

  @override
  Future<void> removeSyncItem(String id) async {
    try {
      final db = await database;
      await db.delete(
        'sync_queue',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw StorageException('Failed to remove sync item: $e');
    }
  }

  @override
  Future<void> updateSyncItemRetryCount(String id, int retryCount) async {
    try {
      final db = await database;
      await db.update(
        'sync_queue',
        {'retry_count': retryCount},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw StorageException('Failed to update sync item retry count: $e');
    }
  }

  // ========== 应用设置管理 ==========

  @override
  Future<void> setSetting(String key, String value) async {
    try {
      final db = await database;
      await db.insert(
        'app_settings',
        {
          'key': key,
          'value': value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw StorageException('Failed to set setting: $e');
    }
  }

  @override
  Future<String?> getSetting(String key) async {
    try {
      final db = await database;
      final result = await db.query(
        'app_settings',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: [key],
      );
      
      return result.isNotEmpty ? result.first['value'] as String : null;
    } catch (e) {
      throw StorageException('Failed to get setting: $e');
    }
  }

  @override
  Future<void> removeSetting(String key) async {
    try {
      final db = await database;
      await db.delete(
        'app_settings',
        where: 'key = ?',
        whereArgs: [key],
      );
    } catch (e) {
      throw StorageException('Failed to remove setting: $e');
    }
  }

  @override
  Future<List<String>> getSettingKeys({String? prefix}) async {
    try {
      final db = await database;
      final result = await db.query(
        'app_settings',
        columns: ['key'],
        where: prefix != null ? 'key LIKE ?' : null,
        whereArgs: prefix != null ? ['$prefix%'] : null,
        orderBy: 'key',
      );
      
      return result.map((row) => row['key'] as String).toList();
    } catch (e) {
      throw StorageException('Failed to get setting keys: $e');
    }
  }

  @override
  Future<Map<String, String>> getSettingsWithPrefix(String prefix) async {
    try {
      final db = await database;
      final result = await db.query(
        'app_settings',
        where: 'key LIKE ?',
        whereArgs: ['$prefix%'],
        orderBy: 'key',
      );
      
      final settings = <String, String>{};
      for (final row in result) {
        settings[row['key'] as String] = row['value'] as String;
      }
      return settings;
    } catch (e) {
      throw StorageException('Failed to get settings with prefix: $e');
    }
  }

  // ========== 数据库维护 ==========

  @override
  Future<void> vacuum() async {
    try {
      final db = await database;
      await db.execute('VACUUM');
    } catch (e) {
      throw StorageException('Failed to vacuum database: $e');
    }
  }

  @override
  Future<int> getDatabaseSize() async {
    try {
      String path;
      if (_databasePath != null) {
        path = _databasePath!;
      } else {
        final documentsDirectory = await getApplicationDocumentsDirectory();
        path = join(documentsDirectory.path, _databaseName);
      }
      
      // 内存数据库返回固定大小
      if (path == ':memory:') {
        return 1024; // 返回一个模拟的大小
      }
      
      final file = File(path);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      throw StorageException('Failed to get database size: $e');
    }
  }

  @override
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}