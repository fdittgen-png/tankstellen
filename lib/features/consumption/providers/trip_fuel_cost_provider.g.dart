// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_fuel_cost_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Estimated fuel cost for the trip identified by [tripId] (#1209).
///
/// Composes the trip history list and the fill-up list filtered to the
/// trip's vehicle, then delegates to the pure
/// [estimateTripFuelCost] helper. Returns `null` when the trip is
/// absent, has no `fuelLitersConsumed` / `startedAt`, has no
/// `vehicleId`, or no eligible fill-up has a usable price — the trip
/// detail summary card uses that null to hide the cost row entirely.
///
/// Per-screen (no `keepAlive`) — matches the [tankLevel] composition
/// pattern from #1195.

@ProviderFor(tripFuelCost)
final tripFuelCostProvider = TripFuelCostFamily._();

/// Estimated fuel cost for the trip identified by [tripId] (#1209).
///
/// Composes the trip history list and the fill-up list filtered to the
/// trip's vehicle, then delegates to the pure
/// [estimateTripFuelCost] helper. Returns `null` when the trip is
/// absent, has no `fuelLitersConsumed` / `startedAt`, has no
/// `vehicleId`, or no eligible fill-up has a usable price — the trip
/// detail summary card uses that null to hide the cost row entirely.
///
/// Per-screen (no `keepAlive`) — matches the [tankLevel] composition
/// pattern from #1195.

final class TripFuelCostProvider
    extends $FunctionalProvider<double?, double?, double?>
    with $Provider<double?> {
  /// Estimated fuel cost for the trip identified by [tripId] (#1209).
  ///
  /// Composes the trip history list and the fill-up list filtered to the
  /// trip's vehicle, then delegates to the pure
  /// [estimateTripFuelCost] helper. Returns `null` when the trip is
  /// absent, has no `fuelLitersConsumed` / `startedAt`, has no
  /// `vehicleId`, or no eligible fill-up has a usable price — the trip
  /// detail summary card uses that null to hide the cost row entirely.
  ///
  /// Per-screen (no `keepAlive`) — matches the [tankLevel] composition
  /// pattern from #1195.
  TripFuelCostProvider._({
    required TripFuelCostFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tripFuelCostProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripFuelCostHash();

  @override
  String toString() {
    return r'tripFuelCostProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double? create(Ref ref) {
    final argument = this.argument as String;
    return tripFuelCost(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TripFuelCostProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripFuelCostHash() => r'8345f765d3dc2b9157c6c0727d5e27617fcdf3a4';

/// Estimated fuel cost for the trip identified by [tripId] (#1209).
///
/// Composes the trip history list and the fill-up list filtered to the
/// trip's vehicle, then delegates to the pure
/// [estimateTripFuelCost] helper. Returns `null` when the trip is
/// absent, has no `fuelLitersConsumed` / `startedAt`, has no
/// `vehicleId`, or no eligible fill-up has a usable price — the trip
/// detail summary card uses that null to hide the cost row entirely.
///
/// Per-screen (no `keepAlive`) — matches the [tankLevel] composition
/// pattern from #1195.

final class TripFuelCostFamily extends $Family
    with $FunctionalFamilyOverride<double?, String> {
  TripFuelCostFamily._()
    : super(
        retry: null,
        name: r'tripFuelCostProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Estimated fuel cost for the trip identified by [tripId] (#1209).
  ///
  /// Composes the trip history list and the fill-up list filtered to the
  /// trip's vehicle, then delegates to the pure
  /// [estimateTripFuelCost] helper. Returns `null` when the trip is
  /// absent, has no `fuelLitersConsumed` / `startedAt`, has no
  /// `vehicleId`, or no eligible fill-up has a usable price — the trip
  /// detail summary card uses that null to hide the cost row entirely.
  ///
  /// Per-screen (no `keepAlive`) — matches the [tankLevel] composition
  /// pattern from #1195.

  TripFuelCostProvider call(String tripId) =>
      TripFuelCostProvider._(argument: tripId, from: this);

  @override
  String toString() => r'tripFuelCostProvider';
}
