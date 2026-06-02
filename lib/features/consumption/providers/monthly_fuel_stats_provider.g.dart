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
