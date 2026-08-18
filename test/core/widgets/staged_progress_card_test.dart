// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/staged_progress_card.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('StagedProgressCard', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      String label = 'Connecting…',
      Object stageKey = 1,
      VoidCallback? onCancel,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StagedProgressCard(
              cardKey: const Key('staged_card'),
              icon: Icons.bluetooth_searching,
              label: label,
              stageKey: stageKey,
              onCancel: onCancel,
              cancelKey: const Key('staged_cancel'),
            ),
          ),
        ),
      );
    }

    testWidgets('renders icon, label and an indeterminate progress bar',
        (tester) async {
      await pumpCard(tester);
      expect(find.byKey(const Key('staged_card')), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth_searching), findsOneWidget);
      expect(find.text('Connecting…'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('hides the cancel button when onCancel is null',
        (tester) async {
      await pumpCard(tester);
      expect(find.byKey(const Key('staged_cancel')), findsNothing);
    });

    testWidgets('shows the cancel button and fires onCancel', (tester) async {
      var cancelled = 0;
      await pumpCard(tester, onCancel: () => cancelled++);
      await tester.tap(find.byKey(const Key('staged_cancel')));
      expect(cancelled, 1);
    });
  });
}
