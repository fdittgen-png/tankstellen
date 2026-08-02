**01 · Start here**

# Foundations & architecture

> One opinionated stack and one layering scheme, both chosen so that the rules can be checked by a machine rather than remembered by a person. The organising idea of this page: an architecture is only real to the extent that something fails when you violate it.

**Chunk prefix** arch **Updated** 2026-08-01 **Depends on** —

#### On this page

1. [The stack, and why each piece](#stack)
1. [Pinning and dependency holds](#pinning)
1. [Feature-first layout](#layout)
1. [Boundaries that are enforced](#boundaries)
1. [State management with Riverpod](#state)
1. [Models, codegen and committed output](#models)
1. [The service-chain pattern](#service-chain)
1. [Storage and the one-accessor rule](#storage)
1. [Cross-platform by default](#platform)
1. [Feature flags and the enum cascade](#feature-flags)

<!-- chunk: arch.stack | tags: stack,dependencies,setup -->

## The stack, and why each piece

Both source projects converged on the same core, independently enough that the overlap is informative.

| Layer | Choice | Why this and not the obvious alternative |
| --- | --- | --- |
| Framework | Flutter 3.41 / Dart 3.11, pinned exactly in CI | A floating `channel: stable` once picked up an SDK whose bundled Gradle plugin hard-failed on a JVM-target mismatch in a transitive plugin. Pin it; bump it deliberately. |
| State | Riverpod 3 with `@riverpod` codegen | Over BLoC: less ceremony per unit of state, compile-time provider wiring, and a test-override mechanism that does not require rebuilding the widget tree by hand. Over plain Provider: no runtime type lookups and no `ProviderNotFoundException` class of bug. |
| Models | freezed + `json_serializable` | Immutability, exhaustive union handling and `copyWith` for free. Set `explicit_to_json: true` — see the trap below. |
| Routing | go_router | Declarative, deep-link-native, and it survives the platform-channel cold-start path that a `Navigator`-based scheme handles badly. |
| Local storage | Hive, with encrypted boxes | Pure Dart, no native build step, key-value access matches the actual read pattern. Re-validated against Isar and Drift in a formal evaluation; the conclusion was that the migration cost exceeded the benefit for a key-value workload. |
| HTTP | Dio, always via a factory | Interceptors are the point: per-client rate limiting, conditional GET, and retry live in one place instead of at every call site. |
| Backend (optional) | Supabase, self-hostable | Open source, so "your data, your server" is a fact a user can act on rather than a marketing line; Postgres RLS is a real authorisation boundary. See [page 07](07-supabase.html). |
| Maps | flutter_map + OpenStreetMap | No Google Maps dependency, which is a prerequisite for a libre build. See [page 17](17-fdroid.html). |
| i18n | ARB + `flutter gen-l10n`, fragment-merged | Editing one 4700-key ARB file in parallel branches is a merge-conflict generator. Per-feature fragments merged by a build script are not. |
| Background work | WorkManager (Android) / BGTaskScheduler (iOS) | Behind a plugin interface — see [cross-platform by default](#platform). |

> **[TRAP]**

> **Symptom: nested objects silently vanish when a model round-trips through storage.** Without `explicit_to_json: true` in `build.yaml`, `json_serializable` leaves nested `@JsonSerializable` types as object instances in the generated `toJson` output rather than converting them to maps. Hive — and anything else expecting plain maps — then drops them without an error.

> ```yaml
> targets:
>   $default:
>     builders:
>       json_serializable:
>         options:
>           explicit_to_json: true
> ```

> A related and nastier variant: a field excluded with `@JsonKey(includeToJson: false)` disappears on *every* serialisation path, not just the one you were thinking about. In one project a structured opening-hours field was JSON-excluded and therefore lost on every cache, favourites and widget round-trip — the feature broke in five of six countries and the adapter unit tests stayed green throughout, because they tested the adapter rather than the search→codec→render path.

<!-- chunk: arch.pinning | tags: dependencies,dependabot,version-pinning -->

## Pinning and dependency holds

Some dependencies must be held back, and the reason must be written next to the constraint or it will be bumped by the next automated update.

Record every hold as a comment in `pubspec.yaml` *and* as an ignore entry in the update bot's configuration. Both, not either — this is the single most reliably relearned lesson in dependency management.

> **[TRAP]**

> **Symptom: an automated dependency PR is red on arrival, and closing it just brings it back next week.** Packages that pin each other form a lock-step cluster. Ignoring one member does *not* stop the bot co-bumping it while resolving another member — it will chase the constraint and reproduce exactly the failure you thought you had suppressed. In one project a lint package, three state-management packages and two serialisation packages formed one cluster, ultimately gated on the Flutter SDK's own pin of a low-level metadata package; ignoring the lint package alone was defeated twice before every member was listed.

> **Countermeasure:** when you discover a cluster, add *every* member to the ignore list in one edit, with a comment naming the upstream event that will unblock it.

Categories of hold worth distinguishing, because they resolve differently:

| Kind of hold | Example | Resolves when |
| --- | --- | --- |
| **Licence** | A BLE package whose 2.x line moved to a commercial-only licence | A human makes a purchasing decision. Never by drift. |
| **Breaking API** | A geo-primitives package whose 0.10 line rewrote types used pervasively | Someone schedules a migration pass. Not part of routine updates. |
| **Toolchain** | A connectivity package whose iOS source references a symbol only present in a newer platform SDK than the CI runner's Xcode | The CI runner image ships the newer SDK. Track the runner-images issue. |
| **Transitive lock-step** | The lint/analyzer/codegen cluster above | The bottom of the chain moves. List every member. |
| **Prerelease leakage** | A bot pulling a `-dev` build into a stable group | Never — add a version-range exclusion permanently. |

> **[WHY]**

> A held dependency with no recorded reason is indistinguishable from neglect. Six months later someone bumps it "to catch up", CI goes red in a way nobody can explain quickly, and the hold is reinstated with a comment saying "breaks CI" — which is exactly the information that was already lost. Write the upstream condition, not the symptom.

<!-- chunk: arch.layout | tags: architecture,layering,project-structure -->

## Feature-first layout

Group by feature, not by technical layer, and keep a strict `core/` for things genuinely shared across features.

```text
lib/
├── main.dart
├── app/                      # composition root only
│   ├── app.dart              # the MaterialApp / root widget
│   ├── app_initializer.dart  # bootstrap sequencing
│   ├── router.dart           # route table
│   └── theme.dart
├── core/                     # cross-cutting ONLY — no feature logic
│   ├── cache/  storage/  network/  sync/  trace/  location/
│   ├── notifications/  permissions/  platform/  theme/  widgets/
│   └── utils/  types/  constants/
└── features/<name>/
    ├── data/                 # repositories, DTOs, remote + local sources
    │   ├── models/
    │   └── repositories/
    ├── domain/               # PURE DART — no Flutter, no Hive, no Dio
    │   ├── entities/
    │   └── services/
    ├── presentation/
    │   ├── screens/
    │   └── widgets/
    └── providers/            # the ONLY bridge from presentation to data
```

The test tree mirrors it exactly, so `test/features/booking/…` corresponds to `lib/features/booking/…` without anyone having to decide where a new test file goes.

> **[RULE]**

> **`domain/` is pure Dart.** No `package:flutter`, no storage library, no HTTP client. The payoff is that domain logic is unit-testable in milliseconds without a widget tester, an event loop pump, or a mocked platform channel — and that is what makes a 70% unit-test ratio achievable rather than aspirational.

Size budgets, applied per file: **screens under 300 lines, providers under 200, repository methods under 50.** These are arbitrary numbers whose value is that they are checked. When a file exceeds its budget, extract — do not raise the budget.

> **[TRAP]**

> **Symptom: three parallel pull requests all conflict in the same file, repeatedly.** Files that grow past ~1000 lines become conflict magnets and then become permanent ones, because everybody who touches the feature has to touch them. One project accumulated a 1400-line trip-recording controller that three separate issues all needed to modify in the same week; every pairing conflicted. Identify these files explicitly, serialise work on them rather than parallelising, and schedule the decomposition as its own tracked work — the conflict cost is real and compounding.

<!-- chunk: arch.boundaries | tags: architecture,lint,enforcement,static-analysis -->

## Boundaries that are enforced

Every architectural rule in this section is backed by a test that fails the build, because unenforced layering rules decay within weeks.

| Rule | Enforcement |
| --- | --- |
| `presentation/` never imports `data/` — always via `providers/` | A test that walks import statements in every presentation file |
| Features never import another feature's internals | A test counting cross-feature import pairs per file, with a snapshot that may only *decrease* |
| Files stay under their line budget | A test with a grandfathered allow-list of existing offenders, ratcheting down |
| No user-facing string literals in widgets | A scanning test with a baseline that may only decrease, target zero |
| No empty `catch (_) {}` | A scanning test; see [page 04](04-robustness.html) |
| Every `catch (e)` is `catch (e, st)` with the trace logged | A scanning test with an explicit opt-out comment for rethrow-only blocks |
| No inline `BorderRadius.circular(n)` — design tokens only | A scanning test |
| No inline `Platform.isIOS` in shared code | A scanning test; see [cross-platform by default](#platform) |
| No string-literal route paths | A scanning test |
| Design-system components only — no raw `AppBar`/`Card` in features | Scanning tests |

The pattern is always the same: a plain Dart test that reads the source tree, greps for the anti-pattern, and asserts the count against a committed baseline number. It costs perhaps forty lines per rule.

```dart
// test/lint/presentation_data_imports_test.dart — the shape of all of them
void main() {
  test('presentation never imports data directly', () {
    final offenders = <String>[];
    for (final file in Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.contains('/presentation/'))) {
      final src = file.readAsStringSync();
      for (final line in src.split('\n')) {
        if (RegExp(r"^import .*/data/").hasMatch(line.trim())) {
          offenders.add('${file.path}: ${line.trim()}');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'presentation must reach data through providers/');
  });
}
```

> **[WHY]**

> The ratcheting baseline is what makes this adoptable in an existing codebase. You do not have to fix 400 violations before you can start enforcing; you record 400, forbid 401, and every pull request that reduces the number lowers the ceiling. The rule that the baseline may only ever decrease is the whole mechanism — the moment someone is allowed to raise it "just this once", the ratchet is gone.

> **[RULE]**

> **When decomposing a file, do not carry cross-feature imports into the new helper.** Pass primitives — `bool byPrice`, not a `SortMode` enum owned by another feature. The boundary test counts pairs per file, so splitting a file can *raise* the count and fail the push even though the refactor looked purely mechanical.

<!-- chunk: arch.state | tags: riverpod,state-management,providers -->

## State management with Riverpod

Use code generation exclusively; hand-written `Provider`/`StateProvider` declarations are banned so that there is one idiom to learn and one thing to grep for.

| Annotation | Use for |
| --- | --- |
| `@riverpod` (auto-dispose) | Screen-scoped state. The default; reach for this unless you can name why not. |
| `@Riverpod(keepAlive: true)` | Genuine app-lifetime state only: storage handles, the active profile, the current locale, a live device connection. |

Call-site discipline:

- `ref.watch` in `build()`. `ref.read` in event handlers. `ref.listen` for snackbars and navigation.
- **Never mix `watch` and `read` in one expression.** Pick one; a mixed expression rebuilds unpredictably.
- After any `await` in widget code: `if (!context.mounted) return;`. Promote `use_build_context_synchronously` to `error` in the analyzer so this is not optional.
- Tests override with `ProviderScope(overrides: [...])`, always starting from a shared `standardTestOverrides()` helper so a new global dependency is wired once rather than in 200 test files.

> **[TRAP]**

> **Symptom: a test fails with `Actual: []` instead of an error, and the empty list makes no sense.** Providers that end in a catch-all — `on Object { return const []; }` — turn any exception into an empty result. Add a `ref.read(otherProvider)` inside one, and in any test container that does not mock `otherProvider` the read throws, the catch-all swallows it, and you get a mysterious empty list rather than a stack trace.

> **Countermeasure:** wrap new cross-provider reads in their own `try`/`catch` with an explicit safe default, so the failure is local and named rather than absorbed by the outer handler.

> **[TRAP]**

> **Symptom: `Bad state: No ProviderScope found` in exactly one test after adding a `Consumer`.** Adding a `Consumer` inside a widely-reused widget breaks every test that pumps that widget without a scope. Most harnesses go through a scoped `pumpApp` helper; the one test that calls `tester.pumpWidget(MaterialApp(...))` directly is the one that breaks. Grep the widget's test files for raw `pumpWidget` before wiring a `Consumer` into it.

<!-- chunk: arch.models | tags: freezed,codegen,build-runner -->

## Models, codegen and committed output

Generated files are committed to version control, which makes regenerating from clean a mandatory pre-push step.

Commit `*.freezed.dart`, `*.g.dart` and the generated localisation Dart. The reason is practical: a fresh clone, and in particular an automated dependency-update pull request, otherwise looks broken until someone runs codegen — and CI cannot distinguish "generated files missing" from "generated files wrong".

> **[RULE]**

> **Regenerate from clean before every push. Never incrementally.**

> ```bash
> dart run build_runner clean
> dart run build_runner build --delete-conflicting-outputs
> git add -- '*.g.dart' '*.freezed.dart'
> ```

> An incremental build keeps stale content hashes that a clean CI run flags. A push that leaves any generated diff uncommitted is a defect — in one project it reached CI four times in a single working session at roughly thirteen minutes per round-trip. Do not defer it to "the next push".

> **Enforce it locally:** a pre-push git hook that runs clean codegen and rejects the push on any drift turns a thirteen-minute CI failure into a thirty-second local one. Ship the hook in the repo and install it with a script; provide a documented emergency bypass so nobody is tempted to use `--no-verify`.

Do not run `dart format` across whole generated files — commit only the diff codegen actually produced, or every regeneration becomes an unreviewable whole-file change.

<!-- chunk: arch.service-chain | tags: networking,resilience,caching,fallback -->

## The service-chain pattern

Every externally-sourced piece of data flows through one chain that provides fresh-first reads, stale fallback, request coalescing and rate limiting — so no call site reimplements any of it.

```text
cache.getFresh()          → hit? return with source=cache, isStale=false
  ↓ miss
service.fetch()           → success? write cache, return with source=<api>
  ↓ failure
cache.get()   (any age)   → hit? return with source=cache, isStale=true
  ↓ miss
throw ServiceChainExhaustedException(snapshot)
```

The return type carries provenance, not just data:

```dart
class ServiceResult<T> {
  final T data;
  final ServiceSource source;   // which API, or cache
  final DateTime fetchedAt;
  final bool isStale;
  final List<Object> errors;    // what was tried and failed on the way
}
```

> **[WHY]**

> Carrying `source` and `isStale` all the way to the UI is what makes honest degradation possible. The results header can name the live data source and link to it; a stale result can say so. Without provenance in the result type, the UI has no way to distinguish "fresh from the authority" from "eleven hours old" and will present both identically — which is the failure described in [page 04](04-robustness.html#honest).

Adding a new external source is then four steps and no new plumbing:

1. Implement the abstract interface (`StationService`, `GeocodingProvider`, whatever the domain calls for).
1. Register it in the registry that maps a key — a country, a region, a provider id — to the implementation.
1. Build its HTTP client with the factory: `DioFactory.create(rateLimit: RateLimitConfig(minInterval: …))`. Never `Dio()` directly, or that source escapes rate limiting and interceptors.
1. Add a recorded-response fixture and drive the real implementation with it in a test. See [false-green tests](03-tdd-and-testing.html#false-green) for why a hand-written fake is not sufficient here.

> **[CHECK]**

> Chain tests must cover three cases every time: API success; API failure with a usable stale entry; total failure with nothing cached. If the third case does not have a test, the exception path is untested and will surface first in production.

<!-- chunk: arch.storage | tags: hive,storage,secure-storage -->

## Storage and the one-accessor rule

Key-value boxes with a documented encryption subset, keys declared as constants, and exactly one accessor per stored value.

- **Keys are constants in one class** with a pinning test asserting uniqueness and naming convention. A duplicated key string is a silent data-corruption bug.
- **Encrypt the boxes holding anything personal.** Derive the key from the platform secure store (Keystore/Keychain), never a constant.
- **Secrets never touch the plain store.** API keys, backend URLs and tokens live in secure storage only, are never logged, and never appear in an export.
- **Normalise map types at the boundary.** Hive returns `Map<dynamic, dynamic>`; a freezed `fromJson` needs `Map<String, dynamic>`. Put the conversion in one helper and always use it.
- **Background isolates need their own initialisation and a lock.** A file-based mutex prevents a background task and the main isolate opening the same box concurrently.

> **[TRAP]**

> **Symptom: a feature reads a stored value as null forever, and the fallback is plausible enough that nobody notices.** When a value has a dedicated accessor that adds semantics — reads the secure vault, applies a shipped default, caches — then *every* reader must go through it. A generic `getSetting(StorageKeys.x)` read of that same value compiles and appears to work, but returns null because the value lives in the vault.

> In one project the map screen read the plain settings box for an API key that the search screen fetched through the accessor. The map therefore served a small built-in demo dataset to every user, configured or not, for months — because the demo data rendered exactly like real data.

> **Countermeasure:** when touching any settings key, grep for *all* readers of that constant and route them through the single accessor. Add a regression test per consumer that overrides a fake accessor and asserts the consumer used it.

<!-- chunk: arch.platform | tags: cross-platform,plugin-pattern,architecture -->

## Cross-platform by default

Features target every supported platform unless there is a reason they cannot; platform-specific code lives behind an interface, never in an inline branch.

> **[RULE]**

> **No inline `if (Platform.isIOS)` in shared code.** Define an abstract capability, implement it once per platform, and select the implementation at composition time. Enforced by a scanning test.

```dart
// core/sensors/imu_sensor_source.dart — the abstract seam
abstract class ImuSensorSource {
  Stream<ImuSample> get samples;
  Future<bool> isAvailable();
}

// One implementation per platform, chosen in the composition root.
// Tests inject a third: a deterministic replay source.
```

The benefits compound in three directions: the shared code stays readable; a platform that cannot do the thing degrades to a named "unsupported" state rather than a crash; and tests get a seam to inject into for free. Page [12](12-nfc-rfid.html) shows the pattern applied to NFC, where the three-state availability enum is what makes a silent failure diagnosable in the field.

The same discipline applies to build variants. Where a distribution channel forbids a dependency — a libre build that must not link proprietary libraries — swap the *package* at dependency-resolution time rather than branching in Dart. See [page 17](17-fdroid.html).

<!-- chunk: arch.feature-flags | tags: feature-flags,enum-cascade,checklist -->

## Feature flags and the enum cascade

A user-facing feature toggle is a fan-out across five or six files, and missing one of them fails the build in a confusing place.

The model that worked: an enum of features, a manifest declaring each feature's default state per build channel and its prerequisite edges, and a settings surface that renders from the manifest.

| # | Touch point | Failure if skipped |
| --- | --- | --- |
| 1 | The enum value, with a doc comment naming the issue and any prerequisites | — |
| 2 | The manifest entry: per-channel default, `requires:` edges | A completeness test fails |
| 3 | Label and description `case` arms in the settings widget | Compile error — the switches are exhaustive, which is the point |
| 4 | Localisation keys for label, description and any blocked-toggle messages, fanned out to every locale | The locale-coverage gate fails |
| 5 | The hard-coded `Feature.values.length` assertion in the settings test | That test fails |
| 6 | Clean codegen, if the feature was wired into a freezed or provider consumer | The codegen-drift job fails |

> **[RULE]**

> **Enum values may be reordered but never renamed.** Persistence keys use `Enum.name`, so a rename silently resets that toggle for every existing user. If you must rename, write a migration.

> **[RULE]**

> **Gate a flagged feature at both layers.** Hide the entry point *and* bounce the deep link. A hidden button is not access control — the route is still reachable from a URL, a notification tap, or a restored navigation stack. Add a widget test for the hidden entry and a second for the bounced deep link.

#### Sources for this page

- Both source repositories: `pubspec.yaml` with its inline hold rationales, `analysis_options.yaml`, `build.yaml`, the `test/lint/` suites, the architecture decision records covering state management, local-first design, storage evaluation and the cross-platform plugin pattern.
- Post-mortem notes attached to the traps: the nested-serialisation drop, the accessor-bypass demo-data incident, the catch-all silent-empty provider failure, and the codegen-drift recurrences.

The line budgets (300/200/50) and the specific lint list are one project's calibration, not a universal standard — adopt the mechanism, choose your own numbers.
