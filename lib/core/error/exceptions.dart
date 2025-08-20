abstract class AppException implements Exception {
  final String message;
  final String? code;
  
  const AppException(this.message, [this.code]);
  
  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkException extends AppException {
  const NetworkException(String message) : super(message, 'NETWORK_ERROR');
}

class StorageException extends AppException {
  const StorageException(String message) : super(message, 'STORAGE_ERROR');
}

class SyncException extends AppException {
  const SyncException(String message) : super(message, 'SYNC_ERROR');
}

class ValidationException extends AppException {
  const ValidationException(String message) : super(message, 'VALIDATION_ERROR');
}

class AuthenticationException extends AppException {
  const AuthenticationException(String message) : super(message, 'AUTH_ERROR');
}

class FileSystemException extends AppException {
  const FileSystemException(String message) : super(message, 'FILESYSTEM_ERROR');
}

class ParseException extends AppException {
  const ParseException(String message) : super(message, 'PARSE_ERROR');
}

class ConflictException extends AppException {
  const ConflictException(String message) : super(message, 'CONFLICT_ERROR');
}