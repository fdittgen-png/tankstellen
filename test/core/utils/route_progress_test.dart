// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/utils/route_progress.dart';
import 'package:tankstellen/core/utils/route_projection.dart';

/// #4432 — progress along a route with hysteresis. 0.1° of longitude at
/// lat 48° is ~7.44 km.
void main() {
  /// East to lng 2.6, north, west, then south THROUGH the first leg at
  /// (48.0, 2.3) — first met at ~22.3 km, again at ~111.4 km.
  final crossing = RouteProjection(const [
    LatLng(48.0, 2.0),
    LatLng(48.0, 2.6),
    LatLng(48.2, 2.6),
    LatLng(48.2, 2.3),
    LatLng(47.8, 2.3),
  ]);

  test('progress follows accepted fixes forward and never moves back', () {
    final t = RouteProgressTracker(crossing);
    expect(t.update(48.0, 2.1), RouteProgressStatus.onRoute);
    expect(t.progressKm, closeTo(7.44, 0.1));
    t.update(48.0, 2.2);
    expect(t.progressKm, closeTo(14.9, 0.1));
    // Jitter 300 m backward: matched, but progress holds.
    t.update(48.0, 2.196);
    expect(t.progressKm, closeTo(14.9, 0.1));
  });

  test(
      'at the crossing on the FIRST pass, progress takes the first '
      'occurrence rather than jumping to the later one', () {
    final t = RouteProgressTracker(crossing)..update(48.0, 2.29);
    t.update(48.0, 2.3);
    expect(t.progressKm, closeTo(22.3, 0.3));
  });

  test(
      'at the crossing on the SECOND pass, a fix matches the later '
      'occurrence and cannot throw the driver back to the first', () {
    final t = RouteProgressTracker(crossing)
      ..update(48.0, 2.1)
      ..update(48.0, 2.5)
      ..update(48.1, 2.6)
      ..update(48.2, 2.45);
    expect(t.progressKm, closeTo(78, 1));
    t.update(48.0, 2.3);
    expect(t.progressKm, closeTo(111.4, 0.6));
  });

  test(
      'a passed occurrence retires only past the margin, and stays '
      'retired whatever later fixes say', () {
    const stationLat = 48.0, stationLng = 2.3; // first pass ~22.3 km
    final t = RouteProgressTracker(crossing)..update(48.0, 2.2);

    bool firstPassEligible() =>
        (crossing
                    .itineraryOccurrence(stationLat, stationLng,
                        corridorKm: 15, fromKm: t.retiredBeforeKm)
                    ?.alongKm ??
                double.infinity) <
            50;

    // 0.6 km past the station: inside the margin, still a stop.
    t.update(48.0, 2.308);
    expect(firstPassEligible(), isTrue);

    // 1.5 km past with a precise fix: retired.
    t.update(48.0, 2.32);
    expect(firstPassEligible(), isFalse);
    final retired = t.retiredBeforeKm;

    // A coarse fix and a backward-noisy fix: neither resurrects it.
    t.update(48.0, 2.321, accuracyMeters: 240);
    t.update(48.0, 2.299);
    expect(t.retiredBeforeKm, greaterThanOrEqualTo(retired));
    expect(firstPassEligible(), isFalse);

    // …but the route meets the same station again later: still eligible
    // there.
    expect(
      crossing
          .itineraryOccurrence(stationLat, stationLng,
              corridorKm: 15, fromKm: t.retiredBeforeKm)!
          .alongKm,
      closeTo(111.4, 0.6),
    );
  });

  test('a coarse fix is unreliable and does not move progress', () {
    final t = RouteProgressTracker(crossing)..update(48.0, 2.1);
    final before = t.progressKm;
    expect(
      t.update(48.0, 2.5, accuracyMeters: kRouteProgressMaxAccuracyMeters + 1),
      RouteProgressStatus.unreliable,
    );
    expect(t.progressKm, before);
  });

  test('leaving the route needs consecutive off-route fixes', () {
    final t = RouteProgressTracker(crossing)..update(48.0, 2.1);
    // ~2.2 km north of the first leg, nowhere near any other.
    expect(t.update(48.02, 2.1), RouteProgressStatus.onRoute,
        reason: 'one fix in a tunnel mouth is not a departure');
    expect(t.update(48.02, 2.12), RouteProgressStatus.offRoute);
    expect(t.lastOffRouteKm, closeTo(2.2, 0.1));
    // Back on the route ahead: on route again.
    expect(t.update(48.0, 2.15), RouteProgressStatus.onRoute);
    expect(t.lastOffRouteKm, isNull);
  });
}
