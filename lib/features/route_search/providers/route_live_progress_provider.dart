// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderListenableSelect;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/guarded.dart';
import '../../../core/location/geolocator_wrapper.dart';
import '../../../core/location/recording_location_settings.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/time/app_clock.dart';
import '../../../core/utils/route_progress.dart';
import '../../../core/utils/route_projection.dart';
import '../domain/route_origin.dart'
    show acceptAsCurrentFix, kRouteOriginMaxFixAge;
import 'route_search_provider.dart';

part 'route_live_progress_provider.g.dart';

/// What the foreground fixes say about the driver on the visible route
/// (#4432).
@immutable
class RouteLiveProgress {
  const RouteLiveProgress({
    this.revision = 0,
    this.fix,
    this.fixAt,
    this.status = RouteProgressStatus.unknown,
    this.retiredBeforeKm = 0,
  });

  /// Nothing to track: no current-location route on screen.
  static const inactive = RouteLiveProgress();

  /// The route request this progress belongs to; 0 when [inactive].
  final int revision;

  /// The last ACCEPTED device fix, or null before the first one.
  final LatLng? fix;

  /// When [fix] was measured (the fix's own timestamp).
  final DateTime? fixAt;

  /// [fix] if it is still current at [now] by the route-origin freshness
  /// bound, else null: a paused listener's last fix is not "you are
  /// here" ten minutes later.
  LatLng? currentFix(DateTime now) {
    final at = fixAt;
    if (fix == null || at == null) return null;
    return now.difference(at).abs() <= kRouteOriginMaxFixAge ? fix : null;
  }

  final RouteProgressStatus status;

  /// Passes of the route before this progress are behind the driver —
  /// hand it to [RouteProjection.itineraryOccurrence] as `fromKm`.
  final double retiredBeforeKm;

  bool get isActive => revision != 0;

  /// The driver left the route, or position is too poor to place them
  /// on it: route-relative claims (best stops, "ahead") need a new route
  /// from where the driver is. Surfaced as "Update route from your
  /// position" — never as an automatic re-route per fix.
  bool get needsRouteUpdate =>
      status == RouteProgressStatus.offRoute ||
      status == RouteProgressStatus.unreliable;
}

/// The corridor, as a multiple of the request's detour budget, inside
/// which a stop still counts as met by the route when retiring passed
/// passes (#4432). 1.5 is the widest limit any strategy filters with
/// (Cheapest), so no stop the search admitted is dropped for its offset.
const double kAheadCorridorFactor = 1.5;

/// The subset of [items] still ahead of the driver on [result]'s route
/// (#4432): every item keeps a pass of the route at or after the
/// progress [progress] has retired. [at] reads an item's coordinate.
///
/// Returns [items] unchanged while [progress] is inactive, belongs to a
/// different request, or has retired nothing yet — a fixed-origin route
/// is never filtered, and a replaced route is never filtered by the old
/// one's progress.
List<T> aheadOfDriver<T>(
  RouteSearchResult result,
  RouteLiveProgress progress,
  List<T> items,
  ({double lat, double lng}) Function(T item) at,
) {
  if (!progress.isActive ||
      progress.revision != result.routeRevision ||
      progress.retiredBeforeKm <= 0) {
    return items;
  }
  final projection = RouteProjection(result.route.geometry);
  final corridorKm =
      kAheadCorridorFactor * (result.request?.searchRadiusKm ?? 15);
  return [
    for (final item in items)
      if (at(item) case (:final lat, :final lng)
          when projection.itineraryOccurrence(lat, lng,
                  corridorKm: corridorKm, fromKm: progress.retiredBeforeKm) !=
              null)
        item,
  ];
}

/// A non-recording, lifecycle-owned position listener for the route
/// results on screen (#4432).
///
/// While a CURRENT-LOCATION route is visible, each accepted foreground
/// fix moves a [RouteProgressTracker] along that route: passed stops
/// retire (with its hysteresis, so they never flicker back) and leaving
/// the route is detected. No fix ever triggers a routing request; the
/// surfaces offer "Update route from your position" instead.
///
/// ## Ownership
///
/// * Auto-dispose: the subscription lives only while a route surface
///   watches this provider, and is cancelled in `onDispose`.
/// * The surface calls [pause] when it is hidden (an offstage tab) or
///   the app is backgrounded, and [resume] when it is shown again.
/// * It joins the SHARED position source (#2646) as a non-recording
///   consumer with the light on-search radar profile, so it never
///   reconfigures an active trip recording, and the source's refcount
///   closes the platform stream when the last listener leaves.
/// * The source replays its latest fix to late joiners; each fix is
///   validated with the route-origin freshness/accuracy policy
///   ([acceptAsCurrentFix]) before it moves anything.
@riverpod
class RouteLiveProgressController extends _$RouteLiveProgressController {
  StreamSubscription<Position>? _sub;
  RouteProgressTracker? _tracker;
  bool _paused = false;

