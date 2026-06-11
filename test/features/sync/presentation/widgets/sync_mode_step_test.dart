// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/sync_config.dart';
import 'package:tankstellen/features/sync/presentation/widgets/sync_mode_step.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('SyncModeStep', () {
    Future<void> pumpStep(
      WidgetTester tester, {
      required ValueChanged<SyncMode> onSelectMode,
      required VoidCallback onStayOffline,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SyncModeStep(
              onSelectMode: onSelectMode,
              onStayOffline: onStayOffline,
            ),
          ),
        ),
      );
    }

    testWidgets('renders three sync mode cards + stay-offline button', (
      tester,
    ) async {
      await pumpStep(tester, onSelectMode: (_) {}, onStayOffline: () {});

      expect(find.text('Sparkilo Community'), findsOneWidget);
      expect(find.text('Private Database'), findsOneWidget);
      expect(find.text('Join a Group'), findsOneWidget);
      expect(find.text('Stay offline'), findsOneWidget);
    });

    testWidgets('tapping community card invokes onSelectMode(community)', (
      tester,
    ) async {
      SyncMode? captured;
      await pumpStep(
        tester,
        onSelectMode: (mode) => captured = mode,
        onStayOffline: () {},
      );

      await tester.tap(find.text('Sparkilo Community'));
      await tester.pump();

      expect(captured, SyncMode.community);
    });

    testWidgets('tapping private card invokes onSelectMode(private)', (
      tester,
    ) async {
      SyncMode? captured;
      await pumpStep(
        tester,
        onSelectMode: (mode) => captured = mode,
        onStayOffline: () {},
      );

      await tester.tap(find.text('Private Database'));
      await tester.pump();

      expect(captured, SyncMode.private);
    });

    testWidgets('tapping join card invokes onSelectMode(joinExisting)', (
      tester,
    ) async {
      SyncMode? captured;
      await pumpStep(
        tester,
        onSelectMode: (mode) => captured = mode,
        onStayOffline: () {},
      );

      await tester.tap(find.text('Join a Group'));
      await tester.pump();

      expect(captured, SyncMode.joinExisting);
    });

    testWidgets('tapping stay-offline invokes onStayOffline', (tester) async {
      var called = false;
      await pumpStep(
        tester,
        onSelectMode: (_) {},
        onStayOffline: () => called = true,
      );

      await tester.tap(find.text('Stay offline'));
      await tester.pump();

      expect(called, isTrue);
    });
  });
}
