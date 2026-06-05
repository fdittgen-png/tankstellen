// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_type_efficiency_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-fuel-type efficiency comparison for the active vehicle (Epic #2881).
///
/// Watches [fillUpListProvider] + [activeVehicleProfileProvider], filters the
/// fills to the selected vehicle's `vehicleId` (when a vehicle is active;
/// otherwise all fills), and returns
/// `FuelTypeEfficiencyAggregator.byFuelType(...)` — one
/// [FuelTypeEfficiencyStats] per fuel, sorted by €/km ascending.
///
/// Read-only re-slice of data the user already logged: no `FillUpList.add`
/// hook, no storage, no `Feature` gate (mirrors the #2698 no-gate precedent).
/// Lives in its own file (not the line-guarded consumption_providers.dart),
/// parallel to `monthlyFuelStatsProvider`.

@ProviderFor(fuelTypeEfficiencyComparison)
final fuelTypeEfficiencyComparisonProvider =
    FuelTypeEfficiencyComparisonProvider._();

/// Per-fuel-type efficiency comparison for the active vehicle (Epic #2881).
///
/// Watches [fillUpListProvider] + [activeVehicleProfileProvider], filters the
/// fills to the selected vehicle's `vehicleId` (when a vehicle is active;
/// otherwise all fills), and returns
/// `FuelTypeEfficiencyAggregator.byFuelType(...)` — one
/// [FuelTypeEfficiencyStats] per fuel, sorted by €/km ascending.
///
/// Read-only re-slice of data the user already logged: no `FillUpList.add`
/// hook, no storage, no `Feature` gate (mirrors the #2698 no-gate precedent).
/// Lives in its own file (not the line-guarded consumption_providers.dart),
/// parallel to `monthlyFuelStatsProvider`.

final class FuelTypeEfficiencyComparisonProvider
    extends
        $FunctionalProvider<
          List<FuelTypeEfficiencyStats>,
          List<FuelTypeEfficiencyStats>,
          List<FuelTypeEfficiencyStats>
        >
    with $Provider<List<FuelTypeEfficiencyStats>> {
  /// Per-fuel-type efficiency comparison for the active vehicle (Epic #2881).
  ///
  /// Watches [fillUpListProvider] + [activeVehicleProfileProvider], filters the
  /// fills to the selected vehicle's `vehicleId` (when a vehicle is active;
  /// otherwise all fills), and returns
  /// `FuelTypeEfficiencyAggregator.byFuelType(...)` — one
  /// [FuelTypeEfficiencyStats] per fuel, sorted by €/km ascending.
  ///
  /// Read-only re-slice of data the user already logged: no `FillUpList.add`
  /// hook, no storage, no `Feature` gate (mirrors the #2698 no-gate precedent).
  /// Lives in its own file (not the line-guarded consumption_providers.dart),
  /// parallel to `monthlyFuelStatsProvider`.
  FuelTypeEfficiencyComparisonProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fuelTypeEfficiencyComparisonProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fuelTypeEfficiencyComparisonHash();

  @$internal
  @override
  $ProviderElement<List<FuelTypeEfficiencyStats>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<FuelTypeEfficiencyStats> create(Ref ref) {
    return fuelTypeEfficiencyComparison(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FuelTypeEfficiencyStats> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FuelTypeEfficiencyStats>>(
        value,
      ),
    );
  }
}

String _$fuelTypeEfficiencyComparisonHash() =>
    r'faf065883d386d67d73c549b8eb922004badccf6';
