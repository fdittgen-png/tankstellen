import 'package:freezed_annotation/freezed_annotation.dart';

part 'radius_alert.freezed.dart';
part 'radius_alert.g.dart';

/// Watch-a-whole-area price alert (#578 phase 1).
///
/// Unlike [PriceAlert], which pins a single station by id, a
/// [RadiusAlert] triggers whenever ANY station within [radiusKm] of
/// ([centerLat], [centerLng]) offers [fuelType] at or below
/// [threshold]. This lets the user say "tell me if diesel drops
/// below 1.50€/L anywhere within 10 km of home" without pre-picking
/// stations.
///
/// [fuelType] is intentionally stored as a string (the `apiValue` of
/// the corresponding `FuelType` — e.g. `'diesel'`, `'e10'`) so this
/// domain entity has zero cross-package coupling with the search
/// feature's sealed class hierarchy. Callers that already hold a
/// `FuelType` instance should pass `fuelType.apiValue`.
///
/// [frequencyPerDay] caps how often the runner re-evaluates this
/// alert. Allowed values are 1/2/3/4 mapping to a minimum gap of
/// 24 h / 12 h / 8 h / 6 h between evaluations. The runner reads the
/// last-evaluated timestamp from a side-table in
/// [RadiusAlertStore] and short-circuits the per-alert loop until
/// the gap has elapsed (#1012 phase 1). Pre-#1012 stored alerts have
/// no field on disk; freezed's `@Default(1)` snaps them to the
/// previous "every cycle" cadence on read.
@freezed
abstract class RadiusAlert with _$RadiusAlert {
  const factory RadiusAlert({
    required String id,
    required String fuelType,
    required double threshold,
    required double centerLat,
    required double centerLng,
    required double radiusKm,
    required String label,
    required DateTime createdAt,
    @Default(true) bool enabled,
    @Default(1) int frequencyPerDay,
  }) = _RadiusAlert;

  factory RadiusAlert.fromJson(Map<String, dynamic> json) =>
      _$RadiusAlertFromJson(json);
}

/// Map a per-day frequency (1/2/3/4) to the minimum gap between
/// runner evaluations. Anything outside the supported set defaults
/// to once-a-day so a corrupt entity can never produce a runaway
/// notification cadence.
Duration frequencyToGap(int frequencyPerDay) {
  switch (frequencyPerDay) {
    case 4:
      return const Duration(hours: 6);
    case 3:
      return const Duration(hours: 8);
    case 2:
      return const Duration(hours: 12);
    case 1:
    default:
      return const Duration(hours: 24);
  }
}
