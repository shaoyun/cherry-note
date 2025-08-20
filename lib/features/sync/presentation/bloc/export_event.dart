import 'package:equatable/equatable.dart';

import '../../domain/services/export_service.dart';

abstract class ExportEvent extends Equatable {
  const ExportEvent();

  @override
  List<Object?> get props => [];
}

class ExportToFolderRequested extends ExportEvent {
  final String localPath;
  final ExportOptions? options;

  const ExportToFolderRequested({
    required this.localPath,
    this.options,
  });

  @override
  List<Object?> get props => [localPath, options];
}

class ExportToZipRequested extends ExportEvent {
  final String zipPath;
  final ExportOptions? options;

  const ExportToZipRequested({
    required this.zipPath,
    this.options,
  });

  @override
  List<Object?> get props => [zipPath, options];
}

class ExportFolderRequested extends ExportEvent {
  final String folderPath;
  final String localPath;
  final bool includeMetadata;

  const ExportFolderRequested({
    required this.folderPath,
    required this.localPath,
    this.includeMetadata = true,
  });

  @override
  List<Object?> get props => [folderPath, localPath, includeMetadata];
}

class ExportCancelRequested extends ExportEvent {
  const ExportCancelRequested();
}

class ExportProgressUpdated extends ExportEvent {
  final ExportProgress progress;

  const ExportProgressUpdated(this.progress);

  @override
  List<Object?> get props => [progress];
}