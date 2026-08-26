/// Base class for all API-related exceptions.
class ApiException implements Exception {
  final String message;
  final String prefix;

  ApiException([this.message = "", this.prefix = ""]);

  @override
  String toString() {
    return message.isNotEmpty ? message : prefix;
  }
}

/// Thrown when there is a network issue or communication failure.
class FetchDataException extends ApiException {
  FetchDataException(String message)
      : super(message, "Error During Communication: ");
}

/// Thrown when the request is malformed or invalid.
class BadRequestException extends ApiException {
  BadRequestException(String message) : super(message, "Invalid Request: ");
}

/// Thrown when authentication fails or credentials are missing.
class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message, "Unauthorized: ");
}

/// Thrown when access is denied due to insufficient permissions.
class ForbiddenException extends ApiException {
  ForbiddenException(String message) : super(message, "Forbidden: ");
}

/// Thrown when the requested resource could not be found (404).
class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message, "Not Found: ");
}

/// Thrown when the server encounters an unexpected condition (500).
class InternalServerException extends ApiException {
  InternalServerException(String message) : super(message, "Internal Server: ");
}

/// Thrown when the request could not be processed (422).
class UnprocessableContentException extends ApiException {
  UnprocessableContentException(String message)
      : super(message, "Unprocessable Content: ");
}

/// Thrown when the authentication token has expired.
class TokenExpiredException extends ApiException {
  TokenExpiredException(String message)
      : super(message, "Token Expired: ");
}

/// Thrown when the input data is invalid.
class InvalidInputException extends ApiException {
  InvalidInputException(String message) : super(message, "Invalid Input: ");
}
