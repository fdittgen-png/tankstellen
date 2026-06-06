// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/proximity_fill_bar.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_content.dart';
import 'package:tankstellen/features/search/providers/radar_search_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #2956 — root-cause pinning regression for the Fuel Station Radar "closeness"
/// bar. The recurring field bug: the distance TEXT is correct but the closeness
/// BAR under every station is ~the same length (it does not scale with
/// distance) — because the bar scaled to the static `searchRadiusProvider`
/// slider (up to 25 km), which is decoupled from where the stations actually
/// are, so every fill compressed toward 1.0.
///
/// These tests drive the REAL radar list-card path (`SearchResultsContent` →
/// `SearchResultsList` → `StationCard` → `ProximityFillBar`) with the exact
/// screenshot distances (265 m, 9.3 km, 9.9 km, 10.0 km) and the field's 25 km
/// slider, then read the fill the rendered bar would paint. RED on master (the
/// far bars cluster at ~0.60–0.63, indistinguishable); green after the fix
/// (scaled to the result span: nearest ~0.97, farthest 0.0).

/// The four radar results from the field screenshot, distance-ranked.
/// `dist` is kilometres (the same value the card distance text shows).
List<Station> _screenshotStations() => const [
      Station(
        id: 'fr-pezenas',
        name: 'Pézenas Carburant',
        brand: '',
        street: '1 route de Béziers',
        postCode: '34120',
        place: 'Pézenas',
        lat: 43.46,
        lng: 3.42,
        dist: 0.265, // 265 m
        e85: 0.789,
        isOpen: true,
      ),
      Station(
        id: 'fr-intermarche',
        name: 'Intermarché',
        brand: 'Intermarché',
        street: 'Avenue de Verdun',
        postCode: '34120',
        place: 'Pézenas',
        lat: 43.49,
        lng: 3.45,
        dist: 9.3,
        e85: 0.799,
        isOpen: true,
      ),
      Station(
        id: 'fr-superu-essence',
        name: 'Station Essence Super U',
        brand: 'Super U',
        street: 'Route de Pézenas',
        postCode: '34630',
        place: 'Saint-Thibéry',
        lat: 43.50,
        lng: 3.41,
        dist: 9.9,
        e85: 0.805,
        isOpen: true,
      ),
      Station(
        id: 'fr-superu',
        name: 'Super U',
        brand: 'Super U',
        street: 'Avenue de la Gare',
        postCode: '34630',
        place: 'Saint-Thibéry',
        lat: 43.51,
        lng: 3.40,
        dist: 10.0,
        e85: 0.809,
        isOpen: true,
      ),
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
/// straight off the widget the real card path built (its `distanceMeters` +
/// `radiusMeters`), via the SAME shared helper the widget uses. This is NOT a
/// hand-rolled value: it is exactly what the surface displays.
double _renderedFillFor(WidgetTester tester, Station station) {
  // Anchor on the per-row key the radar list assigns each card
  // (`station-{id}` in search_results_list), then read THIS card's bar.
  final card = find.byKey(ValueKey('station-${station.id}'));
  expect(card, findsOneWidget,
      reason: 'the radar list must render a card for ${station.id}');
  final bar = tester.widget<ProximityFillBar>(
    find.descendant(of: card, matching: find.byType(ProximityFillBar)),
  );
  // Guard: the bar must be wired to THIS station's distance.
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
      // The field's WIDE slider (25 km) relative to the 10 km result span —
      // the condition under which the old code compressed every bar.
      searchRadiusOverride(radiusKm),
    ].cast(),
  );
  await tester.pump();
}

