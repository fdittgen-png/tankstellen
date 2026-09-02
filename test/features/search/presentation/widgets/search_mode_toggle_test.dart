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

    testWidgets('renders both Nearby and Route segments with SHORT labels', (
      tester,
    ) async {
      await pumpToggle(tester, mode: SearchMode.nearby, onChanged: (_) {});
      // #3927 — the visible labels are the short ones; the long sentences
      // stay on the segment tooltips so nothing is lost.
      expect(find.text('Nearby'), findsOneWidget);
      expect(find.text('Route'), findsOneWidget);
      expect(find.text('Nearby stations'), findsNothing);
      expect(find.text('Search along route'), findsNothing);
      final button = tester.widget<SegmentedButton<SearchMode>>(
        find.byType(SegmentedButton<SearchMode>),
      );
      expect(
        button.segments.map((s) => s.tooltip),
        ['Nearby stations', 'Search along route'],
      );
    });

    testWidgets('#3927 — segment labels never wrap', (tester) async {
      await pumpToggle(tester, mode: SearchMode.nearby, onChanged: (_) {});
      for (final label in const ['Nearby', 'Route']) {
        final text = tester.widget<Text>(find.text(label));
        expect(text.maxLines, 1, reason: '$label must stay on one line');
        expect(text.softWrap, isFalse);
        expect(text.overflow, TextOverflow.ellipsis);
      }
    });

    testWidgets('#3927 — icons are dropped, never the words, when the '
        'toggle is squeezed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 180,
                child: SearchModeToggle(
                  mode: SearchMode.nearby,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.near_me), findsNothing);
      expect(find.byIcon(Icons.route), findsNothing);
      expect(find.text('Nearby'), findsOneWidget);
      expect(find.text('Route'), findsOneWidget);
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
      await tester.tap(find.text('Route'));
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
      await tester.tap(find.text('Nearby'));
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
