// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_obd2_fuel_level_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
/// Native-litres precedence (most accurate first):
///   1. PSA passive-CAN (#1616) — when a `passiveCanCapable` STN-chip
///      adapter is listening to the instrument-cluster broadcast,
///      [psaFuelLevelProvider] streams exact litres decoded straight
///      off the CAN bus. This is the highest-fidelity source; it wins.
///   2. OEM-PID native litres (#1615) — when the `experimentalOemPids`
///      flag is on and an OEM-capable adapter resolved a manufacturer
///      table, the trip-recording fuel sampler populates
///      [TripLiveReading.fuelLevelLitres] with exact litres read via
///      the OEM-PID registry.
///   3. The coarse `percent × tankCapacityL` conversion below.
///
/// Each native source is skipped when absent (no passive-CAN stream /
/// flag off / incapable adapter / no table for the VIN), so the chain
/// degrades cleanly to the percent path with no behaviour change for
/// adapters that surface neither.

@ProviderFor(currentObd2FuelLevelLitres)
final currentObd2FuelLevelLitresProvider =
    CurrentObd2FuelLevelLitresProvider._();

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
/// Native-litres precedence (most accurate first):
///   1. PSA passive-CAN (#1616) — when a `passiveCanCapable` STN-chip
///      adapter is listening to the instrument-cluster broadcast,
///      [psaFuelLevelProvider] streams exact litres decoded straight
///      off the CAN bus. This is the highest-fidelity source; it wins.
///   2. OEM-PID native litres (#1615) — when the `experimentalOemPids`
///      flag is on and an OEM-capable adapter resolved a manufacturer
///      table, the trip-recording fuel sampler populates
///      [TripLiveReading.fuelLevelLitres] with exact litres read via
///      the OEM-PID registry.
///   3. The coarse `percent × tankCapacityL` conversion below.
///
/// Each native source is skipped when absent (no passive-CAN stream /
/// flag off / incapable adapter / no table for the VIN), so the chain
/// degrades cleanly to the percent path with no behaviour change for
/// adapters that surface neither.

final class CurrentObd2FuelLevelLitresProvider
    extends $FunctionalProvider<double?, double?, double?>
    with $Provider<double?> {
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
  /// Native-litres precedence (most accurate first):
  ///   1. PSA passive-CAN (#1616) — when a `passiveCanCapable` STN-chip
  ///      adapter is listening to the instrument-cluster broadcast,
  ///      [psaFuelLevelProvider] streams exact litres decoded straight
  ///      off the CAN bus. This is the highest-fidelity source; it wins.
  ///   2. OEM-PID native litres (#1615) — when the `experimentalOemPids`
  ///      flag is on and an OEM-capable adapter resolved a manufacturer
  ///      table, the trip-recording fuel sampler populates
  ///      [TripLiveReading.fuelLevelLitres] with exact litres read via
  ///      the OEM-PID registry.
  ///   3. The coarse `percent × tankCapacityL` conversion below.
  ///
  /// Each native source is skipped when absent (no passive-CAN stream /
  /// flag off / incapable adapter / no table for the VIN), so the chain
  /// degrades cleanly to the percent path with no behaviour change for
  /// adapters that surface neither.
  CurrentObd2FuelLevelLitresProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentObd2FuelLevelLitresProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentObd2FuelLevelLitresHash();

  @$internal
  @override
  $ProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double? create(Ref ref) {
    return currentObd2FuelLevelLitres(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double?>(value),
    );
  }
}

String _$currentObd2FuelLevelLitresHash() =>
    r'fec0b6d479dc3aef8c8c5256a58b5fb3e16994fe';
