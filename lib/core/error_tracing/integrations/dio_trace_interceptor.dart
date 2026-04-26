import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logging/error_logger.dart';
import '../collectors/app_state_collector.dart';
import '../collectors/breadcrumb_collector.dart';

class DioTraceInterceptor extends Interceptor {
  /// Constructor parameter is intentionally accepted-and-ignored to
  /// preserve the public signature; the unified [errorLogger] holds
  /// the bound `ProviderContainer` and resolves `traceRecorderProvider`
  /// from there.
  DioTraceInterceptor(Ref _);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final endpoint = '${options.method} ${options.uri.path}';
    AppStateCollector.updateLastApi(endpoint);
    BreadcrumbCollector.add('api:request', detail: endpoint);
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // #1104 — route through the unified logger so service-layer Dio
    // failures land in the same pipeline as foreground / background
    // errors. Fire-and-forget: the interceptor contract is sync.
    errorLogger.log(
      ErrorLayer.services,
      err,
      err.stackTrace,
      context: <String, Object?>{
        'method': err.requestOptions.method,
        'path': err.requestOptions.uri.path,
        'statusCode': err.response?.statusCode,
        'dioType': err.type.name,
      },
    );
    handler.next(err);
  }
}
