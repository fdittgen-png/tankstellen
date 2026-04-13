/// Base class for all domain exceptions in the app.
///
/// Sealed so that `switch` on [AppException] is exhaustive and all
/// catch blocks using `on AppException` will match any app error.
sealed class AppException implements Exception {
  const AppException();
  String get message;
}

class ApiException extends AppException {
  @override
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class CacheException extends AppException {
  @override
  final String message;
  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class LocationException extends AppException {
  @override
  final String message;
  const LocationException({required this.message});

  @override
  String toString() => 'LocationException: $message';
}

class NoApiKeyException extends AppException {
  const NoApiKeyException();

  @override
  String get message => 'No API key configured. Please set up your Tankerkoenig API key.';

  @override
  String toString() => message;
}

/// Thrown when the user tries to perform an EV charging-station lookup
/// without an OpenChargeMap key configured. Routed through ErrorLocalizer
/// so the UI message is translated.
class NoEvApiKeyException extends AppException {
  const NoEvApiKeyException();

  @override
  String get message =>
      'OpenChargeMap API key not configured. Set it up in Settings to search for EV charging stations.';

  @override
  String toString() => message;
}

/// Thrown when every service in a fallback chain has failed,
/// including the cache. Carries accumulated errors from each step
/// so the UI can report exactly what went wrong.
class ServiceChainExhaustedException extends AppException {
  final List<dynamic> errors;

  const ServiceChainExhaustedException({required this.errors});

  @override
  String get message {
    if (errors.isEmpty) return 'All services unavailable.';
    final details = errors.map((e) => e.toString()).join('\n');
    return 'All services failed:\n$details';
  }

  @override
  String toString() => message;
}
