# Error Reporting & Tracing

Three complementary systems:

- **`errorLogger.log`** — the single front door every catch site uses (Epic #2146). Layer-tagged, context-attached, never throws.
- **Trace recorder** — silent, local, always-on. Captures every error for forensic reconstruction.
- **Error reporter** — explicit, consent-gated. Composes a GitHub issue from a trace.

## The `errorLogger.log` pattern (Epic #2146)

Epic #2146 rerouted **309 silent / divergent catch blocks** through one canonical front door:

```dart
import 'package:tankstellen/core/logging/error_logger.dart';

try {
  await risky();
} catch (e, st) {
  unawaited(errorLogger.log(
    ErrorLayer.services,
    e,
    st,
    context: {'where': 'FooService.fetch', 'arg': sanitizedArg},
  ));
  rethrow;   // or recover, depending on the call site
}
```

### Layers

`ErrorLayer` (`lib/core/logging/error_logger.dart`) tags each error with the area of the codebase it came from. Eight layers cover the whole app:

| Layer | What lives there |
|---|---|
| `ui` | User-facing screens, widgets, route guards, navigation observers |
| `providers` | Riverpod providers — async notifiers, derived providers, observers |
| `services` | HTTP / API clients, country fetchers, geocoding |
| `storage` | Hive boxes, secure storage, file IO |
| `sync` | TankSync / Supabase / cloud sync flows |
| `background` | Foreground-isolate background work (timers, post-frame callbacks, foreground service runners) |
| `isolate` | Code that may run inside the WorkManager / `dart:isolate` worker where Riverpod is unavailable. Routes to `IsolateErrorSpool` for later replay |
| `other` | Anything not yet classified |

### Routing

`ErrorLogger` is a singleton bound from `AppInitializer` to the foreground `ProviderContainer`. At runtime:

1. **Foreground isolate** (container bound) → delegates to `TraceRecorder.record`, which writes the trace to Hive and feeds Sentry.
2. **Background isolate** (no container) → writes to `IsolateErrorSpool` (Hive ring buffer). The foreground app drains the spool on next launch and replays each entry through the same pipeline.

### Recursive-loop pitfall — KEEP `debugPrint` IN TELEMETRY STORAGE

The storage layer of the telemetry pipeline itself **must keep using `debugPrint`** for its own errors, never `errorLogger.log`. The reason is brutal: `IsolateErrorSpool` writes to a Hive box; if that write fails and we log the failure through `errorLogger`, the logger writes to the same spool, which fails the same way, which logs through the logger again — infinite recursion, app dies. The standing rule:

```dart
// lib/core/telemetry/storage/*.dart  — and only here
} catch (e, st) {
  debugPrint('IsolateErrorSpool write failed: $e\n$st');   // intentional
}
```

The static lint scan `test/lint/no_raw_debugprint_error_test.dart` explicitly whitelists this layer; everywhere else, raw `debugPrint(error)` is rejected.

## Global handlers

`lib/app/app_initializer.dart:_launch` lines 277–303

```dart
FlutterError.onError = (details) {
  FlutterError.presentError(details);
  traceRecorder.record(details.exception, details.stack);
};

PlatformDispatcher.instance.onError = (error, stack) {
  traceRecorder.record(error, stack);
  return true; // swallow from default handler
};
```

- `FlutterError.onError` — framework errors (build/layout/paint)
- `PlatformDispatcher.onError` — async + platform errors that escape the framework

Both feed the `TraceRecorder` before the default handler runs.

## `TraceRecorder`

`lib/core/error_tracing/trace_recorder.dart:33–85`

```dart
Future<void> record(
  Object error,
  StackTrace stackTrace, {
  ServiceChainSnapshot? serviceChainState,
}) async {
  final trace = ErrorTrace(
    id: uuid.v4(),
    occurredAt: DateTime.now(),
    tzOffsetMin: DateTime.now().timeZoneOffset.inMinutes,
    category: ErrorClassifier.classify(error),
    errorType: error.runtimeType.toString(),
    errorMessage: error.toString(),
    stackTrace: stackTrace.toString(),
    deviceInfo: await deviceInfoCollector.collect(),
    appState: appStateSnapshot(),
    serviceChainState: serviceChainState,
    networkState: await networkStateCollector.snapshot(),
    breadcrumbs: breadcrumbBuffer.take(),
  );
  await storage.add(trace);
}
```

### What's captured

| Field | Example | Where from |
|---|---|---|
| `id` | UUID v4 | generated |
| `occurredAt` + `tzOffset` | 2026-04-21T18:32:11+02:00 | `DateTime.now()` |
| `category` | `api`, `network`, `cache`, `ui`, `platform`, `serviceChain`, `provider`, `unknown` | `ErrorClassifier` |
| `errorType` | `DioException` | runtimeType |
| `errorMessage` | terse, no stack | toString |
| `stackTrace` | full | arg |
| `deviceInfo` | OS, version, locale, screen size, app version | `DeviceInfoCollector` |
| `appState` | active route, active profile, last API endpoint, search params | `appStateSnapshot()` |
| `serviceChainState` | which services tried, which failed, which returned stale | optional, passed by chain |
| `networkState` | online/offline, connectivity type | `NetworkStateCollector` |
| `breadcrumbs` | last N user actions | `breadcrumbBuffer` |

### What's NOT captured

- GPS coordinates (explicit opt-out)
- API keys (masked)
- User PII, email, profile name
- Supabase anon key
- Price history raw values

## Error classification

`lib/core/error_tracing/error_classifier.dart:6–25`

```dart
enum ErrorCategory { api, network, cache, ui, platform, serviceChain, provider, unknown }

static ErrorCategory classify(Object error) {
  if (error is ApiException || error is NoApiKeyException)       return ErrorCategory.api;
  if (error is DioException)                                     return ErrorCategory.network;
  if (error is CacheException)                                   return ErrorCategory.cache;
  if (error is FlutterError)                                     return ErrorCategory.ui;
  if (error is LocationException)                                return ErrorCategory.platform;
  if (error is ServiceChainExhaustedException)                   return ErrorCategory.serviceChain;
  if (error is ProviderException)                                return ErrorCategory.provider;
  return ErrorCategory.unknown;
}
```

Used by the trace UI to filter and by the classifier test (`test/core/error_tracing/error_classifier_test.dart`) to ensure every exception type the app throws maps to a non-`unknown` category.

## Trace storage

`lib/core/error_tracing/trace_storage.dart:13–99`

- Hive box `error_traces`
- Max 50 traces (FIFO eviction)
- Auto-purge entries older than 7 days
- Each trace stored as a single JSON row
- `exportAsJson()` serialises all traces for user export

Settings → Diagnostics shows the trace list; tap a trace to see full detail.

## Breadcrumbs

`lib/core/error_tracing/breadcrumb_buffer.dart`

A ring buffer of the last ~30 user actions:

- Tab changes
- Screen navigations
- Search submissions
- Favorite toggles

Each breadcrumb: `{ at, action, context }`. Kept lightweight: no PII, no free-form user strings.

Append via `breadcrumbBuffer.add(Breadcrumb('search.submit', {'country':'DE','fuelType':'e10'}))`.

## Consent-gated reporting

`lib/core/error_reporting/error_reporter.dart:31–54`

When the user taps **Report issue** in Settings → Diagnostics:

1. A dialog shows the **exact payload** that will be sent — the user sees every byte.
2. On confirm, `ErrorReportFormatter` composes a GitHub issue body:
   - Auto-assigned labels (category, severity)
   - Device + app version
   - Category-specific template
   - Trace JSON (sanitised)
3. `launchUrl(githubIssueNewUrl)` opens the browser — **the app itself never uploads**. The user submits the issue themselves.

This avoids every class of "did they really opt in" privacy problem.

## `ErrorReporterContext`

`lib/core/error_reporting/error_reporter_context.dart:13–44`

Synchronous helpers because error dialogs can't do async cleanly:

```dart
static String currentLocale();      // "de_DE"
static String currentPlatform();    // "Android 15"
static String currentAppVersion();  // "5.0.0+5062"
```

Backed by values cached at app init.

## Testing

- `trace_recorder_test.dart` — record → read-back round trip for every category
- `error_classifier_test.dart` — every app exception class maps to the right category
- `device_info_collector_test.dart` — handles web/native/platform differences
- `error_reporter_context_test.dart` — all helpers return non-empty strings
- Integration test: inject a deliberate exception, assert trace is written and visible in Settings → Diagnostics

## Common patterns

### Never silent-catch

The project conventions forbid `catch (_) {}`. A static test (`test/lint/no_silent_catch_test.dart`) enforces this. Every catch site goes through `errorLogger.log` (see the section at the top of this page).

Good:
```dart
try {
  await risky();
} catch (e, st) {
  unawaited(errorLogger.log(
    ErrorLayer.services,
    e,
    st,
    context: const {'where': 'FooService.fetch'},
  ));
  rethrow;
}
```

Bad:
```dart
try { await risky(); } catch (_) {}
```

### Always pass the stack trace

Without it, the trace is useless. `errorLogger.log` accepts a nullable stack and will capture `StackTrace.current` at the call site if you pass `null`, but real catch handlers should always forward the `st` they were given.

### Pass service chain snapshot when available

For service-chain failures, attach the chain snapshot in `context`:

```dart
try { ... } on ServiceChainExhaustedException catch (e, st) {
  unawaited(errorLogger.log(
    ErrorLayer.services,
    e,
    st,
    context: {
      'where': 'StationServiceChain.fetch',
      'snapshot': chain.snapshot().toMap(),
    },
  ));
  rethrow;
}
```

## Related

- [Testing & TDD](Dev-Testing-TDD-Pyramid) — error classification test conventions
- [Service Layer & Fallback](Dev-Service-Layer-Fallback) — where `ServiceChainExhaustedException` originates
