// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charging_charts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Monthly total charging cost in EUR for the active vehicle, over
/// the last six months (#582 phase 3).
///
/// Keys are UTC month starts (day = 1, h/m/s = 0), in ascending order.
/// Missing months are included with a `0.0` value so the downstream
/// bar chart can render a continuous X axis without special-casing
/// empty months.
///
/// Watches [chargingLogsProvider] + [activeVehicleProfileProvider] so
/// it automatically refreshes when a new log lands or the user
/// switches vehicles. When no active vehicle is set or the logs
/// future is still loading/erroring, the provider returns an empty
/// map — the chart's empty state takes over.

@ProviderFor(chargingMonthlyCost)
final chargingMonthlyCostProvider = ChargingMonthlyCostProvider._();

/// Monthly total charging cost in EUR for the active vehicle, over
/// the last six months (#582 phase 3).
///
/// Keys are UTC month starts (day = 1, h/m/s = 0), in ascending order.
/// Missing months are included with a `0.0` value so the downstream
/// bar chart can render a continuous X axis without special-casing
/// empty months.
///
/// Watches [chargingLogsProvider] + [activeVehicleProfileProvider] so
/// it automatically refreshes when a new log lands or the user
/// switches vehicles. When no active vehicle is set or the logs
/// future is still loading/erroring, the provider returns an empty
/// map — the chart's empty state takes over.

final class ChargingMonthlyCostProvider
    extends
        $FunctionalProvider<
          Map<DateTime, double>,
          Map<DateTime, double>,
          Map<DateTime, double>
        >
    with $Provider<Map<DateTime, double>> {
  /// Monthly total charging cost in EUR for the active vehicle, over
  /// the last six months (#582 phase 3).
  ///
  /// Keys are UTC month starts (day = 1, h/m/s = 0), in ascending order.
  /// Missing months are included with a `0.0` value so the downstream
  /// bar chart can render a continuous X axis without special-casing
  /// empty months.
  ///
  /// Watches [chargingLogsProvider] + [activeVehicleProfileProvider] so
  /// it automatically refreshes when a new log lands or the user
  /// switches vehicles. When no active vehicle is set or the logs
  /// future is still loading/erroring, the provider returns an empty
  /// map — the chart's empty state takes over.
  ChargingMonthlyCostProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chargingMonthlyCostProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chargingMonthlyCostHash();

  @$internal
  @override
  $ProviderElement<Map<DateTime, double>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<DateTime, double> create(Ref ref) {
    return chargingMonthlyCost(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<DateTime, double> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<DateTime, double>>(value),
    );
  }
}

String _$chargingMonthlyCostHash() =>
    r'c167ff2f981a40b8a6894e057b8eadfdc21c4843';

/// Monthly charging efficiency in kWh per 100 km for the active
/// vehicle, over the last six months (#582 phase 3).
///
/// Keys are UTC month starts (day = 1, h/m/s = 0), in ascending order.
/// Months with insufficient data to compute a ratio (< 2 logs in the
/// month, or zero distance driven between the segment anchors) map to
/// `null` so the line chart can skip the point instead of drawing a
/// misleading zero.
///
/// The ratio is a cost-weighted mean across the month:
///
///     sum(log.kWh for logs in month) / sum(kmDriven for logs in month) * 100
///
/// where `kmDriven` is the odometer delta from the prior log (either
/// within the same month or from the closest earlier log for the same
/// vehicle). This mirrors [ChargingCostCalculator.avgEurPer100km]'s
/// weighted-mean approach so short outings never dominate the axis.

@ProviderFor(chargingMonthlyEfficiency)
final chargingMonthlyEfficiencyProvider = ChargingMonthlyEfficiencyProvider._();

/// Monthly charging efficiency in kWh per 100 km for the active
/// vehicle, over the last six months (#582 phase 3).
///
/// Keys are UTC month starts (day = 1, h/m/s = 0), in ascending order.
/// Months with insufficient data to compute a ratio (< 2 logs in the
/// month, or zero distance driven between the segment anchors) map to
/// `null` so the line chart can skip the point instead of drawing a
/// misleading zero.
///
/// The ratio is a cost-weighted mean across the month:
///
///     sum(log.kWh for logs in month) / sum(kmDriven for logs in month) * 100
///
/// where `kmDriven` is the odometer delta from the prior log (either
/// within the same month or from the closest earlier log for the same
/// vehicle). This mirrors [ChargingCostCalculator.avgEurPer100km]'s
/// weighted-mean approach so short outings never dominate the axis.

final class ChargingMonthlyEfficiencyProvider
    extends
        $FunctionalProvider<
          Map<DateTime, double?>,
          Map<DateTime, double?>,
          Map<DateTime, double?>
        >
    with $Provider<Map<DateTime, double?>> {
  /// Monthly charging efficiency in kWh per 100 km for the active
  /// vehicle, over the last six months (#582 phase 3).
  ///
  /// Keys are UTC month starts (day = 1, h/m/s = 0), in ascending order.
  /// Months with insufficient data to compute a ratio (< 2 logs in the
  /// month, or zero distance driven between the segment anchors) map to
  /// `null` so the line chart can skip the point instead of drawing a
  /// misleading zero.
  ///
  /// The ratio is a cost-weighted mean across the month:
  ///
  ///     sum(log.kWh for logs in month) / sum(kmDriven for logs in month) * 100
  ///
  /// where `kmDriven` is the odometer delta from the prior log (either
  /// within the same month or from the closest earlier log for the same
  /// vehicle). This mirrors [ChargingCostCalculator.avgEurPer100km]'s
  /// weighted-mean approach so short outings never dominate the axis.
  ChargingMonthlyEfficiencyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chargingMonthlyEfficiencyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chargingMonthlyEfficiencyHash();

  @$internal
  @override
  $ProviderElement<Map<DateTime, double?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<DateTime, double?> create(Ref ref) {
    return chargingMonthlyEfficiency(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<DateTime, double?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<DateTime, double?>>(value),
    );
  }
}

String _$chargingMonthlyEfficiencyHash() =>
    r'712742bd2050168fe5072c7e4ff096a694690538';
