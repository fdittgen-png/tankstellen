// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radar_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The on-search Fuel Station Radar (#2659 / #3267).
///
/// A **live** radar around the user's current position, surfaced in the search
/// results list like a regular search. Unlike its one-shot predecessor, it
/// subscribes to a foreground GPS stream ([radarSearchLocationSettings]) while
/// active and re-stamps each station's distance on every fix, so the distance
/// captions + the closeness bars tick down as the driver approaches — the SAME
/// live-distance behaviour the trip radar gets from the approach detector. The
/// distance/dedup/fuel-filter/sort is the shared [RadarRanking] authority, so
/// both surfaces rank identically (#3267).
///
/// It reuses the #2661 radar data layer ([fuelStationRadarProvider]) — the
/// tier-1 corridor location cache (1 h) + tier-3 JIT price cache (5 min) — for
/// the wide net, and merges a direct in-radius fetch so the result is always a
/// superset of the regular search (#2806). That in-radius merge runs through
/// the shared, movement+time-gated [radarInRadiusCacheProvider] (#3254), so a
/// moving user re-queries the chain at most once per the provider's
/// `minInterval` instead of once per fix; between fetches the distance still
/// updates live off the cached set with **zero** network.
///
/// ### Fast, non-blocking init (#3267)
///
/// On [runRadar] the radar paints immediately from the persisted last-known
/// position (corridor-only, [locating] = true) so the user never stares at a
/// blank screen through the cold GPS fix, then re-scans authoritatively once
/// the fresh fix lands. The GPS subscription and the corridor fetch progress
/// concurrently rather than strictly serially.

@ProviderFor(RadarSearch)
final radarSearchProvider = RadarSearchProvider._();

/// The on-search Fuel Station Radar (#2659 / #3267).
///
/// A **live** radar around the user's current position, surfaced in the search
/// results list like a regular search. Unlike its one-shot predecessor, it
/// subscribes to a foreground GPS stream ([radarSearchLocationSettings]) while
/// active and re-stamps each station's distance on every fix, so the distance
/// captions + the closeness bars tick down as the driver approaches — the SAME
/// live-distance behaviour the trip radar gets from the approach detector. The
/// distance/dedup/fuel-filter/sort is the shared [RadarRanking] authority, so
/// both surfaces rank identically (#3267).
///
/// It reuses the #2661 radar data layer ([fuelStationRadarProvider]) — the
/// tier-1 corridor location cache (1 h) + tier-3 JIT price cache (5 min) — for
/// the wide net, and merges a direct in-radius fetch so the result is always a
/// superset of the regular search (#2806). That in-radius merge runs through
/// the shared, movement+time-gated [radarInRadiusCacheProvider] (#3254), so a
/// moving user re-queries the chain at most once per the provider's
/// `minInterval` instead of once per fix; between fetches the distance still
/// updates live off the cached set with **zero** network.
///
/// ### Fast, non-blocking init (#3267)
///
/// On [runRadar] the radar paints immediately from the persisted last-known
/// position (corridor-only, [locating] = true) so the user never stares at a
/// blank screen through the cold GPS fix, then re-scans authoritatively once
/// the fresh fix lands. The GPS subscription and the corridor fetch progress
/// concurrently rather than strictly serially.
final class RadarSearchProvider
    extends $NotifierProvider<RadarSearch, RadarSearchState> {
  /// The on-search Fuel Station Radar (#2659 / #3267).
  ///
  /// A **live** radar around the user's current position, surfaced in the search
  /// results list like a regular search. Unlike its one-shot predecessor, it
  /// subscribes to a foreground GPS stream ([radarSearchLocationSettings]) while
  /// active and re-stamps each station's distance on every fix, so the distance
  /// captions + the closeness bars tick down as the driver approaches — the SAME
  /// live-distance behaviour the trip radar gets from the approach detector. The
  /// distance/dedup/fuel-filter/sort is the shared [RadarRanking] authority, so
  /// both surfaces rank identically (#3267).
  ///
  /// It reuses the #2661 radar data layer ([fuelStationRadarProvider]) — the
  /// tier-1 corridor location cache (1 h) + tier-3 JIT price cache (5 min) — for
  /// the wide net, and merges a direct in-radius fetch so the result is always a
  /// superset of the regular search (#2806). That in-radius merge runs through
  /// the shared, movement+time-gated [radarInRadiusCacheProvider] (#3254), so a
  /// moving user re-queries the chain at most once per the provider's
  /// `minInterval` instead of once per fix; between fetches the distance still
  /// updates live off the cached set with **zero** network.
  ///
  /// ### Fast, non-blocking init (#3267)
  ///
  /// On [runRadar] the radar paints immediately from the persisted last-known
  /// position (corridor-only, [locating] = true) so the user never stares at a
  /// blank screen through the cold GPS fix, then re-scans authoritatively once
  /// the fresh fix lands. The GPS subscription and the corridor fetch progress
  /// concurrently rather than strictly serially.
  RadarSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'radarSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$radarSearchHash();

  @$internal
  @override
  RadarSearch create() => RadarSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RadarSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RadarSearchState>(value),
    );
  }
}

