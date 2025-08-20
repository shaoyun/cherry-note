import 'package:equatable/equatable.dart';

import '../../domain/services/export_service.dart';

abstract class ExportState extends Equatable {
  const ExportState();

  @override
  List<Object?> get props => [];
}

class ExportInitial extends ExportState {
  const ExportInitial();
}

class ExportInProgress extends ExportState {
  final ExportProgress? progress;

  const ExportInProgress({this.progress});

  @override
  List<Object?> get props => [progress];
}

class ExportSuccess extends ExportState {
  final ExportResult result;

  const ExportSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class ExportFailure extends ExportState {
  final String message;
  final List<String>? errors;

  const ExportFailure({
    required this.message,
    this.errors,
  });

  @override
  List<Object?> get props => [message, errors];
}

class ExportCancelled extends ExportState {
  const ExportCancelled();
}