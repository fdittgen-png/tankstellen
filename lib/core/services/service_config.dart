import '../constants/app_constants.dart';

/// Connection configuration for an external service.
/// Handles protocol details: URL, auth, headers, timeouts.
class ServiceConfig {
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Map<String, String> headers;

  /// Query parameter name for API key injection. Null if no key needed.
  final String? apiKeyParamName;

  const ServiceConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 10),
    this.headers = const {},
    this.apiKeyParamName,
  });
}

/// Concrete configurations for all external services.
/// Central place to change URLs, timeouts, or headers.
class ServiceConfigs {
  ServiceConfigs._();

  static const tankerkoenig = ServiceConfig(
    baseUrl: 'https://creativecommons.tankerkoenig.de/json',
    apiKeyParamName: 'apikey',
    headers: {'User-Agent': AppConstants.userAgent},
  );

  static const nominatim = ServiceConfig(
    baseUrl: 'https://nominatim.openstreetmap.org',
    headers: {'User-Agent': AppConstants.userAgent},
  );

  static const osrm = ServiceConfig(
    baseUrl: 'https://router.project-osrm.org',
    receiveTimeout: Duration(seconds: 30),
    headers: {'User-Agent': AppConstants.userAgent},
  );

  static const openChargeMap = ServiceConfig(
    baseUrl: 'https://api.openchargemap.io/v3',
    apiKeyParamName: 'key',
    headers: {'User-Agent': AppConstants.userAgent},
  );
}
