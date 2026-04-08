import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/presentation/widgets/all_prices_station_card.dart';
import 'package:tankstellen/features/search/presentation/widgets/sort_selector.dart';
import 'package:tankstellen/features/search/presentation/widgets/station_card.dart';
import 'package:tankstellen/features/search/presentation/widgets/user_position_bar.dart';

import '../fixtures/stations.dart';
import '../helpers/mock_providers.dart';
import '../helpers/pump_app.dart';

/// Verifies that key widgets render without overflow at 1.5x and 2.0x
/// text scaling, covering the accessibility requirement from issue #76.
///
/// The tests do NOT assert pixel-perfect layout — they verify that
/// Flutter's layout engine does not report overflow errors when text
/// is scaled up, which would manifest as yellow/black striped bars
/// on real devices.
void main() {
  // ─── StationCard ─────────────────────────────────────────────
  group('StationCard text scaling', () {
    for (final scale in [1.5, 2.0]) {
      testWidgets('renders without overflow at ${scale}x', (tester) async {
        await pumpScaledApp(
          tester,
          const SingleChildScrollView(
            child: StationCard(
              station: testStation,
              selectedFuelType: FuelType.e10,
              isFavorite: true,
              isCheapest: false,
            ),
          ),
          textScaleFactor: scale,
        );

        // If overflow occurs, Flutter logs an error — tester.takeException
        // would catch it. We also verify the widget tree built successfully.
        expect(find.byType(StationCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders with isCheapest badge at ${scale}x',
          (tester) async {
        await pumpScaledApp(
          tester,
          const SingleChildScrollView(
            child: StationCard(
              station: testStation,
              selectedFuelType: FuelType.diesel,
              isCheapest: true,
            ),
          ),
          textScaleFactor: scale,
        );

        expect(find.byType(StationCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders all-prices mode at ${scale}x', (tester) async {
        await pumpScaledApp(
          tester,
          const SingleChildScrollView(
            child: StationCard(
              station: testStation,
              selectedFuelType: FuelType.all,
            ),
          ),
          textScaleFactor: scale,
        );

        expect(find.byType(StationCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders closed station at ${scale}x', (tester) async {
        final closedStation = testStationList[2]; // isOpen: false

        await pumpScaledApp(
          tester,
          SingleChildScrollView(
            child: StationCard(
              station: closedStation,
              selectedFuelType: FuelType.e5,
            ),
          ),
          textScaleFactor: scale,
        );

        expect(find.byType(StationCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  // ─── AllPricesStationCard ────────────────────────────────────
  group('AllPricesStationCard text scaling', () {
    for (final scale in [1.5, 2.0]) {
      testWidgets('renders without overflow at ${scale}x', (tester) async {
        await pumpScaledApp(
          tester,
          const SingleChildScrollView(
            child: AllPricesStationCard(
              station: testStation,
              isFavorite: true,
            ),
          ),
          textScaleFactor: scale,
        );

        expect(find.byType(AllPricesStationCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  // ─── SortSelector ───────────────────────────────────────────
  group('SortSelector text scaling', () {
    for (final scale in [1.5, 2.0]) {
      testWidgets('renders without overflow at ${scale}x', (tester) async {
        await pumpScaledApp(
          tester,
          SortSelector(
            selected: SortMode.price,
            onChanged: (_) {},
          ),
          textScaleFactor: scale,
        );

        expect(find.byType(SortSelector), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  // ─── UserPositionBar (with position) ─────────────────────────
  group('UserPositionBar text scaling', () {
    for (final scale in [1.5, 2.0]) {
      testWidgets('renders with known position at ${scale}x',
          (tester) async {
        await pumpScaledApp(
          tester,
          UserPositionBar(onUpdatePosition: () {}),
          textScaleFactor: scale,
          overrides: [
            userPositionOverride(lat: 52.52, lng: 13.405),
          ],
        );

        expect(find.byType(UserPositionBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders with unknown position at ${scale}x',
          (tester) async {
        await pumpScaledApp(
          tester,
          UserPositionBar(onUpdatePosition: () {}),
          textScaleFactor: scale,
          overrides: [
            userPositionNullOverride(),
          ],
        );

        expect(find.byType(UserPositionBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  // ─── Station list (multiple cards) ───────────────────────────
  group('Station list text scaling', () {
    for (final scale in [1.5, 2.0]) {
      testWidgets('renders multiple station cards at ${scale}x',
          (tester) async {
        await pumpScaledApp(
          tester,
          ListView(
            children: testStationList
                .map((s) => StationCard(
                      station: s,
                      selectedFuelType: FuelType.e10,
                    ))
                .toList(),
          ),
          textScaleFactor: scale,
        );

        expect(find.byType(StationCard), findsNWidgets(testStationList.length));
        expect(tester.takeException(), isNull);
      });
    }
  });

  // ─── FavoritesScreen empty state ──────────────────────────────
  group('Favorites empty state text scaling', () {
    for (final scale in [1.5, 2.0]) {
      testWidgets('renders empty favorites hint at ${scale}x',
          (tester) async {
        // Simulate the empty-favorites UI (icon + two text widgets)
        await pumpScaledApp(
          tester,
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_outline, size: 64),
                SizedBox(height: 16),
                Text(
                  'No favorites yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Tap the star on a station to save it as a favorite.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          textScaleFactor: scale,
        );

        expect(find.text('No favorites yet'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  // ─── Settings-style list tiles ────────────────────────────────
  group('Settings list tile text scaling', () {
    for (final scale in [1.5, 2.0]) {
      testWidgets('renders typical settings tiles at ${scale}x',
          (tester) async {
        await pumpScaledApp(
          tester,
          ListView(
            children: const [
              ListTile(
                leading: Icon(Icons.language),
                title: Text('Language'),
                subtitle: Text('English'),
                trailing: Icon(Icons.chevron_right),
              ),
              ListTile(
                leading: Icon(Icons.palette),
                title: Text('Theme'),
                subtitle: Text('System default'),
                trailing: Icon(Icons.chevron_right),
              ),
              SwitchListTile(
                value: true,
                onChanged: null,
                title: Text('Show prices in notification'),
                subtitle: Text('Display current fuel prices'),
                secondary: Icon(Icons.notifications),
              ),
              ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('About'),
                subtitle: Text('Version 4.1.0'),
              ),
            ],
          ),
          textScaleFactor: scale,
        );

        // SwitchListTile internally contains a ListTile, so 4 total
        expect(find.byType(ListTile), findsNWidgets(4));
        expect(find.byType(SwitchListTile), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
