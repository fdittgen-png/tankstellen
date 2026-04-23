// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charging_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Derived statistics over the user's charging-log history (#582 phase 2).
///
/// Phase 1 shipped the data layer ([ChargingLog] + store + notifier).
/// Phase 2 needs three rollup numbers per active vehicle — total kWh,
/// total spend, and the cost-weighted EUR/100 km average — surfaced on
/// the consumption screen's charging tab. Each derivation is a
/// standalone provider so the UI can rebuild just the affected card
/// when a single log is added/edited/removed.
///
/// All three providers return `null` (or `0.0`) when the dataset is
/// insufficient rather than throwing — the consumption tab renders "—"
/// for those cells. The wheel-lens savings story ("EUR/100 km") is a
/// nudge; it should never hide the fuel tab behind a red error.
/// Rolling EUR/100 km for the active vehicle's charging history.
///
/// Returns `null` when:
/// - there is no active vehicle,
/// - the active vehicle has fewer than two logged sessions (we need a
///   from/to odometer pair), or
/// - every derived segment would be zero-distance (back-to-back
///   sessions with no driving between them — rare but possible when a
///   user logs AC + DC legs of the same stop separately).
///
/// The weighted mean delegates to [ChargingCostCalculator.avgEurPer100km]
/// so the math lives in a single pure-Dart place the background
/// aggregator (phase 3) can reuse.

@ProviderFor(chargingEurPer100Km)
final chargingEurPer100KmProvider = ChargingEurPer100KmProvider._();

/// Derived statistics over the user's charging-log history (#582 phase 2).
///
/// Phase 1 shipped the data layer ([ChargingLog] + store + notifier).
/// Phase 2 needs three rollup numbers per active vehicle — total kWh,
/// total spend, and the cost-weighted EUR/100 km average — surfaced on
/// the consumption screen's charging tab. Each derivation is a
/// standalone provider so the UI can rebuild just the affected card
/// when a single log is added/edited/removed.
///
/// All three providers return `null` (or `0.0`) when the dataset is
/// insufficient rather than throwing — the consumption tab renders "—"
/// for those cells. The wheel-lens savings story ("EUR/100 km") is a
/// nudge; it should never hide the fuel tab behind a red error.
/// Rolling EUR/100 km for the active vehicle's charging history.
///
/// Returns `null` when:
/// - there is no active vehicle,
/// - the active vehicle has fewer than two logged sessions (we need a
///   from/to odometer pair), or
/// - every derived segment would be zero-distance (back-to-back
///   sessions with no driving between them — rare but possible when a
///   user logs AC + DC legs of the same stop separately).
///
/// The weighted mean delegates to [ChargingCostCalculator.avgEurPer100km]
/// so the math lives in a single pure-Dart place the background
/// aggregator (phase 3) can reuse.

final class ChargingEurPer100KmProvider
    extends $FunctionalProvider<AsyncValue<double?>, double?, FutureOr<double?>>
    with $FutureModifier<double?>, $FutureProvider<double?> {
  /// Derived statistics over the user's charging-log history (#582 phase 2).
  ///
  /// Phase 1 shipped the data layer ([ChargingLog] + store + notifier).
  /// Phase 2 needs three rollup numbers per active vehicle — total kWh,
  /// total spend, and the cost-weighted EUR/100 km average — surfaced on
  /// the consumption screen's charging tab. Each derivation is a
  /// standalone provider so the UI can rebuild just the affected card
  /// when a single log is added/edited/removed.
  ///
  /// All three providers return `null` (or `0.0`) when the dataset is
  /// insufficient rather than throwing — the consumption tab renders "—"
  /// for those cells. The wheel-lens savings story ("EUR/100 km") is a
  /// nudge; it should never hide the fuel tab behind a red error.
  /// Rolling EUR/100 km for the active vehicle's charging history.
  ///
  /// Returns `null` when:
  /// - there is no active vehicle,
  /// - the active vehicle has fewer than two logged sessions (we need a
  ///   from/to odometer pair), or
  /// - every derived segment would be zero-distance (back-to-back
  ///   sessions with no driving between them — rare but possible when a
  ///   user logs AC + DC legs of the same stop separately).
  ///
  /// The weighted mean delegates to [ChargingCostCalculator.avgEurPer100km]
  /// so the math lives in a single pure-Dart place the background
  /// aggregator (phase 3) can reuse.
  ChargingEurPer100KmProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chargingEurPer100KmProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chargingEurPer100KmHash();

  @$internal
  @override
  $FutureProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double?> create(Ref ref) {
    return chargingEurPer100Km(ref);
  }
}

String _$chargingEurPer100KmHash() =>
    r'd9dc877468d1a5e99aa7557410f3d25c3d8256dc';

/// Total kWh delivered across the active vehicle's logged sessions.
///
/// Returns `0.0` when no logs exist — the UI renders "0.0 kWh" in that
/// case, matching the fuel side's "Total L" tile when the list is empty.

@ProviderFor(chargingTotalKwh)
final chargingTotalKwhProvider = ChargingTotalKwhProvider._();

/// Total kWh delivered across the active vehicle's logged sessions.
///
/// Returns `0.0` when no logs exist — the UI renders "0.0 kWh" in that
/// case, matching the fuel side's "Total L" tile when the list is empty.

final class ChargingTotalKwhProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  /// Total kWh delivered across the active vehicle's logged sessions.
  ///
  /// Returns `0.0` when no logs exist — the UI renders "0.0 kWh" in that
  /// case, matching the fuel side's "Total L" tile when the list is empty.
  ChargingTotalKwhProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chargingTotalKwhProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chargingTotalKwhHash();

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    return chargingTotalKwh(ref);
  }
}

String _$chargingTotalKwhHash() => r'551d2d3977dd300fbd9da455b91f5771eac06509';

/// Total EUR spent across the active vehicle's logged sessions.

@ProviderFor(chargingTotalCostEur)
final chargingTotalCostEurProvider = ChargingTotalCostEurProvider._();

/// Total EUR spent across the active vehicle's logged sessions.

final class ChargingTotalCostEurProvider
    extends $FunctionalProvider<AsyncValue<double>, double, FutureOr<double>>
    with $FutureModifier<double>, $FutureProvider<double> {
  /// Total EUR spent across the active vehicle's logged sessions.
  ChargingTotalCostEurProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chargingTotalCostEurProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chargingTotalCostEurHash();

  @$internal
  @override
  $FutureProviderElement<double> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double> create(Ref ref) {
    return chargingTotalCostEur(ref);
  }
}

String _$chargingTotalCostEurHash() =>
    r'69df7dab3969065e9c5ca721977bcd58c383d845';
