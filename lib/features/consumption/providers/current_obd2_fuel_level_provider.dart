import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../vehicle/providers/vehicle_providers.dart';
import 'trip_recording_provider.dart';

part 'current_obd2_fuel_level_provider.g.dart';

/// Most recent OBD2 tank-level reading, expressed in litres (#1434).
///
/// Closes the producer-wiring gap from #1401 — PR #1430 shipped the
/// consumer side (verified-by-adapter badge + variance prompt on the
/// fill-up form) but no producer was capturing tank levels at form
/// open / save time, so the badge never fired in production.
///
/// Source chain (read-only — no upstream tampering):
///   1. The trip-recording controller already populates
///      [TripLiveReading.fuelLevelPercent] on every debounced tick
///      from PID `0x2F`. We surface that value through
///      [TripRecording]'s state.
///   2. To convert percent → litres we multiply by the active
///      vehicle's [VehicleProfile.tankCapacityL]. Resulting precision
///      is bounded by the PID's 1/255 step (~0.4 % of tank) plus the
///      user-entered tank-capacity figure — typically ±5 % of the
///      true reading on coarse PIDs. Good enough to anchor the
///      verified-by-adapter badge / variance prompt; insufficient for
///      tankful reconciliation, which keeps using fill-up arithmetic.
///
/// Returns `null` when any one of the following holds:
///   * no trip is currently recording (`!state.isActive`)
///     — TripLiveReading has no per-sample timestamp, so an active
///       recording is the simplest, correct staleness proxy: the
///       controller emits at ~4 Hz so any non-null `state.live` is
///       sub-second fresh, and a stopped recording's stale value is
///       hidden by the `isActive` gate;
///   * the trip's latest [TripLiveReading.fuelLevelPercent] is null
///     (the car / adapter doesn't surface PID `0x2F`);
///   * no active vehicle profile, or its [tankCapacityL] is null /
///     non-positive (we can't convert).
///
/// OEM-PID native-litres path (#1615): when the `experimentalOemPids`
/// flag is on and an OEM-capable adapter resolved a manufacturer table,
/// the trip-recording fuel sampler populates
/// [TripLiveReading.fuelLevelLitres] with the exact litres read via the
/// OEM-PID registry. This provider prefers that native source and skips
/// the percent×capacity conversion entirely. When the field is null
/// (flag off, incapable adapter, or no table for the VIN) the coarse
/// percent×capacity path below runs unchanged.
@riverpod
double? currentObd2FuelLevelLitres(Ref ref) {
  final tripState = ref.watch(tripRecordingProvider);
  if (!tripState.isActive) return null;

  // #1615 — prefer the exact OEM-PID litres when present. A negative
  // value is treated as "no reading" (defensive) and falls through to
  // the percent path.
  final oemLitres = tripState.live?.fuelLevelLitres;
  if (oemLitres != null && oemLitres >= 0) return oemLitres;

  final percent = tripState.live?.fuelLevelPercent;
  if (percent == null) return null;
  if (percent < 0 || percent > 100) return null;

  final vehicle = ref.watch(activeVehicleProfileProvider);
  final capacity = vehicle?.tankCapacityL;
  if (capacity == null || capacity <= 0) return null;

  return (percent / 100.0) * capacity;
}
