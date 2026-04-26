import 'package:flutter/foundation.dart';

import '../error_tracing/storage/isolate_error_spool.dart';
import '../error_tracing/trace_recorder.dart';

/// Unified error logging API for the Tankstellen app (#1104 phase 1).
///
/// The codebase historically had four divergent logging channels —
/// `debugPrint`, `TraceRecorder.record`, `Sentry.captureException`, and
/// silent `catch (_) {}`. [ErrorLogger] is the single entrypoint that
/// foreground (Riverpod-aware) and background isolates (no Riverpod)
/// can both call: it routes to the right downstream pipeline based on
/// where it was invoked from, so callers don't have to care.
///
/// **Routing:**
/// - **Foreground** (after `AppInitializer._launch` has called
///   [markForeground]) → forwards to [TraceRecorder.record] with the
///   layer + context attached as a wrapping error so the foreground
///   pipeline (TraceStorage + Sentry upload) sees the full picture.
/// - **Background isolate** (default — no `markForeground` call) →
///   forwards to [IsolateErrorSpool.enqueue] which writes to a Hive
///   ring buffer that the foreground drains on the next cold start.
///
/// **Phase 1 scope** (this file): introduce the API + unit tests +
/// CLAUDE.md doc. Existing call sites (~12 `TraceRecorder.record` and
/// ~40 raw `debugPrint(e)`) are NOT migrated yet.
///
/// **Phase 2 scope** (separate PR): migrate every callsite, plus add
/// the lint test forbidding raw `debugPrint(e)` outside `tools/` and
/// `lib/core/logging/`.
///
/// Use it via the [errorLogger] singleton:
///
/// ```dart
/// try {
///   await stationService.fetch();
/// } catch (e, st) {
///   await errorLogger.log(
///     'StationService',
///     e,
///     st,
///     context: {'stationId': station.id},
///   );
/// }
/// ```
abstract class ErrorLogger {
  /// Logs an error with optional stack trace and context. Routes to
  /// [TraceRecorder] in foreground (Riverpod available) or
  /// [IsolateErrorSpool] in background isolates (no Riverpod).
  ///
  /// [layer] is a short string identifying the origin (e.g.
  /// `'StationService'`, `'background.refreshPrices'`,
  /// `'BackgroundService'`). It surfaces in the error trace and the
  /// isolate spool entry's `isolateTaskName` field.
  ///
  /// [stackTrace] is forwarded as-is to the background path. The
  /// foreground path requires non-null, so the router substitutes
  /// `StackTrace.current` rather than synthesizing a fake trace
  /// downstream.
  ///
  /// [context] is a metadata map (strings, numbers, bools, lists,
  /// maps). Non-Hive-serializable values are coerced via `toString()`
  /// by the spool to keep the ring buffer durable across schema drift.
  ///
  /// [classification] is an optional override hint. By default the
  /// downstream pipeline uses [ErrorClassifier.classify] on the error
  /// itself; passing this lets a caller force a specific category
  /// (e.g. for synthetic test exceptions whose runtime type doesn't
  /// match a real bucket).
  ///
  /// **Never throws.** Any failure inside the underlying writer is
  /// caught and logged via [debugPrint] with the exception message so
  /// observability failures never break the calling code path. The
  /// fallback message satisfies the "no silent catch" lint
  /// (`test/lint/no_silent_catch_test.dart`).
  Future<void> log(
    String layer,
    Object error,
    StackTrace? stackTrace, {
    Map<String, Object?>? context,
    ErrorClassification? classification,
  });
}

/// Caller-provided classification hint for [ErrorLogger.log]. The
/// downstream pipeline still runs [ErrorClassifier.classify] on the
/// error type by default — this enum exists so phase-2 callsites can
/// override the bucket when the runtime type is too generic
/// (e.g. plain `Exception` rethrown from an isolate, or a synthetic
/// error in tests). Maps 1:1 to [ErrorCategory] for downstream use.
enum ErrorClassification {
  api,
  network,
  cache,
  ui,
  platform,
  serviceChain,
  provider,
  unknown,
}

