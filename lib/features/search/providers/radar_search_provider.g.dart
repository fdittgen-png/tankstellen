// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radar_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The on-search Fuel Station Radar (#2659).
///
/// A one-shot radar fetch around the user's CURRENT position
/// ([userPositionProvider], refreshed from live GPS on each run — #2806 — NOT
/// the trip-only shared GPS stream), surfaced in the search results list like
/// a regular search. It reuses the #2661 radar data layer
/// ([fuelStationRadarProvider]) — the tier-1 corridor location cache (1 h) +
/// tier-3 JIT price cache (5 min) — for the wide net, and merges a direct
/// in-radius fetch so the result is always a superset of the regular search
/// (#2806).
///
/// Deliberately distinct from the trip-gated `nearestStationRadarProvider` /
/// approach detector: those only fire while a trip records (gated on
/// `ApproachPolling`). This provider runs on demand from the search screen, with
/// no geofence polling and no second `ApproachDetector` / `PipController`.

@ProviderFor(RadarSearch)
final radarSearchProvider = RadarSearchProvider._();

/// The on-search Fuel Station Radar (#2659).
///
/// A one-shot radar fetch around the user's CURRENT position
/// ([userPositionProvider], refreshed from live GPS on each run — #2806 — NOT
/// the trip-only shared GPS stream), surfaced in the search results list like
/// a regular search. It reuses the #2661 radar data layer
/// ([fuelStationRadarProvider]) — the tier-1 corridor location cache (1 h) +
/// tier-3 JIT price cache (5 min) — for the wide net, and merges a direct
/// in-radius fetch so the result is always a superset of the regular search
/// (#2806).
///
/// Deliberately distinct from the trip-gated `nearestStationRadarProvider` /
/// approach detector: those only fire while a trip records (gated on
/// `ApproachPolling`). This provider runs on demand from the search screen, with
/// no geofence polling and no second `ApproachDetector` / `PipController`.
final class RadarSearchProvider
    extends $NotifierProvider<RadarSearch, RadarSearchState> {
  /// The on-search Fuel Station Radar (#2659).
  ///
  /// A one-shot radar fetch around the user's CURRENT position
  /// ([userPositionProvider], refreshed from live GPS on each run — #2806 — NOT
  /// the trip-only shared GPS stream), surfaced in the search results list like
  /// a regular search. It reuses the #2661 radar data layer
  /// ([fuelStationRadarProvider]) — the tier-1 corridor location cache (1 h) +
  /// tier-3 JIT price cache (5 min) — for the wide net, and merges a direct
  /// in-radius fetch so the result is always a superset of the regular search
  /// (#2806).
  ///
  /// Deliberately distinct from the trip-gated `nearestStationRadarProvider` /
  /// approach detector: those only fire while a trip records (gated on
  /// `ApproachPolling`). This provider runs on demand from the search screen, with
  /// no geofence polling and no second `ApproachDetector` / `PipController`.
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

String _$radarSearchHash() => r'db0fc654f1e3090050bfcbdd6c014f50d8f14d1b';

/// The on-search Fuel Station Radar (#2659).
///
/// A one-shot radar fetch around the user's CURRENT position
/// ([userPositionProvider], refreshed from live GPS on each run — #2806 — NOT
/// the trip-only shared GPS stream), surfaced in the search results list like
/// a regular search. It reuses the #2661 radar data layer
/// ([fuelStationRadarProvider]) — the tier-1 corridor location cache (1 h) +
/// tier-3 JIT price cache (5 min) — for the wide net, and merges a direct
/// in-radius fetch so the result is always a superset of the regular search
/// (#2806).
///
/// Deliberately distinct from the trip-gated `nearestStationRadarProvider` /
/// approach detector: those only fire while a trip records (gated on
/// `ApproachPolling`). This provider runs on demand from the search screen, with
/// no geofence polling and no second `ApproachDetector` / `PipController`.

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
/// (#2677) the same way `nearestStationRadarProvider` feeds the trip PiP.

@ProviderFor(radarSearchNearest)
final radarSearchNearestProvider = RadarSearchNearestProvider._();

/// The nearest priced radar station, or null. Feeds the small-window PiP tile
/// (#2677) the same way `nearestStationRadarProvider` feeds the trip PiP.

final class RadarSearchNearestProvider
    extends $FunctionalProvider<Station?, Station?, Station?>
    with $Provider<Station?> {
  /// The nearest priced radar station, or null. Feeds the small-window PiP tile
  /// (#2677) the same way `nearestStationRadarProvider` feeds the trip PiP.
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
