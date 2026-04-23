import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../search/domain/entities/fuel_type.dart';

part 'price_snapshot.freezed.dart';
part 'price_snapshot.g.dart';

/// One observation of a fuel price at a single station (#579).
///
/// The background worker writes one snapshot per (station, fuel)
/// every time it fetches fresh prices. The velocity detector then
/// diffs the most-recent snapshot older than `lookback` against the
/// current price to decide whether enough nearby stations have
/// dropped to warrant a notification.
///
/// `fuelType` is stored as a string (FuelType.apiValue) so stored
/// snapshots survive sealed-class changes without a migration. Coords
/// are captured per-snapshot so the detector can filter by radius
/// without re-joining against station data.
@freezed
abstract class PriceSnapshot with _$PriceSnapshot {
  const factory PriceSnapshot({
    required String stationId,
    required String fuelType,
    required double price,
    required DateTime timestamp,
    required double lat,
    required double lng,
  }) = _PriceSnapshot;

  factory PriceSnapshot.fromJson(Map<String, dynamic> json) =>
      _$PriceSnapshotFromJson(json);

  /// Convenience for callers that already hold a [FuelType] instance.
  static PriceSnapshot forFuel({
    required String stationId,
    required FuelType fuelType,
    required double price,
    required DateTime timestamp,
    required double lat,
    required double lng,
  }) {
    return PriceSnapshot(
      stationId: stationId,
      fuelType: fuelType.apiValue,
      price: price,
      timestamp: timestamp,
      lat: lat,
      lng: lng,
    );
  }
}
