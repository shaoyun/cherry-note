import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../features/folders/data/datasources/folder_data_source.dart';
import '../../features/folders/data/datasources/local_folder_data_source.dart';
import '../../features/folders/data/datasources/web_folder_data_source.dart';

/// Application dependency injection module
@module
abstract class AppModule {
  /// Provides the notes directory path
  @Named('notesDirectory')
  @preResolve
  @lazySingleton
  Future<String> notesDirectory() async {
    if (kIsWeb) {
      // For web, use a local storage key-based path
      return 'cherry_notes_web';
    } else {
      // For other platforms, use the documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      return path.join(documentsDir.path, 'CherryNote');
    }
  }

  /// Provides platform-specific folder data source
  @lazySingleton
  FolderDataSource folderDataSource(@Named('notesDirectory') String basePath) {
    if (kIsWeb) {
      return WebFolderDataSource();
    } else {
      return LocalFolderDataSource(basePath: basePath);
    }
  }
}