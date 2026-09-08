// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'run_scope.dart';

import '../telemetry/storage/isolate_error_spool.dart';
import '../telemetry/trace_recorder.dart';

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
typedef SpoolEnqueue = Future<void> Function({
  required String isolateTaskName,
  required Object error,
  StackTrace? stack,
  Map<String, dynamic>? contextMap,
  DateTime? timestamp,
});

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
  TraceRecorder? _testRecorderOverride;

  /// Test seam: route every trace to [recorder] instead of the real
  /// pipeline.
  ///
  /// Installing one also clears the episode table (#3980): the logger is a
  /// process-wide singleton, so without this a test inherits the previous
  /// test's open episode and its first `log()` is silently suppressed —
  /// which is exactly how the UK per-feed test failed on PR #4004, with an
  /// empty recorder and nothing to explain it.
  @visibleForTesting
  TraceRecorder? get testRecorderOverride => _testRecorderOverride;

  @visibleForTesting
  set testRecorderOverride(TraceRecorder? recorder) {
    _testRecorderOverride = recorder;
    _episodes.clear();
  }

  SpoolEnqueue _spoolEnqueueOverride = IsolateErrorSpool.enqueue;

  /// Test seam: replace the spool enqueue function. Defaults to
  /// [IsolateErrorSpool.enqueue]. Tests inject a captor to assert what
  /// was written without touching real Hive boxes.
  ///
  /// Like [testRecorderOverride], installing one clears the episode table
  /// (#3980): this is the seam the background-isolate path writes through,
  /// and a test that captures here would otherwise inherit an earlier
  /// test's open episode and see nothing at all.
  @visibleForTesting
  SpoolEnqueue get spoolEnqueueOverride => _spoolEnqueueOverride;

  @visibleForTesting
  set spoolEnqueueOverride(SpoolEnqueue fn) {
    _spoolEnqueueOverride = fn;
    _episodes.clear();
  }

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
    _testRecorderOverride = null;
    _spoolEnqueueOverride = IsolateErrorSpool.enqueue;
    _episodes.clear(); // #3980 — no test inherits the previous test's episode
  }

  /// `true` when running inside the foreground isolate with a bound
  /// container or an explicit test recorder.
  bool get isForegroundBound =>
      _container != null || _testRecorderOverride != null;

  /// #3581 / #3980 — episode gate, per layer. It began as a SYNC-only
  /// gate: an unreachable self-host retries every table on every resume,
  /// and the identical failure spooled 40× in minutes, flooding real
  /// traces out of the ring. A country-API outage or an OBD2 reconnect
  /// storm does exactly the same on its own layer, so #3980 keeps one
  /// episode per [ErrorLayer]. Consecutive errors on a layer with the
  /// same signature within [episodeWindow] are counted, not spooled; the
  /// first different signature (or window expiry) logs one summary
  /// carrying the suppressed count. Layers never share an episode — a
  /// storage failure during a sync outage is still its own first trace.
  static const Duration episodeWindow = Duration(minutes: 10);
  final Map<ErrorLayer, _Episode> _episodes = {};

  /// Signature = error type + leading message chars + the ADR 0021 context
  /// discriminators, so one outage collapses but INDEPENDENT failures do
  /// not.
  ///
  /// The first cut keyed on the error alone and was too coarse: fourteen
  /// parallel UK feeds throwing the same `DioException`, or two countries
  /// hitting the same opening-hours parse failure, are not one episode —
  /// they are N facts about N subjects, and collapsing them erased exactly
  /// the per-subject independence those call sites promise. `where` /
  /// `entity` / `country` / `runId` are what tell them apart.
  ///
  /// `episode` is the caller's own escape hatch: a site that already owns
  /// its episode semantics (`UnresponsiveAdapterDiagnostic`, which logs
  /// once per outage transition and rate-limits on its own clock) passes an
  /// incrementing id, so a genuinely new episode is never swallowed here.
  static String _signature(Object error, Map<String, Object?>? context) {
    final s = error.toString();
    final head = s.substring(0, s.length < 80 ? s.length : 80);
    final keys = ['where', 'entity', 'country', 'runId', 'episode'];
    final discriminators =
        keys.map((k) => context?[k]?.toString() ?? '').join('|');
    return '${error.runtimeType}:$head|$discriminators';
  }

  /// Test seam — forget every layer's episode.
  @visibleForTesting
  void resetEpisodesForTest() => _episodes.clear();

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
    final now = DateTime.now();
    final signature = _signature(error, context);
    final episode = _episodes[layer];
    if (episode != null &&
        episode.signature == signature &&
        now.difference(episode.lastAt) < episodeWindow) {
      episode.lastAt = now;
      episode.suppressed++;
      return; // counted, not spooled — the episode's first trace stands.
    }
    final suppressed = episode?.suppressed ?? 0;
    _episodes[layer] = _Episode(signature, now);
    if (suppressed > 0) {
      context = {
        ...?context,
        'previousEpisodeSuppressed': suppressed,
        'episodeLayer': layer.name,
      };
    }
    // #3980 — the ADR 0021 runId rides along automatically when the call
    // happens inside a RunScope; an explicit key in [context] wins.
    final runId = RunScope.currentId;
    if (runId != null && !(context?.containsKey('runId') ?? false)) {
      context = {...?context, 'runId': runId};
    }
    try {
      final recorder = _testRecorderOverride;
      if (recorder != null) {
        await recorder.record(
          ContextualError(layer: layer, error: error, context: context),
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
        // change. The recorder also unwraps [ContextualError] to
        // extract the layer for [ErrorCategory] inference (#1394).
        final recorder = container.read(traceRecorderProvider);
        await recorder.record(
          ContextualError(layer: layer, error: error, context: context),
          stackTrace,
        );
        return;
      }
      // Background isolate path: spool through Hive ring buffer.
      await _spoolEnqueueOverride(
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
/// `error.toString()`). The rendered message includes the structured
/// metadata for grep / log triage, while the recorder also pattern-
/// matches on the wrapper type to extract the [layer] for category
/// inference (#1394).
class ContextualError implements Exception {
  final ErrorLayer layer;
  final Object error;
  final Map<String, Object?>? context;

  ContextualError({
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

/// One layer's current outage episode (#3980): the signature that opened
/// it, when it was last seen, and how many identical throws it swallowed.
class _Episode {
  _Episode(this.signature, this.lastAt);
  final String signature;
  DateTime lastAt;
  int suppressed = 0;
}
