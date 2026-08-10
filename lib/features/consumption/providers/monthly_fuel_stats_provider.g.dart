// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monthly_fuel_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-month fill-up statistics for the consumption-statistics detail
/// page (#2698), oldest first. Each month carries the FULL
/// `ConsumptionStats` for that month's fill-ups via the canonical
/// `ConsumptionStats.fromFillUps` window walker — so the page can show
/// month-over-month comparison + evolution charts with no new storage.
///
/// Lives in its own file (not the [fillUpListProvider] god-class) so the
/// 975-line consumption_providers.dart stays at its file_length snapshot.

@ProviderFor(monthlyFuelStats)
final monthlyFuelStatsProvider = MonthlyFuelStatsProvider._();

/// Per-month fill-up statistics for the consumption-statistics detail
/// page (#2698), oldest first. Each month carries the FULL
/// `ConsumptionStats` for that month's fill-ups via the canonical
/// `ConsumptionStats.fromFillUps` window walker — so the page can show
/// month-over-month comparison + evolution charts with no new storage.
///
/// Lives in its own file (not the [fillUpListProvider] god-class) so the
/// 975-line consumption_providers.dart stays at its file_length snapshot.

final class MonthlyFuelStatsProvider
    extends
        $FunctionalProvider<
          List<MonthlyFuelStats>,
          List<MonthlyFuelStats>,
          List<MonthlyFuelStats>
        >
    with $Provider<List<MonthlyFuelStats>> {
  /// Per-month fill-up statistics for the consumption-statistics detail
  /// page (#2698), oldest first. Each month carries the FULL
  /// `ConsumptionStats` for that month's fill-ups via the canonical
  /// `ConsumptionStats.fromFillUps` window walker — so the page can show
  /// month-over-month comparison + evolution charts with no new storage.
  ///
  /// Lives in its own file (not the [fillUpListProvider] god-class) so the
  /// 975-line consumption_providers.dart stays at its file_length snapshot.
  MonthlyFuelStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthlyFuelStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthlyFuelStatsHash();

  @$internal
  @override
  $ProviderElement<List<MonthlyFuelStats>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<MonthlyFuelStats> create(Ref ref) {
    return monthlyFuelStats(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MonthlyFuelStats> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<MonthlyFuelStats>>(value),
    );
  }
}

String _$monthlyFuelStatsHash() => r'2e644548f538e1e557deb474d7aee947634b1bb1';

/// Distinct fuel types present in the fill-up list, first-seen order —
/// drives the per-fuel filter chips on the statistics page (#3691).

@ProviderFor(loggedFuelTypes)
final loggedFuelTypesProvider = LoggedFuelTypesProvider._();

/// Distinct fuel types present in the fill-up list, first-seen order —
/// drives the per-fuel filter chips on the statistics page (#3691).

final class LoggedFuelTypesProvider
    extends $FunctionalProvider<List<FuelType>, List<FuelType>, List<FuelType>>
    with $Provider<List<FuelType>> {
  /// Distinct fuel types present in the fill-up list, first-seen order —
  /// drives the per-fuel filter chips on the statistics page (#3691).
  LoggedFuelTypesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loggedFuelTypesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loggedFuelTypesHash();

  @$internal
  @override
  $ProviderElement<List<FuelType>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<FuelType> create(Ref ref) {
    return loggedFuelTypes(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FuelType> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FuelType>>(value),
    );
  }
}

String _$loggedFuelTypesHash() => r'b48d477184482dcd25d84020c9272b5c5f688152';

/// [monthlyFuelStats] restricted to ONE fuel type (#3691) — null keeps
/// the all-fuels view. Same aggregator, filtered input, so every
/// per-month metric answers "how does THIS fuel perform on the car".

@ProviderFor(monthlyFuelStatsForFuel)
final monthlyFuelStatsForFuelProvider = MonthlyFuelStatsForFuelFamily._();

/// [monthlyFuelStats] restricted to ONE fuel type (#3691) — null keeps
/// the all-fuels view. Same aggregator, filtered input, so every
/// per-month metric answers "how does THIS fuel perform on the car".

