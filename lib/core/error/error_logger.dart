import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'global_error_handler.dart';

/// Service for logging errors to local files
class ErrorLogger {
  static const String _logFileName = 'error_log.txt';
  static const int _maxLogFileSize = 5 * 1024 * 1024; // 5MB
  static const int _maxLogEntries = 1000;

  static final ErrorLogger _instance = ErrorLogger._internal();
  factory ErrorLogger() => _instance;
  ErrorLogger._internal();

  File? _logFile;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
  bool _isWebPlatform = false;

  /// Initialize the error logger
  Future<void> initialize() async {
    try {
      // Check if running on web platform
      _isWebPlatform = kIsWeb;
      
      if (_isWebPlatform) {
        // For web, we can't write to files, so just use console logging
        debugPrint('Error logging initialized for web platform (console only)');
        return;
      }
      
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/$_logFileName');
      
      // Create log file if it doesn't exist
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }

      // Check and rotate log file if needed
      await _rotateLogFileIfNeeded();
    } catch (e) {
      // If we can't initialize logging, continue without it
      debugPrint('Failed to initialize error logger: $e');
    }
  }

  /// Log an error to the file
  Future<void> logError(
    AppError error, {
    String? context,
    StackTrace? stackTrace,
  }) async {
    final logEntry = _createLogEntry(error, context: context, stackTrace: stackTrace);
    
    if (_isWebPlatform) {
      // For web, just log to console
      debugPrint('ERROR LOG:\n$logEntry');
      return;
    }
    
    if (_logFile == null) return;

    try {
      await _logFile!.writeAsString(
        '$logEntry\n',
        mode: FileMode.append,
        flush: true,
      );

      // Check if we need to rotate the log file
      await _rotateLogFileIfNeeded();
    } catch (e) {
      // If logging fails, don't throw - just continue
      debugPrint('Failed to log error: $e');
    }
  }

  /// Create a formatted log entry
  String _createLogEntry(
    AppError error, {
    String? context,
    StackTrace? stackTrace,
  }) {
    final timestamp = _dateFormat.format(error.timestamp);
    final contextInfo = context != null ? ' [Context: $context]' : '';
    
    final logData = {
      'timestamp': timestamp,
      'severity': error.severity.name,
      'category': error.category.name,
      'message': error.message,
      'technicalMessage': error.technicalMessage,
      'code': error.code,
      'context': context,
      'metadata': error.metadata,
      'stackTrace': stackTrace?.toString(),
    };

    return '[$timestamp] ${error.severity.name.toUpperCase()}: ${error.message}$contextInfo\n'
           'Technical: ${error.technicalMessage ?? 'N/A'}\n'
           'Code: ${error.code ?? 'N/A'}\n'
           'Category: ${error.category.name}\n'
           'Data: ${jsonEncode(logData)}\n'
           '${'-' * 80}';
  }

  /// Rotate log file if it's too large
  Future<void> _rotateLogFileIfNeeded() async {
    if (_logFile == null || !await _logFile!.exists()) return;

    try {
      final stat = await _logFile!.stat();
      if (stat.size > _maxLogFileSize) {
        await _rotateLogFile();
      }
    } catch (e) {
      debugPrint('Failed to check log file size: $e');
    }
  }

  /// Rotate the log file by creating a backup and starting fresh
  Future<void> _rotateLogFile() async {
    if (_logFile == null) return;

    try {
      final directory = _logFile!.parent;
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFile = File('${directory.path}/error_log_$timestamp.txt');
      
      // Copy current log to backup
      await _logFile!.copy(backupFile.path);
      
      // Clear current log file
      await _logFile!.writeAsString('');
      
      // Clean up old backup files (keep only last 5)
      await _cleanupOldBackups(directory);
    } catch (e) {
      debugPrint('Failed to rotate log file: $e');
    }
  }

  /// Clean up old backup log files
  Future<void> _cleanupOldBackups(Directory directory) async {
    try {
      final files = await directory
          .list()
          .where((entity) => entity is File && entity.path.contains('error_log_'))
          .cast<File>()
          .toList();

      if (files.length > 5) {
        // Sort by modification time (oldest first)
        files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
        
        // Delete oldest files, keep only 5 most recent
        for (int i = 0; i < files.length - 5; i++) {
          await files[i].delete();
        }
      }
    } catch (e) {
      debugPrint('Failed to cleanup old backup files: $e');
    }
  }

  /// Get recent error logs
  Future<List<String>> getRecentLogs({int maxEntries = 100}) async {
    if (_logFile == null || !await _logFile!.exists()) {
      return [];
    }

    try {
      final content = await _logFile!.readAsString();
      final entries = content.split('-' * 80).where((entry) => entry.trim().isNotEmpty).toList();
      
      // Return most recent entries
      final recentEntries = entries.reversed.take(maxEntries).toList();
      return recentEntries;
    } catch (e) {
      debugPrint('Failed to read log file: $e');
      return [];
    }
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    if (_logFile == null) return;

    try {
      await _logFile!.writeAsString('');
    } catch (e) {
      debugPrint('Failed to clear logs: $e');
    }
  }

  /// Export logs to a specific file
  Future<void> exportLogs(String exportPath) async {
    if (_logFile == null || !await _logFile!.exists()) {
      throw Exception('No log file available for export');
    }

    try {
      final exportFile = File(exportPath);
      await _logFile!.copy(exportFile.path);
    } catch (e) {
      throw Exception('Failed to export logs: $e');
    }
  }

  /// Get log file statistics
  Future<LogStatistics> getLogStatistics() async {
    if (_logFile == null || !await _logFile!.exists()) {
      return LogStatistics.empty();
    }

    try {
      final content = await _logFile!.readAsString();
      final stat = await _logFile!.stat();
      final entries = content.split('-' * 80).where((entry) => entry.trim().isNotEmpty).length;
      
      return LogStatistics(
        fileSize: stat.size,
        entryCount: entries,
        lastModified: stat.modified,
      );
    } catch (e) {
      return LogStatistics.empty();
    }
  }
}

/// Statistics about the error log file
class LogStatistics {
  final int fileSize;
  final int entryCount;
  final DateTime lastModified;

  const LogStatistics({
    required this.fileSize,
    required this.entryCount,
    required this.lastModified,
  });

  factory LogStatistics.empty() {
    return LogStatistics(
      fileSize: 0,
      entryCount: 0,
      lastModified: DateTime.now(),
    );
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}