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
  }) = _RadiusAlert;

  factory RadiusAlert.fromJson(Map<String, dynamic> json) =>
      _$RadiusAlertFromJson(json);
}
