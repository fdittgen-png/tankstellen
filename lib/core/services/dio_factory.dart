import 'package:dio/dio.dart';

import '../constants/app_constants.dart';
import 'rate_limit_interceptor.dart';

/// Centralized Dio instance creation with consistent defaults.
///
/// Every Dio created here gets a [RateLimitInterceptor] by default so
/// background-isolate refreshes and rapid user retries can't fire a
/// thundering herd at any external API. The default is conservative
/// (1 s minimum interval + 500 ms jitter); per-country code paths can
/// pass a tighter or looser [rateLimit], and user-triggered endpoints
/// that must dispatch immediately (e.g. trace upload, station report)
/// pass `rateLimit: null` to opt out.
class DioFactory {
  DioFactory._();

  /// Default minimum interval between requests on a single Dio instance.
  static const Duration defaultRateLimit = Duration(seconds: 1);

  static Dio create({
    String? baseUrl,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 10),
    ResponseType responseType = ResponseType.json,
    List<Interceptor> interceptors = const [],
    Duration? rateLimit = defaultRateLimit,
    int rateLimitJitterBaseMs = 0,
    int rateLimitJitterRangeMs = 500,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? '',
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {'User-Agent': AppConstants.userAgent},
      responseType: responseType,
    ));
    if (rateLimit != null) {
      dio.interceptors.add(RateLimitInterceptor(
        minInterval: rateLimit,
        jitterBaseMs: rateLimitJitterBaseMs,
        jitterRangeMs: rateLimitJitterRangeMs,
      ));
    }
    dio.interceptors.addAll(interceptors);
    return dio;
  }
}
