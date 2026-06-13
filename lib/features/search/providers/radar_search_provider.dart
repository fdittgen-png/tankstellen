// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:geolocator/geolocator.dart' show Position;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/domain/station.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/location/geolocator_wrapper.dart';
import '../../../core/location/recording_location_settings.dart'
    show radarSearchLocationSettings;
import '../../../core/location/user_position_provider.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/utils/geo_utils.dart' as geo;
import '../../../core/services/radar/radar_ranking.dart';
import '../../approach/providers/fuel_station_radar_provider.dart';
import '../../../core/services/radar/radar_in_radius_cache_provider.dart';
import '../../widget/data/car_station_writer.dart';
import 'search_filters_provider.dart';

part 'radar_search_provider.g.dart';

/// State of the on-search Fuel Station Radar (#2659 / #2674 / #3267).
///
/// Holds whether the radar is the active result source ([active]), whether a
/// fresh GPS fix is still being acquired ([locating]) and the `AsyncValue` of
/// the distance-sorted, priced station list it produced.
class RadarSearchState {
  const RadarSearchState({
    required this.active,
    this.locating = false,
    required this.stations,
  });

  /// `true` once a radar run has resolved and the results list should render
  /// the radar stations instead of the regular `searchStateProvider` results.
  final bool active;

  /// `true` while a fresh GPS fix is in flight (#3267). The radar paints
  /// instantly from the last-known position and flips this off once the live
  /// fix lands, so the UI can show an "updating your location" affordance
  /// instead of a blank, blocked screen during the cold fix.
  final bool locating;

  /// The radar's distance-sorted, priced station list (loading/data/error).
  final AsyncValue<List<Station>> stations;

  static const RadarSearchState idle = RadarSearchState(
    active: false,
    locating: false,
    stations: AsyncData<List<Station>>(<Station>[]),
  );

  RadarSearchState copyWith({
    bool? active,
    bool? locating,
    AsyncValue<List<Station>>? stations,
  }) =>
      RadarSearchState(
        active: active ?? this.active,
        locating: locating ?? this.locating,
        stations: stations ?? this.stations,
      );
}

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
@riverpod
class RadarSearch extends _$RadarSearch {
  /// The live GPS subscription, open only while the radar is active. Cancelled
  /// on [dismiss] and on provider dispose.
  StreamSubscription<Position>? _gpsSub;

  /// The most recent raw (un-ranked) station set from the last fetch — corridor
  /// + the gated in-radius merge. Re-ranked against each new GPS fix WITHOUT a
  /// network call, so the distance/order update live between gated re-fetches.
  List<Station> _lastRaw = const [];

  /// The most recent live fix, kept for its heading (corridor tile-ahead
  /// prefetch, #3256).
  Position? _lastFix;

  @override
  RadarSearchState build() {
    ref.onDispose(() {
      unawaited(_gpsSub?.cancel());
      _gpsSub = null;
    });
    return RadarSearchState.idle;
  }

  /// Android Auto v1 (#2948) — mirrors each radar run into the
  /// `car_radar_json` SharedPreferences key the native car Radar screen
  /// reads. Overridable so tests can assert the write without a platform
  /// channel; the headless-engine live bridge is the v2 rewrite (#2947).
  @visibleForTesting
  CarStationWriter carWriter = const CarStationWriter();

  /// Run the radar around the user's current position and keep it live.
  ///
  /// Paints instantly from the persisted last-known position, subscribes to the
  /// live GPS stream, then re-scans around the fresh fix. Surfaces an actionable
  /// error only when there is NO position to scan around at all (#3042).
  Future<void> runRadar() async {
    // Subscribe to live GPS first so a fix that lands during the initial scans
    // already drives a re-rank. Idempotent + test-safe (a platform-less stream
    // is swallowed, keeping the radar usable off the persisted/refreshed fix).
    _subscribeGps();

    // #3267 — instant first paint from the last-known position (corridor-only,
    // no in-radius merge yet) so the user sees something immediately while the
    // fresh fix resolves, rather than a blank, blocked screen.
    final persisted = ref.read(userPositionProvider);
    if (persisted != null) {
      state = state.copyWith(active: true, locating: true);
      await _scan(
        persisted.lat,
        persisted.lng,
        withInRadiusMerge: false,
        silent: false,
      );
    } else {
      state = state.copyWith(
        active: true,
        locating: true,
        stations: const AsyncLoading<List<Station>>(),
      );
    }

    // #2806 — refresh the live GPS fix, exactly as the regular search does, so
    // the authoritative scan is around the user's CURRENT spot, not a position
    // minutes behind them. Best-effort: keep the persisted point if the fix is
    // denied / times out, so an offline run still scans the last spot.
    Object? gpsError;
    StackTrace? gpsStack;
    try {
      await ref.read(userPositionProvider.notifier).updateFromGps();
    } catch (e, st) {
      gpsError = e;
      gpsStack = st;
    }

    final pos = ref.read(userPositionProvider);
    if (pos == null) {
      // #3042 — no position to scan around (fresh install, denied location).
      // Surface the underlying failure as an error so SearchResultsContent
      // renders an actionable banner instead of an empty / silent list.
      state = RadarSearchState(
        active: true,
        locating: false,
        stations: AsyncError<List<Station>>(
          gpsError ??
              const LocationException(message: 'Location permission denied.'),
          gpsStack ?? StackTrace.current,
        ),
      );
      return;
    }

    // Authoritative scan around the fresh fix, with the in-radius superset
    // merge. Clears `locating` — the user is now seeing their real surroundings.
    state = state.copyWith(locating: false);
    await _scan(
      pos.lat,
      pos.lng,
      withInRadiusMerge: true,
      heading: geo.sanitizedHeading(_lastFix?.heading),
      silent: false,
    );
  }

