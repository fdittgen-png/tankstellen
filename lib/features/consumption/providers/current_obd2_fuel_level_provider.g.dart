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
/// PSA OEM-PID / passive-CAN paths (#1415, #1417, #1420) emit litres
/// natively but their producer wiring into Riverpod is not yet
/// complete — the data-layer service that owns those streams is
/// privately held by the trip-recording stack today (see comments in
/// [psaFuelLevelObd2ServiceProvider]). When that wiring lands, this
/// provider can prefer the native litres source and skip the
/// percent×capacity conversion entirely.

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
/// PSA OEM-PID / passive-CAN paths (#1415, #1417, #1420) emit litres
/// natively but their producer wiring into Riverpod is not yet
/// complete — the data-layer service that owns those streams is
/// privately held by the trip-recording stack today (see comments in
/// [psaFuelLevelObd2ServiceProvider]). When that wiring lands, this
/// provider can prefer the native litres source and skip the
/// percent×capacity conversion entirely.

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
  /// PSA OEM-PID / passive-CAN paths (#1415, #1417, #1420) emit litres
  /// natively but their producer wiring into Riverpod is not yet
  /// complete — the data-layer service that owns those streams is
  /// privately held by the trip-recording stack today (see comments in
  /// [psaFuelLevelObd2ServiceProvider]). When that wiring lands, this
  /// provider can prefer the native litres source and skip the
  /// percent×capacity conversion entirely.
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
    r'7e989a3321f641df7c42a0e95822850224bddb7d';
