// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package

part of 'all_prices_table_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Cheapest price per fuel across the results the list is showing.
///
/// Reads the SAME pipeline the list renders (`searchState` → the memoised
/// filter/sort), so the delta a cell shows is measured against what the
/// user can actually see, not against a hidden result set.

@ProviderFor(allPricesBestByFuel)
final allPricesBestByFuelProvider = AllPricesBestByFuelProvider._();

/// Cheapest price per fuel across the results the list is showing.
///
/// Reads the SAME pipeline the list renders (`searchState` → the memoised
/// filter/sort), so the delta a cell shows is measured against what the
/// user can actually see, not against a hidden result set.

final class AllPricesBestByFuelProvider
    extends
        $FunctionalProvider<
          Map<FuelType, double>,
          Map<FuelType, double>,
          Map<FuelType, double>
        >
    with $Provider<Map<FuelType, double>> {
  /// Cheapest price per fuel across the results the list is showing.
  ///
  /// Reads the SAME pipeline the list renders (`searchState` → the memoised
  /// filter/sort), so the delta a cell shows is measured against what the
  /// user can actually see, not against a hidden result set.
  AllPricesBestByFuelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allPricesBestByFuelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allPricesBestByFuelHash();

  @$internal
  @override
  $ProviderElement<Map<FuelType, double>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<FuelType, double> create(Ref ref) {
    return allPricesBestByFuel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<FuelType, double> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<FuelType, double>>(value),
    );
  }
}

String _$allPricesBestByFuelHash() =>
    r'80ea5f30f0023f1e595d20b11843847aa78a316d';

/// The active vehicle's per-fuel cost model, or [FuelCostModel.empty]
/// when there is no vehicle / no usable history.
///
/// The consumption numbers are NOT re-derived here (#3934): they come from
/// `fuelTypeEfficiencyComparisonProvider` — the fill-ups feature's own
/// per-fuel aggregator (ADR 0015 v3), the same one the consumption screen
/// renders — reached through the `fill_ups/api.dart` barrel. One model, so
/// the table and that screen can never state two different L/100 km for the
/// same tank history.
///
/// Only PURE buckets become a per-fuel figure. A MIX bucket (`E85/E10`) is
/// a blend the driver burned, not a grade they can buy at the pump, and
/// crediting its litres to the dominant grade is exactly the ADR 0014
/// collapse ADR 0015 rejected — so a mix contributes to no column, and a
/// fuel only ever driven blended simply has no cost-per-100 km cell.
///
/// The aggregator also owns the vehicle scoping: it keeps the ACTIVE
/// vehicle's own fills only, where the deleted local copy also swept in
/// fills carrying no `vehicleId`. Single-vehicle users see no difference
/// (their fills are the vehicle's); multi-vehicle users no longer risk a
/// stray unassigned fill of another car moving this car's number.
///
/// The pump-anchored gain (`VehicleProfile.pumpGain*`, Epic #3886) is
/// deliberately NOT applied: it trims ESTIMATED OBD2 fuel rates onto the
/// pump's litres, and these litres already come from the pump.

@ProviderFor(allPricesFuelCostModel)
final allPricesFuelCostModelProvider = AllPricesFuelCostModelProvider._();

/// The active vehicle's per-fuel cost model, or [FuelCostModel.empty]
/// when there is no vehicle / no usable history.
///
/// The consumption numbers are NOT re-derived here (#3934): they come from
/// `fuelTypeEfficiencyComparisonProvider` — the fill-ups feature's own
/// per-fuel aggregator (ADR 0015 v3), the same one the consumption screen
/// renders — reached through the `fill_ups/api.dart` barrel. One model, so
/// the table and that screen can never state two different L/100 km for the
/// same tank history.
///
/// Only PURE buckets become a per-fuel figure. A MIX bucket (`E85/E10`) is
/// a blend the driver burned, not a grade they can buy at the pump, and
/// crediting its litres to the dominant grade is exactly the ADR 0014
/// collapse ADR 0015 rejected — so a mix contributes to no column, and a
/// fuel only ever driven blended simply has no cost-per-100 km cell.
///
/// The aggregator also owns the vehicle scoping: it keeps the ACTIVE
/// vehicle's own fills only, where the deleted local copy also swept in
/// fills carrying no `vehicleId`. Single-vehicle users see no difference
/// (their fills are the vehicle's); multi-vehicle users no longer risk a
/// stray unassigned fill of another car moving this car's number.
///
/// The pump-anchored gain (`VehicleProfile.pumpGain*`, Epic #3886) is
/// deliberately NOT applied: it trims ESTIMATED OBD2 fuel rates onto the
/// pump's litres, and these litres already come from the pump.