final class MonthlyFuelStatsForFuelProvider
    extends
        $FunctionalProvider<
          List<MonthlyFuelStats>,
          List<MonthlyFuelStats>,
          List<MonthlyFuelStats>
        >
    with $Provider<List<MonthlyFuelStats>> {
  /// [monthlyFuelStats] restricted to ONE fuel type (#3691) — null keeps
  /// the all-fuels view. Same aggregator, filtered input, so every
  /// per-month metric answers "how does THIS fuel perform on the car".
  MonthlyFuelStatsForFuelProvider._({
    required MonthlyFuelStatsForFuelFamily super.from,
    required FuelType? super.argument,
  }) : super(
         retry: null,
         name: r'monthlyFuelStatsForFuelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$monthlyFuelStatsForFuelHash();

  @override
  String toString() {
    return r'monthlyFuelStatsForFuelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<MonthlyFuelStats>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<MonthlyFuelStats> create(Ref ref) {
    final argument = this.argument as FuelType?;
    return monthlyFuelStatsForFuel(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MonthlyFuelStats> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<MonthlyFuelStats>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyFuelStatsForFuelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthlyFuelStatsForFuelHash() =>
    r'feac90a1a661ada706063eb6ad3b5f4836406d93';

/// [monthlyFuelStats] restricted to ONE fuel type (#3691) — null keeps
/// the all-fuels view. Same aggregator, filtered input, so every
/// per-month metric answers "how does THIS fuel perform on the car".

final class MonthlyFuelStatsForFuelFamily extends $Family
    with $FunctionalFamilyOverride<List<MonthlyFuelStats>, FuelType?> {
  MonthlyFuelStatsForFuelFamily._()
    : super(
        retry: null,
        name: r'monthlyFuelStatsForFuelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [monthlyFuelStats] restricted to ONE fuel type (#3691) — null keeps
  /// the all-fuels view. Same aggregator, filtered input, so every
  /// per-month metric answers "how does THIS fuel perform on the car".

  MonthlyFuelStatsForFuelProvider call(FuelType? fuel) =>
      MonthlyFuelStatsForFuelProvider._(argument: fuel, from: this);

  @override
  String toString() => r'monthlyFuelStatsForFuelProvider';
}

/// [consumptionStats] restricted to ONE fuel type (#3691) — null keeps
/// the all-fuels aggregate. Feeds the header tiles and the
/// month-over-month card under a fuel filter.

@ProviderFor(consumptionStatsForFuel)
final consumptionStatsForFuelProvider = ConsumptionStatsForFuelFamily._();

/// [consumptionStats] restricted to ONE fuel type (#3691) — null keeps
/// the all-fuels aggregate. Feeds the header tiles and the
/// month-over-month card under a fuel filter.

final class ConsumptionStatsForFuelProvider
    extends
        $FunctionalProvider<
          ConsumptionStats,
          ConsumptionStats,
          ConsumptionStats
        >
    with $Provider<ConsumptionStats> {
  /// [consumptionStats] restricted to ONE fuel type (#3691) — null keeps
  /// the all-fuels aggregate. Feeds the header tiles and the
  /// month-over-month card under a fuel filter.
  ConsumptionStatsForFuelProvider._({
    required ConsumptionStatsForFuelFamily super.from,
    required FuelType? super.argument,
  }) : super(
         retry: null,
         name: r'consumptionStatsForFuelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$consumptionStatsForFuelHash();

  @override
  String toString() {
    return r'consumptionStatsForFuelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ConsumptionStats> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConsumptionStats create(Ref ref) {
    final argument = this.argument as FuelType?;
    return consumptionStatsForFuel(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConsumptionStats value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConsumptionStats>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConsumptionStatsForFuelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$consumptionStatsForFuelHash() =>
    r'558d1a515c84db101e8c0e415cc3a9d57f542b22';

/// [consumptionStats] restricted to ONE fuel type (#3691) — null keeps
/// the all-fuels aggregate. Feeds the header tiles and the
/// month-over-month card under a fuel filter.

final class ConsumptionStatsForFuelFamily extends $Family
    with $FunctionalFamilyOverride<ConsumptionStats, FuelType?> {
  ConsumptionStatsForFuelFamily._()
    : super(
        retry: null,
        name: r'consumptionStatsForFuelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [consumptionStats] restricted to ONE fuel type (#3691) — null keeps
  /// the all-fuels aggregate. Feeds the header tiles and the
  /// month-over-month card under a fuel filter.

  ConsumptionStatsForFuelProvider call(FuelType? fuel) =>
      ConsumptionStatsForFuelProvider._(argument: fuel, from: this);

  @override
  String toString() => r'consumptionStatsForFuelProvider';
}
