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
/// - the nearest [Station] (sorted by distance) for an
///   [ApproachPolling] fix, or `null` when the search chain returns
///   nothing in range.
///
/// The lookup mirrors the detector's own `fetchStations` callback
/// ([approachStateProvider]) — same `searchStations` chain, same
/// effective fuel type — so the price column the card reads matches
/// what the in-radius layout would show.

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
/// - the nearest [Station] (sorted by distance) for an
///   [ApproachPolling] fix, or `null` when the search chain returns
///   nothing in range.
///
/// The lookup mirrors the detector's own `fetchStations` callback
/// ([approachStateProvider]) — same `searchStations` chain, same
/// effective fuel type — so the price column the card reads matches
/// what the in-radius layout would show.

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
  /// - the nearest [Station] (sorted by distance) for an
  ///   [ApproachPolling] fix, or `null` when the search chain returns
  ///   nothing in range.
  ///
  /// The lookup mirrors the detector's own `fetchStations` callback
  /// ([approachStateProvider]) — same `searchStations` chain, same
  /// effective fuel type — so the price column the card reads matches
  /// what the in-radius layout would show.
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
    r'9922d973739e0321b79e5ddede5403fa25029a87';
