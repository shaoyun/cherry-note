import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/services/export_service.dart';
import 'export_event.dart';
import 'export_state.dart';

class ExportBloc extends Bloc<ExportEvent, ExportState> {
  final ExportService _exportService;
  StreamController<ExportProgress>? _progressController;

  ExportBloc(this._exportService) : super(const ExportInitial()) {
    on<ExportToFolderRequested>(_onExportToFolderRequested);
    on<ExportToZipRequested>(_onExportToZipRequested);
    on<ExportFolderRequested>(_onExportFolderRequested);
    on<ExportCancelRequested>(_onExportCancelRequested);
    on<ExportProgressUpdated>(_onExportProgressUpdated);
  }

  Future<void> _onExportToFolderRequested(
    ExportToFolderRequested event,
    Emitter<ExportState> emit,
  ) async {
    if (_exportService.isExporting) {
      emit(const ExportFailure(message: 'Export operation already in progress'));
      return;
    }

    emit(const ExportInProgress());

    try {
      _progressController = StreamController<ExportProgress>();
      _progressController!.stream.listen((progress) {
        add(ExportProgressUpdated(progress));
      });

      final result = await _exportService.exportToFolder(
        event.localPath,
        options: event.options,
        progressController: _progressController,
      );

      if (result.success) {
        emit(ExportSuccess(result));
      } else {
        emit(ExportFailure(
          message: 'Export completed with errors',
          errors: result.errors,
        ));
      }
    } catch (e) {
      emit(ExportFailure(message: 'Export failed: $e'));
    } finally {
      await _progressController?.close();
      _progressController = null;
    }
  }

  Future<void> _onExportToZipRequested(
    ExportToZipRequested event,
    Emitter<ExportState> emit,
  ) async {
    if (_exportService.isExporting) {
      emit(const ExportFailure(message: 'Export operation already in progress'));
      return;
    }

    emit(const ExportInProgress());

    try {
      _progressController = StreamController<ExportProgress>();
      _progressController!.stream.listen((progress) {
        add(ExportProgressUpdated(progress));
      });

      final result = await _exportService.exportToZip(
        event.zipPath,
        options: event.options,
        progressController: _progressController,
      );

      if (result.success) {
        emit(ExportSuccess(result));
      } else {
        emit(ExportFailure(
          message: 'Export completed with errors',
          errors: result.errors,
        ));
      }
    } catch (e) {
      emit(ExportFailure(message: 'Export failed: $e'));
    } finally {
      await _progressController?.close();
      _progressController = null;
    }
  }

  Future<void> _onExportFolderRequested(
    ExportFolderRequested event,
    Emitter<ExportState> emit,
  ) async {
    if (_exportService.isExporting) {
      emit(const ExportFailure(message: 'Export operation already in progress'));
      return;
    }

    emit(const ExportInProgress());

    try {
      _progressController = StreamController<ExportProgress>();
      _progressController!.stream.listen((progress) {
        add(ExportProgressUpdated(progress));
      });

      final result = await _exportService.exportFolder(
        event.folderPath,
        event.localPath,
        includeMetadata: event.includeMetadata,
        progressController: _progressController,
      );

      if (result.success) {
        emit(ExportSuccess(result));
      } else {
        emit(ExportFailure(
          message: 'Export completed with errors',
          errors: result.errors,
        ));
      }
    } catch (e) {
      emit(ExportFailure(message: 'Export failed: $e'));
    } finally {
      await _progressController?.close();
      _progressController = null;
    }
  }

  Future<void> _onExportCancelRequested(
    ExportCancelRequested event,
    Emitter<ExportState> emit,
  ) async {
    try {
      await _exportService.cancelExport();
      emit(const ExportCancelled());
    } catch (e) {
      emit(ExportFailure(message: 'Failed to cancel export: $e'));
    } finally {
      await _progressController?.close();
      _progressController = null;
    }
  }

  void _onExportProgressUpdated(
    ExportProgressUpdated event,
    Emitter<ExportState> emit,
  ) {
    emit(ExportInProgress(progress: event.progress));
  }

  @override
  Future<void> close() async {
    await _progressController?.close();
    return super.close();
  }
}