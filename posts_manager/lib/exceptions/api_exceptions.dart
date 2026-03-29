/// Base class for all API-related exceptions
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// Thrown when the device has no internet connection or the server is unreachable
class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

/// Thrown when the server returns an unexpected or error HTTP status code
class ServerException extends ApiException {
  ServerException(String message, int statusCode)
      : super(message, statusCode: statusCode);
}

/// Thrown when the JSON response cannot be parsed into the expected model
class DataParseException extends ApiException {
  DataParseException(String message) : super(message);
}
