// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'effective_fuel_type_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolves the **effective** fuel type the app should use, based on the
/// vehicle-vs-direct contract described in #694/#705.
///
/// Priority:
///   1. If a default vehicle is configured and matches a stored vehicle:
///      - EV vehicle → [FuelType.electric]
///      - Combustion vehicle → vehicle's preferredFuelType parsed via
///        [FuelType.fromString]; fall back to profile's `preferredFuelType`
///        if the vehicle has no fuel set
///      - Hybrid vehicle → not handled here; #704 will add
///        `hybridFuelChoice` and route through it.
///   2. Otherwise the profile's own `preferredFuelType` wins.
///
/// Every picker in the app (search chips, station filters, consumption
/// log) should read from this provider so a change to the profile or
/// the vehicle propagates in one place.

@ProviderFor(effectiveFuelType)
final effectiveFuelTypeProvider = EffectiveFuelTypeProvider._();

/// Resolves the **effective** fuel type the app should use, based on the
/// vehicle-vs-direct contract described in #694/#705.
///
/// Priority:
///   1. If a default vehicle is configured and matches a stored vehicle:
///      - EV vehicle → [FuelType.electric]
///      - Combustion vehicle → vehicle's preferredFuelType parsed via
///        [FuelType.fromString]; fall back to profile's `preferredFuelType`
///        if the vehicle has no fuel set
///      - Hybrid vehicle → not handled here; #704 will add
///        `hybridFuelChoice` and route through it.
///   2. Otherwise the profile's own `preferredFuelType` wins.
///
/// Every picker in the app (search chips, station filters, consumption
/// log) should read from this provider so a change to the profile or
/// the vehicle propagates in one place.

final class EffectiveFuelTypeProvider
    extends $FunctionalProvider<FuelType, FuelType, FuelType>
    with $Provider<FuelType> {
  /// Resolves the **effective** fuel type the app should use, based on the
  /// vehicle-vs-direct contract described in #694/#705.
  ///
  /// Priority:
  ///   1. If a default vehicle is configured and matches a stored vehicle:
  ///      - EV vehicle → [FuelType.electric]
  ///      - Combustion vehicle → vehicle's preferredFuelType parsed via
  ///        [FuelType.fromString]; fall back to profile's `preferredFuelType`
  ///        if the vehicle has no fuel set
  ///      - Hybrid vehicle → not handled here; #704 will add
  ///        `hybridFuelChoice` and route through it.
  ///   2. Otherwise the profile's own `preferredFuelType` wins.
  ///
  /// Every picker in the app (search chips, station filters, consumption
  /// log) should read from this provider so a change to the profile or
  /// the vehicle propagates in one place.
  EffectiveFuelTypeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'effectiveFuelTypeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$effectiveFuelTypeHash();

  @$internal
  @override
  $ProviderElement<FuelType> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FuelType create(Ref ref) {
    return effectiveFuelType(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FuelType value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FuelType>(value),
    );
  }
}

String _$effectiveFuelTypeHash() => r'22d9da033039ea986f05a18c4a913483e144f373';
