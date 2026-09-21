// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card_price_column.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_presentation.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/pump_app.dart';

/// #4133 — one derivation for what a station row shows.
///
/// The search list, the route list and the favourites list each used to
/// re-derive price, discount, currency, brand fallback and the #4124 fuel
/// label. That is how #4124 happened: the label had a caller once, lost it
/// in a refactor, and no other surface noticed for months.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('StationPresentation.of', () {
    test('titles by brand, then name, then the localized fallback', () {
      expect(
        StationPresentation.of(testStation,
                selectedFuelType: FuelType.e10, l10n: l10n)
            .title,
        'STAR',
      );

      const noBrand = Station(
        id: 'x', name: 'Chez Martin', brand: '', street: 'R',
        postCode: '1', place: 'P', lat: 48.85, lng: 2.35,
      );
      final named = StationPresentation.of(noBrand,
          selectedFuelType: FuelType.e10, l10n: l10n);
      expect(named.title, 'Chez Martin');
      expect(named.hasBrand, isFalse,
          reason: 'a name is not a brand — the mark must stay absent');
      expect(named.brandMark, isNull);

      // #2926 — the street is NEVER promoted to the title; it is the
      // address line below, and promoting it read as a duplicate.
      const nothing = Station(
        id: 'y', name: '', brand: '', street: '26 AVENUE DE VERDUN',
        postCode: '1', place: 'P', lat: 48.85, lng: 2.35,
      );
      expect(
        StationPresentation.of(nothing,
                selectedFuelType: FuelType.e10, l10n: l10n)
            .title,
        isNot(contains('VERDUN')),
      );
    });

    test('applies a loyalty discount once, and keeps the raw price', () {
      final p = StationPresentation.of(
        testStation,
        selectedFuelType: FuelType.e10,
        // Keyed by CANONICAL brand: 'STAR' resolves to 'Orlen' (the
        // rebrand), which is exactly why the lookup canonicalizes rather
        // than matching the raw API spelling.
        activeDiscountsByBrand: const {'Orlen': 0.05},
        l10n: l10n,
      );

      expect(p.rawPrice, 1.799);
      expect(p.price, closeTo(1.749, 1e-9));
      expect(p.hasDiscount, isTrue);
    });

    test('floors a nonsense discount instead of rendering a negative', () {
      final p = StationPresentation.of(
        testStation,
        selectedFuelType: FuelType.e10,
        activeDiscountsByBrand: const {'Orlen': 99},
        l10n: l10n,
      );
      expect(p.price, 0.001);
    });

    group('the #4124 substituted-fuel label', () {
      StationPresentation label(FuelType selected, FuelType? requested) =>
          StationPresentation.of(testStation,
              selectedFuelType: selected,
              requestedFuelType: requested,
              l10n: l10n);

      test('names the fuel when it is not the one asked for', () {
        expect(label(FuelType.e5, FuelType.e85).substitutedFuelLabel, 'E5');
      });

      test('says nothing when the price IS what was asked for', () {
        expect(label(FuelType.e10, FuelType.e10).substitutedFuelLabel, isNull);
      });

      test('says nothing on a list that never substitutes', () {
        expect(label(FuelType.e5, null).substitutedFuelLabel, isNull);
      });

      test('says nothing under a wildcard search', () {
        // "Any fuel" already expects whatever the forecourt sells, so a
        // label would sit on every row and mean nothing on any of them.
        expect(label(FuelType.e5, FuelType.all).substitutedFuelLabel, isNull);
      });

      test('says nothing when there is no number to qualify', () {
        const noPrice = Station(
          id: 'z', name: 'N', brand: 'STAR', street: 'R',
          postCode: '1', place: 'P', lat: 52.52, lng: 13.405,
        );
        expect(
          StationPresentation.of(noPrice,
                  selectedFuelType: FuelType.e5,
                  requestedFuelType: FuelType.e85,
                  l10n: l10n)
              .substitutedFuelLabel,
          isNull,
        );
      });

      test('uses the station country\'s own pump name (#2717)', () {
        const mx = Station(
          id: 'mx-1', name: 'PEMEX', brand: 'PEMEX', street: 'Av',
          postCode: '06500', place: 'CDMX', lat: 19.4326, lng: -99.1332,
          e5: 23.49,
        );
        expect(
          StationPresentation.of(mx,
                  selectedFuelType: FuelType.e5,
                  requestedFuelType: FuelType.diesel,
                  l10n: l10n)
              .substitutedFuelLabel,
          'Magna',
        );
      });
    });
  });

  group('every surface agrees', () {
    // The assertion #4124 lacked. The search list, the route list and the
    // favourites list build a StationCard with different arguments; for
    // the same station and fuel they must still show the same row.
    testWidgets('the same station renders the same title and price wherever '
        'it appears', (tester) async {
      await pumpApp(
        tester,
        const Column(
          children: [
            // search-list shape
            StationCard(station: testStation, selectedFuelType: FuelType.e10),
            // route-list shape: priced by the station's own country fuel
            StationCard(
              station: testStation,
              selectedFuelType: FuelType.e10,
              requestedFuelType: FuelType.e10,
            ),
            // favourites shape
            StationCard(
              station: testStation,
              selectedFuelType: FuelType.e10,
              isFavorite: true,
            ),
          ],
        ),
      );

      expect(find.text('STAR'), findsNWidgets(3));

      // One derivation, three surfaces. The price is rendered as a
      // RichText span (superscript tenths), so compare the derived values
      // rather than the glyphs — that is the thing that used to drift.
      final rows = tester
          .widgetList<StationCardHeadlineRow>(
              find.byType(StationCardHeadlineRow))
          .toList();
      expect(rows, hasLength(3));
      final first = rows.first.presentation;
      for (final row in rows.skip(1)) {
        expect(row.presentation.price, first.price);
        expect(row.presentation.rawPrice, first.rawPrice);
        expect(row.presentation.title, first.title);
        expect(row.presentation.currencySymbol, first.currencySymbol);
        expect(row.presentation.substitutedFuelLabel,
            first.substitutedFuelLabel);
      }
    });
  });
}
