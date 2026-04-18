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
    testWidgets('renders 10 data rows — one per data category',
        (tester) async {
      await pumpApp(tester, LocalDataCard(snapshot: _snapshot()));
      // 10 categories: favorites, ignored, ratings, alerts,
      // priceHistory, profiles, itineraries, cache, hasApiKey,
      // hasEvApiKey.
      expect(find.byType(PrivacyDataRow), findsNWidgets(10));
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
      // Both a "Yes" and a "No" row should be present.
      expect(find.text('Yes'), findsOneWidget);
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

    testWidgets('category icons are all present', (tester) async {
      await pumpApp(tester, LocalDataCard(snapshot: _snapshot()));
      // Pinned icons = the visual contract for the dashboard.
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
