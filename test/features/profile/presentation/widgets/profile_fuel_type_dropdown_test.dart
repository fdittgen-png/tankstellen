// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/core/country/country_provider.dart';
import 'package:tankstellen/features/profile/presentation/widgets/profile_fuel_type_dropdown.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Override the active country to France so the dropdown includes
/// enough fuels to exercise the "not all" + "at least E5/diesel"
/// assertions. #703 made the picker country-aware.
class _FixedFrance extends ActiveCountry {
  @override
  CountryConfig build() => Countries.france;
}

void main() {
  group('ProfileFuelTypeDropdown', () {
    Future<void> pumpDropdown(
      WidgetTester tester, {
      required FuelType value,
      ValueChanged<FuelType>? onChanged,
      // #4304 — the delegates were always installed; only the locale was
      // missing, so every assertion here was implicitly English.
      Locale locale = const Locale('en'),
    }) {
      return tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeCountryProvider.overrideWith(() => _FixedFrance()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            home: Scaffold(
              body: ProfileFuelTypeDropdown(
                value: value,
                onChanged: onChanged ?? (_) {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders the localized name of the selected fuel type',
        (tester) async {
      await pumpDropdown(tester, value: FuelType.e10);
      // #4304 — the ARB string the widget renders. It happens to equal
      // FuelType.e10.displayName, which is exactly why this assertion
      // alone cannot police the label's provenance; the German case
      // below is the one that can.
      expect(find.text('Super E10'), findsOneWidget);
    });

    testWidgets('opening the menu lists every FuelType except `all`',
        (tester) async {
      await pumpDropdown(tester, value: FuelType.e10);
      await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
      await tester.pumpAndSettle();

      // #4304 — the wildcard must not be OFFERED, asserted on the menu's
      // values rather than on text. The old check searched for
      // `FuelType.all.displayName` (the literal "All"), a string this
      // dropdown never renders under any circumstances — so it could not
      // fail, and tested nothing its comment claimed.
      final offered = tester
          .widgetList<DropdownMenuItem<FuelType>>(
            find.byType(DropdownMenuItem<FuelType>),
          )
          .map((i) => i.value)
          .toSet();
      expect(offered, isNot(contains(FuelType.all)),
          reason: 'the search-time wildcard is not a profile preference');

      // A few real fuel types should appear in the open menu, spelled as
      // the ARB strings the widget renders.
      expect(find.text('Super E5'), findsAtLeast(1));
      expect(find.text('Diesel'), findsAtLeast(1));
    });

    testWidgets('forwards selection to onChanged when user picks a new fuel',
        (tester) async {
      FuelType? captured;
      await pumpDropdown(
        tester,
        value: FuelType.e10,
        onChanged: (v) => captured = v,
      );
      await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
      await tester.pumpAndSettle();
      // .last is the menu entry (the field label is .first).
      await tester.tap(find.text('Diesel').last);
      await tester.pumpAndSettle();
      expect(captured, FuelType.diesel);
    });

    testWidgets('renders the reader\'s language, not displayName (#4304)',
        (tester) async {
      await pumpDropdown(
        tester,
        value: FuelType.lpg,
        locale: const Locale('de'),
      );

      // lpg is the probe. German says `Autogas (LPG)`; FuelType.displayName
      // says `GPL / LPG`, a French/English hybrid. For e5/e10/e98/diesel the
      // ARB string and displayName are byte-identical, so every other
      // assertion in this file passes whichever one the widget uses — which
      // is why none of them could detect #4283's fix regressing here.
      expect(find.text('Autogas (LPG)'), findsOneWidget);
      expect(find.text('GPL / LPG'), findsNothing);
    });
  });
}
