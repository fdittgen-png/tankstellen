import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../error/exceptions.dart';
import '../services/service_result.dart';
import 'collectors/app_state_collector.dart';
import 'collectors/breadcrumb_collector.dart';
import 'collectors/device_info_collector.dart';
import 'collectors/network_state_collector.dart';
import 'error_classifier.dart';
import 'models/error_trace.dart';
import 'storage/trace_storage.dart';
import 'upload/trace_uploader.dart';

part 'trace_recorder.g.dart';

@Riverpod(keepAlive: true)
TraceRecorder traceRecorder(Ref ref) {
  return TraceRecorder(
    ref.watch(traceStorageProvider),
    ref.watch(traceUploaderProvider),
    ref,
  );
}

class TraceRecorder {
  final TraceStorage _storage;
  final TraceUploader _uploader;
  final Ref _ref;
  static const _uuid = Uuid();

  TraceRecorder(this._storage, this._uploader, this._ref);

  Future<void> record(
    Object error,
    StackTrace stackTrace, {
    ServiceChainSnapshot? serviceChainState,
  }) async {
    final now = DateTime.now();
    final tz = now.timeZoneOffset;
    final tzStr =
        '${tz.isNegative ? '-' : '+'}${tz.inHours.abs().toString().padLeft(2, '0')}:'
        '${(tz.inMinutes.abs() % 60).toString().padLeft(2, '0')}';

    // Build chain snapshot from ServiceChainExhaustedException
    var chain = serviceChainState;
    if (chain == null && error is ServiceChainExhaustedException) {
      chain = ServiceChainSnapshot(
        attempts: error.errors.map((e) {
          if (e is ServiceError) {
            return ServiceAttempt(
              serviceName: e.source.displayName,
              succeeded: false,
              errorMessage: e.message,
              statusCode: e.statusCode,
              attemptedAt: e.occurredAt,
            );
          }
          return ServiceAttempt(
            serviceName: 'unknown',
            succeeded: false,
            errorMessage: e.toString(),
            attemptedAt: now,
          );
        }).toList(),
      );
    }

    final trace = ErrorTrace(
      id: _uuid.v4(),
      timestamp: now,
      timezoneOffset: tzStr,
      category: ErrorClassifier.classify(error),
      errorType: error.runtimeType.toString(),
      errorMessage: error.toString(),
      stackTrace: stackTrace.toString(),
      deviceInfo: DeviceInfoCollector.collect(),
      appState: AppStateCollector.collect(_ref),
      serviceChainState: chain,
      networkState: await NetworkStateCollector.collect(),
      breadcrumbs: BreadcrumbCollector.snapshot(),
    );

    await _storage.store(trace);
    await _uploader.uploadIfEnabled(trace);
  }
}
