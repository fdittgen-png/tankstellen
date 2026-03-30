import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

/// Centralized Dio instance creation with consistent defaults.
///
/// Replaces 6 independent `Dio(BaseOptions(...))` constructions across
/// service implementations, ensuring consistent User-Agent headers and
/// reducing boilerplate.
class DioFactory {
  DioFactory._();

  static Dio create({
    String? baseUrl,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 10),
    ResponseType responseType = ResponseType.json,
    List<Interceptor> interceptors = const [],
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? '',
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {'User-Agent': AppConstants.userAgent},
      responseType: responseType,
    ));
    dio.interceptors.addAll(interceptors);
    return dio;
  }
}
