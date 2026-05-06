import '../../features/ev/domain/entities/charging_station.dart';
import 'refuel_availability.dart';
import 'refuel_option.dart';
import 'refuel_price.dart';
import 'refuel_provider.dart';

/// [RefuelOption] adapter that wraps an EV [ChargingStation].
///
/// Phase 2 of the fuel/EV unification (#1116). Mirrors
/// [StationAsRefuelOption] for the EV side so the unified search list
/// (phase 3) can render fuel pumps and EV chargers from one
/// [RefuelOption] iterable.
///
/// ### Known phase-2 limitations
///
/// * [price] is **always `null`**. The upstream
///   [ChargingStation.usageCost] is a free-form string ("0.49 EUR/kWh",
///   "Free", "0.79 EUR/kWh after first 30 min", …). Parsing requires
///   country-specific heuristics best owned by phase 3 alongside the
///   pricing-display widgets.
/// * The `limited` / `closed` reasons are literal English fallbacks.
///   The adapter layer is locale-agnostic; the consumer (phase 3) will
///   wrap the reason in `AppLocalizations` before showing it to the
///   user.
class ChargingStationAsRefuelOption extends RefuelOption {
  /// Wrapped EV charging station.
  final ChargingStation station;

  const ChargingStationAsRefuelOption(this.station);

  @override
  ({double lat, double lng}) get coordinates =>
      (lat: station.latitude, lng: station.longitude);

  @override
  String get id => 'ev:${station.id}';

  @override
  RefuelProvider get provider {
    final op = station.operator;
    if (op == null || op.isEmpty) {
      return RefuelProvider.unknown;
    }
    return RefuelProvider(
      name: op,
      kind: RefuelProviderKind.ev,
    );
  }

  @override
  RefuelAvailability get availability {
    // Operator-level shutdown trumps connector status.
    if (station.isOperational == false) {
      return RefuelAvailability.closed();
    }

    final connectors = station.connectors;
    if (connectors.isEmpty) {
      return RefuelAvailability.unknown;
    }

    final hasAvailable =
        connectors.any((c) => c.status == ConnectorStatus.available);
    if (hasAvailable) {
      return RefuelAvailability.open;
    }

    final hasOccupied =
        connectors.any((c) => c.status == ConnectorStatus.occupied);
    if (hasOccupied) {
      return RefuelAvailability.limited(
        reason: 'All connectors occupied',
      );
    }

    final hasOutOfOrder =
        connectors.any((c) => c.status == ConnectorStatus.outOfOrder);
    if (hasOutOfOrder) {
      return RefuelAvailability.closed(
        reason: 'All connectors out of order',
      );
    }

    return RefuelAvailability.unknown;
  }

  @override
  Object get source => station;

  /// Always `null` in phase 2. See class doc for rationale.
  @override
  RefuelPrice? get price => null;

  @override
  String get address {
    final addr = station.address?.trim() ?? '';
    final post = station.postCode?.trim() ?? '';
    final place = station.place?.trim() ?? '';
    final cityParts = <String>[
      if (post.isNotEmpty) post,
      if (place.isNotEmpty) place,
    ];
    final city = cityParts.join(' ');
    if (addr.isNotEmpty && city.isNotEmpty) return '$addr, $city';
    if (addr.isNotEmpty) return addr;
    return city;
  }

  // [ChargingStation.dist] is upstream-provided in kilometres (mirrors
  // the fuel-side [Station.dist] convention introduced when the legacy
  // search-side EV entity was consolidated under #560). Convert to
  // metres so [RefuelOption] consumers see one unit; treat `0.0` as
  // "distance unknown" for the same reason as the fuel adapter.
  @override
  double? get distanceMeters =>
      station.dist > 0 ? station.dist * 1000.0 : null;

  // The EV upstream [ChargingStation] does not (yet) expose a 24h
  // flag — the [openingHours] field carries weekday-by-weekday windows
  // and a true 24h derivation would require parsing each day's window.
  // Default to `false` here; the unified card therefore won't render
  // a 24h badge for EV rows. A future enrichment can compute this from
  // `openingHours` if a UI consumer needs it.
  @override
  bool get is24h => false;

  @override
  DateTime? get lastUpdated {
    // Prefer the structured [lastUpdate] when available; fall back to
    // the legacy string [updatedAt] (kept for API-compat with the
    // pre-#560 entity shape — see class doc).
    final structured = station.lastUpdate;
    if (structured != null) return structured;
    final raw = station.updatedAt;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
