// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/fuel_type_dropdown.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';

import '../../helpers/pump_app.dart';
import 'package:tankstellen/core/utils/localized_fuel_name.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

// Every non-wildcard fuel — used to exercise the dropdown without the
// active-country filter kicking in (#703). Call sites that want the
// country filter just omit `options:`.
final _allFuels = FuelType.values.where((t) => t != FuelType.all).toList();

void main() {
  group('FuelTypeDropdown', () {
    testWidgets('shows all non-wildcard fuels by their localized label', (tester) async {
      await pumpApp(
        tester,
        FuelTypeDropdown(
          value: FuelType.e10,
          onChanged: (_) {},
          options: _allFuels,
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
          tester.element(find.byType(DropdownButtonFormField<FuelType>)));

      for (final f in _allFuels) {
        expect(find.text(localizedFuelName(l10n, f)), findsWidgets,
            reason: '${localizedFuelName(l10n, f)} must render with its localized label');
      }
      expect(find.text(localizedFuelName(l10n, FuelType.all)), findsNothing,
          reason: 'The "all" wildcard must never be pickable as a preference');
    });

    testWidgets(
        '#3198 — a stored selection missing from the catalog stays '
        'renderable instead of asserting', (tester) async {
      // e.g. an e10 preference saved before the phantom-E10 cleanup, in a
      // country whose catalog no longer offers e10.
      await pumpApp(
        tester,
        FuelTypeDropdown(
          value: FuelType.e10,
          onChanged: (_) {},
          options: const [FuelType.e5, FuelType.diesel],
        ),
      );

      final l10n = AppLocalizations.of(
          tester.element(find.byType(DropdownButtonFormField<FuelType>)));      expect(tester.takeException(), isNull);
      expect(find.text(localizedFuelName(l10n, FuelType.e10)), findsOneWidget,
          reason: 'the legacy selection must render so the user can '
              'switch to a real grade');
    });

    testWidgets('selecting a fuel fires onChanged with the FuelType',
        (tester) async {
      FuelType? picked;
      await pumpApp(
        tester,
        FuelTypeDropdown(
          value: FuelType.e10,
          onChanged: (v) => picked = v,
          options: _allFuels,
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
          tester.element(find.byType(DropdownButtonFormField<FuelType>)));
      await tester.tap(find.text(localizedFuelName(l10n, FuelType.diesel)).last);
      await tester.pumpAndSettle();

      expect(picked, FuelType.diesel);
    });
  });

  group('NullableFuelTypeDropdown', () {
    testWidgets('includes a "not set" entry plus all fuels by their localized label',
        (tester) async {
      await pumpApp(
        tester,
        NullableFuelTypeDropdown(
          value: null,
          onChanged: (_) {},
          options: _allFuels,
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<FuelType?>));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
          tester.element(find.byType(DropdownButtonFormField<FuelType?>)));

      expect(find.text('Not set'), findsWidgets);
      expect(find.text(localizedFuelName(l10n, FuelType.e10)), findsWidgets);
      expect(find.text(localizedFuelName(l10n, FuelType.electric)), findsWidgets);
    });

    testWidgets('options parameter restricts which fuels appear',
        (tester) async {
      await pumpApp(
        tester,
        NullableFuelTypeDropdown(
          value: null,
          onChanged: (_) {},
          options: const [FuelType.e5, FuelType.diesel],
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<FuelType?>));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
          tester.element(find.byType(DropdownButtonFormField<FuelType?>)));

      expect(find.text(localizedFuelName(l10n, FuelType.e5)), findsWidgets);
      expect(find.text(localizedFuelName(l10n, FuelType.diesel)), findsWidgets);
      expect(find.text(localizedFuelName(l10n, FuelType.electric)), findsNothing,
          reason: 'Restricted list must hide fuels not in [options]');
    });
  });
}
