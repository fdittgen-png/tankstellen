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

@ProviderFor(allPricesFuelCostModel)
final allPricesFuelCostModelProvider = AllPricesFuelCostModelProvider._();

/// The active vehicle's per-fuel cost model, or [FuelCostModel.empty]
/// when there is no vehicle / no usable history.

final class AllPricesFuelCostModelProvider
    extends $FunctionalProvider<FuelCostModel, FuelCostModel, FuelCostModel>
    with $Provider<FuelCostModel> {
  /// The active vehicle's per-fuel cost model, or [FuelCostModel.empty]
  /// when there is no vehicle / no usable history.
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
    r'462b2aba299e8df33702e49b966075e49b0f5927';

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
