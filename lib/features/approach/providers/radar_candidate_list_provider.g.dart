// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radar_candidate_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ranked list of nearby **priced** fuel stations for the swipe-to-page
/// radar card (#2633).
///
/// The single-station [nearestStationRadarProvider] only surfaces the
/// nearest priced station; the swipe gesture needs the FULL distance-
/// ranked candidate set so the card can advance to the next-nearest on a
/// swipe-left and restore the previous one on a swipe-right.
///
/// Like [nearestStationRadarProvider] this fires ONLY on the polling
/// fallback path: while the driver is still approaching the detector
/// emits [ApproachPolling] carrying the live GPS fix it polls against.
/// We reuse **that same** position — no new geolocator subscription.
///
/// Returns:
/// - `const []` for any non-[ApproachPolling] state — the in-radius /
///   leaving states render a single locked target straight off the
///   approach state, so the swipe page-set stays out of the way; idle /
///   null has no GPS fix yet.
/// - the distance-sorted [Station] list filtered to those carrying a
///   price for the effective fuel (`priceFor(fuel)` non-null and `> 0`)
///   — the same priced filter as `approach_detector.dart` and
///   [nearestStationRadarProvider], so the card never pages onto a `--`
///   placeholder price the driver can't compare (#2583).
/// - `const []` on a radar / chain failure (the provider re-runs on the
///   next approach-state tick).
///
/// ### Data source (#2664)
///
/// The page-set routes through the cache-first [fuelStationRadarProvider]
/// — the SAME three-tier engine the in-radius detector uses
/// (`approach_state_provider.dart`): tier-1 cached corridor LOCATIONS
/// (zero network inside a covered tile / a bulk-file country) + tier-3
/// JIT price for only the imminent station(s). It runs at the user's
/// **default radar radius** (`profile.approachRadiusKm`, the same radius
/// the trip detector geofences against), not a hard-coded 10 km — so a
/// warm corridor tile costs zero station-network calls and at most one
/// JIT price per imminent station instead of re-pricing a whole 10 km set
/// on every poll. The ranked page-set therefore matches exactly what the
/// in-radius layout would surface.

@ProviderFor(radarCandidateList)
final radarCandidateListProvider = RadarCandidateListProvider._();

/// Ranked list of nearby **priced** fuel stations for the swipe-to-page
/// radar card (#2633).
///
/// The single-station [nearestStationRadarProvider] only surfaces the
/// nearest priced station; the swipe gesture needs the FULL distance-
/// ranked candidate set so the card can advance to the next-nearest on a
/// swipe-left and restore the previous one on a swipe-right.
///
/// Like [nearestStationRadarProvider] this fires ONLY on the polling
/// fallback path: while the driver is still approaching the detector
/// emits [ApproachPolling] carrying the live GPS fix it polls against.
/// We reuse **that same** position — no new geolocator subscription.
///
/// Returns:
/// - `const []` for any non-[ApproachPolling] state — the in-radius /
///   leaving states render a single locked target straight off the
///   approach state, so the swipe page-set stays out of the way; idle /
///   null has no GPS fix yet.
/// - the distance-sorted [Station] list filtered to those carrying a
///   price for the effective fuel (`priceFor(fuel)` non-null and `> 0`)
///   — the same priced filter as `approach_detector.dart` and
///   [nearestStationRadarProvider], so the card never pages onto a `--`
///   placeholder price the driver can't compare (#2583).
/// - `const []` on a radar / chain failure (the provider re-runs on the
///   next approach-state tick).
///
/// ### Data source (#2664)
///
/// The page-set routes through the cache-first [fuelStationRadarProvider]
/// — the SAME three-tier engine the in-radius detector uses
/// (`approach_state_provider.dart`): tier-1 cached corridor LOCATIONS
/// (zero network inside a covered tile / a bulk-file country) + tier-3
/// JIT price for only the imminent station(s). It runs at the user's
/// **default radar radius** (`profile.approachRadiusKm`, the same radius
/// the trip detector geofences against), not a hard-coded 10 km — so a
/// warm corridor tile costs zero station-network calls and at most one
/// JIT price per imminent station instead of re-pricing a whole 10 km set
/// on every poll. The ranked page-set therefore matches exactly what the
/// in-radius layout would surface.

final class RadarCandidateListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Station>>,
          List<Station>,
          FutureOr<List<Station>>
        >
    with $FutureModifier<List<Station>>, $FutureProvider<List<Station>> {
  /// Ranked list of nearby **priced** fuel stations for the swipe-to-page
  /// radar card (#2633).
  ///
  /// The single-station [nearestStationRadarProvider] only surfaces the
  /// nearest priced station; the swipe gesture needs the FULL distance-
  /// ranked candidate set so the card can advance to the next-nearest on a
  /// swipe-left and restore the previous one on a swipe-right.
  ///
  /// Like [nearestStationRadarProvider] this fires ONLY on the polling
  /// fallback path: while the driver is still approaching the detector
  /// emits [ApproachPolling] carrying the live GPS fix it polls against.
  /// We reuse **that same** position — no new geolocator subscription.
  ///
  /// Returns:
  /// - `const []` for any non-[ApproachPolling] state — the in-radius /
  ///   leaving states render a single locked target straight off the
  ///   approach state, so the swipe page-set stays out of the way; idle /
  ///   null has no GPS fix yet.
  /// - the distance-sorted [Station] list filtered to those carrying a
  ///   price for the effective fuel (`priceFor(fuel)` non-null and `> 0`)
  ///   — the same priced filter as `approach_detector.dart` and
  ///   [nearestStationRadarProvider], so the card never pages onto a `--`
  ///   placeholder price the driver can't compare (#2583).
  /// - `const []` on a radar / chain failure (the provider re-runs on the
  ///   next approach-state tick).
  ///
  /// ### Data source (#2664)
  ///
  /// The page-set routes through the cache-first [fuelStationRadarProvider]
  /// — the SAME three-tier engine the in-radius detector uses
  /// (`approach_state_provider.dart`): tier-1 cached corridor LOCATIONS
  /// (zero network inside a covered tile / a bulk-file country) + tier-3
  /// JIT price for only the imminent station(s). It runs at the user's
  /// **default radar radius** (`profile.approachRadiusKm`, the same radius
  /// the trip detector geofences against), not a hard-coded 10 km — so a
  /// warm corridor tile costs zero station-network calls and at most one
  /// JIT price per imminent station instead of re-pricing a whole 10 km set
  /// on every poll. The ranked page-set therefore matches exactly what the
  /// in-radius layout would surface.
  RadarCandidateListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'radarCandidateListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$radarCandidateListHash();

  @$internal
  @override
  $FutureProviderElement<List<Station>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Station>> create(Ref ref) {
    return radarCandidateList(ref);
  }
}

String _$radarCandidateListHash() =>
    r'1d6dbe2341ea09cb25004f189ddd76ce95629173';
