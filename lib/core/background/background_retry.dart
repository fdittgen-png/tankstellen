import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Retry configuration for background network requests.
class BackgroundRetryConfig {
  final int maxAttempts;
  final Duration baseDelay;

  const BackgroundRetryConfig({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(seconds: 2),
  });
}

/// Fetches JSON from a URL with retry and exponential backoff.
/// Returns the parsed response data on success, null if all retries fail.
Future<Map<String, dynamic>?> fetchWithRetry({
  required Dio dio,
  required String url,
  required Map<String, dynamic> queryParameters,
  BackgroundRetryConfig config = const BackgroundRetryConfig(),
}) async {
  for (var attempt = 0; attempt < config.maxAttempts; attempt++) {
    try {
      final response = await dio.get(
        url,
        queryParameters: queryParameters,
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e, st) { // ignore: unused_catch_stack
      final isLastAttempt = attempt == config.maxAttempts - 1;
      if (isLastAttempt || !isRetryable(e)) {
        debugPrint(
          'BackgroundRetry: failed after ${attempt + 1} '
          'attempt(s): ${e.type} - ${e.message}',
        );
        return null;
      }
      // Exponential backoff: 2s, 4s, 8s...
      final delay = config.baseDelay * (1 << attempt);
      debugPrint(
        'BackgroundRetry: retry ${attempt + 1}/${config.maxAttempts} '
        'after ${delay.inSeconds}s (${e.type})',
      );
      await Future<void>.delayed(delay);
    }
  }
  return null;
}

/// Whether a DioException is worth retrying (transient network issues).
bool isRetryable(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return true;
    case DioExceptionType.badResponse:
      // Retry on server errors (5xx), not on client errors (4xx)
      final statusCode = e.response?.statusCode;
      return statusCode != null && statusCode >= 500;
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return false;
  }
}
