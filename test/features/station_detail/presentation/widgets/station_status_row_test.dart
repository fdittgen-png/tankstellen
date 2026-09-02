// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/search/providers/station_rating_provider.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_status_row.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

ServiceResult<dynamic> _result({DateTime? fetchedAt}) {
  return ServiceResult(
    data: const Object(),
    source: ServiceSource.tankerkoenigApi,
    fetchedAt:
        fetchedAt ?? DateTime.now().subtract(const Duration(seconds: 10)),
  );
}

Station _station({bool? isOpen = true}) {
  return Station(
    id: 'st-1',
    name: 'Test',
    brand: 'JET',
    street: 'Hauptstr.',
    houseNumber: '12',
    postCode: '10115',
    place: 'Berlin',
    lat: 52.5,
    lng: 13.4,
    dist: 1.0,
    e5: 1.79,
    e10: 1.74,
    diesel: 1.65,
    isOpen: isOpen,
  );
}

/// Test stub for the keep-alive [StationRatings] notifier so we can seed
/// the rating without touching real Hive storage.
class _FakeStationRatings extends StationRatings {
  _FakeStationRatings(this._initial);
  final Map<String, int> _initial;
  @override
  Map<String, int> build() => _initial;
}

void main() {
  group('StationStatusRow', () {
    Future<void> pumpRow(
      WidgetTester tester, {
      required Station station,
      required ServiceResult<dynamic> serviceResult,
      int? rating,
      Locale locale = const Locale('en'),
    }) {
      final ratings = <String, int>{};
      if (rating != null) ratings[station.id] = rating;
      return tester.pumpWidget(
        ProviderScope(
          overrides: [
            stationRatingsProvider.overrideWith(
              () => _FakeStationRatings(ratings),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            home: Scaffold(
              body: StationStatusRow(
                station: station,
                serviceResult: serviceResult,
                stationId: station.id,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders the open status text when station is open', (
      tester,
    ) async {
      await pumpRow(
        tester,
        station: _station(isOpen: true),
        serviceResult: _result(),
      );
      expect(find.text('Open · updated < 1 min ago'), findsOneWidget);
    });

    testWidgets('renders the closed status text when station is closed', (
      tester,
    ) async {
      await pumpRow(
        tester,
        station: _station(isOpen: false),
        serviceResult: _result(),
      );
      expect(find.text('Closed · updated < 1 min ago'), findsOneWidget);
    });

    testWidgets('#3198 unknown open state renders the neutral wording', (
      tester,
    ) async {
      await pumpRow(
        tester,
        station: _station(isOpen: null),
        serviceResult: _result(),
      );
      expect(find.text('Unknown · updated < 1 min ago'), findsOneWidget);
    });

    // #3902 — the phrase used to be glued together from word fragments
    // ("$status — $freshness $ago"), which put the French "il y a" AFTER
    // the duration: "Ouvert — < 1 min il y a". One parameterised key per
    // locale now owns the word order.
    testWidgets('#3902 French puts "il y a" before the duration', (
      tester,
    ) async {
      await pumpRow(
        tester,
        station: _station(isOpen: true),
        serviceResult: _result(),
        locale: const Locale('fr'),
      );
      expect(find.text('Ouvert · mis à jour il y a < 1 min'), findsOneWidget);
      expect(find.textContaining('min il y a'), findsNothing,
          reason: 'the old fragment order must not come back');
    });

    testWidgets('#3902 German phrase reads "aktualisiert vor …"', (
      tester,
    ) async {
      await pumpRow(
        tester,
        station: _station(isOpen: true),
        serviceResult: _result(),
        locale: const Locale('de'),
      );
      expect(
        find.text('Geöffnet · aktualisiert vor < 1 min'),
        findsOneWidget,
      );
    });

    testWidgets('#3902 the status text stays on one line (ellipsis)', (
      tester,
    ) async {
      await pumpRow(
        tester,
        station: _station(isOpen: true),
        serviceResult: _result(),
      );
      final text = tester.widget<Text>(
        find.text('Open · updated < 1 min ago'),
      );
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });

    testWidgets('shows 5 star icons when a rating is present', (tester) async {
      await pumpRow(
        tester,
        station: _station(),
        serviceResult: _result(),
        rating: 4,
      );
      // Total icons = 1 status dot Container (not Icon) + 4 filled stars +
      // 1 outline star = 5 Icons.
      final filled = find.byIcon(Icons.star);
      final empty = find.byIcon(Icons.star_border);
      expect(filled, findsNWidgets(4));
      expect(empty, findsNWidgets(1));
    });

    testWidgets('hides star row when no rating is present', (tester) async {
      await pumpRow(
        tester,
        station: _station(),
        serviceResult: _result(),
        rating: null,
      );
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });
  });
}
