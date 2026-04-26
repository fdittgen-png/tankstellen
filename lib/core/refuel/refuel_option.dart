import 'refuel_availability.dart';
import 'refuel_price.dart';
import 'refuel_provider.dart';

/// A single user-actionable refueling option — fuel pump or EV charger.
///
/// Phase 1 of the fuel/EV unification (#1116). The leitmotiv treats
/// EV charging as a pump for an electric car: plug-in hybrid drivers
/// (the fastest-growing EU demographic) currently see two disjoint
/// search UIs, and merging them is the highest strategic-value
/// architectural bet for v5.x.
///
/// Subtypes are adapters that wrap existing `Station` /
/// `ChargingStation` data — those land in phase 2. Phase 1 introduces
/// the abstract type and its companions (`RefuelProvider`,
/// `RefuelPrice`, `RefuelAvailability`) only; no UI consumer changes
/// yet.
abstract class RefuelOption {
  /// Const constructor so adapters can be const when their underlying
  /// fields are.
  const RefuelOption();

  /// Geographic location for distance + map rendering. Tuple shape
  /// (record) keeps callers free of `package:latlong2` coupling at
  /// the abstract layer.
  ({double lat, double lng}) get coordinates;

  /// Best-known current price, or `null` if unavailable.
  ///
  /// For fuel: cents/liter for the user's preferred fuel type.
  /// For EV: cents/kWh, or per-session if the provider charges flat.
  RefuelPrice? get price;

  /// Identity of the operator — brand for fuel, network for EV.
  RefuelProvider get provider;

  /// Whether the option is open / closed / partially available /
  /// unknown right now.
  RefuelAvailability get availability;

  /// Stable identifier across re-fetches.
  ///
  /// Adapters derive this from the underlying entity's id with a
  /// type prefix (e.g. `"fuel:42"`, `"ev:abc-123"`) so a unified
  /// search list can deduplicate without colliding on shared
  /// numeric ids between the two source systems.
  String get id;
}
