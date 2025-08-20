import 'package:equatable/equatable.dart';

import '../../domain/services/import_service.dart';

abstract class ImportState extends Equatable {
  const ImportState();

  @override
  List<Object?> get props => [];
}

class ImportInitial extends ImportState {
  const ImportInitial();
}

class ImportValidating extends ImportState {
  const ImportValidating();
}

class ImportValidationComplete extends ImportState {
  final ValidationResult result;

  const ImportValidationComplete(this.result);

  @override
  List<Object?> get props => [result];
}

class ImportInProgress extends ImportState {
  final ImportProgress? progress;

  const ImportInProgress({this.progress});

  @override
  List<Object?> get props => [progress];
}

class ImportConflictDetected extends ImportState {
  final List<FileConflict> conflicts;
  final ImportResult partialResult;

  const ImportConflictDetected({
    required this.conflicts,
    required this.partialResult,
  });

  @override
  List<Object?> get props => [conflicts, partialResult];
}

class ImportSuccess extends ImportState {
  final ImportResult result;

  const ImportSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class ImportFailure extends ImportState {
  final String message;
  final List<String>? errors;

  const ImportFailure({
    required this.message,
    this.errors,
  });

  @override
  List<Object?> get props => [message, errors];
}

class ImportCancelled extends ImportState {
  const ImportCancelled();
}