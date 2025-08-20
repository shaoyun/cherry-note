import 'package:equatable/equatable.dart';

import '../../domain/services/import_service.dart';

abstract class ImportEvent extends Equatable {
  const ImportEvent();

  @override
  List<Object?> get props => [];
}

class ImportFromFolderRequested extends ImportEvent {
  final String localPath;
  final ImportOptions? options;

  const ImportFromFolderRequested({
    required this.localPath,
    this.options,
  });

  @override
  List<Object?> get props => [localPath, options];
}

class ImportFromZipRequested extends ImportEvent {
  final String zipPath;
  final ImportOptions? options;

  const ImportFromZipRequested({
    required this.zipPath,
    this.options,
  });

  @override
  List<Object?> get props => [zipPath, options];
}

class ImportValidationRequested extends ImportEvent {
  final String path;

  const ImportValidationRequested(this.path);

  @override
  List<Object?> get props => [path];
}

class ImportConflictResolved extends ImportEvent {
  final String filePath;
  final ConflictStrategy strategy;

  const ImportConflictResolved({
    required this.filePath,
    required this.strategy,
  });

  @override
  List<Object?> get props => [filePath, strategy];
}

class ImportCancelRequested extends ImportEvent {
  const ImportCancelRequested();
}

class ImportProgressUpdated extends ImportEvent {
  final ImportProgress progress;

  const ImportProgressUpdated(this.progress);

  @override
  List<Object?> get props => [progress];
}