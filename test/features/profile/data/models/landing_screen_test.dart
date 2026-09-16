// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/profile/presentation/landing_screen_l10n.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  // #4269 — the labels used to be a hard-coded 10-language table on the
  // enum, and these tests checked that table. They now check the ARB-backed
  // extension instead; the per-locale translations themselves are covered by
  // the l10n coverage gate, not here.
  group('LandingScreen persistence key', () {
    test('favorites / map / cheapest / nearest are the known values', () {
      // Guards that a future rename without updating the persistence
      // switch stays obvious. The `key` is what is written to Hive, so it
      // must never track a display string.
      expect(LandingScreen.values.map((s) => s.key).toSet(),
          {'favorites', 'map', 'cheapest', 'nearest'});
    });
  });

  group('LandingScreenL10n.label', () {
    /// Pumps a localized subtree and hands back its [AppLocalizations].
    Future<AppLocalizations> l10nFor(WidgetTester tester, Locale locale) async {
      late AppLocalizations out;
      await tester.pumpWidget(MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          out = AppLocalizations.of(context);
          return const SizedBox.shrink();
        }),
      ));
      return out;
    }

    testWidgets('every value has a non-empty label in en and de',
        (tester) async {
      for (final locale in const [Locale('en'), Locale('de')]) {
        final l10n = await l10nFor(tester, locale);
        for (final s in LandingScreen.values) {
          final label = s.label(l10n);
          expect(label, isNotEmpty,
              reason: '${s.name} has no label in ${locale.languageCode}');
          expect(label, isNot(s.key),
              reason: '${s.name} fell back to its persistence key');
        }
      }
    });

    testWidgets('labels are distinct within a locale', (tester) async {
      // Two screens sharing a label would make the dropdown ambiguous.
      for (final locale in const [Locale('en'), Locale('de')]) {
        final l10n = await l10nFor(tester, locale);
        final labels =
            LandingScreen.values.map((s) => s.label(l10n)).toSet();
        expect(labels.length, LandingScreen.values.length,
            reason: '${locale.languageCode} has ambiguous labels');
      }
    });

    testWidgets('de differs from en — the labels really are translated',
        (tester) async {
      final en = await l10nFor(tester, const Locale('en'));
      final enLabels =
          LandingScreen.values.map((s) => s.label(en)).toList();
      final de = await l10nFor(tester, const Locale('de'));
      final deLabels =
          LandingScreen.values.map((s) => s.label(de)).toList();
      expect(deLabels, isNot(enLabels));
    });
  });
}
