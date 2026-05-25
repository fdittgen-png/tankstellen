// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/presentation/widgets/privacy_dashboard/local_data_card.dart';
import 'package:tankstellen/features/profile/presentation/widgets/privacy_dashboard/privacy_data_row.dart';
import 'package:tankstellen/features/profile/providers/privacy_data_provider.dart';

import '../../../../../helpers/pump_app.dart';

PrivacyDataSnapshot _snapshot({
  int favorites = 0,
  int ignored = 0,
  int ratings = 0,
  int alerts = 0,
  int priceHistory = 0,
  int profiles = 1,
  int cache = 0,
  int itineraries = 0,
  bool hasApiKey = false,
  bool hasEvApiKey = false,
  int bytes = 1024,
}) =>
    PrivacyDataSnapshot(
      favoritesCount: favorites,
      ignoredCount: ignored,
      ratingsCount: ratings,
      alertsCount: alerts,
      priceHistoryStationCount: priceHistory,
      profileCount: profiles,
      cacheEntryCount: cache,
      itineraryCount: itineraries,
      hasApiKey: hasApiKey,
      hasEvApiKey: hasEvApiKey,
      syncEnabled: false,
      syncMode: null,
      syncUserId: null,
      estimatedTotalBytes: bytes,
    );

void main() {
  group('LocalDataCard', () {
    testWidgets(
      '#1529 — hides zero-value rows by default; shows non-empty ones only',
      (tester) async {
        // Snapshot: only profiles=1 is non-empty. The 9 other rows are
        // 0 / No and must collapse out of the dashboard.
        await pumpApp(tester, LocalDataCard(snapshot: _snapshot()));

        expect(find.byType(PrivacyDataRow), findsOneWidget,
            reason: 'Only the non-zero "Search profiles" row should render '
                'when every other category is empty.');
        // The "Show N empty rows" toggle must surface so the user can
        // still inspect the full list.
        expect(
          find.byKey(const Key('privacyShowAllRowsToggle')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '#1529 — tapping the show-all toggle reveals every category row',
      (tester) async {
        await pumpApp(tester, LocalDataCard(snapshot: _snapshot()));
        await tester.tap(find.byKey(const Key('privacyShowAllRowsToggle')));
        await tester.pumpAndSettle();
        // 10 categories total — all visible after expand.
        expect(find.byType(PrivacyDataRow), findsNWidgets(10));
      },
    );

    testWidgets('renders all 10 rows when no value is empty', (tester) async {
      await pumpApp(
        tester,
        LocalDataCard(
          snapshot: _snapshot(
            favorites: 12,
            ignored: 3,
            ratings: 7,
            alerts: 2,
            priceHistory: 5,
            profiles: 2,
            cache: 87,
            itineraries: 4,
            hasApiKey: true,
            hasEvApiKey: true,
          ),
        ),
      );
      expect(find.byType(PrivacyDataRow), findsNWidgets(10));
      // No toggle when nothing is hidden.
      expect(
        find.byKey(const Key('privacyShowAllRowsToggle')),
        findsNothing,
      );
    });

    testWidgets('each category count surfaces in a row', (tester) async {
      await pumpApp(
        tester,
        LocalDataCard(
          snapshot: _snapshot(
            favorites: 12,
            ignored: 3,
            ratings: 7,
            alerts: 2,
            priceHistory: 5,
            profiles: 2,
            cache: 87,
            itineraries: 4,
          ),
        ),
      );
      expect(find.text('12'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // profiles = 2, alerts = 2
      expect(find.text('5'), findsOneWidget);
      expect(find.text('87'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('API key rows show Yes/No text based on hasApiKey flags',
        (tester) async {
      await pumpApp(
        tester,
        LocalDataCard(
          snapshot: _snapshot(hasApiKey: true, hasEvApiKey: false),
        ),
      );
      // hasApiKey=true → "Yes" row visible by default. hasEvApiKey=false
      // → "No" row hidden behind the show-all toggle.
      expect(find.text('Yes'), findsOneWidget);
      // Reveal the hidden empty rows to verify the No appears too.
      await tester.tap(find.byKey(const Key('privacyShowAllRowsToggle')));
      await tester.pumpAndSettle();
      expect(find.text('No'), findsOneWidget);
    });

    testWidgets('title bar carries phone_android icon + bold title',
        (tester) async {
      await pumpApp(tester, LocalDataCard(snapshot: _snapshot()));
      expect(find.byIcon(Icons.phone_android), findsOneWidget);

      final title = tester.widget<Text>(find.text('Data on this device'));
      expect(title.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('footer shows the human-readable total size',
        (tester) async {
      await pumpApp(
        tester,
        LocalDataCard(snapshot: _snapshot(bytes: 2048)),
      );
      // formatBytes(2048) = "2.0 KB" (exact formatting is owned by
      // the storage_bar helper; we just assert it surfaces).
      expect(find.textContaining('Estimated storage'), findsOneWidget);
      expect(find.textContaining('KB'), findsOneWidget);
    });

    testWidgets('category icons are all present after expand',
        (tester) async {
      await pumpApp(tester, LocalDataCard(snapshot: _snapshot()));
      // Default view hides empty rows (and their icons). Expand to
      // verify the visual contract still holds for the full list.
      await tester.tap(find.byKey(const Key('privacyShowAllRowsToggle')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.byIcon(Icons.show_chart), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.route), findsOneWidget);
      expect(find.byIcon(Icons.cached), findsOneWidget);
      expect(find.byIcon(Icons.key), findsOneWidget);
      expect(find.byIcon(Icons.ev_station), findsOneWidget);
    });
  });
}
