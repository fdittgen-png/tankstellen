# Startup KPI on-device measurement procedure (Epic #4316)

Epic #4316's code-level children (#4317-#4319, #4341) are merged. What is
left is exactly what `scripts/check_startup_budget.sh` and
`test/core/perf/startup_regression_gate_test.dart` say they cannot do: time
a real cold start on a real phone. This is that procedure, for the
maintainer, on real devices, producing raw numbers to attach to the epic.

**This document does not restate the "CI cannot time a cold start"
constraint.** `startup_regression_gate_test.dart`'s file doc comment
already carries it, and `scripts/check_startup_budget.sh` explains the
same split at its CI entry point. Read either first if the "why not just
assert it in CI" question is open. This document starts from "the
constraint is accepted; how do I produce the number by hand."

## What you are measuring

`StartupKpi` (`lib/core/perf/startup_kpi.dart`) defines the one number
this app defends: time to useful map, launch to the first painted frame
on which a station price is readable (`StartupKpi.definition`).
`kColdStartBudget` (`lib/core/perf/perf_budgets.dart`) is the ceiling:
2,500 ms, measured on a Samsung mid-range device with a cold cache after
#4110. Every run below is judged against that same ceiling, or against
`kHiveOpenBudget` (400 ms, same file) for the Hive-open half specifically.

## One-time setup: turn the panel on

The startup-trace panel is behind two feature flags, both default-off in
every channel (`lib/features/feature_management/domain/feature_manifest.dart`).
On the build under test:

1. Open the app, go to Profile, then Feature management.
2. Enable "Developer / Debug mode" (`Feature.debugMode`).
3. Enable "Startup initialization trace" (`Feature.startupTrace`).
4. Fully close the app (swipe it away / force-stop). The panel reads
   `StartupTimer.instance`, which is populated once, at the launch that is
   currently running. Flipping the flags does not retroactively populate
   it; the NEXT cold launch is the first one you can read.

## Where the numbers come from

Profile, then Advanced & developer, then Developer tools (visible once
`debugMode` is on) shows the "Startup initialization trace" section
(visible once `startupTrace` is on): a waterfall of the phases in
`StartupTimer.instance.milestones`/`.spans`, and an "Export startup trace"
button.

