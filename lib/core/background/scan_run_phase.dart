// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The lifecycle of ONE background alert scan, written down (#4162).
///
/// Before this the run was a sequence of awaits in
/// `BackgroundAlertScanCoordinator` and a `HiveIsolateLock?` that was or
/// was not null — correct in the happy path, and silent about where the
/// OS may stop it. The OS stops it anywhere: WorkManager cancels a worker
/// past its window, iOS expires a BGTask after ~30 s, and the process can
/// die at any await. The phases below name those awaits so a kill test
/// can land on each of them, and so the gate can say which edge a field
/// trace took.
///
/// ## Phases and their writer
///
/// The coordinator is the ONLY writer. The scan body and the dispatcher
/// report nothing on their own; the coordinator advances between the
/// body's stages.
///
/// * [idle] — no scan in this isolate.
/// * [locking] — waiting for the cross-isolate Hive lock.
/// * [opening] — the lock is held; the isolate's Hive boxes are opening.
/// * [gated] — boxes open; reading the cross-trigger cooldown.
/// * [collecting] — the price fetch and history write (network-bound).
/// * [dispatching] — detect → budget → notify → feed.
/// * [refreshingWidgets] — home-widget refresh (network-bound again).
/// * [stamping] — the cooldown stamp and the journal row.
enum ScanRunPhase {
  idle,
  locking,
  opening,
  gated,
  collecting,
  dispatching,
  refreshingWidgets,
  stamping,
}

/// How a scan run ended — what its journal row says (#3147, #4162).
///
/// Exactly one per run that reached [ScanRunPhase.locking]. The journal
/// row used to be an untyped bag of optional groups (skip reason, error,
/// counts) with eight representable combinations and three legal ones;
/// this enum is the three plus the second skip reason, and nothing else.
enum ScanOutcome {
  /// The body ran to the end and the cooldown was stamped.
  completed,

  /// Another holder kept the Hive lock past the acquire deadline.
  skippedLock,

  /// A scan completed inside the cross-trigger cooldown.
  skippedCooldown,

  /// Something threw; the run was abandoned.
  failed,
}

/// Every phase change a scan run legitimately makes (#4162).
///
/// Each edge names the line of `BackgroundAlertScanCoordinator` that
/// writes it:
///
/// * `idle → locking` — `scan()` starts.
/// * `locking → opening` — the lock was acquired. A lock that was not
///   acquired ends the run instead ([ScanOutcome.skippedLock]).
/// * `opening → gated` — the isolate's boxes are open.
/// * `gated → collecting` — outside the cooldown. Inside it the run ends
///   ([ScanOutcome.skippedCooldown]).
/// * `collecting → dispatching` — prices were collected for at least one
///   station. `collecting → refreshingWidgets` — the station set was
///   empty (#609: the nearest widget still refreshes).
/// * `dispatching → refreshingWidgets`, `refreshingWidgets → stamping`.
/// * any phase → `idle` — the `finally` that closes the boxes and
///   releases the lock, after the outcome was recorded.
///
/// ## Hidden sub-states (deliberately not phases)
///
/// * a scan inside the FOREGROUND isolate (the widget-refresh runners):
///   the same phases, but `opening` finds boxes the main isolate owns
///   and `closeIsolateBoxes` leaves them open (#2670);
/// * `dispatching` with a notification shown but its budget slot not yet
///   written — the window #4333 closes;
/// * `locking` "acquired" by a second isolate of the same process, which
///   the per-isolate claim could not see — also #4333.
const Map<ScanRunPhase, Set<ScanRunPhase>> kScanRunTransitions = {
  ScanRunPhase.idle: {ScanRunPhase.locking},
  ScanRunPhase.locking: {ScanRunPhase.opening, ScanRunPhase.idle},
  ScanRunPhase.opening: {ScanRunPhase.gated, ScanRunPhase.idle},
  ScanRunPhase.gated: {ScanRunPhase.collecting, ScanRunPhase.idle},
  ScanRunPhase.collecting: {
    ScanRunPhase.dispatching,
    ScanRunPhase.refreshingWidgets,
    ScanRunPhase.idle,
  },
  ScanRunPhase.dispatching: {
    ScanRunPhase.refreshingWidgets,
    ScanRunPhase.idle,
  },
  ScanRunPhase.refreshingWidgets: {ScanRunPhase.stamping, ScanRunPhase.idle},
  ScanRunPhase.stamping: {ScanRunPhase.idle},
};

/// The phases each [ScanOutcome] may be recorded from (#4162).
///
/// [ScanOutcome.failed] may end a run anywhere it can throw — which is
/// every phase past `idle`.
const Map<ScanOutcome, Set<ScanRunPhase>> kScanOutcomeFrom = {
  ScanOutcome.completed: {ScanRunPhase.stamping},
  ScanOutcome.skippedLock: {ScanRunPhase.locking},
  ScanOutcome.skippedCooldown: {ScanRunPhase.gated},
  ScanOutcome.failed: {
    ScanRunPhase.locking,
    ScanRunPhase.opening,
    ScanRunPhase.gated,
    ScanRunPhase.collecting,
    ScanRunPhase.dispatching,
    ScanRunPhase.refreshingWidgets,
    ScanRunPhase.stamping,
  },
};

/// Whether moving from [from] to [to] is a documented transition — or no
/// transition at all.
bool isScanRunTransition(ScanRunPhase from, ScanRunPhase to) =>
    from == to || (kScanRunTransitions[from]?.contains(to) ?? false);

/// Whether [outcome] may end a run that is in [from].
bool isScanOutcomeFrom(ScanOutcome outcome, ScanRunPhase from) =>
    kScanOutcomeFrom[outcome]?.contains(from) ?? false;

/// Where the coordinator reports its phase changes (#4162).
///
/// Observers only: a sink is told what happened and cannot change it.
/// Tests use it to land a simulated kill on an exact edge; production
/// passes none.
abstract interface class ScanPhaseSink {
  /// The run moved from [from] to [to].
  void onPhase(ScanRunPhase from, ScanRunPhase to);

  /// The run ended with [outcome] while in [from].
  void onOutcome(ScanOutcome outcome, ScanRunPhase from);
}
