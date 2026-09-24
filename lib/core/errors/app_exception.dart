import 'dart:async';

/// Base type for every error the app knows how to present to the user.
///
/// Lower layers translate low-level failures (sockets, HTTP status codes,
/// malformed JSON) into one of these so the UI never shows raw exceptions.
sealed class AppException implements Exception {
  const AppException(this.message);

  /// A short, user-facing explanation.
  final String message;

  /// Whether retrying the same action might succeed.
  bool get isRetryable => true;

  /// Converts any thrown object into an [AppException].
  static AppException from(Object error) => switch (error) {
    AppException() => error,
    TimeoutException() => const RequestTimeoutException(),
    FormatException() => const ParseException(),
    _ => UnknownException(error.toString()),
  };

  @override
  String toString() => '$runtimeType: $message';
}

/// The device appears to be offline or the host is unreachable.
final class NetworkException extends AppException {
  const NetworkException([
    super.message = "You're offline. Check your connection and try again.",
  ]);
}

/// The request took too long.
final class RequestTimeoutException extends AppException {
  const RequestTimeoutException([
    super.message = 'The request timed out. Please try again.',
  ]);
}

/// Jikan rejected the request because of rate limiting (HTTP 429).
final class RateLimitException extends AppException {
  const RateLimitException([
    super.message = 'Too many requests. Please wait a moment and try again.',
  ]);
}

/// The requested resource does not exist (HTTP 404).
final class NotFoundException extends AppException {
  const NotFoundException([super.message = "We couldn't find that anime."]);

  @override
  bool get isRetryable => false;
}

/// Jikan or MyAnimeList returned a server-side error (HTTP 5xx or other).
final class ServerException extends AppException {
  const ServerException({
    this.statusCode,
    String message = 'The anime service is having trouble. Try again soon.',
  }) : super(message);

  final int? statusCode;
}

/// The response could not be parsed.
final class ParseException extends AppException {
  const ParseException([
    super.message = 'We received unexpected data from the server.',
  ]);

  @override
  bool get isRetryable => false;
}

/// Anything else.
final class UnknownException extends AppException {
  const UnknownException([this.details])
    : super('Something went wrong. Please try again.');

  /// Diagnostic information; never shown to the user.
  final String? details;
}
