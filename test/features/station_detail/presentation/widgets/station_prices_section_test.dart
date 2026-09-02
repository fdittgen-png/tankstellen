// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/profile/domain/entities/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/price_tile.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_prices_section.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/pump_app.dart';

class _NullActiveProfile extends ActiveProfile {
  @override
  UserProfile? build() => null;
}

/// A French forecourt that sells everything but Super E5 — the shape of the
/// #3902 screenshot ("Super E5  --" rendered as a grey row).
const _noE5 = Station(
  id: 'fr-34550001',
  name: 'Intermarché',
  brand: '',
  street: 'Route St Thibéry',
  postCode: '34550',
  place: 'Bessan',
  lat: 43.36,
  lng: 3.40,
  dist: 7.2,
  e10: 2.089,
  diesel: 2.209,
  e98: 2.199,
  e85: 0.839,
  lpg: 1.069,
  isOpen: true,
);

void main() {
  final overrides = <Object>[
    activeProfileProvider.overrideWith(() => _NullActiveProfile()),
  ];

  group('StationPricesSection', () {
    testWidgets('renders the prices header and the base-fuel tiles',
        (tester) async {
      await pumpApp(
        tester,
        const StationPricesSection(station: testStation),
        overrides: overrides,
      );

      // The localized "Prices" header should be present.
      expect(find.text('Prices'), findsOneWidget);
      // Each of the three base fuel types must render as a PriceTile.
      expect(find.text('Super E5'), findsOneWidget);
      expect(find.text('Super E10'), findsOneWidget);
      expect(find.text('Diesel'), findsOneWidget);
      // The "Log fill-up" CTA must render (locale = en -> "Add fill-up").
      expect(find.text('Add fill-up'), findsOneWidget);
      // Every base fuel is priced → no "not sold here" footnote.
      expect(find.byKey(const ValueKey('prices-not-sold-here')), findsNothing);
    });

    testWidgets(
        '#3902 an unpriced base fuel is hidden from the list and named once '
        'in the "Not sold here" footnote', (tester) async {
      await pumpApp(
        tester,
        const StationPricesSection(station: _noE5),
        overrides: overrides,
      );

      // No grey "Super E5  --" tile.
      expect(
        find.descendant(
          of: find.byType(PriceTile),
          matching: find.text('Super E5'),
        ),
        findsNothing,
      );
      expect(find.text('--'), findsNothing);
      // The priced fuels are all there, in order.
      expect(find.byType(PriceTile), findsNWidgets(5));
      for (final label in ['Super E10', 'Diesel', 'Super 98', 'E85', 'LPG']) {
        expect(find.text(label), findsOneWidget);
      }
      // The footnote names the missing base fuel.
      expect(find.byKey(const ValueKey('prices-not-sold-here')),
          findsOneWidget);
      expect(find.text('Not sold here: Super E5'), findsOneWidget);
    });

    testWidgets('#3902 several missing base fuels are comma-joined',
        (tester) async {
      const dieselOnly = Station(
        id: 'de-1',
        name: 'Diesel only',
        brand: 'JET',
        street: 'Hauptstr.',
        postCode: '10115',
        place: 'Berlin',
        lat: 52.5,
        lng: 13.4,
        diesel: 1.65,
        isOpen: true,
      );
      await pumpApp(
        tester,
        const StationPricesSection(station: dieselOnly),
        overrides: overrides,
      );

      expect(find.byType(PriceTile), findsOneWidget);
      expect(find.text('Not sold here: Super E5, Super E10'), findsOneWidget);
    });

    testWidgets('#3902 the footnote is localised (fr / de)', (tester) async {
      await pumpApp(
        tester,
        const StationPricesSection(station: _noE5),
        overrides: overrides,
        locale: const Locale('fr'),
      );
      expect(find.text('Non vendu ici : Super E5'), findsOneWidget);

      await pumpApp(
        tester,
        const StationPricesSection(station: _noE5),
        overrides: overrides,
        locale: const Locale('de'),
      );
      expect(find.text('Hier nicht angeboten: Super E5'), findsOneWidget);
    });

    testWidgets('#3902 an absent OPTIONAL fuel is neither listed nor named',
        (tester) async {
      // testStation has no 98 / E85 / LPG / CNG price — none of those may
      // show up as "not sold" (that would be noise on every forecourt).
      await pumpApp(
        tester,
        const StationPricesSection(station: testStation),
        overrides: overrides,
      );
      expect(find.text('Super 98'), findsNothing);
      expect(find.text('LPG'), findsNothing);
      expect(find.byKey(const ValueKey('prices-not-sold-here')), findsNothing);
    });
  });
}
