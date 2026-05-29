// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_station_radar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Builds the [FuelStationRadar] for the active country, reusing the country's
/// chain-backed [StationService] (which already carries the #2267 persisted
/// dataset + per-service rate limiter) for both the corridor fetch and the JIT
/// price fetch.

@ProviderFor(fuelStationRadar)
final fuelStationRadarProvider = FuelStationRadarProvider._();

/// Builds the [FuelStationRadar] for the active country, reusing the country's
/// chain-backed [StationService] (which already carries the #2267 persisted
/// dataset + per-service rate limiter) for both the corridor fetch and the JIT
/// price fetch.

final class FuelStationRadarProvider
    extends
        $FunctionalProvider<
          FuelStationRadar,
          FuelStationRadar,
          FuelStationRadar
        >
    with $Provider<FuelStationRadar> {
  /// Builds the [FuelStationRadar] for the active country, reusing the country's
  /// chain-backed [StationService] (which already carries the #2267 persisted
  /// dataset + per-service rate limiter) for both the corridor fetch and the JIT
  /// price fetch.
  FuelStationRadarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fuelStationRadarProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fuelStationRadarHash();

  @$internal
  @override
  $ProviderElement<FuelStationRadar> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FuelStationRadar create(Ref ref) {
    return fuelStationRadar(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FuelStationRadar value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FuelStationRadar>(value),
    );
  }
}

String _$fuelStationRadarHash() => r'f571f5d00dff05eeccb12bd475b880971dd1fbf8';
