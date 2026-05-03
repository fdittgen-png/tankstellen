import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../error/exceptions.dart';
import '../logging/error_logger.dart';
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

    // Unwrap [ContextualError] so the persisted trace reflects the
    // ROOT exception type and so we can read the [ErrorLayer] for
    // category inference (#1394). Direct callers (dio interceptor,
    // navigation observer) pass real exceptions and skip this branch.
    final ErrorLayer? layer;
    final Object effectiveError;
    if (error is ContextualError) {
      layer = error.layer;
      effectiveError = error.inner;
    } else {
      layer = null;
      effectiveError = error;
    }

    // Build chain snapshot from ServiceChainExhaustedException
    var chain = serviceChainState;
    if (chain == null && effectiveError is ServiceChainExhaustedException) {
      chain = ServiceChainSnapshot(
        attempts: effectiveError.errors.map((e) {
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

    // Category resolution order:
    //   1. Existing [ErrorClassifier] (recognises Dio, ApiException,
    //      ServiceChainExhausted, FlutterError, etc.).
    //   2. If still unknown AND we have a layer (i.e. the call came
    //      through `errorLogger.log`), fall back to layer-based
    //      inference so traces stop bucketing as `unknown` (#1394).
    var category = ErrorClassifier.classify(effectiveError);
    if (category == ErrorCategory.unknown && layer != null) {
      category = inferCategoryFromLayer(layer, effectiveError);
    }

    final trace = ErrorTrace(
      id: _uuid.v4(),
      timestamp: now,
      timezoneOffset: tzStr,
      category: category,
      // Use the original (wrapper) toString so the layer prefix and
      // context map remain visible in `errorMessage`. The trace's
      // `errorType` reflects the unwrapped exception class so the
      // privacy dashboard groups by real type, not `ContextualError`.
      errorType: effectiveError.runtimeType.toString(),
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

/// Map [ErrorLayer] (a code-area indicator) to the user-facing
/// [ErrorCategory] (root-cause grouping) used in the privacy dashboard
/// (#1394). [PlatformException] always maps to `platform` regardless
/// of layer — the layer says where the error BUBBLED UP, but the
/// platform-channel failure is the ROOT cause and the most actionable
/// hint for the user. Likewise common network exceptions map to
/// `network` no matter which layer logged them.
///
/// Exposed via [visibleForTesting] so the inference rules can be
/// asserted without standing up the full Hive + provider stack.
@visibleForTesting
ErrorCategory inferCategoryFromLayer(ErrorLayer layer, Object? error) {
  // PlatformException trumps the layer — the layer says where the
  // error BUBBLED UP, but the platform-channel failure is the ROOT
  // cause. Match by runtimeType name to avoid pulling Flutter's
  // services library (and its bindings) into pure-Dart unit tests.
  final typeName = error?.runtimeType.toString() ?? '';
  if (typeName.contains('PlatformException')) {
    return ErrorCategory.platform;
  }
  // Network exceptions usually surface in the services layer but the
  // category should reflect the failure shape, not the call site.
  if (typeName.contains('SocketException') ||
      typeName.contains('TimeoutException') ||
      typeName.contains('HttpException')) {
    return ErrorCategory.network;
  }
  switch (layer) {
    case ErrorLayer.ui:
      return ErrorCategory.ui;
    case ErrorLayer.providers:
      return ErrorCategory.provider;
    case ErrorLayer.services:
      return ErrorCategory.api;
    case ErrorLayer.storage:
      return ErrorCategory.cache;
    case ErrorLayer.sync:
      return ErrorCategory.api;
    case ErrorLayer.background:
      return ErrorCategory.unknown;
    case ErrorLayer.isolate:
      return ErrorCategory.unknown;
    case ErrorLayer.other:
      return ErrorCategory.unknown;
  }
}
