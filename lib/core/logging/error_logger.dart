import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error_tracing/storage/isolate_error_spool.dart';
import '../error_tracing/trace_recorder.dart';

/// Layer / area of the codebase where an error originated. Used as a
/// single grep target for cross-cutting analytics ("how many service
/// errors did we see in the last 7 days?") and as routing metadata
/// when the error eventually lands in Sentry / Glitchtip.
enum ErrorLayer {
  /// User-facing screens, widgets, route guards, navigation observers.
  ui,

  /// Riverpod providers — async notifiers, derived providers, observers.
  providers,

  /// Service layer (HTTP / API clients, country fetchers, geocoding).
  services,

  /// Local persistence (Hive boxes, secure storage, file IO).
  storage,

  /// TankSync / Supabase / cloud sync flows.
  sync,

  /// Background tasks running inside the foreground isolate
  /// (Timers, post-frame callbacks, foreground-service runners).
  background,

  /// Code that may run inside the WorkManager / `dart:isolate` worker
  /// where Riverpod is unavailable. Routes to [IsolateErrorSpool] for
  /// later replay.
  isolate,

  /// Anything else / not yet classified.
  other,
}

/// Single error-logging API for the app (#1104).
///
/// Replaces the four divergent channels (`debugPrint(e)`,
/// `TraceRecorder.record`, `Sentry.captureException`, silent swallow)
/// with one entry point. Foreground callsites are routed to
/// [TraceRecorder] (which already feeds Sentry via the configured
/// uploader); background-isolate callsites — where Riverpod is
/// unavailable — are spooled to [IsolateErrorSpool] for replay through
/// the same pipeline once the foreground app drains the ring buffer
/// (see `lib/app/app_initializer.dart`).
///
/// ## Routing
/// 1. If a `ProviderContainer` has been bound via [bind], we are in the
///    foreground isolate → delegate to `TraceRecorder.record`.
/// 2. Otherwise → write to [IsolateErrorSpool] (Hive ring buffer).
///
/// ## Why a singleton + bind, not a Riverpod provider
/// The whole point is to make the API callable from background
/// isolates that have no Riverpod container. A Riverpod-based logger
/// would need a different shape per isolate; the singleton lets every
/// callsite use the same `errorLogger.log(...)` regardless of context.
///
/// ## Contract
/// - `log` never throws — observability must not derail the caller.
/// - Stack trace is forwarded to TraceRecorder / spool unchanged; if
///   the caller passes `null`, `StackTrace.current` is captured at the
///   call site so the trace is still useful.
/// - `context` is a free-form map of Hive-safe primitives (string,
///   num, bool, null, List, Map). Non-primitives are coerced via
///   `toString()` by the spool; for the foreground path the wrapper
///   error preserves them in its `toString()`.
class ErrorLogger {
  ErrorLogger._();

  /// The bound foreground container, set once by `AppInitializer` after
  /// it builds the root `ProviderContainer`. Workers (background
  /// isolates) never call [bind] so their `_container` stays null and
  /// `log` falls through to the spool.
  ProviderContainer? _container;

  /// Test seam: an in-memory recorder that bypasses Riverpod. When set,
  /// `log` calls it instead of resolving `traceRecorderProvider` from
  /// the bound container. Useful for unit tests that don't want to
  /// stand up a full Hive + provider stack.
  @visibleForTesting
  TraceRecorder? testRecorderOverride;

  /// Test seam: replace the spool enqueue function. Defaults to
  /// [IsolateErrorSpool.enqueue]. Tests inject a captor to assert what
  /// was written without touching real Hive boxes.
  @visibleForTesting
  Future<void> Function({
    required String isolateTaskName,
    required Object error,
    StackTrace? stack,
    Map<String, dynamic>? contextMap,
    DateTime? timestamp,
  }) spoolEnqueueOverride = IsolateErrorSpool.enqueue;

