// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'fuel_type_efficiency_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The fills that belong to the ACTIVE vehicle (#3945).
///
/// Every per-vehicle consumption read (the per-fuel comparison below, the
/// all-prices table's cost model) scopes through this one seam so they can
/// never disagree on whose fill a fill is. The rule lives in
/// [scopeFillUpsToVehicle]: the vehicle's own fills, plus — for a user with
/// exactly ONE vehicle profile — the fills carrying no `vehicleId` (their
/// pre-profile history, which can only be that car's). With two or more
/// profiles an unassigned fill is ambiguous and stays excluded. No active
/// vehicle ⇒ every fill.

@ProviderFor(activeVehicleFillUps)
final activeVehicleFillUpsProvider = ActiveVehicleFillUpsProvider._();

/// The fills that belong to the ACTIVE vehicle (#3945).
///
/// Every per-vehicle consumption read (the per-fuel comparison below, the
/// all-prices table's cost model) scopes through this one seam so they can
/// never disagree on whose fill a fill is. The rule lives in
/// [scopeFillUpsToVehicle]: the vehicle's own fills, plus — for a user with
/// exactly ONE vehicle profile — the fills carrying no `vehicleId` (their
/// pre-profile history, which can only be that car's). With two or more
/// profiles an unassigned fill is ambiguous and stays excluded. No active
/// vehicle ⇒ every fill.

final class ActiveVehicleFillUpsProvider
    extends $FunctionalProvider<List<FillUp>, List<FillUp>, List<FillUp>>
    with $Provider<List<FillUp>> {
  /// The fills that belong to the ACTIVE vehicle (#3945).
  ///
  /// Every per-vehicle consumption read (the per-fuel comparison below, the
  /// all-prices table's cost model) scopes through this one seam so they can
  /// never disagree on whose fill a fill is. The rule lives in
  /// [scopeFillUpsToVehicle]: the vehicle's own fills, plus — for a user with
  /// exactly ONE vehicle profile — the fills carrying no `vehicleId` (their
  /// pre-profile history, which can only be that car's). With two or more
  /// profiles an unassigned fill is ambiguous and stays excluded. No active
  /// vehicle ⇒ every fill.
  ActiveVehicleFillUpsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeVehicleFillUpsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeVehicleFillUpsHash();

  @$internal
  @override
  $ProviderElement<List<FillUp>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<FillUp> create(Ref ref) {
    return activeVehicleFillUps(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FillUp> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FillUp>>(value),
    );
  }
}

String _$activeVehicleFillUpsHash() =>
    r'd15e2b5736efb001bba93f4590aafbd52003161b';

/// Per-fuel-type efficiency comparison for the active vehicle (Epic #2881).
///
/// Watches [activeVehicleFillUpsProvider] (the fill-up list scoped to the
/// selected vehicle — or every fill when none is active) +
/// [activeVehicleProfileProvider], and returns
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
/// Watches [activeVehicleFillUpsProvider] (the fill-up list scoped to the
/// selected vehicle — or every fill when none is active) +
/// [activeVehicleProfileProvider], and returns
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
  /// Watches [activeVehicleFillUpsProvider] (the fill-up list scoped to the
  /// selected vehicle — or every fill when none is active) +
  /// [activeVehicleProfileProvider], and returns
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
    r'130a6fb6deeb38152364c2e9fef4b0642feb902e';
