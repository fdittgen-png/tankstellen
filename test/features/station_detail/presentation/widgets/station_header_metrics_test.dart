// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/domain/entities/brand_registry.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_brand_header.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_brand_helpers.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_header_metrics.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../fixtures/stations.dart';

/// #3902 — the compact sliver header is sized from its content, so the
/// band ends `kHeaderBottomInset` under the address instead of leaving a
/// strip of empty brand-green (the old fixed 196).
void main() {
  /// Pumps the brand header at [width] / [textScale] and returns the
  /// measured expanded height alongside the header's laid-out height.
  Future<({double expanded, double painted})> measure(
    WidgetTester tester,
    Station station, {
    double width = 360,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    double? expanded;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                expanded = stationHeaderExpandedHeight(context, station);
                // Same container shape as the sliver header: a min-height
                // Column hands the header an unbounded height, so it sizes
                // to its text (a bounded box would let the inner Column
                // expand to fill it).
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kHeaderHorizontalPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [StationBrandHeader(station: station)],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final painted = tester.getSize(find.byType(StationBrandHeader)).height;
    return (expanded: expanded!, painted: painted);
  }

  group('stationHeaderExpandedHeight (#3902)', () {
    testWidgets('budgets toolbar + status row + the painted brand header + '
        'insets — nothing more', (tester) async {
      final m = await measure(tester, testStation);
      final floor = kToolbarHeight +
          kHeaderTopGap +
          kStatusDotSize +
          kHeaderStatusGap +
          m.painted +
          kHeaderBottomInset;
      expect(m.expanded, greaterThanOrEqualTo(floor));
      // The status row is one bodyMedium line (~20 dp) — the band must not
      // reserve more than that beyond the floor (plus ceil rounding).
      expect(m.expanded, lessThan(floor + 24));
      // And it is tighter than the old fixed 196.
      expect(m.expanded, lessThan(196));
    });

    testWidgets('grows with the text scale so the header never overflows',
        (tester) async {
      final base = await measure(tester, testStation);
      final scaled = await measure(tester, testStation, textScale: 1.3);
      expect(scaled.expanded, greaterThan(base.expanded));
      expect(
        scaled.expanded,
        greaterThanOrEqualTo(
          kToolbarHeight +
              kHeaderTopGap +
              kStatusDotSize +
              kHeaderStatusGap +
              scaled.painted +
              kHeaderBottomInset,
        ),
      );
    });

    testWidgets('budgets a long address that wraps on a 320 dp phone',
        (tester) async {
      const longAddress = Station(
        id: 'de-long',
        name: 'Long',
        brand: 'JET',
        street: 'Bürgermeister-Wilhelm-Musterhausen-Allee 1234',
        postCode: '12345',
        place: 'Musterhausen-Nordwest an der Weser',
        lat: 52.5,
        lng: 13.4,
        isOpen: true,
      );
      final narrow = await measure(tester, longAddress, width: 320);
      final wide = await measure(tester, longAddress, width: 900);
      expect(narrow.expanded, greaterThan(wide.expanded),
          reason: 'the wrapped second address line must be budgeted');
      expect(
        narrow.expanded,
        greaterThanOrEqualTo(
          kToolbarHeight +
              kHeaderTopGap +
              kStatusDotSize +
              kHeaderStatusGap +
              narrow.painted +
              kHeaderBottomInset,
        ),
      );
    });

    testWidgets('budgets the "Independent station" third line',
        (tester) async {
      const independent = Station(
        id: 's-indep',
        name: 'Independent',
        brand: BrandRegistry.independentLabel,
        street: 'Some Street',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.52,
        lng: 13.40,
        isOpen: true,
      );
      final m = await measure(tester, independent);
      expect(
        m.expanded,
        greaterThanOrEqualTo(
          kToolbarHeight +
              kHeaderTopGap +
              kStatusDotSize +
              kHeaderStatusGap +
              m.painted +
              kHeaderBottomInset,
        ),
      );
    });
  });

  group('stationHeaderSubtitle', () {
    test('brand heading → street, postcode place', () {
      expect(stationHeaderSubtitle(testStation), 'Hauptstr., 10115 Berlin');
    });

    test('street heading → postcode place only', () {
      const bare = Station(
        id: 'bare',
        name: '',
        brand: '',
        street: 'Only Street',
        postCode: '00000',
        place: 'Nowhere',
        lat: 0,
        lng: 0,
        isOpen: true,
      );
      expect(stationHeaderSubtitle(bare), '00000 Nowhere');
    });

    test('nothing left → null, never an orphan comma', () {
      const nameOnly = Station(
        id: 'n',
        name: 'Only Name',
        brand: '',
        street: '',
        postCode: '',
        place: '',
        lat: 1,
        lng: 1,
        isOpen: true,
      );
      expect(stationHeaderSubtitle(nameOnly), isNull);
      const streetOnly = Station(
        id: 's',
        name: '',
        brand: '',
        street: 'Street',
        postCode: '',
        place: '',
        lat: 1,
        lng: 1,
        isOpen: true,
      );
      expect(stationHeaderSubtitle(streetOnly), isNull);
    });
  });
}
