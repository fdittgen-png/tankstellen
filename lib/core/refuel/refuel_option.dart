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

  /// Human-readable address line for the unified results card. Format
  /// is best-effort `"<street>, <postCode> <place>"` when those parts
  /// are populated, else a shorter fallback (or empty string when no
  /// address data is available at all). Drives the address line on the
  /// unified card so fuel pumps and EV chargers render with the same
  /// density as the legacy `StationCard` (#1116 phase 4).
  String get address;

  /// Distance from the user's reference point, in metres. `null` when
  /// the upstream search did not compute distance. Drives the distance
  /// label on the unified card and the merged-list sort order in
  /// `unifiedSearchResultsProvider` so EV + fuel options interleave by
  /// proximity rather than appearing as two segregated blocks.
  double? get distanceMeters;

  /// Whether the option is open 24h/24. Drives the small "24h" badge
  /// the unified card stacks under the status dot. Defaults to `false`
  /// for upstream entities that don't expose a 24h flag.
  bool get is24h;

  /// Best-known timestamp for the displayed station data, parsed from
  /// the upstream `updatedAt` string. Distinct from
  /// [RefuelPrice.lastUpdated] (which is `null` when the price is
  /// unavailable for the active fuel) — the unified card needs an
  /// updated-at marker even on closed / price-less rows so users can
  /// see how recent the data is at a glance.
  DateTime? get lastUpdated;

  /// The underlying entity this option wraps — type-erased so the
  /// abstract layer stays free of `Station` / `ChargingStation`
  /// imports. Phase 5 (#1116) opens this seam so the unified card can
  /// downcast for kind-specific extras (amenity icon chips for fuel,
  /// connector stats for EV) without spreading those imports across
  /// generic consumers. Generic consumers (sort, filter, dedup) MUST
  /// NOT depend on the concrete type — only the rendering layer is
  /// allowed to peek inside.
  Object get source;
}