  /// Bind the root foreground [ProviderContainer]. Called exactly
  /// once from `AppInitializer` after the container is built. After
  /// this call, foreground `log` invocations are routed through
  /// `TraceRecorder`; before it (or in a background isolate that
  /// never calls bind) they are spooled.
  void bind(ProviderContainer container) {
    _container = container;
  }

  /// Reset the foreground binding. Used in tests; not expected in
  /// production code (containers live for the lifetime of the app).
  @visibleForTesting
  void resetForTest() {
    _container = null;
    testRecorderOverride = null;
    spoolEnqueueOverride = IsolateErrorSpool.enqueue;
  }

  /// `true` when running inside the foreground isolate with a bound
  /// container or an explicit test recorder.
  bool get isForegroundBound =>
      _container != null || testRecorderOverride != null;

  /// Log [error] under [layer]. Routes to [TraceRecorder] in the
  /// foreground and to [IsolateErrorSpool] in background isolates.
  ///
  /// Never throws. Logs internal failures via [debugPrint] so the
  /// caller is never derailed by an observability fault.
  Future<void> log(
    ErrorLayer layer,
    Object error,
    StackTrace? stack, {
    Map<String, Object?>? context,
  }) async {
    final stackTrace = stack ?? StackTrace.current;
    try {
      if (testRecorderOverride != null) {
        await testRecorderOverride!.record(
          _ContextualError(layer: layer, error: error, context: context),
          stackTrace,
        );
        return;
      }
      final container = _container;
      if (container != null) {
        // Foreground path: TraceRecorder pipeline + Sentry uploader.
        // Wrap in a contextual error so the layer + context map land
        // in `error.toString()` (which TraceRecorder serialises to
        // `errorMessage`) without requiring a TraceRecorder API
        // change.
        final recorder = container.read(traceRecorderProvider);
        await recorder.record(
          _ContextualError(layer: layer, error: error, context: context),
          stackTrace,
        );
        return;
      }
      // Background isolate path: spool through Hive ring buffer.
      await spoolEnqueueOverride(
        isolateTaskName: layer.name,
        error: error,
        stack: stackTrace,
        contextMap: _toHiveContext(layer, context),
      );
    } catch (e, st) {
      // Never re-throw from the logger. Observability MUST NOT break
      // the calling task; #1105 spool follows the same contract.
      debugPrint('ErrorLogger: log failed (${layer.name}): $e\n$st');
    }
  }

  /// Convert a `Map<String, Object?>` (the public, type-safe context
  /// map) into the `Map<String, dynamic>` shape the spool expects.
  /// Adds the layer name under a reserved key so background-origin
  /// errors carry the layer through replay.
  static Map<String, dynamic> _toHiveContext(
    ErrorLayer layer,
    Map<String, Object?>? context,
  ) {
    final out = <String, dynamic>{
      'errorLayer': layer.name,
    };
    if (context == null || context.isEmpty) {
      return out;
    }
    for (final entry in context.entries) {
      out[entry.key] = entry.value;
    }
    return out;
  }
}

/// Wrapper error that carries the [ErrorLayer] and context map through
/// [TraceRecorder]'s `errorMessage` field (which is built from
/// `error.toString()`). This avoids a breaking change to
/// `TraceRecorder.record` — the recorder still gets a single `Object`
/// + `StackTrace`, but the rendered message includes the structured
/// metadata for grep / log triage.
class _ContextualError implements Exception {
  final ErrorLayer layer;
  final Object error;
  final Map<String, Object?>? context;

  _ContextualError({
    required this.layer,
    required this.error,
    required this.context,
  });

  /// Expose the wrapped error for callers that want to inspect the
  /// original type without parsing `toString()`.
  Object get inner => error;

  @override
  String toString() {
    final ctx = context;
    if (ctx == null || ctx.isEmpty) {
      return '[${layer.name}] $error';
    }
    return '[${layer.name}] $error [context=$ctx]';
  }
}

/// Process-wide singleton. Safe to call from any isolate; routing is
/// decided per call based on whether [ErrorLogger.bind] has been
/// invoked in the current isolate.
final ErrorLogger errorLogger = ErrorLogger._();
