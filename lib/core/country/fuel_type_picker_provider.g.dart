// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_type_picker_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Single source of truth for every fuel-type dropdown in the app
/// (#703). Returns the active country's supportedFuelTypes, with
/// [FuelType.all] filtered out (it is a search-time wildcard, not a
/// real preference).
///
/// Consumers:
/// - FuelTypeDropdown (defaults to this when no `options` override)
/// - NullableFuelTypeDropdown (same)
/// - Future: profile-save validator that rejects a preferredFuelType
///   not in this list
///
/// Switching country invalidates every dependent picker through
/// Riverpod's normal dependency tracking — no manual wiring needed.

@ProviderFor(fuelTypePicker)
final fuelTypePickerProvider = FuelTypePickerProvider._();

/// Single source of truth for every fuel-type dropdown in the app
/// (#703). Returns the active country's supportedFuelTypes, with
/// [FuelType.all] filtered out (it is a search-time wildcard, not a
/// real preference).
///
/// Consumers:
/// - FuelTypeDropdown (defaults to this when no `options` override)
/// - NullableFuelTypeDropdown (same)
/// - Future: profile-save validator that rejects a preferredFuelType
///   not in this list
///
/// Switching country invalidates every dependent picker through
/// Riverpod's normal dependency tracking — no manual wiring needed.

final class FuelTypePickerProvider
    extends $FunctionalProvider<List<FuelType>, List<FuelType>, List<FuelType>>
    with $Provider<List<FuelType>> {
  /// Single source of truth for every fuel-type dropdown in the app
  /// (#703). Returns the active country's supportedFuelTypes, with
  /// [FuelType.all] filtered out (it is a search-time wildcard, not a
  /// real preference).
  ///
  /// Consumers:
  /// - FuelTypeDropdown (defaults to this when no `options` override)
  /// - NullableFuelTypeDropdown (same)
  /// - Future: profile-save validator that rejects a preferredFuelType
  ///   not in this list
  ///
  /// Switching country invalidates every dependent picker through
  /// Riverpod's normal dependency tracking — no manual wiring needed.
  FuelTypePickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fuelTypePickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fuelTypePickerHash();

  @$internal
  @override
  $ProviderElement<List<FuelType>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<FuelType> create(Ref ref) {
    return fuelTypePicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FuelType> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FuelType>>(value),
    );
  }
}

String _$fuelTypePickerHash() => r'ee5df868637bcdd4543fdcd058ab0379fd31fc7c';
