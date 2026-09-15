// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The one shape an alert detector reads a price in (#4149).
///
/// There were two. `StationPriceSample` (radius alerts) and
/// `VelocityStationObservation` (the drop detector) were both minimal
/// `{stationId, price, lat, lng}` value types, both written explicitly
/// so a detector could run inside a WorkManager isolate without hauling
/// the full [Station] graph through the channel, and both invented
/// independently for the same reason. Epic #4148 exists to stop a fourth
/// reason to notify meaning a fourth of everything; a third copy of the
/// INPUT would have been the same mistake one layer down.
///
/// The collapse is not purely cosmetic: the velocity detector had no
/// `fuelType` on its observations and had to trust that every one it was
/// handed belonged to the configured fuel. Now it can check.
library;

import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/station.dart';
import '../../../core/utils/station_extensions.dart';

/// A minimal value-type describing one station's current price for
/// one fuel, used by [RadiusAlertEvaluator] (#578 phase 1).
///
/// Kept deliberately small and serialization-free so the evaluator can
/// run inside a WorkManager isolate in phase 2 without pulling the
/// full [Station] graph through the channel. Build one per (station,
/// fuelType) combination you care about.
class StationPriceSample {
  final String stationId;

  /// User-facing station name (brand → name → street fallback). #2211 —
  /// carried so the grouped radius-alert notification shows real names
  /// instead of raw station ids.
  final String name;
  final double lat;
  final double lng;

  /// The `apiValue` of the fuel — matches
  /// [RadiusAlert.fuelType]'s string storage convention.
  final String fuelType;

  /// Current observed price in whatever unit matches [fuelType]
  /// (EUR/L for petrol/diesel, EUR/kg for CNG/H2, EUR/kWh for EV).
  /// Callers must make sure the unit lines up with the alert
  /// threshold — the evaluator doesn't convert units.
  final double pricePerLiter;

  /// When the provider says this price was set (#4186), or null where it
  /// publishes no stamp. Carried so a radius opportunity can be dated
  /// instead of reporting an absence the provider did not have.
  final DateTime? priceUpdatedAt;

  const StationPriceSample({
    required this.stationId,
    required this.name,
    required this.lat,
    required this.lng,
    required this.fuelType,
    required this.pricePerLiter,
    this.priceUpdatedAt,
  });

  /// Build one sample per fuel that [station] has a price for.
  ///
  /// Stations typically report several fuels at once, so a single
  /// sweep of the current search result produces a list like
  /// `[diesel@1.67, e10@1.78, e5@1.83, …]` — exactly what the
  /// evaluator needs to cross-check against every user-configured
  /// radius alert in one pass.
  static List<StationPriceSample> fromStation(Station station) {
    final out = <StationPriceSample>[];
    for (final fuel in FuelType.values) {
      // Skip the "all" wildcard — it isn't a real fuel and its price
      // comes from priceFor() falling back to another column, which
      // would double-count samples.
      if (fuel == FuelType.all) continue;
      final price = station.priceFor(fuel);
      if (price == null) continue;
      out.add(StationPriceSample(
        stationId: station.id,
        name: station.displayName,
        lat: station.lat,
        lng: station.lng,
        fuelType: fuel.apiValue,
        pricePerLiter: price,
        priceUpdatedAt: station.priceUpdatedAt,
      ));
    }
    return out;
  }
}