  @override
  RouteLiveProgress build() {
    ref.onDispose(_cancel);
    // Only the request identity and whether its origin is the vehicle
    // matter here; partial results of the same request share both, so
    // streaming batches do not restart the listener.
    final key = ref.watch(routeSearchStateProvider
        .select((AsyncValue<RouteSearchResult?> s) {
      final request = s.value?.request;
      if (request == null || !request.originIsVehiclePosition) return 0;
      return request.revision;
    }));
    _cancel();
    _tracker = null;
    if (key == 0) return RouteLiveProgress.inactive;
    final result = ref.read(routeSearchStateProvider).value;
    if (result == null || result.route.geometry.length < 2) {
      return RouteLiveProgress.inactive;
    }
    _tracker = RouteProgressTracker(RouteProjection(result.route.geometry));
    if (!_paused) _listen();
    return RouteLiveProgress(revision: key);
  }

  /// Stop listening while the route surface is hidden or backgrounded.
  void pause() {
    _paused = true;
    _cancel();
  }

  /// Listen again once the surface is visible. Progress already made is
  /// kept: retirement is monotonic.
  void resume() {
    _paused = false;
    if (_tracker != null && _sub == null) _listen();
  }

  /// Whether a platform subscription is currently held.
  @visibleForTesting
  bool get isListening => _sub != null;

  void _listen() {
    _sub = ref
        .read(geolocatorWrapperProvider)
        .sharedPositionStream(locationSettings: radarSearchLocationSettings())
        .listen(
          _onFix,
          onError: (Object e, StackTrace st) => logFailure(e, st,
              where: 'RouteLiveProgressController: position stream',
              layer: ErrorLayer.providers),
        );
  }

  void _onFix(Position position) {
    final tracker = _tracker;
    if (tracker == null || !ref.mounted) return;
    // The shared source replays its last fix to a late joiner; that
    // sample may be minutes old and is no evidence of where the driver
    // is now.
    if (!acceptAsCurrentFix(position, ref.read(appClockProvider).now())) {
      return;
    }
    final status = tracker.update(
      position.latitude,
      position.longitude,
      accuracyMeters: position.accuracy,
    );
    final reliable = status != RouteProgressStatus.unreliable;
    state = RouteLiveProgress(
      revision: state.revision,
      fix: reliable ? LatLng(position.latitude, position.longitude) : state.fix,
      fixAt: reliable ? position.timestamp : state.fixAt,
      status: status,
      retiredBeforeKm: tracker.retiredBeforeKm,
    );
    ref.read(routeProgressSnapshotProvider.notifier).publish(state);
  }

  void _cancel() {
    unawaited(_sub?.cancel());
    _sub = null;
  }
}

/// The last progress [RouteLiveProgressController] published, held
/// WITHOUT owning its listener (#4432).
///
/// Consumers that must honour retirement but must not keep the GPS
/// subscription alive — the refuel planner and the vehicle comparison,
/// which are not auto-dispose — watch this instead of the controller.
/// Watching the controller from them would pin the platform stream open
/// after the route surface is gone.
///
/// Holding the last value after the listener stops is sound: retirement
/// is monotonic (a stop passed is still passed while the surface is
/// hidden), and every consumer goes through [aheadOfDriver], which
/// ignores progress stamped with another route's revision.
@Riverpod(keepAlive: true)
class RouteProgressSnapshot extends _$RouteProgressSnapshot {
  @override
  RouteLiveProgress build() => RouteLiveProgress.inactive;

  void publish(RouteLiveProgress progress) => state = progress;
}

/// Ids of [result]'s stations that [progress] has retired: already
/// behind the driver on every pass of the route (#4432).
///
/// Empty whenever [aheadOfDriver] would filter nothing — inactive
/// progress, another route's progress, nothing retired yet.
Set<String> passedStationIds(
  RouteSearchResult result,
  RouteLiveProgress progress,
) {
  final all = result.stations;
  final ahead = aheadOfDriver(
      result, progress, all, (s) => (lat: s.lat, lng: s.lng));
  if (identical(ahead, all) || ahead.length == all.length) {
    return const <String>{};
  }
  final kept = {for (final s in ahead) s.id};
  return {
    for (final s in all)
      if (!kept.contains(s.id)) s.id,
  };
}
