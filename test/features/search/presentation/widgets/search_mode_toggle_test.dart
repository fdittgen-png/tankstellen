// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/search_mode.dart';
import 'package:tankstellen/features/search/presentation/widgets/search_mode_toggle.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

void main() {
  group('SearchModeToggle', () {
    Future<void> pumpToggle(
      WidgetTester tester, {
      required SearchMode mode,
      required ValueChanged<SearchMode> onChanged,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SearchModeToggle(mode: mode, onChanged: onChanged),
          ),
        ),
      );
    }

    testWidgets('renders both Nearby and Along route segments', (tester) async {
      await pumpToggle(tester, mode: SearchMode.nearby, onChanged: (_) {});
      expect(find.text('Nearby stations'), findsOneWidget);
      expect(find.text('Search along route'), findsOneWidget);
    });

    testWidgets('selecting the route segment invokes onChanged(route)', (
      tester,
    ) async {
      SearchMode? captured;
      await pumpToggle(
        tester,
        mode: SearchMode.nearby,
        onChanged: (m) => captured = m,
      );
      await tester.tap(find.text('Search along route'));
      await tester.pumpAndSettle();
      expect(captured, SearchMode.route);
    });

    testWidgets('selecting the nearby segment invokes onChanged(nearby)', (
      tester,
    ) async {
      SearchMode? captured;
      await pumpToggle(
        tester,
        mode: SearchMode.route,
        onChanged: (m) => captured = m,
      );
      await tester.tap(find.text('Nearby stations'));
      await tester.pumpAndSettle();
      expect(captured, SearchMode.nearby);
    });

    testWidgets('initial mode is reflected in the segmented button selection', (
      tester,
    ) async {
      await pumpToggle(tester, mode: SearchMode.route, onChanged: (_) {});
      final button = tester.widget<SegmentedButton<SearchMode>>(
        find.byType(SegmentedButton<SearchMode>),
      );
      expect(button.selected, {SearchMode.route});
    });
  });
}
