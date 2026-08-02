**03 · Method**

# TDD & the test pyramid

> Tests exist to make a specific claim false when the code is wrong. Most of this page is about the ways a test suite can be large, green and worthless — because that is the failure mode that actually happens, and every rule here was written after one of them shipped.

**Chunk prefix** test **Updated** 2026-08-01 **Depends on** 01 Foundations

#### On this page

1. [The pyramid and what goes in each layer](#pyramid)
1. [The eight-step bug-fix protocol](#bugfix)
1. [Twin-bug audits](#twin)
1. [False-green tests](#false-green)
1. [Fakes over mocks, and the shared override helper](#fakes)
1. [Tests that enforce architecture](#lint-tests)
1. [Goldens, accessibility and time](#goldens)
1. [Running the suite without lying to yourself](#running)
1. [Coverage gates and what they are worth](#coverage)
1. [Regression escalation](#recurrence)

<!-- chunk: test.pyramid | tags: testing,pyramid,strategy -->

## The pyramid and what goes in each layer

Target 70% unit, 20% widget, 10% integration — and note that the ratio is achievable only because `domain/` is pure Dart.

| Layer | Share | What belongs here | Speed |
| --- | --- | --- | --- |
| **Unit** | 70% | Domain services, calculators, parsers, state reducers, cache logic, anything in `domain/`. No widget tester, no pump. | Sub-millisecond each |
| **Widget** | 20% | A screen renders the right thing for a given provider state; a tap dispatches the right call; a hidden feature stays hidden. | Tens of milliseconds |
| **Integration** | 10% | Boot, first-run wizard, a full flow across screens, and on-device behaviour that a headless test cannot reach. | Seconds; runs on a device or emulator |

Two further categories sit outside the pyramid and are worth naming separately because they behave differently in CI:

- **Static lint tests** — plain Dart tests that read the source tree and assert on it. They are unit tests by mechanism but architecture enforcement by purpose. See [below](#lint-tests).
- **Aliveness tests** — a test that installs the real release artifact on a real emulator and asserts the process is still running fifteen seconds later. Not a unit test in any sense; the only thing that catches a class of failure described in [page 13](13-android.html#r8).

> **[RULE]**

> **Tag tests that cannot be trusted to gate a pull request, and exclude them by tag rather than by deletion.** Two tags earn their keep: `network` for tests that hit real third-party APIs (an upstream timeout must never block a merge) and `flaky` for tests that have observably flaked without a related code change. Run PR and mainline CI with `--exclude-tags=network,flaky`, and run both tag sets in a nightly job so a genuine regression still surfaces within a day.

> ```yaml
> # dart_test.yaml — declaring the tags stops the runner warning about them
> tags:
>   network:
>     description: Hits real third-party APIs. Run on demand.
>   flaky:
>     description: Observably flaked in CI without a related code change.
> ```

<!-- chunk: test.bugfix | tags: testing,bug-fix,protocol,tdd -->

## The eight-step bug-fix protocol

Every bug fix starts with a test that fails *for the same reason the app fails*. The remaining steps exist because each of them was skipped once and cost a second round-trip.

1. **Grep the UI to find the exact method the failing widget calls.** Not the method you think it should call — the one it does.
1. **Write a failing test calling that exact method.** The test must fail with the same error, or the same wrong value, that the app produces.
1. **If the test passes immediately, you are testing the wrong thing.** Re-read the widget. This step catches more mistakes than any other on the list.
1. **Implement the fix; make the test pass.**
1. **Run the full suite.** Not the one file.
1. **Only then build an artifact.** Never build before the test proves the fix — a build cycle is minutes and proves nothing a test could not prove in seconds.
1. **Grep all callers of any changed function or getter** before asserting the new behaviour is safe.
1. **Twin-bug audit.** See [the next section](#twin).

> **[WHY]**

> Step 3 is the one people skip and the one that matters. A test written from your mental model of the code passes on first run, you declare the bug fixed, and the actual defect is untouched — because your mental model was the bug. A test that does not fail first has told you nothing.

> **[RULE]**

> **If a fix adds an affordance, a test must exercise it.** A pull request that adds a button, banner or dialog must include a test that *taps* it in the post-fix state. One project shipped a cold-start recovery banner whose Resume and End buttons were silent no-ops — the recovery path left the controller null, so both handlers returned immediately. A tap test would have failed on the first run.

> **[RULE]**

> **Producer and consumer ship together.** Never merge the reader half of a feature without the writer, or without a failing test that proves the gap. One project shipped a fuel-level badge whose backing fields no producer ever populated; the feature ran entirely dark in production until a later issue wired the writer. A feature with no producer is not closeable.

<!-- chunk: test.twin | tags: testing,bug-fix,pattern-audit -->

## Twin-bug audits

Before closing a bug, grep the codebase for the *pattern*, not just the file — the same defect almost always exists in a second location.

What to search for:

- The same exception type leaking into the UI from a different call site.
- The same paired call sequence where only one of the pair was fixed.
- Twin screens sharing a widget — fix one, check the other.
- A second error surface in the same method (a future's `catchError` handled, the sibling stream's `onError` ten lines below left raw).

> **[TRAP]**

> **Symptom: a bug you just fixed reappears under a different issue number within a fortnight.** In one project, four of six follow-up chains were "same bug, second location". One fixed an authentication screen and left the identical leak in the sync-setup screen. Another mapped a Bluetooth error on the `startScan` future and left the sibling `scanResults` stream's `onError` raw ten lines below. A thirty-second grep at fix time would have closed both at once, and in both cases the second report cost a full triage-fix-review-CI cycle.

> **[CHECK]**

> Write the grep you ran into the pull-request description. It takes one line, it proves the audit happened, and it tells the next person which pattern to search when the bug comes back anyway.

<!-- chunk: test.false-green | tags: testing,false-green,fixtures,anti-pattern -->

## False-green tests

The most dangerous test is one that passes for a reason unrelated to the behaviour it claims to check. Three species, all observed in production codebases.

### Species 1 — the fake that echoes the request

A fake service that returns whatever it was asked for cannot detect a data-availability bug, because the bug is precisely that the real service does *not* return what you asked for.

> **[TRAP]**

> **Symptom: a cross-border data bug survives three separate fixes, each with a passing test.** A fake country service returned the requested fuel grade for any input. The real API for that country never returns that grade — it sells a different one. Every test passed; the feature was broken for every user in that country. The fake was not modelling the service, it was modelling the test's own expectation.

> **Countermeasure:** for any bug about data *shape* or data *availability*, drive the real implementation with a **recorded real-API fixture**, and prove the test is red on the unfixed mainline before you fix it. Hand-written fakes are correct for behaviour tests and wrong for shape tests.

### Species 2 — testing the adapter instead of the path

> **[TRAP]**

> **Symptom: unit tests for a parser are green and the feature is broken in five of six regions.** A structured opening-hours field was correctly parsed by the adapter — and then excluded from serialisation, so it was lost on every cache, favourites and widget round-trip. The adapter tests asserted the adapter's output. Nothing asserted the search → codec → render path.

> **Countermeasure:** for anything that persists, test the round-trip, not the producer. Serialise, deserialise, and assert the field survived.

### Species 3 — trusting your own classification

> **[TRAP]**

> **Symptom: you tell a user their data is missing upstream, and it is not.** A parser dropped an opening-hours range of `01:00–01:00` as "degenerate". The upstream authority's own web UI displayed those stations as open 24 hours — that range *is* the 24-hour convention in that dataset. The test asserting the drop was part of the bug.

> **Countermeasure:** when a report says data is missing, verify against the **authoritative upstream source** — its own UI, its own documentation — before trusting your parser's classification of it.

> **[RULE]**

> **A bug-fix test must be demonstrated red on the unfixed code.** Not "would fail" — actually run it against mainline and see it fail. This single habit eliminates all three species above, because a false-green test is by definition one that was never seen red.

<!-- chunk: test.fakes | tags: testing,fakes,mocks,riverpod -->

## Fakes over mocks, and the shared override helper

Use a small hand-written fake for anything with behaviour; reserve a mocking library for verifying that a callback fired.

```dart
// Canonical shape: a fake lives in the test file that needs it, unless it
// is shared, in which case it lives in test/helpers/.
class _FakeStationService implements StationService {
  _FakeStationService({this.stations = const [], this.throws});

  final List<Station> stations;
  final Object? throws;
  int fetchCount = 0;

  @override
  Future<List<Station>> fetch(SearchQuery q) async {
    fetchCount++;
    if (throws != null) throw throws!;
    return stations;
  }
}
```

Why a fake rather than a mock: the fake can hold state, so it can express "the second call returns something different", "this call must not happen twice", or "this fake mirrors the server's row-level-security visibility". A mock expresses only "was called with".

> **[RULE]**

> **Fakes must mirror the server's authorisation behaviour, not just its data shape.** If the backend hides a field from non-owners, the fake must hide it too. One project's fake workspace repository answers an admin-invite-code getter only for owners — because a fake that is more permissive than the server produces widget tests that pass for users who would see an error in production.

**The shared override helper.** Every widget test starts from one function:

```dart
// test/helpers/mock_providers.dart
List<Override> standardTestOverrides({
  AuthRepository? auth,
  WorkspaceRepository? workspace,
  Clock? clock,
}) => [
  authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
  workspaceRepositoryProvider.overrideWithValue(workspace ?? FakeWorkspaceRepository()),
  clockProvider.overrideWithValue(clock ?? FixedClock(DateTime.utc(2026, 3, 1))),
  // …every app-lifetime dependency, defaulted
];
```

> **[WHY]**

> Without a shared helper, adding one new app-lifetime provider breaks every widget test in the repository and each one is fixed by hand. With it, the new provider is defaulted in one place. The helper is also the natural home for the fixed clock that [the time section](#goldens) insists on.

<!-- chunk: test.lint-tests | tags: testing,lint,architecture-enforcement -->

## Tests that enforce architecture

A plain Dart test that reads the source tree is the cheapest available mechanism for enforcing a rule the analyzer cannot express.

One project runs twenty-six of them. The catalogue is worth reproducing because each entry represents a class of defect somebody shipped:

| Category | Rules enforced this way |
| --- | --- |
| **Layering** | presentation must not import data; cross-feature import pairs may only decrease; file-length budgets with a ratcheting allow-list |
| **Error handling** | no empty `catch (_) {}`; every `catch (e)` carries a stack trace; errors are not merely `debugPrint`ed |
| **Localisation** | no hard-coded user-facing string literals; ARB fragment consistency; locale key parity; text-expansion survival |
| **Design system** | no inline border radii; no raw `AppBar`/`Card` in feature code; no inline title theming |
| **Platform** | no inline `Platform.isX` checks in shared code |
| **Routing** | no string-literal route paths; an exact route-count assertion so a new route cannot be added silently |
| **Contracts** | a "never throws" doc comment must have a sibling fault-injection test; declared-dependency hygiene; the analyzer severity table cannot silently regress |
| **Docs parity** | decision-record format; a how-to guide matches the code it documents; the privacy policy matches the declared data practices |

> **[TRAP]**

> **Symptom: a scanning test's regex false-matches and blocks an unrelated pull request.** One project's "every icon button has a tooltip" test used a regex that also matched `SomethingIconButton(`. Scanning tests need their own tests, or at minimum an explicit allow-list and a failure message that prints the offending line — a lint failure whose message does not show you the match costs more time than the rule saves.

> **[RULE]**

> **A baseline may only ever decrease.** Every ratcheting test commits a number. Lowering it is a normal pull request; raising it is forbidden, including "temporarily". The moment one exception is granted the ratchet stops working, because the next person cites the precedent.

One organisational hazard: the allow-list file is a shared surface and a conflict magnet. When two pull requests each re-grandfather the *same* file, the resolved number must be the **combined post-merge line count**, not either branch's figure. In one project, two PRs set 1402 and 1367; after both merged the real count was 1412.

<!-- chunk: test.goldens | tags: testing,goldens,accessibility,time -->

## Goldens, accessibility and time

### Do not commit locally-generated golden images

> **[TRAP]**

> **Symptom: golden tests pass locally and fail CI at 3–4% difference against a 1.5% tolerance, on every pull request.** Font rasterisation differs between macOS and Linux. A golden baselined on a developer's Mac will never match a Linux runner. Either generate baselines *on the CI platform* in a container, or — the recommendation — prefer structural widget tests that assert on the widget tree rather than on pixels.

### Assert accessibility, do not hope for it

```dart
testWidgets('booking screen meets tap-target guidelines', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(/* … */);
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  handle.dispose();
});
```

Every interactive screen gets this. Every new tappable affordance needs a large enough target *and* its own test that taps it.

### Pin the clock

> **[TRAP]**

> **Symptom: CI was green on the 28th and red on the 1st, with no commits in between.** Two tests in one project asserted against the literal current month and against a period-bound seeded record. They passed for three weeks and failed at the month boundary. These are time bombs, not regressions — and bumping the string just resets the fuse for next month.

> **Countermeasure:** inject a clock through the provider graph and default it to a fixed instant in `standardTestOverrides`. Never let a test read the wall clock. A grep for `DateTime.now()` in `test/` should return nothing.

<!-- chunk: test.running | tags: testing,ci,tooling -->

## Running the suite without lying to yourself

> **[TRAP]**

> **Symptom: "the tests passed" and they did not.** Run `flutter test` **bare**. Piping it — `flutter test | tail`, `flutter test | grep -i fail` — yields the *pipe's* exit code, not the suite's. A red run reads as green to any script checking `$?`. If you need to filter the output, capture to a file and check the exit status separately.

> ```bash
> # wrong — exit code is tail's
> flutter test | tail -20
>
> # right
> flutter test 2>&1 | tee /tmp/test.log; status=${PIPESTATUS[0]}
> tail -20 /tmp/test.log; exit "$status"
> ```

| Command | Use |
| --- | --- |
| `flutter analyze` | Zero tolerance, over `lib/` **and** `test/`. Agents and humans both routinely analyse only `lib/` and miss test-file lints that CI catches. |
| `flutter test` | The full suite. Minutes, not seconds, once real — run it in the background and keep working. |
| `flutter test test/features/<x>/` | One feature during the edit loop. |
| `flutter test --coverage` | Produces `coverage/lcov.info` for the gate. |
| `flutter test --tags=network` | The excluded upstream probes, on demand. |
| `flutter test integration_test -d <device>` | On-device end-to-end. |

**Sharding.** Once the suite passes ~20 minutes, split it across parallel CI jobs. Four shards is a reasonable first step. Set `fail-fast: false` so one failing shard does not hide the others — you want every failure visible in one run, not one per round-trip. See [page 18](18-github.html#sharding) for the matrix-skip trap that sharding introduces.

<!-- chunk: test.coverage | tags: testing,coverage,metrics -->

## Coverage gates and what they are worth

A coverage gate is a floor against catastrophic regression, not a measure of test quality — and setting it too low makes it decorative.

```bash
# Parse lcov, exclude generated files, fail below the threshold.
# LF = lines found, LH = lines hit.
TOTAL=$(grep -h '^LF:' "$LCOV" | cut -d: -f2 | paste -sd+ | bc)
HIT=$(grep  -h '^LH:' "$LCOV" | cut -d: -f2 | paste -sd+ | bc)
PCT=$(( HIT * 100 / TOTAL ))
[ "$PCT" -lt "$THRESHOLD" ] && { echo "::error::coverage $PCT% < $THRESHOLD%"; exit 1; }
```

> **[WHY]**

> Both source projects settled at a 45% line-coverage gate, and one of them says plainly in its own known-gaps section that this is *not* a meaningful ratchet: a thousand-test suite clears 45% comfortably, so the gate never fires and therefore never influences behaviour. That is an honest assessment worth copying. If a gate has not failed a build in a year, either raise it by a few points per quarter until it starts to bite, or stop presenting it as a quality control.

Exclude generated files from the denominator or the number is meaningless — a large freezed model set will carry the percentage on its own.

<!-- chunk: test.recurrence | tags: testing,regression,root-cause -->

## Regression escalation

If a bug has been fixed before and came back, do not ship fix N+1. Stop and ask whether there are two different failure modes that look identical on screen.

> **[TRAP]**

> **Symptom: the same user-visible symptom recurs across many issue numbers over months.** One project's grey-map-tile bug was "fixed" nine times across a span of issues. Cause #1 was real and each fix addressed it correctly. Cause #2 produced an identical grey tile and was never isolated, so every fix appeared to work in testing and failed again in the field.

> **Protocol on the second recurrence:**

1. Stop patching. Do not open a fix pull request.
1. Enumerate *every* code path that can produce this exact symptom. Write them down.
1. Add discriminating instrumentation — a distinct trace signature per path — and ship *that* alone.
1. Wait for a real occurrence and read which path fired.
1. Only then fix, with an integration-level reproduction test.

> Two further rules from the same experience: verify against the current mainline rather than a stale working branch, and **never ship diagnostics as a product feature** — instrumentation added for triage gets removed when the cause is found, or it becomes permanent noise nobody dares delete.

#### Sources for this page

- Both projects' test trees (roughly 1500 and 161 test files respectively), their `dart_test.yaml` tag declarations, coverage scripts and CI sharding configuration.
- Post-mortems supplying the traps: the echoing-fake cross-border failure, the serialisation-drop round-trip failure, the upstream-classification error, the golden-platform mismatch, the month-boundary time bombs, the piped-exit-code incident, and the nine-times-fixed map bug.
- One project's twenty-six static lint tests, catalogued by category.

The 70/20/10 ratio is a target both projects state; neither publishes a measured breakdown against it, so treat it as intent rather than as a reported figure.
