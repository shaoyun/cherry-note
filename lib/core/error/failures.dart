import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;
  
  const Failure(this.message, [this.code]);
  
  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message, 'NETWORK_FAILURE');
}

class StorageFailure extends Failure {
  const StorageFailure(String message) : super(message, 'STORAGE_FAILURE');
}

class SyncFailure extends Failure {
  const SyncFailure(String message) : super(message, 'SYNC_FAILURE');
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message, 'VALIDATION_FAILURE');
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(String message) : super(message, 'AUTH_FAILURE');
}

class FileSystemFailure extends Failure {
  const FileSystemFailure(String message) : super(message, 'FILESYSTEM_FAILURE');
}

class ParseFailure extends Failure {
  const ParseFailure(String message) : super(message, 'PARSE_FAILURE');
}

class ConflictFailure extends Failure {
  const ConflictFailure(String message) : super(message, 'CONFLICT_FAILURE');
}