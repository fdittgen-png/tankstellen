// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/proximity_fill_bar.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_content.dart';
import 'package:tankstellen/features/search/providers/radar_search_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #2956/#2995 — root-cause pinning regression for the Fuel Station Radar
/// "closeness" bar. The recurring field bug: the distance TEXT is correct but
/// the closeness BAR under every station is ~the same length (it does not scale
/// with distance).
///
/// The bar scales to the user's APPROACH RADIUS (`profile.approachRadiusKm *
/// 1000`) — the SAME base the recording radar card + PiP use (#2995 brought the
/// list onto this base, reversing the `min(searchRadius, 15 km cap)` list scale
/// of #2984/#2985). So a wide search slider no longer stretches the list scale,
/// the bars stay visibly different down the list, and a near station reads the
/// SAME fill it would on the recording radar.
///
/// These tests drive the REAL radar list-card path (`SearchResultsContent` →
/// `SearchResultsList` → `StationCard` → `ProximityFillBar`) with stations
/// inside the approach radius, then read the fill the rendered bar would paint.

/// Four radar results within a 3 km approach radius, distance-ranked. `dist` is
/// kilometres (the same value the card distance text shows).
List<Station> _stations() => const [
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
        dist: 1.2,
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
        dist: 2.0,
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
        dist: 2.7,
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

/// Feeds a fixed profile into [activeProfileProvider] so the list bar's
/// approach-radius scale is deterministic — the SAME stub shape the recording
/// card test uses.
class _StubActiveProfile extends ActiveProfile {
  _StubActiveProfile(this._profile);
  final UserProfile? _profile;
  @override
  UserProfile? build() => _profile;
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
  required double approachRadiusKm,
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
      activeProfileProvider.overrideWith(
        () => _StubActiveProfile(
          UserProfile(
            id: 'p1',
            name: 'Test',
            approachRadiusKm: approachRadiusKm,
          ),
        ),
      ),
    ].cast(),
  );
  await tester.pump();
}

void main() {
  // The pure helper arithmetic + never-throws contract are pinned in
  // test/core/utils/radar_closeness_test.dart. This file pins the REAL radar
  // list-card surface end-to-end (the regression lock) + the shared-helper
  // invariant across all three radar surfaces.
  group('radar list-card closeness bar — the real surface (#2995)', () {
    testWidgets(
        'scales to the APPROACH radius (3 km): nearest near-full, the rows '
        'visibly spread down the list (closer = fuller)', (tester) async {
      await _pumpRadar(
        tester,
        stations: _stations(),
        approachRadiusKm: 3.0,
      );

      final stations = _stations();
      final near = _renderedFillFor(tester, stations[0]); // 265 m
      final mid = _renderedFillFor(tester, stations[1]); // 1.2 km
      final farish = _renderedFillFor(tester, stations[2]); // 2.0 km
      final far = _renderedFillFor(tester, stations[3]); // 2.7 km

      // Pinned to the 3 km approach radius — the SAME base the recording radar
      // uses. These are the values the bar actually paints; none force-emptied.
      expect(near, closeTo(0.9117, 1e-3),
          reason: '265 m of a 3 km scale → ~0.91 (nearly full)');
      expect(mid, closeTo(0.6, 1e-3), reason: '1.2 km of 3 km → 0.6');
      expect(farish, closeTo(0.3333, 1e-3), reason: '2.0 km of 3 km → ~0.33');
      expect(far, closeTo(0.1, 1e-3),
          reason: '2.7 km of 3 km → 0.1 (NOT empty — within reach)');

      // The core regression lock: the bars must be VISIBLY DIFFERENT down the
      // list, not a compressed band clustered near 1.0.
      expect(near - far, greaterThan(0.6),
          reason: 'closest vs farthest must differ by most of the bar');
      expect(mid - far, greaterThan(0.04),
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
        stations: _stations(),
        approachRadiusKm: 3.0,
      );
      expect(
        find.byType(ProximityFillBar),
        findsNWidgets(_stations().length),
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
