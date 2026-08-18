// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/pinned_save_bar.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('PinnedSaveBar', () {
    Future<void> pumpBar(
      WidgetTester tester, {
      required VoidCallback onSave,
      IconData icon = Icons.save,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: const SizedBox.shrink(),
            bottomNavigationBar: PinnedSaveBar(onSave: onSave, icon: icon),
          ),
        ),
      );
    }

    testWidgets('renders the Save CTA with the given icon and fires onSave',
        (tester) async {
      var saved = 0;
      await pumpBar(
        tester,
        onSave: () => saved++,
        icon: Icons.save_outlined,
      );
      expect(find.byIcon(Icons.save_outlined), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(saved, 1);
    });

    testWidgets('defaults to the filled save icon', (tester) async {
      await pumpBar(tester, onSave: () {});
      expect(find.byIcon(Icons.save), findsOneWidget);
    });
  });
}
