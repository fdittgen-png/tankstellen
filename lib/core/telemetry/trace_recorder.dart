// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../error/exceptions.dart';
import '../logging/error_logger.dart';
import '../network/dio_offline.dart';
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

    // #2671 / #2703 — benign offline/cancelled/connection transients are
    // EXPECTED, not errors. A no-network DNS failure, a user-cancelled
    // request, AND the connection-layer transients that slipped through
    // (#2703: a `DioException[connectionError]` WRAPPING the host-lookup
    // SocketException, the *timeout types, an `HttpException` connection
    // abort) reached the trace store with NO suppression, polluting a
    // signal-rich error log. Skip them with a breadcrumb only — no store,
    // no upload. Placed in `record()` (not the classifier) so EVERY caller
    // path (dio interceptor, `errorLogger.log`, the service chain) is
    // covered, and matched against the UNWRAPPED [effectiveError] so a
    // ContextualError-wrapped transient is suppressed too.
    //
    // #2703 — read the device online-state UPFRONT so the gate can suppress
    // any network-category transient while the device is offline. Shape-match
    // is PRIMARY (it catches online-but-DNS-dead); `isOnline == false` is the
    // secondary signal for a network failure with no offline-specific shape.
    final isOnline = await _isDeviceOnline();
    if (_isBenignTransient(effectiveError, isOnline: isOnline)) {
      debugPrint('TraceRecorder: skipping benign transient (offline/'
          'cancelled/connection), not persisting (#2671/#2703): '
          '$effectiveError');
      return;
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

  /// #2671 / #2703 — true for an EXPECTED offline/cancelled/connection
  /// transient that must not be persisted as an error trace:
  ///   1. a [SocketException] whose message reports a failed host lookup
  ///      (the device is simply offline — DNS can't resolve the API host);
  ///   2. a [DioException] of type [DioExceptionType.cancel] (the user
  ///      navigated away / a newer request superseded this one);
  ///   3. (#2703) a connection-LAYER Dio transient or a bare [HttpException]
  ///      — classified by the shared [isOfflineDioException] util so this
  ///      and the FR service can't drift (`connectionError` /
  ///      `connectionTimeout` / `sendTimeout` / `receiveTimeout`, an
  ///      `unknown` wrapping a SocketException, a connection abort);
  ///   4. (#2703) when [isOnline] is `false`, any other network-category
  ///      exception (`SocketException` / `TimeoutException` / `HttpException`)
  ///      — a doomed call made while the device has no connection.
  /// Narrow by construction: a [DioExceptionType.badResponse] (a 4xx/5xx the
  /// server actually answered) and a connection-REFUSED [SocketException]
  /// while online are real errors and still persist.
  static bool _isBenignTransient(Object error, {required bool isOnline}) {
    if (error is SocketException) {
      if (error.message.toUpperCase().contains('FAILED HOST LOOKUP')) {
        return true;
      }
      // Any socket failure while the device is offline is expected (#2703);
      // while online (e.g. connection refused) it stays a real error.
      return !isOnline;
    }
    if (error is DioException && error.type == DioExceptionType.cancel) {
      return true;
    }
    // #2703 — shared connection-layer classification (PRIMARY signal).
    if (isOfflineDioException(error)) return true;
    // #2703 — secondary offline signal: a doomed network call while offline.
    if (!isOnline && _isNetworkCategory(error)) return true;
    return false;
  }

  /// Whether [error] is a network-category exception by SHAPE — used only as
  /// the secondary `isOnline == false` signal (#2703). Deliberately EXCLUDES
  /// [DioException]: a connection-layer Dio failure is already caught as the
  /// PRIMARY signal by [isOfflineDioException], while a
  /// [DioExceptionType.badResponse] is a real server answer that must persist
  /// even if the connectivity probe momentarily reports offline.
  static bool _isNetworkCategory(Object error) =>
      error is SocketException ||
      error is HttpException ||
      error.runtimeType.toString().contains('TimeoutException');

  /// Read the current device online-state for the de-noise gate (#2703).
  /// Best-effort: any failure of the connectivity plugin returns `true`
  /// (assume online) so the gate falls back to pure shape-matching rather
  /// than wrongly suppressing a real error.
  static Future<bool> _isDeviceOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.isNotEmpty && !results.contains(ConnectivityResult.none);
    } catch (_) {
      return true;
    }
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
