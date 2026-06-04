// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearest_station_radar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fallback "radar" lookup for the trip-screen [TripRadarCard] (#2380).
///
/// The approach detector only flips into [ApproachInRadius] once the
/// driver is inside the configured geo-fence. Outside the radius it
/// emits [ApproachPolling], which already carries the live GPS fix the
/// detector is polling against. This provider reuses **that same**
/// position — no new GPS subscription — to surface the single nearest
/// fuel station + its price so the card has something useful to show
/// while the driver is still approaching.
///
/// Returns:
/// - `null` when the effective approach state is [ApproachInRadius] or
///   [ApproachLeaving] — the card renders those directly off the
///   approach state, so the fallback stays out of the way.
/// - `null` when the state is [ApproachIdle] / null (no GPS fix yet) —
///   the card shows its "scanning" placeholder.
/// - the nearest [Station] **that has a price for the effective fuel**
///   (the distance-sorted list filtered to `priceFor(fuel) > 0`) for an
///   [ApproachPolling] fix, or `null` when nothing in range is priced
///   for the driver's fuel (#2583). Unpriced nearest stations are
///   skipped so the card only ever surfaces a station the driver can
///   actually price-compare — never a `--` placeholder price.
///
/// ### Data source (#2664)
///
/// The lookup routes through the cache-first [fuelStationRadarProvider] —
/// the SAME three-tier engine the in-radius detector uses
/// (`approach_state_provider.dart`): tier-1 cached corridor LOCATIONS
/// (zero network inside a covered tile / a bulk-file country) + tier-3
/// JIT price for only the imminent station(s). It runs at the user's
/// **default radar radius** (`profile.approachRadiusKm`, the same radius
/// the trip detector geofences against), not a hard-coded 10 km — so a
/// warm corridor tile costs zero station-network calls and at most one
/// JIT price per imminent station instead of re-pricing a whole 10 km
/// set on every poll. The price column the card reads therefore matches
/// exactly what the in-radius layout would show.

@ProviderFor(nearestStationRadar)
final nearestStationRadarProvider = NearestStationRadarProvider._();

/// Fallback "radar" lookup for the trip-screen [TripRadarCard] (#2380).
///
/// The approach detector only flips into [ApproachInRadius] once the
/// driver is inside the configured geo-fence. Outside the radius it
/// emits [ApproachPolling], which already carries the live GPS fix the
/// detector is polling against. This provider reuses **that same**
/// position — no new GPS subscription — to surface the single nearest
/// fuel station + its price so the card has something useful to show
/// while the driver is still approaching.
///
/// Returns:
/// - `null` when the effective approach state is [ApproachInRadius] or
///   [ApproachLeaving] — the card renders those directly off the
///   approach state, so the fallback stays out of the way.
/// - `null` when the state is [ApproachIdle] / null (no GPS fix yet) —
///   the card shows its "scanning" placeholder.
/// - the nearest [Station] **that has a price for the effective fuel**
///   (the distance-sorted list filtered to `priceFor(fuel) > 0`) for an
///   [ApproachPolling] fix, or `null` when nothing in range is priced
///   for the driver's fuel (#2583). Unpriced nearest stations are
///   skipped so the card only ever surfaces a station the driver can
///   actually price-compare — never a `--` placeholder price.
///
/// ### Data source (#2664)
///
/// The lookup routes through the cache-first [fuelStationRadarProvider] —
/// the SAME three-tier engine the in-radius detector uses
/// (`approach_state_provider.dart`): tier-1 cached corridor LOCATIONS
/// (zero network inside a covered tile / a bulk-file country) + tier-3
/// JIT price for only the imminent station(s). It runs at the user's
/// **default radar radius** (`profile.approachRadiusKm`, the same radius
/// the trip detector geofences against), not a hard-coded 10 km — so a
/// warm corridor tile costs zero station-network calls and at most one
/// JIT price per imminent station instead of re-pricing a whole 10 km
/// set on every poll. The price column the card reads therefore matches
/// exactly what the in-radius layout would show.

final class NearestStationRadarProvider
    extends
        $FunctionalProvider<AsyncValue<Station?>, Station?, FutureOr<Station?>>
    with $FutureModifier<Station?>, $FutureProvider<Station?> {
  /// Fallback "radar" lookup for the trip-screen [TripRadarCard] (#2380).
  ///
  /// The approach detector only flips into [ApproachInRadius] once the
  /// driver is inside the configured geo-fence. Outside the radius it
  /// emits [ApproachPolling], which already carries the live GPS fix the
  /// detector is polling against. This provider reuses **that same**
  /// position — no new GPS subscription — to surface the single nearest
  /// fuel station + its price so the card has something useful to show
  /// while the driver is still approaching.
  ///
  /// Returns:
  /// - `null` when the effective approach state is [ApproachInRadius] or
  ///   [ApproachLeaving] — the card renders those directly off the
  ///   approach state, so the fallback stays out of the way.
  /// - `null` when the state is [ApproachIdle] / null (no GPS fix yet) —
  ///   the card shows its "scanning" placeholder.
  /// - the nearest [Station] **that has a price for the effective fuel**
  ///   (the distance-sorted list filtered to `priceFor(fuel) > 0`) for an
  ///   [ApproachPolling] fix, or `null` when nothing in range is priced
  ///   for the driver's fuel (#2583). Unpriced nearest stations are
  ///   skipped so the card only ever surfaces a station the driver can
  ///   actually price-compare — never a `--` placeholder price.
  ///
  /// ### Data source (#2664)
  ///
  /// The lookup routes through the cache-first [fuelStationRadarProvider] —
  /// the SAME three-tier engine the in-radius detector uses
  /// (`approach_state_provider.dart`): tier-1 cached corridor LOCATIONS
  /// (zero network inside a covered tile / a bulk-file country) + tier-3
  /// JIT price for only the imminent station(s). It runs at the user's
  /// **default radar radius** (`profile.approachRadiusKm`, the same radius
  /// the trip detector geofences against), not a hard-coded 10 km — so a
  /// warm corridor tile costs zero station-network calls and at most one
  /// JIT price per imminent station instead of re-pricing a whole 10 km
  /// set on every poll. The price column the card reads therefore matches
  /// exactly what the in-radius layout would show.
  NearestStationRadarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearestStationRadarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearestStationRadarHash();

  @$internal
  @override
  $FutureProviderElement<Station?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Station?> create(Ref ref) {
    return nearestStationRadar(ref);
  }
}

String _$nearestStationRadarHash() =>
    r'ef42198fcc6ac6493b83d4148eaa21a3f97b0ed1';