void main() {
  // The pure helper arithmetic + never-throws contract are pinned in
  // test/core/utils/radar_closeness_test.dart. This file pins the REAL radar
  // list-card surface end-to-end (the regression lock) + the shared-helper
  // invariant across all three radar surfaces.
  group('radar list-card closeness bar — the real surface (#2956)', () {
    testWidgets(
        'scales to the result span: nearest near-full, farthest empty '
        '(NOT the 25 km slider that compressed every bar)', (tester) async {
      await _pumpRadar(
        tester,
        stations: _screenshotStations(),
        radiusKm: 25.0, // the field's WIDE slider
      );

      final stations = _screenshotStations();
      final near = _renderedFillFor(tester, stations[0]); // 265 m
      final mid = _renderedFillFor(tester, stations[1]); // 9.3 km
      final farish = _renderedFillFor(tester, stations[2]); // 9.9 km
      final far = _renderedFillFor(tester, stations[3]); // 10.0 km

      // Pinned to the result-span scale (farthest = 10 km), NOT the 25 km
      // slider. These are the values the bar actually paints.
      expect(near, closeTo(0.9735, 1e-3),
          reason: '265 m of a 10 km span → ~0.97 (nearly full)');
      expect(mid, closeTo(0.07, 1e-3), reason: '9.3 km of 10 km → ~0.07');
      expect(farish, closeTo(0.01, 1e-3), reason: '9.9 km of 10 km → ~0.01');
      expect(far, closeTo(0.0, 1e-6), reason: '10.0 km = the span edge → empty');

      // The core regression lock: the bars must be VISIBLY DIFFERENT down the
      // list. On master (scaled to the 25 km slider) the three far rows all sat
      // at ~0.60–0.63 — indistinguishable — which is the reported symptom.
      expect(near - far, greaterThan(0.9),
          reason: 'closest vs farthest must differ by nearly a full bar');
      expect(mid - far, greaterThan(0.05),
          reason: 'mid vs far must be clearly distinct, not a compressed band');
      // Strictly monotonic: closer ⇒ fuller.
      expect(near, greaterThan(mid));
      expect(mid, greaterThan(farish));
      expect(farish, greaterThan(far));
    });

    testWidgets('every result row renders exactly one closeness bar',
        (tester) async {
      await _pumpRadar(
        tester,
        stations: _screenshotStations(),
        radiusKm: 25.0,
      );
      expect(
        find.byType(ProximityFillBar),
        findsNWidgets(_screenshotStations().length),
      );
    });
  });

  // #2956 — guard against a future re-divergence. The patch-pile recurred
  // partly because each surface re-derived the fill independently; one shared
  // helper closes that. Pin it structurally: the ProximityFillBar (the widget
  // every surface renders) must compute the fill via [RadarCloseness], and no
  // radar surface may re-implement the `1 - distance/radius` arithmetic inline.
  group('shared-helper invariant (#2956)', () {
    File srcFile(String relative) {
      final f = File(relative);
      expect(f.existsSync(), isTrue, reason: 'missing $relative');
      return f;
    }

    test('ProximityFillBar delegates its fill to RadarCloseness', () {
      final bar = srcFile(
        'lib/features/consumption/presentation/widgets/proximity_fill_bar.dart',
      ).readAsStringSync();
      expect(bar.contains('RadarCloseness.fillFor'), isTrue,
          reason: 'the bar must delegate the fill formula to the shared helper');
    });

    test('no radar surface re-implements the fill arithmetic inline', () {
      // The naked formula `1 - <dist> / <radius>` must live ONLY in
      // RadarCloseness. A re-introduced inline copy on any surface is exactly
      // how the bar desynced before.
      final formula = RegExp(r'1\.0?\s*-\s*\(?\s*\w*[Dd]istance');
      const consumption = 'lib/features/consumption/presentation/widgets';
      const search = 'lib/features/search/presentation/widgets';
      final paths = <String>[
        '$search/station_card_status.dart',
        '$search/search_results_list.dart',
        '$consumption/trip_radar_card.dart',
        '$consumption/trip_recording_pip_price_layout.dart',
        '$consumption/proximity_fill_bar.dart',
      ];
      for (final path in paths) {
        expect(formula.hasMatch(srcFile(path).readAsStringSync()), isFalse,
            reason: '$path must use RadarCloseness, not an inline fill formula');
      }
    });
  });
}
