// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #3382 — time budgets that bound the OBD2 trip-START sequence so a slow /
/// silent adapter (or a Hive stall) can never leave the recording stuck in
/// "initializing" forever — the field "must restart the app" report.
///
/// Two layers:
///  - per-step budgets ([kObd2TripStartOdometerBudget],
///    [kObd2TripStartVinBudget]) on the best-effort identity reads in
///    `TripRecordingController.start`. Both DEGRADE TO NULL on timeout (a null
///    odometer / VIN is already a supported degraded start), so the trip still
///    starts instead of hanging on a slow read.
///  - an overall watchdog ([kObd2TripStartWatchdog]) + a Hive baseline-load
///    bound ([kObd2TripStartBaselinesBudget]) in `Obd2RecordingPipeline.start`.
///    A timeout there ABORTS cleanly: tear down the half-open link + surface a
///    recoverable error so the user can retry immediately, no app restart.
///
/// The watchdog comfortably exceeds the sum of the per-step budgets + the
/// baseline load, so it only fires on a genuine stall, never a slow-but-ok car.
library;

/// Odometer read budget — its PID-A6 → PID-31 → Mode-22 fallback is otherwise
/// unbounded.
const Duration kObd2TripStartOdometerBudget = Duration(seconds: 6);

/// VIN (0902) read budget — a silent adapter mid-handshake can stall it.
const Duration kObd2TripStartVinBudget = Duration(seconds: 4);

/// Hive baseline-load budget — guards against storage stall / lock contention.
const Duration kObd2TripStartBaselinesBudget = Duration(seconds: 8);

/// Hard backstop on the whole blocking init (baseline load + controller start).
const Duration kObd2TripStartWatchdog = Duration(seconds: 25);

/// Bound a best-effort trip-start identity read ([read]) by [budget],
/// degrading to `null` on timeout so a slow/silent adapter can't stall the
/// start. The caller treats a null result as "unknown" — a normal degraded
/// start — so the trip proceeds regardless.
Future<T?> boundedStartRead<T>(Future<T?> read, Duration budget) =>
    read.timeout(budget, onTimeout: () => null);
