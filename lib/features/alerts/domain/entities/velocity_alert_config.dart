import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../search/domain/entities/fuel_type.dart';

part 'velocity_alert_config.freezed.dart';
part 'velocity_alert_config.g.dart';

/// Configuration for the price-drop velocity detector (#579).
///
/// Stored as a single JSON blob under the settings box; defaults are
/// applied when no config has been persisted yet. The detector is a
/// pure function that consumes this config plus the current nearby
/// stations and recent snapshots, and emits a [VelocityAlertEvent]
/// when enough nearby stations drop fast enough.
///
/// Defaults mirror the issue's "3 ct / 2 stations / 15 km / 1 h"
/// spec with a 6 h cooldown between fires of the same fuel type.
@freezed
abstract class VelocityAlertConfig with _$VelocityAlertConfig {
  const factory VelocityAlertConfig({
    @FuelTypeJsonConverter() required FuelType fuelType,
    @Default(3) double minDropCents,
    @Default(2) int minStations,
    @Default(15) double radiusKm,
    @Default(6) int cooldownHours,
  }) = _VelocityAlertConfig;

  factory VelocityAlertConfig.fromJson(Map<String, dynamic> json) =>
      _$VelocityAlertConfigFromJson(json);

  /// Default config — E10 with the spec thresholds. Used when the
  /// settings box has no persisted config yet.
  factory VelocityAlertConfig.defaults() =>
      const VelocityAlertConfig(fuelType: FuelType.e10);
}
