
class ValidationException implements Exception {
  final String message;

  const ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}

class NotFoundException implements Exception {
  final String message;

  const NotFoundException(this.message);

  @override
  String toString() => 'NotFoundException: $message';
}

class ConflictException implements Exception {
  final String message;

  const ConflictException(this.message);

  @override
  String toString() => 'ConflictException: $message';
}

class AuthorizationException implements Exception {
  final String message;

  const AuthorizationException(this.message);

  @override
  String toString() => 'AuthorizationException: $message';
}

/// Ensures that a string is not empty or whitespace-only.
void requireNonBlank(String value, String field) {
  if (value.trim().isEmpty) {
    throw ValidationException('$field cannot be empty.');
  }
}

/// Ensures that a number is finite and greater than zero.
void requirePositiveNumber(num value, String field) {
  if (!value.isFinite || value <= 0) {
    throw ValidationException(
      '$field must be greater than zero.',
    );
  }
}