String _$radarSearchHash() => r'6915d5a189620edc8479072f08a23d7eecddd521';

/// The on-search Fuel Station Radar (#2659 / #3267).
///
/// A **live** radar around the user's current position, surfaced in the search
/// results list like a regular search. Unlike its one-shot predecessor, it
/// subscribes to a foreground GPS stream ([radarSearchLocationSettings]) while
/// active and re-stamps each station's distance on every fix, so the distance
/// captions + the closeness bars tick down as the driver approaches — the SAME
/// live-distance behaviour the trip radar gets from the approach detector. The
/// distance/dedup/fuel-filter/sort is the shared [RadarRanking] authority, so
/// both surfaces rank identically (#3267).
///
/// It reuses the #2661 radar data layer ([fuelStationRadarProvider]) — the
/// tier-1 corridor location cache (1 h) + tier-3 JIT price cache (5 min) — for
/// the wide net, and merges a direct in-radius fetch so the result is always a
/// superset of the regular search (#2806). That in-radius merge runs through
/// the shared, movement+time-gated [radarInRadiusCacheProvider] (#3254), so a
/// moving user re-queries the chain at most once per the provider's
/// `minInterval` instead of once per fix; between fetches the distance still
/// updates live off the cached set with **zero** network.
///
/// ### Fast, non-blocking init (#3267)
///
/// On [runRadar] the radar paints immediately from the persisted last-known
/// position (corridor-only, [locating] = true) so the user never stares at a
/// blank screen through the cold GPS fix, then re-scans authoritatively once
/// the fresh fix lands. The GPS subscription and the corridor fetch progress
/// concurrently rather than strictly serially.

abstract class _$RadarSearch extends $Notifier<RadarSearchState> {
  RadarSearchState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<RadarSearchState, RadarSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RadarSearchState, RadarSearchState>,
              RadarSearchState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// The nearest priced radar station, or null. Feeds the small-window PiP tile
/// (#2677) the same way `nearestStationRadarProvider` feeds the trip PiP. Now
/// carries the LIVE distance (the list it reads is re-stamped on every GPS
/// fix), so the tile's distance + closeness bar move as the user approaches —
/// fixing the frozen-snapshot distance #3255 flagged.

@ProviderFor(radarSearchNearest)
final radarSearchNearestProvider = RadarSearchNearestProvider._();

/// The nearest priced radar station, or null. Feeds the small-window PiP tile
/// (#2677) the same way `nearestStationRadarProvider` feeds the trip PiP. Now
/// carries the LIVE distance (the list it reads is re-stamped on every GPS
/// fix), so the tile's distance + closeness bar move as the user approaches —
/// fixing the frozen-snapshot distance #3255 flagged.

final class RadarSearchNearestProvider
    extends $FunctionalProvider<Station?, Station?, Station?>
    with $Provider<Station?> {
  /// The nearest priced radar station, or null. Feeds the small-window PiP tile
  /// (#2677) the same way `nearestStationRadarProvider` feeds the trip PiP. Now
  /// carries the LIVE distance (the list it reads is re-stamped on every GPS
  /// fix), so the tile's distance + closeness bar move as the user approaches —
  /// fixing the frozen-snapshot distance #3255 flagged.
  RadarSearchNearestProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'radarSearchNearestProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$radarSearchNearestHash();

  @$internal
  @override
  $ProviderElement<Station?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Station? create(Ref ref) {
    return radarSearchNearest(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Station? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Station?>(value),
    );
  }
}

String _$radarSearchNearestHash() =>
    r'b69ac244695db9325ceb5fe03c40a565082317a3';
