import '../../../core/utils/geo_utils.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../data/models/price_snapshot.dart';
import 'entities/velocity_alert_config.dart';

/// Snapshot of a station's *current* price for a given fuel.
///
/// The detector accepts a minimal shape rather than the full
/// [Station] model so it can be driven from the background isolate,
/// tests, or a future different source without coupling to the
/// search feature.
class VelocityStationObservation {
  final String stationId;
  final double price;
  final double lat;
  final double lng;

  const VelocityStationObservation({
    required this.stationId,
    required this.price,
    required this.lat,
    required this.lng,
  });
}

/// Emitted when enough nearby stations have dropped fast enough on
/// the watched fuel type (#579).
class VelocityAlertEvent {
  final FuelType fuelType;
  final List<String> affectedStationIds;

  /// Largest observed drop across the qualifying stations, in cents.
  final double maxDropCents;

  const VelocityAlertEvent({
    required this.fuelType,
    required this.affectedStationIds,
    required this.maxDropCents,
  });

  /// Convenience: number of stations that contributed to the event.
  int get stationCount => affectedStationIds.length;
}

/// Detects "price is falling fast" across multiple nearby stations
/// by diffing current observations against the most-recent
/// [PriceSnapshot] older than [VelocityAlertConfig] lookback.
///
/// Pure function — no storage, no notifications. The background
/// hook is responsible for calling this, checking the cooldown, and
/// firing the local notification.
class VelocityAlertDetector {
  VelocityAlertDetector._();

  /// Run the detector once against the provided observations.
  ///
  /// [observations] — current per-station price readings for the
  /// fuel in [config.fuelType].
  /// [previousSnapshots] — snapshots older than [lookback]; the
  /// detector picks the *most recent* one per (station, fuel) to
  /// compare against.
  /// [userLat]/[userLng] — radius filter origin. Pass `null` to
  /// disable the radius check (e.g. when the user's location is
  /// unknown at run time).
  /// [now] — injected clock for deterministic tests.
  ///
  /// Returns `null` when nothing interesting happened, otherwise a
  /// [VelocityAlertEvent] summarising the drops.
  static VelocityAlertEvent? detect({
    required VelocityAlertConfig config,
    required List<VelocityStationObservation> observations,
    required List<PriceSnapshot> previousSnapshots,
    required DateTime now,
    double? userLat,
    double? userLng,
    Duration lookback = const Duration(hours: 1),
  }) {
    if (observations.isEmpty) return null;

    final fuelApiValue = config.fuelType.apiValue;
    final cutoff = now.subtract(lookback);

    // Index previous snapshots by station for O(1) lookup and pick
    // the *most-recent-before-cutoff* per station for the fuel we
    // care about. A station can legitimately have several snapshots
    // in the box (multiple BG cycles) so we need the freshest one
    // that still predates the lookback window.
    final mostRecentBefore = <String, PriceSnapshot>{};
    for (final s in previousSnapshots) {
      if (s.fuelType != fuelApiValue) continue;
      if (!s.timestamp.isBefore(cutoff)) continue;
      final existing = mostRecentBefore[s.stationId];
      if (existing == null || s.timestamp.isAfter(existing.timestamp)) {
        mostRecentBefore[s.stationId] = s;
      }
    }

    final drops = <_Drop>[];
    for (final obs in observations) {
      // Radius filter — skip stations outside the configured
      // radius when we know where the user is. When we don't,
      // accept every station (better to fire than be silent).
      if (userLat != null && userLng != null) {
        final d = distanceKm(userLat, userLng, obs.lat, obs.lng);
        if (d > config.radiusKm) continue;
      }
      final prior = mostRecentBefore[obs.stationId];
      if (prior == null) continue; // first time seen → can't compute drop
      final dropCents = (prior.price - obs.price) * 100;
      if (dropCents < config.minDropCents) continue;
      drops.add(_Drop(obs.stationId, dropCents));
    }

    if (drops.length < config.minStations) return null;

    drops.sort((a, b) => b.cents.compareTo(a.cents));
    final max = drops.first.cents;
    return VelocityAlertEvent(
      fuelType: config.fuelType,
      affectedStationIds: drops.map((d) => d.stationId).toList(),
      maxDropCents: max,
    );
  }
}

class _Drop {
  final String stationId;
  final double cents;
  const _Drop(this.stationId, this.cents);
}