  /// Open the live GPS subscription if it isn't already. Never throws — a
  /// platform-less stream (unit tests, a device with location off) is logged
  /// and swallowed, leaving the radar live off the persisted / refreshed fix.
  void _subscribeGps() {
    if (_gpsSub != null) return;
    try {
      final stream = ref
          .read(geolocatorWrapperProvider)
          .getPositionStream(locationSettings: radarSearchLocationSettings());
      _gpsSub = stream.listen(
        _onFix,
        onError: (Object e, StackTrace st) {
          // A mid-run permission revoke / OS location kill: keep the last
          // results, just stop ticking. Leave a breadcrumb (#2297 style).
          unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
            'where': 'RadarSearch GPS stream error',
          }));
        },
        cancelOnError: false,
      );
    } on Object catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {
        'where': 'RadarSearch GPS subscribe',
      }));
    }
  }

  /// Handle a live GPS fix while the radar is active: re-rank the cached set
  /// against the new position immediately (zero network) so the distance ticks
  /// down, then trigger a gated re-fetch in the background.
  void _onFix(Position p) {
    _lastFix = p;
    if (!state.active) return;
    // 1. Immediate, network-free re-rank off the cached raw set so the distance
    //    captions + closeness bars move on every fix.
    _republish(p.latitude, p.longitude);
    // 2. Background gated re-fetch — the corridor is cache-served inside a tile
    //    and the in-radius merge is movement+time-gated (#3254), so this is
    //    mostly free and never re-queries more than necessary. Silent: a
    //    transient failure must not clobber the live results with an error.
    unawaited(_scan(
      p.latitude,
      p.longitude,
      withInRadiusMerge: true,
      heading: geo.sanitizedHeading(p.heading),
      silent: true,
    ));
  }

  /// Fetch the corridor (+ optional gated in-radius merge) around ([lat],
  /// [lng]), rank it with the shared authority, and publish.
  Future<void> _scan(
    double lat,
    double lng, {
    required bool withInRadiusMerge,
    double? heading,
    required bool silent,
  }) async {
    final radiusKm = ref.read(searchRadiusProvider);
    final fuel = ref.read(selectedFuelTypeProvider);
    try {
      final radar = ref.read(fuelStationRadarProvider);
      final corridor = await radar.fetchStations(
        lat,
        lng,
        radiusKm,
        fuel.apiValue,
        headingDegrees: heading,
      );

      // #2806 — the wide corridor is row-capped + un-distance-ordered, so it can
      // miss the closest forecourts. Merge a direct in-radius fetch so the radar
      // is always a SUPERSET of the in-radius search. #3254 — through the shared
      // movement+time gate, so a moving user re-queries at most once per
      // minInterval. Skipped on the provisional first paint (corridor-only).
      final nearby = withInRadiusMerge
          ? await ref.read(radarInRadiusCacheProvider).stationsNear(
                lat,
                lng,
                radiusKm,
              )
          : const <Station>[];

      _lastRaw = [...corridor, ...nearby];
      final ranked = RadarRanking.rank(_lastRaw, lat: lat, lng: lng, fuel: fuel);

      // #2948 — publish to the Android Auto Radar screen (swallows write faults).
      unawaited(carWriter.writeRadar(ranked, fuel));

      state = state.copyWith(stations: AsyncData<List<Station>>(ranked));
    } catch (e, st) {
      // On a background (live) refresh, keep the last good results; only an
      // explicit (initial / retry) scan surfaces the error.
      if (!silent) {
        state = state.copyWith(stations: AsyncError<List<Station>>(e, st));
      }
    }
  }

  /// Re-rank the cached raw set against ([lat], [lng]) and publish — no network.
  void _republish(double lat, double lng) {
    if (_lastRaw.isEmpty) return;
    final fuel = ref.read(selectedFuelTypeProvider);
    final ranked = RadarRanking.rank(_lastRaw, lat: lat, lng: lng, fuel: fuel);
    unawaited(carWriter.writeRadar(ranked, fuel));
    state = state.copyWith(stations: AsyncData<List<Station>>(ranked));
  }

  /// Dismiss the radar result and hand the results list back to the regular
  /// `searchStateProvider`. Cancels the live GPS subscription.
  void dismiss() {
    unawaited(_gpsSub?.cancel());
    _gpsSub = null;
    _lastRaw = const [];
    _lastFix = null;
    state = RadarSearchState.idle;
  }
}

/// The nearest priced radar station, or null. Feeds the small-window PiP tile
/// (#2677) the same way `nearestStationRadarProvider` feeds the trip PiP. Now
/// carries the LIVE distance (the list it reads is re-stamped on every GPS
/// fix), so the tile's distance + closeness bar move as the user approaches —
/// fixing the frozen-snapshot distance #3255 flagged.
@riverpod
Station? radarSearchNearest(Ref ref) {
  final radar = ref.watch(radarSearchProvider);
  if (!radar.active) return null;
  final list = radar.stations.value;
  if (list == null || list.isEmpty) return null;
  return list.first;
}
