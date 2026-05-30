// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/features/setup/presentation/widgets/country_selector.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('CountrySelector', () {
    Future<void> pumpSelector(
      WidgetTester tester, {
      required CountryConfig selected,
      required ValueChanged<CountryConfig> onSelect,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: CountrySelector(
                selected: selected,
                onSelect: onSelect,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders one ChoiceChip per verified country',
        (tester) async {
      await pumpSelector(
        tester,
        selected: Countries.verified.first,
        onSelect: (_) {},
      );
      // #1828 — the picker offers only verified countries, not every
      // registered one.
      expect(
        find.byType(ChoiceChip),
        findsNWidgets(Countries.verified.length),
      );
    });

    testWidgets('marks the chip matching `selected` as selected',
        (tester) async {
      const germany = Countries.germany;
      await pumpSelector(
        tester,
        selected: germany,
        onSelect: (_) {},
      );
      final selectedChip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('${germany.flag} ${germany.name}'),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(selectedChip.selected, isTrue);
    });

    testWidgets('forwards taps to onSelect with the chosen country',
        (tester) async {
      CountryConfig? captured;
      // Pick a verified country that is NOT the first one so we know
      // the tap changed the selection.
      final target = Countries.verified.firstWhere(
        (c) => c.code != Countries.verified.first.code,
      );
      await pumpSelector(
        tester,
        selected: Countries.verified.first,
        onSelect: (c) => captured = c,
      );
      await tester.ensureVisible(find.text('${target.flag} ${target.name}'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('${target.flag} ${target.name}'));
      expect(captured?.code, target.code);
    });

    testWidgets(
        'announces selected state via the Semantics label so screen '
        'readers know which country is active', (tester) async {
      await pumpSelector(
        tester,
        selected: Countries.germany,
        onSelect: (_) {},
      );
      expect(
        find.bySemanticsLabel(
          RegExp('Country ${Countries.germany.name}, selected'),
        ),
        findsAtLeast(1),
      );
    });
  });
}
