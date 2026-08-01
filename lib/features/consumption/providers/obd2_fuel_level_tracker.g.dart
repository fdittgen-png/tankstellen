// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'obd2_fuel_level_tracker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persists the live OBD2 tank-level reading so it survives the drive
/// (#3647) — the producer half of "the sensor tracks the tank between
/// fills".
///
/// Armed by `TripRecordingBanner` (which wraps every screen via
/// `MaterialApp.builder`), exactly like [LiveActivitySync]: the banner
/// `ref.watch`es this keepAlive notifier so it observes the live level
/// no matter which route is visible — including a backgrounded
/// recording. [currentObd2FuelLevelLitres] is null outside an active
/// recording, so this writes nothing when the car is parked; the last
/// persisted value from the previous drive IS the parked-tank truth.
///
/// Write policy: a change of at least [minDeltaLiters] against the last
/// persisted value (per vehicle). PID `0x2F` steps at 1/255 of tank
/// (~0.2 L on a small car), so 0.25 L keeps the settings-box churn at a
/// handful of writes per drive while never lagging the gauge by more
/// than one visible step. The first reading of a drive always writes.

@ProviderFor(Obd2FuelLevelTracker)
final obd2FuelLevelTrackerProvider = Obd2FuelLevelTrackerProvider._();

/// Persists the live OBD2 tank-level reading so it survives the drive
/// (#3647) — the producer half of "the sensor tracks the tank between
/// fills".
///
/// Armed by `TripRecordingBanner` (which wraps every screen via
/// `MaterialApp.builder`), exactly like [LiveActivitySync]: the banner
/// `ref.watch`es this keepAlive notifier so it observes the live level
/// no matter which route is visible — including a backgrounded
/// recording. [currentObd2FuelLevelLitres] is null outside an active
/// recording, so this writes nothing when the car is parked; the last
/// persisted value from the previous drive IS the parked-tank truth.
///
/// Write policy: a change of at least [minDeltaLiters] against the last
/// persisted value (per vehicle). PID `0x2F` steps at 1/255 of tank
/// (~0.2 L on a small car), so 0.25 L keeps the settings-box churn at a
/// handful of writes per drive while never lagging the gauge by more
/// than one visible step. The first reading of a drive always writes.
final class Obd2FuelLevelTrackerProvider
    extends $NotifierProvider<Obd2FuelLevelTracker, void> {
  /// Persists the live OBD2 tank-level reading so it survives the drive
  /// (#3647) — the producer half of "the sensor tracks the tank between
  /// fills".
  ///
  /// Armed by `TripRecordingBanner` (which wraps every screen via
  /// `MaterialApp.builder`), exactly like [LiveActivitySync]: the banner
  /// `ref.watch`es this keepAlive notifier so it observes the live level
  /// no matter which route is visible — including a backgrounded
  /// recording. [currentObd2FuelLevelLitres] is null outside an active
  /// recording, so this writes nothing when the car is parked; the last
  /// persisted value from the previous drive IS the parked-tank truth.
  ///
  /// Write policy: a change of at least [minDeltaLiters] against the last
  /// persisted value (per vehicle). PID `0x2F` steps at 1/255 of tank
  /// (~0.2 L on a small car), so 0.25 L keeps the settings-box churn at a
  /// handful of writes per drive while never lagging the gauge by more
  /// than one visible step. The first reading of a drive always writes.
  Obd2FuelLevelTrackerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'obd2FuelLevelTrackerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$obd2FuelLevelTrackerHash();

  @$internal
  @override
  Obd2FuelLevelTracker create() => Obd2FuelLevelTracker();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$obd2FuelLevelTrackerHash() =>
    r'081a29d5ce0505c89ed1806fefb4ff36a1edf180';

/// Persists the live OBD2 tank-level reading so it survives the drive
/// (#3647) — the producer half of "the sensor tracks the tank between
/// fills".
///
/// Armed by `TripRecordingBanner` (which wraps every screen via
/// `MaterialApp.builder`), exactly like [LiveActivitySync]: the banner
/// `ref.watch`es this keepAlive notifier so it observes the live level
/// no matter which route is visible — including a backgrounded
/// recording. [currentObd2FuelLevelLitres] is null outside an active
/// recording, so this writes nothing when the car is parked; the last
/// persisted value from the previous drive IS the parked-tank truth.
///
/// Write policy: a change of at least [minDeltaLiters] against the last
/// persisted value (per vehicle). PID `0x2F` steps at 1/255 of tank
/// (~0.2 L on a small car), so 0.25 L keeps the settings-box churn at a
/// handful of writes per drive while never lagging the gauge by more
/// than one visible step. The first reading of a drive always writes.

abstract class _$Obd2FuelLevelTracker extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
