import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/stores/settings_hive_store.dart';
import 'package:tankstellen/features/ev/presentation/screens/ev_station_detail_screen.dart';

import '../../../../fixtures/ev_stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  setUpAll(() {
    // mocktail requires registering fallback values for any() matchers
    // against Map<String, dynamic> arguments.
    registerFallbackValue(<String, dynamic>{});
  });

  group('EV Station API key', () {
    test('default EV API key is available', () {
      expect(SettingsHiveStore.defaultEvApiKey, isNotEmpty);
      expect(SettingsHiveStore.defaultEvApiKey, contains('-'));
    });

    test('default EV API key has valid UUID format', () {
      const key = SettingsHiveStore.defaultEvApiKey;
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidRegex.hasMatch(key), isTrue);
    });
  });

  group('EvStationDetailScreen favorite toggle', () {
    testWidgets('shows outlined star when station is not favorited',
        (tester) async {
      final test = standardTestOverrides(favoriteIds: const []);
      when(() => test.mockStorage.getRatings()).thenReturn(<String, int>{});

      await pumpApp(
        tester,
        const EvStationDetailScreen(station: testEvStation),
        overrides: test.overrides,
      );

      final appBarStar = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.star_border),
      );
      expect(appBarStar, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.star),
        ),
        findsNothing,
      );
    });

    testWidgets('shows filled amber star when station is favorited',
        (tester) async {
      final test = standardTestOverrides(favoriteIds: [testEvStation.id]);
      when(() => test.mockStorage.getRatings()).thenReturn(<String, int>{});

      await pumpApp(
        tester,
        const EvStationDetailScreen(station: testEvStation),
        overrides: [
          ...test.overrides,
          isFavoriteOverride(testEvStation.id, true),
        ],
      );

      final appBarStar = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.star),
      );
      expect(appBarStar, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.star_border),
        ),
        findsNothing,
      );

      final appBarIcon = tester.widget<Icon>(appBarStar);
      expect(appBarIcon.color, Colors.amber);
    });

    testWidgets('tapping star calls toggle with rawJson containing station data',
        (tester) async {
      final test = standardTestOverrides(favoriteIds: const []);
      when(() => test.mockStorage.getRatings()).thenReturn(<String, int>{});
      when(() => test.mockStorage.addEvFavorite(any()))
          .thenAnswer((_) async {});
      // Favorites.add verifies the JSON readback succeeded (#690 guard
      // against Hive dropping payloads). The mock must mirror the write.
      final savedJson = <String, Map<String, dynamic>>{};
      when(() => test.mockStorage.saveEvFavoriteStationData(any(), any()))
          .thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        final json = invocation.positionalArguments[1] as Map<String, dynamic>;
        savedJson[id] = json;
      });
      when(() => test.mockStorage.getEvFavoriteStationData(any()))
          .thenAnswer((invocation) =>
              savedJson[invocation.positionalArguments[0] as String]);

      await pumpApp(
        tester,
        const EvStationDetailScreen(station: testEvStation),
        overrides: test.overrides,
      );

      await tester.tap(find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.star_border),
      ));
      await tester.pump();

      // Route 1: EV-prefixed ID goes to EV storage (not fuel).
      verify(() => test.mockStorage.addEvFavorite(testEvStation.id))
          .called(1);

      // Route 2: station JSON is persisted so the favorites tab can render it.
      verify(() => test.mockStorage.saveEvFavoriteStationData(
            testEvStation.id,
            testEvStation.toJson(),
          )).called(1);
    });

    testWidgets('never routes EV station to fuel storage', (tester) async {
      final test = standardTestOverrides(favoriteIds: const []);
      when(() => test.mockStorage.getRatings()).thenReturn(<String, int>{});
      when(() => test.mockStorage.addEvFavorite(any()))
          .thenAnswer((_) async {});
      final savedJson = <String, Map<String, dynamic>>{};
      when(() => test.mockStorage.saveEvFavoriteStationData(any(), any()))
          .thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        final json = invocation.positionalArguments[1] as Map<String, dynamic>;
        savedJson[id] = json;
      });
      when(() => test.mockStorage.getEvFavoriteStationData(any()))
          .thenAnswer((invocation) =>
              savedJson[invocation.positionalArguments[0] as String]);

      await pumpApp(
        tester,
        const EvStationDetailScreen(station: testEvStation),
        overrides: test.overrides,
      );

      await tester.tap(find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.star_border),
      ));
      await tester.pump();

      // Fuel storage must never be touched for ocm- IDs; this was the #552 bug.
      verifyNever(() => test.mockStorage.addFavorite(any()));
      verifyNever(() => test.mockStorage.saveFavoriteStationData(any(), any()));
    });

    testWidgets('tooltip reflects favorite state', (tester) async {
      final test = standardTestOverrides(favoriteIds: const []);
      when(() => test.mockStorage.getRatings()).thenReturn(<String, int>{});

      await pumpApp(
        tester,
        const EvStationDetailScreen(station: testEvStation),
        overrides: test.overrides,
      );

      // Not favorited → "Add to favorites"
      expect(find.byTooltip('Add to favorites'), findsOneWidget);

      // Re-pump with favorited override
      await tester.pumpWidget(const SizedBox());
      await pumpApp(
        tester,
        const EvStationDetailScreen(station: testEvStation),
        overrides: [
          ...test.overrides,
          isFavoriteOverride(testEvStation.id, true),
        ],
      );

      expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    });
  });
}
