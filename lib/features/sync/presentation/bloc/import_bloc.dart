import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/services/import_service.dart';
import 'import_event.dart';
import 'import_state.dart';

class ImportBloc extends Bloc<ImportEvent, ImportState> {
  final ImportService _importService;
  StreamController<ImportProgress>? _progressController;

  ImportBloc(this._importService) : super(const ImportInitial()) {
    on<ImportFromFolderRequested>(_onImportFromFolderRequested);
    on<ImportFromZipRequested>(_onImportFromZipRequested);
    on<ImportValidationRequested>(_onImportValidationRequested);
    on<ImportConflictResolved>(_onImportConflictResolved);
    on<ImportCancelRequested>(_onImportCancelRequested);
    on<ImportProgressUpdated>(_onImportProgressUpdated);
  }

  Future<void> _onImportFromFolderRequested(
    ImportFromFolderRequested event,
    Emitter<ImportState> emit,
  ) async {
    if (_importService.isImporting) {
      emit(const ImportFailure(message: 'Import operation already in progress'));
      return;
    }

    emit(const ImportInProgress());

    try {
      _progressController = StreamController<ImportProgress>();
      _progressController!.stream.listen((progress) {
        add(ImportProgressUpdated(progress));
      });

      final result = await _importService.importFromFolder(
        event.localPath,
        options: event.options,
        progressController: _progressController,
      );

      if (result.conflicts.isNotEmpty) {
        emit(ImportConflictDetected(
          conflicts: result.conflicts,
          partialResult: result,
        ));
      } else if (result.success) {
        emit(ImportSuccess(result));
      } else {
        emit(ImportFailure(
          message: 'Import completed with errors',
          errors: result.errors,
        ));
      }
    } catch (e) {
      emit(ImportFailure(message: 'Import failed: $e'));
    } finally {
      await _progressController?.close();
      _progressController = null;
    }
  }

  Future<void> _onImportFromZipRequested(
    ImportFromZipRequested event,
    Emitter<ImportState> emit,
  ) async {
    if (_importService.isImporting) {
      emit(const ImportFailure(message: 'Import operation already in progress'));
      return;
    }

    emit(const ImportInProgress());

    try {
      _progressController = StreamController<ImportProgress>();
      _progressController!.stream.listen((progress) {
        add(ImportProgressUpdated(progress));
      });

      final result = await _importService.importFromZip(
        event.zipPath,
        options: event.options,
        progressController: _progressController,
      );

      if (result.conflicts.isNotEmpty) {
        emit(ImportConflictDetected(
          conflicts: result.conflicts,
          partialResult: result,
        ));
      } else if (result.success) {
        emit(ImportSuccess(result));
      } else {
        emit(ImportFailure(
          message: 'Import completed with errors',
          errors: result.errors,
        ));
      }
    } catch (e) {
      emit(ImportFailure(message: 'Import failed: $e'));
    } finally {
      await _progressController?.close();
      _progressController = null;
    }
  }

  Future<void> _onImportValidationRequested(
    ImportValidationRequested event,
    Emitter<ImportState> emit,
  ) async {
    emit(const ImportValidating());

    try {
      final result = await _importService.validateImportStructure(event.path);
      emit(ImportValidationComplete(result));
    } catch (e) {
      emit(ImportFailure(message: 'Validation failed: $e'));
    }
  }

  Future<void> _onImportConflictResolved(
    ImportConflictResolved event,
    Emitter<ImportState> emit,
  ) async {
    try {
      await _importService.resolveConflict(event.filePath, event.strategy);
      
      // Check if there are more conflicts
      final remainingConflicts = await _importService.getPendingConflicts();
      
      if (remainingConflicts.isEmpty) {
        // All conflicts resolved, complete the import
        emit(const ImportSuccess(ImportResult(
          success: true,
          importedFiles: 0, // This would need to be tracked properly
          importedFolders: 0,
          skippedFiles: 0,
          errors: [],
          conflicts: [],
        )));
      } else {
        // Still have conflicts to resolve
        emit(ImportConflictDetected(
          conflicts: remainingConflicts,
          partialResult: const ImportResult(
            success: false,
            importedFiles: 0,
            importedFolders: 0,
            skippedFiles: 0,
            errors: [],
            conflicts: [],
          ),
        ));
      }
    } catch (e) {
      emit(ImportFailure(message: 'Failed to resolve conflict: $e'));
    }
  }

  Future<void> _onImportCancelRequested(
    ImportCancelRequested event,
    Emitter<ImportState> emit,
  ) async {
    try {
      await _importService.cancelImport();
      emit(const ImportCancelled());
    } catch (e) {
      emit(ImportFailure(message: 'Failed to cancel import: $e'));
    } finally {
      await _progressController?.close();
      _progressController = null;
    }
  }

  void _onImportProgressUpdated(
    ImportProgressUpdated event,
    Emitter<ImportState> emit,
  ) {
    emit(ImportInProgress(progress: event.progress));
  }

  @override
  Future<void> close() async {
    await _progressController?.close();
    return super.close();
  }
}