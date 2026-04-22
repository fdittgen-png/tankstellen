import '../../../core/utils/geo_utils.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../../search/domain/entities/station.dart';
import '../../../core/utils/station_extensions.dart';
import 'entities/radius_alert.dart';

/// A minimal value-type describing one station's current price for
/// one fuel, used by [RadiusAlertEvaluator] (#578 phase 1).
///
/// Kept deliberately small and serialization-free so the evaluator can
/// run inside a WorkManager isolate in phase 2 without pulling the
/// full [Station] graph through the channel. Build one per (station,
/// fuelType) combination you care about.
class StationPriceSample {
  final String stationId;
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

  const StationPriceSample({
    required this.stationId,
    required this.lat,
    required this.lng,
    required this.fuelType,
    required this.pricePerLiter,
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
        lat: station.lat,
        lng: station.lng,
        fuelType: fuel.apiValue,
        pricePerLiter: price,
      ));
    }
    return out;
  }
}

/// Pure-Dart threshold evaluator for [RadiusAlert] (#578 phase 1).
///
/// Zero Riverpod / Hive imports so this can be reused inside the
/// phase-2 background worker without hauling the whole app
/// dependency graph into a WorkManager isolate.
class RadiusAlertEvaluator {
  const RadiusAlertEvaluator();

  /// True iff at least one [StationPriceSample] satisfies all three
  /// of: (a) same fuel as [alert], (b) price at or below
  /// [RadiusAlert.threshold], and (c) located within
  /// [RadiusAlert.radiusKm] of the alert's centre.
  ///
  /// Disabled alerts ([RadiusAlert.enabled] false) never trigger —
  /// the caller can filter on `enabled` themselves, but short-
  /// circuiting here keeps the common "toggled off" path cheap.
  bool triggered(RadiusAlert alert, List<StationPriceSample> samples) {
    if (!alert.enabled) return false;
    for (final s in samples) {
      if (_matches(alert, s)) return true;
    }
    return false;
  }

  /// Iterable of every sample that would trigger [alert]. Used by
  /// the phase-2 notification payload so the user sees a list like
  /// "Shell, Aldi, Total" instead of a bare "someone is cheap
  /// somewhere".
  ///
  /// Returns an empty iterable when [alert] is disabled.
  Iterable<StationPriceSample> matches(
    RadiusAlert alert,
    List<StationPriceSample> samples,
  ) sync* {
    if (!alert.enabled) return;
    for (final s in samples) {
      if (_matches(alert, s)) yield s;
    }
  }

  bool _matches(RadiusAlert alert, StationPriceSample s) {
    if (s.fuelType != alert.fuelType) return false;
    if (s.pricePerLiter > alert.threshold) return false;
    final d = distanceKm(
      alert.centerLat,
      alert.centerLng,
      s.lat,
      s.lng,
    );
    return d <= alert.radiusKm;
  }
}
