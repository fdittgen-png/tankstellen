import '../../price_history/data/models/price_record.dart';
import '../../search/domain/entities/fuel_type.dart';

/// Event a [PriceVelocityDetector] emits when multiple stations have
/// dropped prices by meaningful amounts within a short window (#579).
///
/// The alert carries enough context for the UI to render a single
/// useful sentence ("E10 dropped 5 ct in the last hour at 3 stations
/// near you") without the caller needing to re-scan the price history.
class VelocityAlert {
  final FuelType fuelType;
  final List<String> affectedStationIds;

  /// Largest single-station drop in the window, in cents. Callers use
  /// this to emphasise the best opportunity in notification copy.
  final double maxDropCt;

  /// Average drop across the affected stations, in cents. Useful for
  /// "prices down ~4 ct" copy when multiple stations dropped similar
  /// amounts.
  final double avgDropCt;

  const VelocityAlert({
    required this.fuelType,
    required this.affectedStationIds,
    required this.maxDropCt,
    required this.avgDropCt,
  });
}

/// Detects "price is falling fast" across multiple nearby stations.
///
/// Pure function — no storage, no network, no side effects. The
/// background task feeds it a price-history snapshot and decides
/// whether to fire a notification. The caller is responsible for
/// applying the cooldown (the detector itself has no memory).
class PriceVelocityDetector {
  PriceVelocityDetector._();

  /// Run the detector. Returns `null` when nothing interesting has
  /// happened, or a [VelocityAlert] when enough stations have dropped
  /// by at least [minDropCt] within the last [lookback] window.
  ///
  /// Defaults match the issue's "3 ct / 2 stations / 1 h" spec.
  static VelocityAlert? detect({
    required FuelType fuelType,
    required List<PriceRecord> history,
    required DateTime now,
    double minDropCt = 3,
    int minStations = 2,
    Duration lookback = const Duration(hours: 1),
  }) {
    if (history.isEmpty) return null;
    final cutoff = now.subtract(lookback);

    // Per-station scan: find the oldest sample ≥cutoff and the latest
    // sample, diff them. Skip stations where either endpoint is
    // missing OR the fuel column is null.
    final byStation = <String, List<PriceRecord>>{};
    for (final r in history) {
      byStation.putIfAbsent(r.stationId, () => []).add(r);
    }

    final drops = <String, double>{};
    for (final entry in byStation.entries) {
      final sorted = [...entry.value]
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      // Latest snapshot in the window.
      PriceRecord? latest;
      for (final r in sorted.reversed) {
        if (r.recordedAt.isAfter(cutoff) ||
            r.recordedAt.isAtSameMomentAs(cutoff)) {
          latest = r;
          break;
        }
      }
      if (latest == null) continue;
      // Earliest snapshot within the window that predates [latest].
      PriceRecord? baseline;
      for (final r in sorted) {
        if (r.recordedAt.isAfter(cutoff) ||
            r.recordedAt.isAtSameMomentAs(cutoff)) {
          if (r.recordedAt.isBefore(latest.recordedAt)) {
            baseline = r;
            break;
          }
        }
      }
      if (baseline == null) continue;
      final current = _priceFor(latest, fuelType);
      final prior = _priceFor(baseline, fuelType);
      if (current == null || prior == null) continue;
      final dropEur = prior - current;
      final dropCt = dropEur * 100;
      if (dropCt >= minDropCt) {
        drops[entry.key] = dropCt;
      }
    }

    if (drops.length < minStations) return null;

    final sortedCt = drops.values.toList()..sort();
    final max = sortedCt.last;
    final avg = drops.values.reduce((a, b) => a + b) / drops.length;
    return VelocityAlert(
      fuelType: fuelType,
      affectedStationIds: drops.keys.toList(),
      maxDropCt: max,
      avgDropCt: avg,
    );
  }

  /// Extract the price of [fuelType] from a [PriceRecord], or null
  /// when the record didn't carry that fuel.
  static double? _priceFor(PriceRecord r, FuelType fuelType) {
    return switch (fuelType) {
      FuelTypeE5() => r.e5,
      FuelTypeE10() => r.e10,
      FuelTypeE98() => r.e98,
      FuelTypeDiesel() => r.diesel,
      FuelTypeDieselPremium() => r.dieselPremium,
      FuelTypeE85() => r.e85,
      FuelTypeLpg() => r.lpg,
      FuelTypeCng() => r.cng,
      _ => null,
    };
  }
}
