// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/utils/radar_closeness.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/proximity_fill_bar.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_content.dart';
import 'package:tankstellen/features/search/providers/radar_search_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #2984 — the Fuel Station Radar list closeness bar uses an ABSOLUTE,
/// FIXED-SCALE model: the maintainer rejected the relative-to-span model of
/// #2959 (root-cause reimplementation of #2956).
///
/// "How close is THIS station, on a stable absolute scale" — fuller = closer:
///
/// ```
/// scale = min(searchRadiusMeters, kRadarClosenessScaleCapMeters)
/// fill  = clamp(1 - distanceMeters / scale, 0, 1)
/// ```
///
/// These tests drive the REAL radar list-card path (`SearchResultsContent` →
/// `SearchResultsList` → `StationCard` → `ProximityFillBar`) with the radar
/// active and read the fill the rendered bar would paint. The crux is the
/// STABILITY property: a near station reads the SAME fill no matter what else
/// is in the list. On master (the span model) removing the far station changes
/// the near fill → RED; with the absolute scale → IDENTICAL → GREEN.

/// A radar station at [distKm] from the user (km — the value the card text
/// shows). Carries an E10 price so the fuel filter keeps it.
Station _at(String id, double distKm) => Station(
      id: id,
      name: 'Station $id',
      brand: '',
      street: '$id street',
      postCode: '00000',
      place: 'Town',
      lat: 43.0 + distKm / 100.0,
      lng: 3.0,
      dist: distKm,
      e10: 1.799,
      isOpen: true,
    );

/// The four-station validation set: 2.5 / 7.2 / 10.3 / 13 km.
List<Station> _fourStations() => [
      _at('s-2', 2.5),
      _at('s-7', 7.2),
      _at('s-10', 10.3),
      _at('s-13', 13.0),
    ];

class _ActiveRadar extends RadarSearch {
  _ActiveRadar(this._stations);
  final List<Station> _stations;

  @override
  RadarSearchState build() => RadarSearchState(
        active: true,
        stations: AsyncData<List<Station>>(_stations),
      );
}

/// The fill the rendered [ProximityFillBar] for [station] would paint — read
/// straight off the widget the real card path built. Not a hand-rolled value:
/// exactly what the surface displays.
double _renderedFillFor(WidgetTester tester, Station station) {
  final card = find.byKey(ValueKey('station-${station.id}'));
  expect(card, findsOneWidget,
      reason: 'the radar list must render a card for ${station.id}');
  final bar = tester.widget<ProximityFillBar>(
    find.descendant(of: card, matching: find.byType(ProximityFillBar)),
  );
  expect(bar.distanceMeters, closeTo(station.dist * 1000.0, 1e-6),
      reason: 'the bar must use station.dist (the same value the text shows)');
  return ProximityFillBar.fillFor(bar.distanceMeters, bar.radiusMeters!);
}

Future<void> _pumpRadar(
  WidgetTester tester, {
  required List<Station> stations,
  required double radiusKm,
}) async {
  final test = standardTestOverrides();
  when(() => test.mockStorage.hasApiKey()).thenReturn(false);
  when(() => test.mockStorage.getIgnoredIds()).thenReturn(<String>[]);
  when(() => test.mockStorage.getRatings()).thenReturn(const <String, int>{});

  await pumpApp(
    tester,
    SearchResultsContent(onGpsRetry: () async {}),
    overrides: [
      ...test.overrides,
      userPositionNullOverride(),
      radarSearchProvider.overrideWith(() => _ActiveRadar(stations)),
      searchRadiusOverride(radiusKm),
    ].cast(),
  );
  await tester.pump();
}

void main() {
  group('radar list closeness bar — ABSOLUTE fixed scale (#2984)', () {
    // The configured radius (20 km) exceeds the 15 km cap, so the scale is the
    // 15 km cap for every station regardless of the result set.
    const radiusKm = 20.0;
    final scaleMeters =
        math.min(radiusKm * 1000.0, kRadarClosenessScaleCapMeters);

    testWidgets('fill is strictly DECREASING with distance (closer = fuller)',
        (tester) async {
      await _pumpRadar(tester, stations: _fourStations(), radiusKm: radiusKm);

      final s = _fourStations();
      final f2 = _renderedFillFor(tester, s[0]); // 2.5 km
      final f7 = _renderedFillFor(tester, s[1]); // 7.2 km
      final f10 = _renderedFillFor(tester, s[2]); // 10.3 km
      final f13 = _renderedFillFor(tester, s[3]); // 13 km

      expect(f2, greaterThan(f7));
      expect(f7, greaterThan(f10));
      expect(f10, greaterThan(f13));
    });

    testWidgets(
        'STABILITY: the 2.5 km fill is IDENTICAL with or without the 13 km '
        'station (scale depends on the radius + cap, NOT the result set)',
        (tester) async {
      // With the far (13 km) station present.
      await _pumpRadar(tester, stations: _fourStations(), radiusKm: radiusKm);
      final withFar = _renderedFillFor(tester, _at('s-2', 2.5));

      // Fully tear down the first tree so the second pump renders a fresh
      // list (a bare second pumpWidget reuses the element tree).
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      // Without it: drop the 13 km outlier; the near station must NOT move.
      final withoutFarSet = _fourStations()..removeLast();
      await _pumpRadar(tester, stations: withoutFarSet, radiusKm: radiusKm);
      final withoutFar = _renderedFillFor(tester, _at('s-2', 2.5));

      expect(withoutFar, closeTo(withFar, 1e-9),
          reason: 'an absolute scale must give the SAME near fill regardless '
              'of whether a far station is in the list — on the span model '
              'removing the far station changes the near fill');
    });

    testWidgets('the farthest station is NOT 0% (only nears empty near the '
        'scale, never force-emptied)', (tester) async {
      // 2.5 & 7.2 km: the farthest (7.2 km) reads ~52%, not empty — on the
      // span model the farthest (the span edge) is pinned to 0%.
      await _pumpRadar(
        tester,
        stations: [_at('s-2', 2.5), _at('s-7', 7.2)],
        radiusKm: radiusKm,
      );
      final far = _renderedFillFor(tester, _at('s-7', 7.2));
      expect(far, greaterThan(0.4),
          reason: '7.2 km of a 15 km scale ≈ 0.52 — clearly NOT empty');
      expect(far, closeTo(0.52, 1e-3));
    });

    testWidgets('the exact fills match the absolute formula for the '
        'configured radius (scale = min(radius, cap))', (tester) async {
      await _pumpRadar(tester, stations: _fourStations(), radiusKm: radiusKm);

      final s = _fourStations();
      for (final station in s) {
        final expected =
            RadarCloseness.fillFor(station.dist * 1000.0, scaleMeters);
        expect(_renderedFillFor(tester, station), closeTo(expected, 1e-6),
            reason: 'station ${station.id} (${station.dist} km) must read the '
                'absolute fill for scale ${scaleMeters / 1000} km');
      }

      // The worked examples (scale = 15 km): ~83%, ~52%, ~31%, ~13%.
      expect(_renderedFillFor(tester, s[0]), closeTo(0.8333, 1e-3));
      expect(_renderedFillFor(tester, s[1]), closeTo(0.52, 1e-3));
      expect(_renderedFillFor(tester, s[2]), closeTo(0.3133, 1e-3));
      expect(_renderedFillFor(tester, s[3]), closeTo(0.1333, 1e-3));
    });
  });
}
