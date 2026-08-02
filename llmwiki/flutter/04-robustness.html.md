**04 · Method**

# Robustness & error handling

> A robust app is not one that never fails. It is one where every failure is visible to someone who can act on it — the user, the log, or the test suite — and where nothing important fails quietly. Almost every rule here exists because something failed quietly for months.

**Chunk prefix** rob **Updated** 2026-08-01 **Depends on** 01 Foundations

#### On this page

1. [The never-silent-catch rules](#never-silent)
1. [One guarded-mutation helper](#guarded)
1. [Analyzer settings that catch real bugs](#analyzer)
1. [Honest degradation](#honest)
1. [Episode gating for repeated failures](#episode)
1. [Streams that swallow errors](#streams)
1. [Telling the truth about persistence](#persistence)
1. [Boot, recovery and the startup budget](#boot)
1. ["Never throws" is a contract](#never-throws)

<!-- chunk: rob.never-silent | tags: error-handling,lint,rules -->

## The never-silent-catch rules

Three rules, all machine-enforced, that between them eliminate the entire category of "the app did nothing and we have no idea why".

> **[RULE]**

> `catch (_) {}` is forbidden. Enforced by a scanning test. An empty catch is a decision to discard evidence, made by someone who will not be the one debugging it.

> **[RULE]**

> Every `catch (e)` is `catch (e, st)`, and `st` reaches the logger or trace recorder. A rethrow-only block may opt out with an explicit comment naming the reason. Enforced by a scanning test.

> ```dart
> // wrong — the location is gone
> try { await repo.save(x); } catch (e) { debugPrint('save failed: $e'); }
>
> // right
> try {
>   await repo.save(x);
> } catch (e, st) {
>   debugPrint('save failed: $e\n$st');
>   TraceLogger.instance.error('storage', 'save failed', error: e, stackTrace: st);
> }
> ```

> This rule was violated four times in a single working session on one project before it was added to the standard preamble given to implementation agents — the reflex to write a swallow-and-print catch is very strong.

> **[RULE]**

> A catch whose entire body is a `debugPrint` has not handled anything; it has converted an exception into a line nobody reads on a device nobody has. Enforced by a separate scanning test. Every caught error must do at least one of: recover with a named fallback, surface to the user, or record to the trace log. Printing is additive, never sufficient.

<!-- chunk: rob.guarded | tags: error-handling,helper,dry -->

## One guarded-mutation helper

The ten-line try/catch that every mutating call site was open-coding becomes one function, and the call site becomes one line.

```dart
/// Runs a mutating [action] with the error boilerplate every call site used
/// to open-code: on failure the error is printed, traced under
/// [domain]/[message], and — when [errorText] is given and [context] is still
/// mounted — surfaced as an error snackbar. Returns whether it succeeded.
Future<bool> runGuarded(
  BuildContext context, {
  required String domain,
  required String message,
  required Future<void> Function() action,
  String? errorText,
}) async {
  try {
    await action();
    return true;
  } catch (e, st) {
    debugPrint('$message: $e\n$st');
    TraceLogger.instance.error(domain, message, error: e, stackTrace: st);
    if (errorText != null && context.mounted) {
      AppSnack.error(context, errorText);
    }
    return false;
  }
}
```

```dart
// Call site: one line, correct by construction.
if (!await runGuarded(context,
    domain: 'money',
    message: 'fee band save failed',
    errorText: l10n.genericSaveError,
    action: () => repo.replaceFeeBands(id, bands))) {
  return;
}
```

> **[WHY]**

> Three properties fall out at once. The `context.mounted` check cannot be forgotten because it lives in the helper. The trace domain is a required parameter, so no call site records an untagged error. And the boolean return replaces the pattern where a failed mutation silently continued into the success path — which is the actual bug this helper was written to kill.

> **[RULE]**

> **Make the safe path shorter than the unsafe one.** This is the general principle the helper illustrates. If correct error handling takes ten lines and sloppy handling takes two, the codebase will fill with two-line versions regardless of what the guidelines say. Build the helper, then the correct version is the convenient one.

<!-- chunk: rob.analyzer | tags: analyzer,lint,static-analysis,configuration -->

## Analyzer settings that catch real bugs

Turn on strict language modes and promote the correctness lints to errors — every entry below corresponds to a defect class that shipped at least once.

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude: [ third_party/** ]        # vendored code keeps upstream conventions
  language:
    strict-casts: true               # no implicit downcasts
    strict-inference: true           # no uninferable invocations
    strict-raw-types: true           # no bare generics
  errors:
    invalid_annotation_target: ignore        # freezed @JsonKey false positive
    use_build_context_synchronously: error   # StateError on unmounted widget
    unawaited_futures: error                 # fire-and-forget persistence races
    discarded_futures: error                 # same, in sync contexts
    cancel_subscriptions: error              # leaked StreamSubscription
    close_sinks: error                       # leaked StreamController
    avoid_slow_async_io: error
    avoid_type_to_string: error
    no_logic_in_create_state: error
    throw_in_finally: error
    unnecessary_statements: error
    unrelated_type_equality_checks: error
    valid_regexps: error
    avoid_print: info                        # style-weighted, still fatal in CI
```

> **[WHY]**

> One project paid for implicit dynamic casts twice in its storage and JSON codec layer before enabling `strict-casts`. The failure mode is characteristic: a `Map<dynamic, dynamic>` coming out of a key-value store flows into code expecting `Map<String, dynamic>`, compiles cleanly, and throws at runtime on a device in a different locale or with older stored data. Strict casts turn that into a compile-time diagnostic.

Two operational notes:

- **Run the analyzer fatal on infos in CI**, and over `test/` as well as `lib/`. A test file tripping a lint is still a lint.
- **Pin the severity table with a test.** One project has a test asserting that `analysis_options.yaml` still promotes each of these to `error`, so a well-meaning edit cannot quietly downgrade the set.

> **[TRAP]**

> **Symptom: a lint rule cannot be suppressed at the site where the exception is legitimate.** Some analyzer-plugin rules do not honour `// ignore:` comments. When that happens, the only lever is disabling the rule globally — so document the full inventory of sites that would have carried an ignore comment, in the configuration file itself, along with the upstream condition that will let you re-enable it. Otherwise the disabled rule looks like laziness to the next reader and gets either re-enabled blindly or forgotten permanently.

<!-- chunk: rob.honest | tags: degradation,fallback,ux,observability -->

## Honest degradation

A fallback that is indistinguishable from the real thing hides outages and bugs indefinitely. Every degraded state needs a recognisable signature.

> **[TRAP]**

> **Symptom: a feature has been broken for months and nobody reported it, because the broken state looks plausible.** One project's map screen fell back to a small built-in demo dataset when its API key was unavailable. The demo stations rendered exactly like real ones. The key was being read from the wrong store — so *every* user got demo data, configured or not, and nobody noticed because there was nothing to notice.

> **Countermeasure — three parts, all required:**

1. **Give the fallback a signature.** A visible banner, a distinct marker style, a "sample data" label. Something a screenshot in a bug report will show.
1. **Log the downgrade.** A trace entry saying which tier served this result and why the tier above it did not.
1. **Document the tell in user-facing docs.** "The same handful of generic stations everywhere means the live fetch failed" turns a confused user into a useful report.

The same principle applies to build artifacts, and it is where the phrase came from:

> **[RULE]**

> **An artifact that cannot do its job must say so in its own name.** One project's macOS workflow produces a DMG even when no signing certificate is available — but names it `AppName-unsigned.dmg` and emits a build warning explaining what the user will have to do. A file called `AppName.dmg` that macOS refuses to open is worse than one that admits what it is. Generalise: a partial export, an unsigned build, a degraded dataset — name it, do not disguise it.

And to results that travel through the app:

- Carry `source` and `isStale` in the result type all the way to the UI ([the service-chain pattern](01-foundations-architecture.html#service-chain)) so the presentation layer *can* be honest.
- When a heuristic filter produces nothing on a safety-relevant surface, **fall back to unfiltered, never to empty** — and expose that in the API. One project's directional filter returns the full candidate list when nothing survives the cone, with `result.filtered == false` so the UI can say "showing all". A driver low on fuel must never see zero results because of a heuristic.

<!-- chunk: rob.episode | tags: logging,error-handling,observability -->

## Episode gating for repeated failures

Repeated identical failures get a counter, not a log entry each — otherwise one outage evicts the traces you actually need.

The failure is mechanical. A bounded error log holds, say, 500 entries. A backend goes down overnight and a sync retry fires every two minutes. By morning the log contains 300 copies of the same connection error and nothing else — every trace from the crash you were actually investigating has been evicted by the noise.

```dart
/// Collapses consecutive identical failures into one entry plus a count.
class EpisodeGate {
  EpisodeGate({this.window = const Duration(minutes: 30)});

  final Duration window;
  String? _signature;
  DateTime? _first;
  int _count = 0;

  /// Returns the suppressed count to stamp on the next DISTINCT trace,
  /// or null when this error should be logged normally.
  int? suppress(String signature, DateTime now) {
    if (signature == _signature &&
        _first != null &&
        now.difference(_first!) < window) {
      _count++;
      return _count;                // caller skips the log entry
    }
    final carried = _count;
    _signature = signature;
    _first = now;
    _count = 0;
    return carried > 0 ? null : null; // stamp `carried` on the new entry
  }
}
```

Build the signature from the error type plus the operation, not from the message — messages often embed a timestamp or an id that makes every occurrence look unique.

> **[CHECK]**

> Simulate it: make a dependency fail continuously for an hour of simulated time and assert that the bounded log still contains the entries that preceded the outage. If they are gone, the gate is not working.

<!-- chunk: rob.streams | tags: streams,dart,error-handling,watchdog -->

## Streams that swallow errors

A stream that emits a sentinel on failure and never errors or closes makes every `onError` and `onDone` handler attached to it dead code.

> **[TRAP]**

> **Symptom: a watchdog never fires, even though the underlying device is clearly gone.** Several device-facing streams are designed to emit `null` when a read fails, and to keep polling forever. That is a reasonable design — the consumer wants "no reading right now", not a terminated stream. But a liveness check written as `stream.listen(..., onError: reconnect, onDone: reconnect)` will *never* run, because neither callback is ever invoked.

> **Countermeasure:** read the stream's contract before wiring error callbacks. For a never-erroring stream, put the liveness check *in band* — evaluate a condition on every tick (for example, poll `!service.isConnected`) rather than waiting for a callback that cannot arrive.

```dart
// Wrong for a never-erroring stream — both callbacks are unreachable.
sub = telemetry.listen(_onSample, onError: _reconnect, onDone: _reconnect);

// Right — the liveness check rides the data path.
sub = telemetry.listen((sample) {
  if (sample == null && !_service.isConnected) {
    _missedTicks++;
    if (_missedTicks > _threshold) _reconnect();
  } else {
    _missedTicks = 0;
    _onSample(sample);
  }
});
```

Related discipline: enable `cancel_subscriptions` and `close_sinks` as analyzer *errors*. A leaked subscription on a screen that is pushed repeatedly is a slow memory and CPU leak that presents as "the app gets sluggish after a while", which is the hardest kind of report to act on.

<!-- chunk: rob.persistence | tags: ux,persistence,honesty -->

## Telling the truth about persistence

The UI must not imply a save decision is pending when the data is already stored.

> **[TRAP]**

> **Symptom: users report losing data they explicitly discarded — or keeping data they thought they discarded.** A summary sheet appeared after an operation, offering "Save" and "Discard". The record had already been written to storage when the operation ended. "Discard" dismissed the sheet and left the record in place. Users who tapped Discard found the item still there; users who assumed Discard worked never checked.

> **Countermeasure:** align the affordances with what storage actually did.

- Already saved? Say "saved automatically", offer **Done** and a real **Delete**.
- Not yet saved? Then and only then offer Save and Discard — and make Discard actually discard.
- Never offer a control whose label describes an action the code does not perform.

The general rule this instance illustrates: **the interface is a claim about system state, and a false claim is a defect of the same severity as a crash** — often worse, because a crash is reported and a false claim is believed.

<!-- chunk: rob.boot | tags: startup,recovery,performance -->

## Boot, recovery and the startup budget

Startup is the one code path every user executes, and the one where a failure produces no UI to report it from.

| Concern | Practice |
| --- | --- |
| **Global handlers first** | Install `FlutterError.onError` and `PlatformDispatcher.instance.onError` before anything else, routing both into the trace recorder. An error during initialisation is otherwise invisible. |
| **Storage failure is survivable** | If the local store cannot open — corrupt box, migration failure, denied sandbox — mount a minimal recovery host that offers export and reset rather than crash-looping. One project runs a bare provider scope for these pre-initialisation hosts. |
| **Defer what can be deferred** | Open only the boxes the first frame needs; open the rest lazily. Mark the deferred set explicitly so the split is visible. |
| **Budget it, and enforce the budget** | A cold-start budget (one project uses 2000 ms) checked by a CI job. Startup regressions are cumulative and invisible per-commit. |
| **Prove the release artifact boots** | Unit tests cannot catch a release-only crash. See [page 13](13-android.html#r8) — a shrinker removing a class used only by reflection produces a build that passes every test and dies before the first frame. |

> **[CHECK]**

> The aliveness test, in one line of CI: install the release build on an emulator, clear the log, launch with a deterministic activity name, wait fifteen seconds, and assert the process id still exists. It is crude and it catches the entire class.

<!-- chunk: rob.never-throws | tags: contracts,testing,documentation -->

## "Never throws" is a contract

A doc comment claiming a function never throws is an API contract, and it needs a fault-injection test proving it.

> **[RULE]**

> Any function documented as never-throwing must have a sibling test that injects a failure into each of its dependencies and asserts the function returns normally. One project enforces this with a scanning test that pairs the doc-comment marker with the existence of the test — and it went red twice in one session because the rule is easy to forget when adding the doc comment feels like the finishing touch.

Design the seams so injection is possible:

```dart
class TraceLogger {
  TraceLogger({
    Future<Directory> Function()? directoryProvider,  // inject a thrower
    this.capacity = 500,
    this.maxFileBytes = 512 * 1024,
  }) : _directoryProvider = directoryProvider;

  bool _fileDisabled = false;   // set once file IO fails — degrade to memory

  /// Never throws. File IO is strictly best-effort: any failure (missing
  /// directory, full disk, sandbox denial) degrades this logger to
  /// memory-only for the rest of the process.
  Future<void> log(TraceEntry e) async { /* … */ }
}
```

Note the design: the logger takes its directory provider as a constructor parameter specifically so a test can pass one that throws. A logger that calls `getApplicationSupportDirectory()` directly cannot be fault-tested at all — the seam is the point.

> **[WHY]**

> Because it is called from catch blocks. A logger that throws inside a catch block replaces a recoverable error with an unrecoverable one, at exactly the moment the system is already degraded. The same reasoning applies to crash reporters, analytics, and anything else on the failure path.

#### Sources for this page

- One project's `runGuarded` helper and `TraceLogger` (including its never-throws contract and injectable directory provider); the other's analyzer configuration with its promoted severity table and the test pinning it.
- Both projects' scanning lint tests for empty catches, missing stack traces, and print-only catch bodies.
- Post-mortems supplying the traps: the demo-data fallback that was invisible for months, the overnight-outage log eviction, the never-erroring telemetry stream, the Discard-that-kept-the-record sheet, and the unsigned-artifact naming decision.

The `EpisodeGate` code is an illustrative reconstruction of the described behaviour, not a verbatim copy of either project's implementation.