/// Production singleton. Test code may override via
/// [debugSetErrorLoggerForTesting] in a `setUp` and reset it in
/// `tearDown`.
ErrorLogger errorLogger = _RoutingErrorLogger();

/// Test-only override.
@visibleForTesting
void debugSetErrorLoggerForTesting(ErrorLogger logger) {
  errorLogger = logger;
}

/// Test-only reset back to the production singleton.
@visibleForTesting
void debugResetErrorLoggerForTesting() {
  errorLogger = _RoutingErrorLogger();
}

/// Foreground/background mode flag. `AppInitializer._launch` flips
/// this to `true` once a Riverpod [ProviderContainer] is constructed
/// and a [TraceRecorder] is available.
///
/// Background isolates (WorkManager) never call [markForeground], so
/// they keep the default `false` value and route to the spool.
bool _isForeground = false;

/// Reference to the foreground [TraceRecorder]. Set by
/// [markForeground]; consulted by [_RoutingErrorLogger] when the
/// foreground flag is `true`.
TraceRecorder? _foregroundRecorder;

/// Called by `AppInitializer._launch` once Riverpod is up. After this
/// call, [errorLogger.log] routes to [TraceRecorder.record].
///
/// Phase 1: nothing in `lib/` calls this yet — phase 2 wires it from
/// `app_initializer.dart` alongside the FlutterError /
/// PlatformDispatcher global handlers. Tests use
/// [debugSetForegroundForTesting].
void markForeground(TraceRecorder recorder) {
  _isForeground = true;
  _foregroundRecorder = recorder;
}

/// Test-only setter for the foreground flag + recorder reference.
@visibleForTesting
void debugSetForegroundForTesting({
  required bool isForeground,
  TraceRecorder? recorder,
}) {
  _isForeground = isForeground;
  _foregroundRecorder = recorder;
}

/// Resets the foreground flag back to its background default.
@visibleForTesting
void debugResetForegroundForTesting() {
  _isForeground = false;
  _foregroundRecorder = null;
}

/// Foreground writer signature. Test code can swap this to capture
/// arguments without spinning up Riverpod or Sentry.
typedef ForegroundWriter = Future<void> Function(
  TraceRecorder recorder,
  Object error,
  StackTrace stackTrace,
  String layer,
  Map<String, Object?>? context,
  ErrorClassification? classification,
);

/// Background writer signature. Test code can swap this to capture
/// arguments without touching Hive.
typedef BackgroundWriter = Future<void> Function(
  String layer,
  Object error,
  StackTrace? stackTrace,
  Map<String, Object?>? context,
  ErrorClassification? classification,
);

/// Active foreground writer. Production default forwards to
/// [TraceRecorder.record].
ForegroundWriter _foregroundWriter = _writeForeground;

/// Active background writer. Production default forwards to
/// [IsolateErrorSpool.enqueue].
BackgroundWriter _backgroundWriter = _writeBackground;

/// Test-only writer override. Pair with [debugResetWritersForTesting]
/// in `tearDown` so other tests aren't affected.
@visibleForTesting
void debugSetForegroundWriterForTesting(ForegroundWriter writer) {
  _foregroundWriter = writer;
}

/// Test-only writer override.
@visibleForTesting
void debugSetBackgroundWriterForTesting(BackgroundWriter writer) {
  _backgroundWriter = writer;
}

/// Test-only reset of both writer seams.
@visibleForTesting
void debugResetWritersForTesting() {
  _foregroundWriter = _writeForeground;
  _backgroundWriter = _writeBackground;
}

