// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// The mocktail Mock* storage doubles are deprecated as a steering hint
// (prefer the stateful fakes) but remain sanctioned for widget tests that
// stub reads exclusively -- see test/helpers/mock_providers.dart (#3742).
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/services/country_service_registry.dart';
import 'package:tankstellen/features/search/presentation/widgets/results/summary_chip.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_summary_bar.dart';
import 'package:tankstellen/features/search/providers/radar_search_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #3957 — the summary band must be ONE line and as short as chrome can be:
/// every dp it holds is list height the results do not get.
///
/// The band's height is the assertion that matters, and it is font-safe:
/// the pills are capped, so the test font's square glyphs change the
/// TRUNCATION point, never the row count or the height.
void main() {
  /// The band with the French source, E85 and the radar owning the results
  /// — the exact configuration that wrapped onto a second line.
  Future<void> pumpRadarBand(WidgetTester tester, {double width = 412}) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final test = standardTestOverrides(country: Countries.france);
    when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
    await pumpApp(
      tester,
      const SearchSummaryBar(),
      overrides: [
        ...test.overrides,
        selectedFuelTypeOverride(FuelType.e85),
        searchRadiusOverride(25),
        // A known position, like the screenshot: the position-unknown
        // caveat pill is a different (and legitimate) fourth segment.
        userPositionOverride(lat: 43.46, lng: 3.42),
        radarSearchProvider.overrideWith(_ActiveRadar.new),
      ],
    );
  }

  group('SearchSummaryBar density (#3957)', () {
    for (final width in [412.0, 360.0]) {
      testWidgets('at ${width.toInt()} dp every segment sits on ONE row',
          (tester) async {
        await pumpRadarBand(tester, width: width);

        // The pills are centred on their row, and a glyph-only pill is
        // shorter than a text one — so the row invariant is a shared
        // vertical CENTRE, not a shared top edge.
        final centres = tester
            .widgetList<SummaryChip>(find.byType(SummaryChip))
            .map((chip) => tester.getRect(find.byWidget(chip)).center.dy)
            .toSet();
        expect(
          find.byType(SummaryChip),
          findsNWidgets(3), // source · fuel · radar
          reason: 'the fixture is the band that used to wrap',
        );
        expect(
          centres,
          hasLength(1),
          reason: 'more than one centre line means the band wrapped again',
        );
      });
    }

    testWidgets('the band is chrome-thin — one dense row, not two', (
      tester,
    ) async {
      await pumpRadarBand(tester);

      // Before #3957 this configuration was two ~28 dp rows plus 12 dp of
      // band padding. One row of dense pills fits well under 32.
      expect(tester.getSize(find.byType(SearchSummaryBar)).height,
          lessThanOrEqualTo(32));
    });

    testWidgets('the radar segment is glyph-only, and still announces the '
        'full sentence', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpRadarBand(tester);

      final radar = find.byKey(const Key('search_summary_radar'));
      expect(radar, findsOneWidget);
      expect(
        find.descendant(of: radar, matching: find.byType(Text)),
        findsNothing,
        reason: 'the glyph carries the meaning; the label would cost a line',
      );
      expect(find.byIcon(Icons.radar), findsOneWidget);
      final tooltip = tester.widget<Tooltip>(
        find.descendant(of: radar, matching: find.byType(Tooltip)),
      );
      expect(tooltip.message, 'Fuel Station Radar result');
      expect(
        tester.getSemantics(radar).label,
        contains('Fuel Station Radar result'),
      );
      handle.dispose();
    });

    testWidgets('the source pill shows the provider WITHOUT its parenthetical '
        'while the credit keeps the full name and the licence', (tester) async {
      await pumpRadarBand(tester);

      expect(find.text('Prix-Carburants'), findsOneWidget);
      expect(find.textContaining('gouv.fr'), findsNothing);

      final policy = CountryServiceRegistry.policyFor('FR')!;
      final tooltip = tester.widget<Tooltip>(
        find.ancestor(
          of: find.text('Prix-Carburants'),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, contains(policy.attribution));
      expect(tooltip.message, contains(policy.license));
    });
  });
}

class _ActiveRadar extends RadarSearch {
  @override
  RadarSearchState build() => const RadarSearchState(
        active: true,
        stations: AsyncData<List<Station>>(<Station>[]),
      );
}