Tapping it calls `StartupTraceExport.export()`, which writes the full
schema-v5 JSON document (`StartupTraceExport.buildDocument`) to the
device's public Downloads folder as
`tankstellen-startuptrace-<ISO8601 timestamp>.json` (Android: via
`MediaStore.Downloads`; iOS: `<app documents>/Downloads/`, reachable from
the Files app). Pull it off the device (`adb pull` on Android, the Files
app's share sheet or a cable copy on iOS) after each run — each export
gets its own timestamped filename, so runs never collide, but they also
never get automatically bundled off-device for you.

The fields that matter for this procedure, all already in the document
(see `startup_trace_export.dart` for the exact shape):

| JSON path | What it is |
|---|---|
| `kpi.ms` | the number, time to useful map, or absent (see below) |
| `kpi.withinBudget` | `StartupKpi.isWithinBudget`, or absent if `kpi.ms` is absent |
| `kpi.budgetMs` | `kColdStartBudget.limit`, carried so the row is self-contained |
| `phases[]` | each `StartupTimer` milestone as a `{name, atMs, durationMs}` phase |
| `boxOpens[]` | every timed Hive box open (first-frame AND deferred), with `durationMs` and `entries` — this is the dataset/box size column |
| `slowestBoxOpen` | the long-pole box for this run, if any opens were timed |
| `spans[]` | post-first-frame launch-sync spans (TankSync, trip merge, ...) |
| `appVersion` | `AppConstants.appVersion` |

`kpi.ms` is absent, not zero or null, when the launch never painted a
price (`DataUnknownReason.notMeasuredYet`; see `StartupKpi`'s own doc
comment on why). A run whose export has no `kpi.ms` recorded nothing about
the budget and must not be read as "fast" or discarded silently. Log it as
what it is: the launch never reached a price, and say why (empty search
result, no network, cache miss) if you can tell.

The same document also rides the standard error-log export once the panel
has been opened (`StartupTraceExport.ensureExtraExportSectionRegistered()`
registers the `startupTrace` section key). Developer tools' "Save error
log" button produces an equivalent bundle if that path is more convenient
on a given run.

`appVersion`, `phases`, and the Developer tools "Build info" group (App
version / Build channel) are also visible on-screen without pulling the
file, for a quick sanity check before running the whole matrix.

## Recording what the epic asks for

Before running anything, capture the fixed facts that do not change run to
run:

- App / flavor / build SHA: the commit you built from (`git rev-parse
  HEAD` in the checkout you built), which `flutter build`/`flutter run`
  invocation you used, and the "App version" / "Build channel" shown in
  Developer tools, Build info.
- Device / OS: model name, Android/iOS version, and whether it is the
  same physical device as any prior baseline run (see "Comparing
  before/after" below; a different device invalidates the comparison, not
  just changes it).
- Dataset / box sizes: after the FIRST run in a session, pull that run's
  export and read `boxOpens[].entries` per box; this is the per-box row
  count the first-frame batch (or a deferred box) actually deserialized.
  Record it once per session unless deliberately varying the seeded
  dataset between runs (e.g. testing a populated vs. empty favorites box).

### The scenarios (epic's checklist, made literal)

Run each with the flags from "One-time setup" already on, so every run
produces an export.

1. Fresh install, empty local cache: uninstall the app (Android: `adb
   uninstall <package>`; iOS: delete via the home screen), reinstall the
   build under test, launch, let it settle, export.
2. Populated local cache: from a warm install with favorites/search
   history already present (or after scenario 1's install has been used
   normally once), force-stop and cold-launch again, export.
3. Offline cached start: enable Airplane Mode (or otherwise cut network)
   on the device BEFORE launching, force-stop first, cold-launch, export.
   This exercises the cache-first read path; the `HiveFirstFrameBoxes`
   consumer notes call out the cache-miss-on-a-closed-box risk directly.
4. Configured landing routes: Profile, Start screen (`landingScreen`);
   run once with it set to Map, once to Favorites, once to Search
   (whichever the profile supports), force-stop and cold-launch between
   each change, export each.
5. Cold widget / deep-link launch: with the app fully force-stopped (not
   just backgrounded), launch via a home-screen widget tap, a
   `tankstellen://` deep link, or a share-intent hand-off (whichever cold
   entry points the build under test ships), then export.

For every scenario, also do ONE plain warm start (app already resident in
memory, bring it back to foreground) as the "warm" half of the
cold-vs-warm comparison. `kWarmStartBudget` in `perf_budgets.dart` has no
ceiling yet (`PerfBudget.unmeasured`, "no instrumentation yet"), so a warm
run has no `kpi` row to read at all. Record it anyway as a wall-clock
observation (stopwatch from tap to price-on-screen) with a note that it is
NOT a `StartupKpi` reading. Do not write a number into `kpi.ms`'s slot for
a warm run.

### Multiple runs, one number

A single export is one sample, and the epic's checkpoint explicitly says
"one fast run is not a defended improvement." For each scenario:

1. Force-stop and cold-launch at least 5 times, exporting after each.
2. Pull all exports for that scenario off the device.
3. Read `kpi.ms` out of each (skip, and note, any that are absent).
   `jq -r '.kpi.ms' tankstellen-startuptrace-*.json` across the pulled
   batch is the fastest way to get the column.
4. Report the median (middle value; average of the two middle values on
   an even count) and a tail value (the max, or the 90th percentile if
   there are enough runs to make that meaningful). The median is the
   number to compare against `kColdStartBudget`; the tail shows whether
   the median is hiding an occasional bad run.

### Comparing before/after

The epic's checkpoint asks for matched before/after samples, not two runs
done differently:

- Same device, same OS version, same scenario, same dataset size, ideally
  back-to-back in one sitting (device thermal state and background load
  drift over a day).
- "Before" is a build from the commit immediately before whatever change
  is under evaluation; "after" is the change. If no such build/APK/IPA
  exists to install, that is an explicit evidence gap: say so ("no
  pre-change baseline available on this device/build") rather than
  comparing against a differently-shaped prior number (a different
  device, a different scenario, or a number carried over from an old
  field export).
- Attach both matched sets of raw exports (not just the computed medians)
  to the epic, so a reader can recompute the median/tail themselves.

## What counts as a valid run vs. a gap to report

Valid, worth attaching:

- A cold launch, force-stopped immediately before, with a `kpi.ms`
  present in the export (or explicitly absent with a stated reason: a
  launch that legitimately never reached a price is data, not a
  discard).
- At least 5 runs per scenario, from the SAME device/OS/build, with all
  raw exports attached.

Not valid, report the gap, do not paper over it:

- No device available for a scenario (e.g. no iOS hardware on hand): say
  "blocked: no device" for that cell of the matrix rather than omitting
  it silently or substituting a simulator/emulator run (a simulator's
  cold start is not a phone's, for the same reason a CI runner's is not).
- No pre-change build to install for a before/after comparison: say
  "blocked: no pre-change artifact" rather than comparing against an old
  number from a different measurement session.
- A single run standing in for "multiple runs": one number is not a
  median, and the epic's checkpoint explicitly rejects "one fast run" as
  a defended improvement.
- A number recomputed or estimated rather than read out of an actual
  export JSON. Every number in the report must trace to a file that was
  actually pulled off a device.

## What this does NOT replace

`test/core/perf/startup_delay_mutation_test.dart` (added alongside this
document) proves the measurement pipeline (`HiveOpenTiming`,
`kHiveOpenBudget`, `StartupKpi`'s budget predicate) would catch a
regression of the #4110 shape, on a CI runner, with an injected fault. It
is evidence the plumbing works, not a substitute for the device numbers
this document collects. Neither one stands in for the other; the epic's
checkpoint needs both, and only this one needs a phone.

## Filing the result

Attach to Epic #4316:

- The raw exported JSON files, per scenario, per run (not just the
  computed summary).
- The pass/fail/blocked matrix: one row per scenario times device/OS,
  with median, tail, and `withinBudget` against `kColdStartBudget`, or
  the specific blocked reason from the section above.
- If comparing before/after: both matched sample sets and which commit
  SHA each came from.

Do not close the epic on a single green cell. The checkpoint is about the
whole matrix, and a matrix with gaps is still worth filing with the gaps
named.
