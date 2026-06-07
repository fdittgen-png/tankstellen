// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/utils/radar_closeness.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/proximity_fill_bar.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_results_content.dart';
import 'package:tankstellen/features/search/providers/radar_search_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #2995 — the Fuel Station Radar list closeness bar scales to the APPROACH
/// RADIUS (`profile.approachRadiusKm * 1000`), the SAME base the RECORDING radar
/// card + PiP use. This REVERSES #2984/#2985: the maintainer decided the
/// recording radar (approach-radius base) is correct and the list (which #2985
/// scaled to `min(searchRadius, 15 km cap)`) was wrong.
///
/// "How close is THIS station, on the user's approach-radius base" — fuller =
/// closer:
///
/// ```
/// scale = profile.approachRadiusKm * 1000   // identical on list + recording + PiP
/// fill  = clamp(1 - distanceMeters / scale, 0, 1)
/// ```
///
/// These tests drive the REAL radar list-card path (`SearchResultsContent` →
/// `SearchResultsList` → `StationCard` → `ProximityFillBar`) with the radar
/// active and read the fill the rendered bar would paint. The crux: the list's
/// resolved `radiusMeters` is the approach radius (3 km for a 3 km profile),
/// NOT the 15 km list scale (RED on master) — so a 2.5 km station reads ~0.17,
/// matching the recording radar, and a station beyond the approach radius reads
/// ~0 (only stations within reach show a fill, by design).

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
/// card test (`trip_radar_card_test.dart`) uses.
class _StubActiveProfile extends ActiveProfile {
  _StubActiveProfile(this._profile);
  final UserProfile? _profile;
  @override
  UserProfile? build() => _profile;
}

ProximityFillBar _renderedBarFor(WidgetTester tester, Station station) {
  final card = find.byKey(ValueKey('station-${station.id}'));
  expect(card, findsOneWidget,
      reason: 'the radar list must render a card for ${station.id}');
  return tester.widget<ProximityFillBar>(
    find.descendant(of: card, matching: find.byType(ProximityFillBar)),
  );
}

/// The fill the rendered [ProximityFillBar] for [station] would paint — read
/// straight off the widget the real card path built. Not a hand-rolled value:
/// exactly what the surface displays.
double _renderedFillFor(WidgetTester tester, Station station) {
  final bar = _renderedBarFor(tester, station);
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
  group('radar list closeness bar — APPROACH-RADIUS scale (#2995)', () {
    const approachRadiusKm = 3.0; // the 3 km base the recording radar uses

    testWidgets(
        'the bar scales to the APPROACH radius (3 km), NOT the 15 km list '
        'scale or the search slider', (tester) async {
      await _pumpRadar(
        tester,
        stations: [_at('s-2', 2.5)],
        approachRadiusKm: approachRadiusKm,
      );

      final bar = _renderedBarFor(tester, _at('s-2', 2.5));
      // RED on master: master resolved `listScaleMeters(searchRadius*1000)`,
      // up to the 15 km cap (15000). The fix wires it to approachRadiusKm*1000.
      expect(bar.radiusMeters, 3000.0,
          reason: 'the list must scale to the approach radius (3 km → 3000 m), '
              'identical to the recording radar — NOT 15000 / the slider');
    });

    testWidgets('a 2.5 km station reads ~0.17 (was ~0.83 on the 15 km scale)',
        (tester) async {
      await _pumpRadar(
        tester,
        stations: [_at('s-2', 2.5)],
        approachRadiusKm: approachRadiusKm,
      );

      // 1 - 2.5/3 ≈ 0.1667 — matching the recording radar. On master (15 km
      // scale) this read 1 - 2.5/15 ≈ 0.83.
      expect(_renderedFillFor(tester, _at('s-2', 2.5)), closeTo(0.1667, 1e-3));
    });

    testWidgets(
        'a station BEYOND the approach radius (5 km of a 3 km radius) reads ~0 '
        '(only stations within reach show a fill, by design)', (tester) async {
      await _pumpRadar(
        tester,
        stations: [_at('s-5', 5.0)],
        approachRadiusKm: approachRadiusKm,
      );

      expect(_renderedFillFor(tester, _at('s-5', 5.0)), closeTo(0.0, 1e-9),
          reason: '5 km is past the 3 km approach radius → clamped to empty');
    });

    testWidgets(
        'CONSISTENCY: the list resolves the SAME radiusMeters as the recording '
        'card for the same profile (both profile.approachRadiusKm * 1000)',
        (tester) async {
      await _pumpRadar(
        tester,
        stations: [_at('s-2', 2.5)],
        approachRadiusKm: approachRadiusKm,
      );

      final bar = _renderedBarFor(tester, _at('s-2', 2.5));
      // The recording card computes exactly `profile.approachRadiusKm * 1000.0`
      // (trip_radar_card.dart). The list must match it bit-for-bit.
      const recordingCardRadiusMeters = approachRadiusKm * 1000.0;
      expect(bar.radiusMeters, recordingCardRadiusMeters,
          reason: 'list + recording radar must share the approach-radius base');
      // …and therefore paint the identical fill for the same distance.
      expect(
        ProximityFillBar.fillFor(bar.distanceMeters, bar.radiusMeters!),
        closeTo(
          RadarCloseness.fillFor(2500.0, recordingCardRadiusMeters),
          1e-9,
        ),
      );
    });

    testWidgets('fill is strictly DECREASING with distance (closer = fuller)',
        (tester) async {
      // All within the 3 km approach radius so each carries a non-zero fill.
      final near = _at('near', 0.5);
      final mid = _at('mid', 1.5);
      final edge = _at('edge', 2.7);
      await _pumpRadar(
        tester,
        stations: [near, mid, edge],
        approachRadiusKm: approachRadiusKm,
      );

      final fNear = _renderedFillFor(tester, near);
      final fMid = _renderedFillFor(tester, mid);
      final fEdge = _renderedFillFor(tester, edge);

      expect(fNear, greaterThan(fMid));
      expect(fMid, greaterThan(fEdge));
    });
  });
}