/// Production [ErrorLogger] implementation. Inspects the foreground
/// flag and dispatches to the right downstream sink.
class _RoutingErrorLogger implements ErrorLogger {
  @override
  Future<void> log(
    String layer,
    Object error,
    StackTrace? stackTrace, {
    Map<String, Object?>? context,
    ErrorClassification? classification,
  }) async {
    try {
      if (_isForeground) {
        final recorder = _foregroundRecorder;
        if (recorder == null) {
          // Foreground flag flipped but recorder missing — should not
          // happen in production because [markForeground] sets both
          // atomically, but stay defensive: fall through to the spool
          // so the error doesn't disappear.
          await _backgroundWriter(
            layer,
            error,
            stackTrace,
            context,
            classification,
          );
          return;
        }
        await _foregroundWriter(
          recorder,
          error,
          stackTrace ?? StackTrace.current,
          layer,
          context,
          classification,
        );
        return;
      }
      await _backgroundWriter(
        layer,
        error,
        stackTrace,
        context,
        classification,
      );
    } catch (e) {
      // Never bubble — observability failures must not derail callers.
      // Include the exception message so we don't violate the
      // "no silent catch" rule (test/lint/no_silent_catch_test.dart).
      debugPrint('errorLogger.log fallback: $e');
    }
  }
}

/// Default foreground writer — wraps the original error in a
/// [LoggedError] so the layer + context surface in
/// [TraceRecorder.record]'s downstream pipeline (TraceStorage +
/// Sentry).
Future<void> _writeForeground(
  TraceRecorder recorder,
  Object error,
  StackTrace stackTrace,
  String layer,
  Map<String, Object?>? context,
  ErrorClassification? classification,
) async {
  final wrapped = LoggedError(
    layer: layer,
    cause: error,
    context: context,
    classification: classification,
  );
  await recorder.record(wrapped, stackTrace);
}

/// Default background writer — appends to [IsolateErrorSpool].
Future<void> _writeBackground(
  String layer,
  Object error,
  StackTrace? stackTrace,
  Map<String, Object?>? context,
  ErrorClassification? classification,
) async {
  await IsolateErrorSpool.enqueue(
    isolateTaskName: layer,
    error: error,
    stack: stackTrace,
    contextMap: _coerceContextForSpool(context, classification),
  );
}

/// Convert the public `Map<String, Object?>` shape that `errorLogger.log`
/// accepts into the `Map<String, dynamic>` shape that the spool
/// requires, and tack the optional classification on so it survives
/// the Hive round-trip.
Map<String, dynamic>? _coerceContextForSpool(
  Map<String, Object?>? context,
  ErrorClassification? classification,
) {
  if (context == null && classification == null) return null;
  final out = <String, dynamic>{};
  if (context != null) {
    for (final entry in context.entries) {
      out[entry.key] = entry.value;
    }
  }
  if (classification != null) {
    out['_classification'] = classification.name;
  }
  return out;
}

/// Wrapper exception used when forwarding to [TraceRecorder] in the
/// foreground. Carries the [layer], optional [context] map, and
/// optional [classification] hint alongside the original [cause] so
/// the existing trace pipeline (which classifies by `runtimeType` and
/// `error.toString()`) keeps working.
///
/// Mirrors the shape of `_IsolateBackgroundError` in the spool — both
/// adapter wrappers exist so the trace pipeline doesn't need to know
/// about layer / context as first-class fields. Phase 2 may promote
/// them to first-class once every callsite is on the new API.
class LoggedError implements Exception {
  final String layer;
  final Object cause;
  final Map<String, Object?>? context;
  final ErrorClassification? classification;

  LoggedError({
    required this.layer,
    required this.cause,
    this.context,
    this.classification,
  });

  @override
  String toString() {
    final ctx = context;
    final cls = classification;
    final parts = <String>['LoggedError($layer): $cause'];
    if (ctx != null && ctx.isNotEmpty) {
      parts.add('[context=$ctx]');
    }
    if (cls != null) {
      parts.add('[classification=${cls.name}]');
    }
    return parts.join(' ');
  }
}
