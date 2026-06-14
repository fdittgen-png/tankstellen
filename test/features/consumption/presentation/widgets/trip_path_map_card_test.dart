// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/dark_mode_colors.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_detail_charts.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_path_map_card.dart';

import '../../../../helpers/pump_app.dart';

/// #1374 phases 2 + 3 — widget coverage for [TripPathMapCard], the
/// trip-detail card that renders the GPS-recorded route as a polyline
/// on an OpenStreetMap tile layer.
///
/// Phase 2 pinned the render-gating contract (single-colour polyline,
/// self-suppressing on legacy / opted-out trips). Phase 3 swaps the
/// single colour for a per-segment heatmap derived from the
/// instantaneous L/100 km, with a 3-bucket legend below the map. The
/// tests here cover both phases:
///
///  * Render gating: FlutterMap + PolylineLayer only when at least
///    one sample carries both lat + lng; SizedBox.shrink otherwise.
///  * Polyline points: in-order projection of the fully-coord samples,
///    half-set fixes dropped.
///  * Phase 3 heatmap: per-segment colours by computed L/100 km,
///    same-colour runs collapsed into one polyline, low-speed and
///    null-fuel-rate segments pinned to efficient (green).
///  * Legend: three labels rendered with the matching swatch colours.
TripDetailSample _sample({
  required int sec,
  double speed = 60.0,
  double? lat,
  double? lng,
  double? fuelRate,
}) {
  return TripDetailSample(
    timestamp: DateTime.utc(2026, 5, 3, 10, 0, sec),
    speedKmh: speed,
    fuelRateLPerHour: fuelRate,
    latitude: lat,
    longitude: lng,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripPathMapCard — render gating', () {
    testWidgets('renders FlutterMap + PolylineLayer when samples carry coords',
        (tester) async {
      final samples = [
        _sample(sec: 0, lat: 43.46, lng: 3.43),
        _sample(sec: 1, lat: 43.47, lng: 3.44),
        _sample(sec: 2, lat: 43.48, lng: 3.45),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(PolylineLayer), findsOneWidget);
      // The card title comes from AppLocalizations and is the
      // user-visible label of the section.
      expect(find.text('Trip path'), findsOneWidget);
    });

    testWidgets('self-suppresses when no sample carries coords',
        (tester) async {
      // Legacy / opted-out trip — every sample has null on both
      // lat and lng. The widget MUST NOT render a placeholder card;
      // it returns SizedBox.shrink so the trip-detail layout stays
      // unchanged for trips that pre-date GPS sampling.
      final samples = [
        _sample(sec: 0),
        _sample(sec: 1),
        _sample(sec: 2),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      expect(find.byType(FlutterMap), findsNothing);
      expect(find.byType(PolylineLayer), findsNothing);
      expect(find.text('Trip path'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('self-suppresses when samples list is empty', (tester) async {
      await pumpApp(tester, const TripPathMapCard(samples: []));

      expect(find.byType(FlutterMap), findsNothing);
      expect(find.text('Trip path'), findsNothing);
    });
  });

  group('TripPathMapCard — polyline points', () {
    testWidgets(
        'polyline coverage spans the full non-null coord sequence in order',
        (tester) async {
      // With Phase 3 the path is split across N polylines (one per
      // colour bucket run). The full coord sequence still has to be
      // covered, so flatten all polyline points and assert the
      // concatenation matches the input order. Same-bucket samples
      // collapse to a single polyline; here every segment is
      // efficient (no fuel-rate data), so the layer holds exactly
      // one polyline of all 3 points.
      final samples = [
        _sample(sec: 0, lat: 43.46, lng: 3.43),
        _sample(sec: 1, lat: 43.47, lng: 3.44),
        _sample(sec: 2, lat: 43.48, lng: 3.45),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(layer.polylines, hasLength(1));
      final pts = layer.polylines.single.points;
      expect(pts, hasLength(3));
      expect(pts[0].latitude, closeTo(43.46, 1e-9));
      expect(pts[0].longitude, closeTo(3.43, 1e-9));
      expect(pts[1].latitude, closeTo(43.47, 1e-9));
      expect(pts[1].longitude, closeTo(3.44, 1e-9));
      expect(pts[2].latitude, closeTo(43.48, 1e-9));
      expect(pts[2].longitude, closeTo(3.45, 1e-9));
    });

    testWidgets('skips samples that have one of lat / lng null',
        (tester) async {
      // Mix: some samples with both coords, some with one of the two
      // null (defensive — `TripSample` writes the pair atomically per
      // its doc, but the type still allows it). The polyline must
      // contain ONLY the fully-coord samples, in their original order.
      final samples = [
        _sample(sec: 0, lat: 43.46, lng: 3.43), // kept
        _sample(sec: 1, lat: 43.47), // dropped (lng null)
        _sample(sec: 2, lng: 3.45), // dropped (lat null)
        _sample(sec: 3, lat: 43.49, lng: 3.46), // kept
        _sample(sec: 4), // dropped (both null)
        _sample(sec: 5, lat: 43.50, lng: 3.47), // kept
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      // All kept samples are efficient (no fuel rate) → one polyline
      // covering every kept point.
      expect(layer.polylines, hasLength(1));
      final pts = layer.polylines.single.points;
      expect(pts, hasLength(3));
      expect(pts[0].latitude, closeTo(43.46, 1e-9));
      expect(pts[1].latitude, closeTo(43.49, 1e-9));
      expect(pts[2].latitude, closeTo(43.50, 1e-9));
    });

    testWidgets('renders even when only a single GPS sample is present',
        (tester) async {
      // Edge case: a very short trip with exactly one GPS fix should
      // still surface the card (the user got a fix — that's worth
      // showing) without throwing on the bounds calculation. With
      // Phase 3 there are zero segments to colour, so the polyline
      // layer is empty but the map still renders.
      final samples = [
        _sample(sec: 0, lat: 43.46, lng: 3.43),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      expect(find.byType(FlutterMap), findsOneWidget);
      final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(layer.polylines, isEmpty);
    });
  });

  group('TripPathMapCard — phase 3 heatmap', () {
    testWidgets(
        'three consecutive bucket transitions yield three coloured polylines',
        (tester) async {
      // Construct samples whose computed L/100 km lands cleanly in
      // each bucket. L/100 km = fuelRate / speed * 100.
      //   * efficient   speed=60, fuel=3.0  → 5.0  (< 6)
      //   * borderline  speed=60, fuel=4.8  → 8.0  (6 ≤ x < 10)
      //   * wasteful    speed=60, fuel=7.2  → 12.0 (≥ 10)
      // Four points → three segments → one polyline per bucket.
      final samples = [
        _sample(sec: 0, lat: 43.40, lng: 3.40, speed: 60, fuelRate: 3.0),
        _sample(sec: 1, lat: 43.41, lng: 3.41, speed: 60, fuelRate: 4.8),
        _sample(sec: 2, lat: 43.42, lng: 3.42, speed: 60, fuelRate: 7.2),
        _sample(sec: 3, lat: 43.43, lng: 3.43, speed: 60, fuelRate: 7.2),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(layer.polylines, hasLength(3));

      final ctx = tester.element(find.byType(FlutterMap));
      expect(layer.polylines[0].color, DarkModeColors.success(ctx));
      expect(layer.polylines[1].color, DarkModeColors.warning(ctx));
      expect(layer.polylines[2].color, DarkModeColors.error(ctx));
    });

    testWidgets('consecutive same-bucket segments collapse into one polyline',
        (tester) async {
      // Six samples → five segments. Bucket sequence:
      //   eff, eff, bord, bord, eff
      // → three polylines: efficient run (3 pts), borderline run
      // (3 pts), efficient run (2 pts). Adjacent runs share the
      // boundary point so the line stays visually continuous.
      final samples = [
        _sample(sec: 0, lat: 43.40, lng: 3.40, speed: 60, fuelRate: 3.0),
        _sample(sec: 1, lat: 43.41, lng: 3.41, speed: 60, fuelRate: 3.0),
        _sample(sec: 2, lat: 43.42, lng: 3.42, speed: 60, fuelRate: 4.8),
        _sample(sec: 3, lat: 43.43, lng: 3.43, speed: 60, fuelRate: 4.8),
        _sample(sec: 4, lat: 43.44, lng: 3.44, speed: 60, fuelRate: 3.0),
        _sample(sec: 5, lat: 43.45, lng: 3.45, speed: 60, fuelRate: 3.0),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(layer.polylines, hasLength(3));

      final ctx = tester.element(find.byType(FlutterMap));
      expect(layer.polylines[0].color, DarkModeColors.success(ctx));
      expect(layer.polylines[1].color, DarkModeColors.warning(ctx));
      expect(layer.polylines[2].color, DarkModeColors.success(ctx));
    });

    testWidgets(
        'samples with null fuel rate render as a single efficient polyline',
        (tester) async {
      // Legacy / partial samples (no PID 5E and no MAF fallback)
      // should NOT paint red just because fuel rate wasn't measured.
      // The classifier collapses them to efficient (green).
      final samples = [
        _sample(sec: 0, lat: 43.40, lng: 3.40, speed: 60),
        _sample(sec: 1, lat: 43.41, lng: 3.41, speed: 60),
        _sample(sec: 2, lat: 43.42, lng: 3.42, speed: 60),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(layer.polylines, hasLength(1));
      final ctx = tester.element(find.byType(FlutterMap));
      expect(layer.polylines.single.color, DarkModeColors.success(ctx));
    });

    testWidgets(
        'low-speed segments classify as efficient regardless of fuel rate',
        (tester) async {
      // Speed below 5 km/h produces a divide-by-near-zero L/100 km
      // that's meaningless for coaching (creep, idle). Lock the
      // classifier to efficient so idle / parking-lot crawl doesn't
      // show up red. Even with a high fuel rate (idling engine),
      // the segments must come back green.
      final samples = [
        _sample(sec: 0, lat: 43.40, lng: 3.40, speed: 1.0, fuelRate: 1.5),
        _sample(sec: 1, lat: 43.40001, lng: 3.40001, speed: 2.0, fuelRate: 1.5),
        _sample(sec: 2, lat: 43.40002, lng: 3.40002, speed: 3.0, fuelRate: 1.5),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(layer.polylines, hasLength(1));
      final ctx = tester.element(find.byType(FlutterMap));
      expect(layer.polylines.single.color, DarkModeColors.success(ctx));
    });

    testWidgets('single GPS sample renders zero polylines without throwing',
        (tester) async {
      // One GPS fix → zero segments → zero polylines, but FlutterMap
      // still renders so the card surfaces the start marker.
      final samples = [
        _sample(sec: 0, lat: 43.46, lng: 3.43, speed: 60, fuelRate: 5.0),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      expect(find.byType(FlutterMap), findsOneWidget);
      final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(layer.polylines, isEmpty);
    });

    testWidgets(
        'hard-acceleration events render bolt markers on top of the heatmap',
        (tester) async {
      // Two hard-accel events, both PLAUSIBLE (≤ the ~0.9 g physical ceiling
      // the #2895 clamp enforces, so GPS noise can't fabricate them but a
      // real hard launch still fires): 0 → 28 km/h in 1 s (≈ 7.78 m/s² ≈
      // 0.79 g) at the 0 → 1 boundary, and 30 → 58 km/h in 1 s (≈ 7.78 m/s²)
      // at the 4 → 5 boundary. Both above the 3.0 m/s² threshold, below the
      // ceiling. The segments between them stay calm so no other event fires.
      final samples = [
        _sample(sec: 0, lat: 43.40, lng: 3.40, speed: 0),
        _sample(sec: 1, lat: 43.41, lng: 3.41, speed: 28), // hard accel #1
        _sample(sec: 2, lat: 43.42, lng: 3.42, speed: 28),
        _sample(sec: 3, lat: 43.43, lng: 3.43, speed: 28),
        _sample(sec: 4, lat: 43.44, lng: 3.44, speed: 30),
        _sample(sec: 5, lat: 43.45, lng: 3.45, speed: 58), // hard accel #2
        _sample(sec: 6, lat: 43.46, lng: 3.46, speed: 58),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      // Two bolt icons — one per detected event.
      expect(find.byIcon(Icons.bolt), findsNWidgets(2));

      // Regression guard: the start (play_arrow) and end (flag) pins
      // are still rendered alongside the bolt overlays.
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsOneWidget);
    });

    testWidgets('no hard-acceleration events → no bolt markers',
        (tester) async {
      // Constant-speed cruise — analyzer reports zero events.
      final samples = [
        _sample(sec: 0, lat: 43.40, lng: 3.40, speed: 60),
        _sample(sec: 1, lat: 43.41, lng: 3.41, speed: 60),
        _sample(sec: 2, lat: 43.42, lng: 3.42, speed: 60),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      expect(find.byIcon(Icons.bolt), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsOneWidget);
    });

    testWidgets('legend renders the three bucket labels', (tester) async {
      // The legend must surface all three colour buckets so a user
      // can decode the heatmap without referring to docs.
      final samples = [
        _sample(sec: 0, lat: 43.46, lng: 3.43),
        _sample(sec: 1, lat: 43.47, lng: 3.44),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      expect(find.text('Efficient (< 6 L/100km)'), findsOneWidget);
      expect(find.text('Borderline (6–10 L/100km)'), findsOneWidget);
      expect(find.text('Wasteful (≥ 10 L/100km)'), findsOneWidget);
    });
  });

  group('TripPathMapCard — camera framing (#2624)', () {
    testWidgets(
        'first paint is framed by MapOptions.initialCameraFit, not a '
        'post-frame fitCamera', (tester) async {
      // #2624 — the camera is positioned during the FIRST layout pass via
      // `MapOptions.initialCameraFit`, mirroring the main map page's
      // #2398/#2399 fix. The OLD post-frame `fitCamera` jumped the camera
      // after the first tile fetch had already targeted the fallback
      // viewport, leaving grey tiles. Asserting `initialCameraFit` is
      // non-null pins the framing mechanism so a regression to the
      // post-frame fit fails here.
      final samples = [
        _sample(sec: 0, lat: 43.46, lng: 3.43),
        _sample(sec: 1, lat: 43.47, lng: 3.44),
        _sample(sec: 2, lat: 43.48, lng: 3.45),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      final flutterMap = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(flutterMap.options.initialCameraFit, isNotNull,
          reason: 'first paint must be framed via initialCameraFit so the '
              'first tile fetch targets the right viewport (no grey tiles)');
    });

    testWidgets('single-sample trip still frames via initialCameraFit',
        (tester) async {
      // Degenerate bounds (single fix) must not break the framing path —
      // `_computeBounds` synthesizes a tiny box so `CameraFit.bounds`
      // centres on the point rather than dividing by zero.
      final samples = [
        _sample(sec: 0, lat: 43.46, lng: 3.43),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      final flutterMap = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(flutterMap.options.initialCameraFit, isNotNull);
    });
  });

  group('TripPathMapCard — non-finite / degenerate guard (#3316)', () {
    testWidgets('NaN / Infinity coords are dropped, the map still builds',
        (tester) async {
      // A field export crashed MarkerLayer (Crs.checkLatLng) on a NaN
      // LatLng. The finite subset must still render, no exception thrown.
      final samples = [
        _sample(sec: 0, lat: 43.46, lng: 3.43),
        _sample(sec: 1, lat: double.nan, lng: 3.44),
        _sample(sec: 2, lat: 43.48, lng: double.infinity),
        _sample(sec: 3, lat: 43.49, lng: 3.46),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      expect(tester.takeException(), isNull);
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets(
        'all-identical points (a stationary trip) build without an infinite '
        'CameraFit zoom', (tester) async {
      // Every fix at the same coordinate → zero-span bounds → the old
      // CameraFit computed an infinite fit-zoom that _clampToNativeZoom
      // turned into Infinity.toInt() → UnsupportedError.
      final samples = [
        _sample(sec: 0, lat: 43.46, lng: 3.43),
        _sample(sec: 1, lat: 43.46, lng: 3.43),
        _sample(sec: 2, lat: 43.46, lng: 3.43),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      expect(tester.takeException(), isNull);
      expect(find.byType(FlutterMap), findsOneWidget);
    });
  });
}
