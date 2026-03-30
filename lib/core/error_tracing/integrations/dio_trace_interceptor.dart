import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../collectors/app_state_collector.dart';
import '../collectors/breadcrumb_collector.dart';
import '../trace_recorder.dart';

class DioTraceInterceptor extends Interceptor {
  final Ref _ref;
  DioTraceInterceptor(this._ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final endpoint = '${options.method} ${options.uri.path}';
    AppStateCollector.updateLastApi(endpoint);
    BreadcrumbCollector.add('api:request', detail: endpoint);
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _ref.read(traceRecorderProvider).record(
          err,
          err.stackTrace,
        );
    handler.next(err);
  }
}