final class AllPricesFuelCostModelProvider
    extends $FunctionalProvider<FuelCostModel, FuelCostModel, FuelCostModel>
    with $Provider<FuelCostModel> {
  /// The active vehicle's per-fuel cost model, or [FuelCostModel.empty]
  /// when there is no vehicle / no usable history.
  ///
  /// The consumption numbers are NOT re-derived here (#3934): they come from
  /// `fuelTypeEfficiencyComparisonProvider` — the fill-ups feature's own
  /// per-fuel aggregator (ADR 0015 v3), the same one the consumption screen
  /// renders — reached through the `fill_ups/api.dart` barrel. One model, so
  /// the table and that screen can never state two different L/100 km for the
  /// same tank history.
  ///
  /// Only PURE buckets become a per-fuel figure. A MIX bucket (`E85/E10`) is
  /// a blend the driver burned, not a grade they can buy at the pump, and
  /// crediting its litres to the dominant grade is exactly the ADR 0014
  /// collapse ADR 0015 rejected — so a mix contributes to no column, and a
  /// fuel only ever driven blended simply has no cost-per-100 km cell.
  ///
  /// The aggregator also owns the vehicle scoping: it keeps the ACTIVE
  /// vehicle's own fills only, where the deleted local copy also swept in
  /// fills carrying no `vehicleId`. Single-vehicle users see no difference
  /// (their fills are the vehicle's); multi-vehicle users no longer risk a
  /// stray unassigned fill of another car moving this car's number.
  ///
  /// The pump-anchored gain (`VehicleProfile.pumpGain*`, Epic #3886) is
  /// deliberately NOT applied: it trims ESTIMATED OBD2 fuel rates onto the
  /// pump's litres, and these litres already come from the pump.
  AllPricesFuelCostModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allPricesFuelCostModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allPricesFuelCostModelHash();

  @$internal
  @override
  $ProviderElement<FuelCostModel> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FuelCostModel create(Ref ref) {
    return allPricesFuelCostModel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FuelCostModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FuelCostModel>(value),
    );
  }
}

String _$allPricesFuelCostModelHash() =>
    r'4c1bb83e51c4ca87e7f14e2e464938249000e0a8';

/// The stable column set every all-prices card renders.
///
/// Derived only from list-wide inputs (country fuel set, active vehicle,
/// best prices), so every card in the list gets the identical answer and
/// the columns line up.

@ProviderFor(allPricesColumns)
final allPricesColumnsProvider = AllPricesColumnsProvider._();

/// The stable column set every all-prices card renders.
///
/// Derived only from list-wide inputs (country fuel set, active vehicle,
/// best prices), so every card in the list gets the identical answer and
/// the columns line up.

final class AllPricesColumnsProvider
    extends
        $FunctionalProvider<
          AllPricesColumns,
          AllPricesColumns,
          AllPricesColumns
        >
    with $Provider<AllPricesColumns> {
  /// The stable column set every all-prices card renders.
  ///
  /// Derived only from list-wide inputs (country fuel set, active vehicle,
  /// best prices), so every card in the list gets the identical answer and
  /// the columns line up.
  AllPricesColumnsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allPricesColumnsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allPricesColumnsHash();

  @$internal
  @override
  $ProviderElement<AllPricesColumns> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AllPricesColumns create(Ref ref) {
    return allPricesColumns(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AllPricesColumns value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AllPricesColumns>(value),
    );
  }
}

String _$allPricesColumnsHash() => r'e2559b8c7d355c1ea2268bc9781396783e6fa1b7';
