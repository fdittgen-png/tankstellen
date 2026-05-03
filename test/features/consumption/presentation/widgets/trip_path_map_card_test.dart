import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_detail_charts.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_path_map_card.dart';

import '../../../../helpers/pump_app.dart';

/// #1374 phase 2 — widget coverage for [TripPathMapCard], the
/// trip-detail card that renders the GPS-recorded route as a single-
/// colour polyline on an OpenStreetMap tile layer.
///
/// The widget is the user-visible surface of Phase 1's GPS sampling
/// work; phase 3 will swap the single colour for a per-segment
/// heatmap. These tests pin the Phase 2 contract:
///
///  * Renders the [FlutterMap] + [PolylineLayer] only when the trip
///    carries at least one fully-coord sample.
///  * Self-suppresses (returns [SizedBox.shrink]) for legacy /
///    opted-out trips so the trip-detail layout stays unchanged.
///  * The polyline points list is the in-order projection of the
///    samples that have BOTH lat and lng — half-set fixes are dropped.
TripDetailSample _sample({
  required int sec,
  double speed = 60.0,
  double? lat,
  double? lng,
}) {
  return TripDetailSample(
    timestamp: DateTime.utc(2026, 5, 3, 10, 0, sec),
    speedKmh: speed,
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
    testWidgets('polyline points match the non-null coord sequence in order',
        (tester) async {
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
      // showing) without throwing on the bounds calculation.
      final samples = [
        _sample(sec: 0, lat: 43.46, lng: 3.43),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      expect(find.byType(FlutterMap), findsOneWidget);
      final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(layer.polylines.single.points, hasLength(1));
    });
  });

  group('TripPathMapCard — polyline colour', () {
    testWidgets('polyline uses theme colorScheme.primary (Phase 2 single colour)',
        (tester) async {
      // Phase 2 specifies a single theme-driven colour. Phase 3 will
      // replace this with per-segment heatmap colours; this test
      // pins the Phase 2 contract so any accidental colour change
      // (e.g. inlining Colors.green) is caught immediately.
      final samples = [
        _sample(sec: 0, lat: 43.46, lng: 3.43),
        _sample(sec: 1, lat: 43.47, lng: 3.44),
      ];

      await pumpApp(tester, TripPathMapCard(samples: samples));

      final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      // Resolve the same primary colour the widget would have read.
      final ctx = tester.element(find.byType(FlutterMap));
      final expectedColor = Theme.of(ctx).colorScheme.primary;
      expect(layer.polylines.single.color, expectedColor);
    });
  });
}
