import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_detail_app_bar_actions.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('StationDetailAppBarActions', () {
    testWidgets('renders the five action buttons with tooltips',
        (tester) async {
      await pumpApp(
        tester,
        const StationDetailAppBarActions(
          stationId: '51d4b477-a095-1aa0-e100-80009459e03a',
          station: testStation,
        ),
        overrides: [
          favoritesOverride(const []),
          isFavoriteOverride('51d4b477-a095-1aa0-e100-80009459e03a', false),
        ],
      );

      // Five icon buttons: directions, alert, scan QR, report, favorite.
      expect(find.byIcon(Icons.directions), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
      // Favorite is an AnimatedFavoriteStar — assert the un-favorited
      // border icon is present.
      expect(find.byIcon(Icons.star_border), findsWidgets);
    });

    testWidgets('shows filled star when station is favorited',
        (tester) async {
      await pumpApp(
        tester,
        const StationDetailAppBarActions(
          stationId: '51d4b477-a095-1aa0-e100-80009459e03a',
          station: testStation,
        ),
        overrides: [
          favoritesOverride(const ['51d4b477-a095-1aa0-e100-80009459e03a']),
          isFavoriteOverride(
              '51d4b477-a095-1aa0-e100-80009459e03a', true),
        ],
      );

      // Favorited -> filled star icon.
      expect(find.byIcon(Icons.star), findsWidgets);
    });
  });
}
