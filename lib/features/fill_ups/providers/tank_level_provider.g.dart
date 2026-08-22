// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'tank_level_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tank level for [vehicleId] — v2 model (#3647): the most recent
/// physical fill-up anchors the level (full → 100 %), an OBD2
/// fuel-level reading newer than that fill overrides it, and trip
/// recordings are not consulted at all.
///
/// Sensor source preference:
///  1. the LIVE reading while a recording is active
///     ([currentObd2FuelLevelLitres] — PSA CAN > OEM litres > 0x2F),
///     stamped "now";
///  2. the persisted per-vehicle snapshot the tracker wrote during the
///     last drive ([Obd2FuelLevelSnapshotStore]);
///  3. none — the estimator stays on the fill anchor.
///
/// The live watch also keeps this provider rebuilding during a drive,
/// so the Carburant card follows the gauge in real time; after the
/// drive the live value drops to null and the freshly-persisted
/// snapshot takes over seamlessly.
///
/// Returns [TankLevelEstimate.unknown] when [vehicleId] matches no
/// stored vehicle profile or the vehicle has no fill-ups logged yet.

@ProviderFor(tankLevel)
final tankLevelProvider = TankLevelFamily._();

/// Tank level for [vehicleId] — v2 model (#3647): the most recent
/// physical fill-up anchors the level (full → 100 %), an OBD2
/// fuel-level reading newer than that fill overrides it, and trip
/// recordings are not consulted at all.
///
/// Sensor source preference:
///  1. the LIVE reading while a recording is active
///     ([currentObd2FuelLevelLitres] — PSA CAN > OEM litres > 0x2F),
///     stamped "now";
///  2. the persisted per-vehicle snapshot the tracker wrote during the
///     last drive ([Obd2FuelLevelSnapshotStore]);
///  3. none — the estimator stays on the fill anchor.
///
/// The live watch also keeps this provider rebuilding during a drive,
/// so the Carburant card follows the gauge in real time; after the
/// drive the live value drops to null and the freshly-persisted
/// snapshot takes over seamlessly.
///
/// Returns [TankLevelEstimate.unknown] when [vehicleId] matches no
/// stored vehicle profile or the vehicle has no fill-ups logged yet.

final class TankLevelProvider
    extends
        $FunctionalProvider<
          TankLevelEstimate,
          TankLevelEstimate,
          TankLevelEstimate
        >
    with $Provider<TankLevelEstimate> {
  /// Tank level for [vehicleId] — v2 model (#3647): the most recent
  /// physical fill-up anchors the level (full → 100 %), an OBD2
  /// fuel-level reading newer than that fill overrides it, and trip
  /// recordings are not consulted at all.
  ///
  /// Sensor source preference:
  ///  1. the LIVE reading while a recording is active
  ///     ([currentObd2FuelLevelLitres] — PSA CAN > OEM litres > 0x2F),
  ///     stamped "now";
  ///  2. the persisted per-vehicle snapshot the tracker wrote during the
  ///     last drive ([Obd2FuelLevelSnapshotStore]);
  ///  3. none — the estimator stays on the fill anchor.
  ///
  /// The live watch also keeps this provider rebuilding during a drive,
  /// so the Carburant card follows the gauge in real time; after the
  /// drive the live value drops to null and the freshly-persisted
  /// snapshot takes over seamlessly.
  ///
  /// Returns [TankLevelEstimate.unknown] when [vehicleId] matches no
  /// stored vehicle profile or the vehicle has no fill-ups logged yet.
  TankLevelProvider._({
    required TankLevelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tankLevelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tankLevelHash();

  @override
  String toString() {
    return r'tankLevelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TankLevelEstimate> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TankLevelEstimate create(Ref ref) {
    final argument = this.argument as String;
    return tankLevel(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TankLevelEstimate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TankLevelEstimate>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TankLevelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tankLevelHash() => r'b86d1d5cdeec1adb0e54909f76fbc2a6b35c6591';

/// Tank level for [vehicleId] — v2 model (#3647): the most recent
/// physical fill-up anchors the level (full → 100 %), an OBD2
/// fuel-level reading newer than that fill overrides it, and trip
/// recordings are not consulted at all.
///
/// Sensor source preference:
///  1. the LIVE reading while a recording is active
///     ([currentObd2FuelLevelLitres] — PSA CAN > OEM litres > 0x2F),
///     stamped "now";
///  2. the persisted per-vehicle snapshot the tracker wrote during the
///     last drive ([Obd2FuelLevelSnapshotStore]);
///  3. none — the estimator stays on the fill anchor.
///
/// The live watch also keeps this provider rebuilding during a drive,
/// so the Carburant card follows the gauge in real time; after the
/// drive the live value drops to null and the freshly-persisted
/// snapshot takes over seamlessly.
///
/// Returns [TankLevelEstimate.unknown] when [vehicleId] matches no
/// stored vehicle profile or the vehicle has no fill-ups logged yet.

final class TankLevelFamily extends $Family
    with $FunctionalFamilyOverride<TankLevelEstimate, String> {
  TankLevelFamily._()
    : super(
        retry: null,
        name: r'tankLevelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Tank level for [vehicleId] — v2 model (#3647): the most recent
  /// physical fill-up anchors the level (full → 100 %), an OBD2
  /// fuel-level reading newer than that fill overrides it, and trip
  /// recordings are not consulted at all.
  ///
  /// Sensor source preference:
  ///  1. the LIVE reading while a recording is active
  ///     ([currentObd2FuelLevelLitres] — PSA CAN > OEM litres > 0x2F),
  ///     stamped "now";
  ///  2. the persisted per-vehicle snapshot the tracker wrote during the
  ///     last drive ([Obd2FuelLevelSnapshotStore]);
  ///  3. none — the estimator stays on the fill anchor.
  ///
  /// The live watch also keeps this provider rebuilding during a drive,
  /// so the Carburant card follows the gauge in real time; after the
  /// drive the live value drops to null and the freshly-persisted
  /// snapshot takes over seamlessly.
  ///
  /// Returns [TankLevelEstimate.unknown] when [vehicleId] matches no
  /// stored vehicle profile or the vehicle has no fill-ups logged yet.

  TankLevelProvider call(String vehicleId) =>
      TankLevelProvider._(argument: vehicleId, from: this);

  @override
  String toString() => r'tankLevelProvider';
}
