// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/search/providers/station_rating_provider.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_status_row.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// The instant every assertion is measured from, so which freshness band
/// the stamp falls in is a decision of this file and not of the wall
/// clock. Mid-month Wednesday, per the AppClock guidance.
final _now = DateTime(2026, 9, 16, 14, 30);

Station _station({bool? isOpen = true, String? updatedAt}) {
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
    updatedAt: updatedAt ??
        _now.subtract(const Duration(minutes: 10)).toIso8601String(),
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
            appClockProvider.overrideWithValue(FixedClock(_now)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            home: Scaffold(
              body: StationStatusRow(
                station: station,
                stationId: station.id,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('#4092 availability and price freshness are TWO facts, '
        'never one phrase', (tester) async {
      await pumpRow(tester, station: _station(isOpen: true));

      // Availability on its own …
      expect(find.text('Open'), findsOneWidget);
      // … price age on its own, in words.
      expect(find.byKey(const Key('station_detail_freshness_word')),
          findsOneWidget);
      expect(find.text('Fresh price'), findsOneWidget);
      // … and nothing that glues them into a single claim.
      expect(find.textContaining('Open · updated'), findsNothing,
          reason: 'one green sentence claimed the forecourt was open AND '
              'the price current; a reader could not tell which the '
              'colour belonged to');
    });

    testWidgets('#4092 the two facts carry SEPARATE colours', (tester) async {
      await pumpRow(
        tester,
        station: _station(
          isOpen: true,
          // Older than the stale threshold: the price is an attention
          // state while the forecourt is perfectly open.
          updatedAt:
              _now.subtract(const Duration(days: 9)).toIso8601String(),
        ),
      );
      final ctx = tester.element(find.byType(StationStatusRow));
      final scheme = Theme.of(ctx).colorScheme;

      final availability = tester.widget<Text>(find.text('Open'));
      final freshness = tester.widget<Text>(
        find.byKey(const Key('station_detail_freshness_word')),
      );
      expect(find.text('Old price'), findsOneWidget);
      expect(freshness.style?.color, scheme.tertiary);
      expect(availability.style?.color, isNot(scheme.tertiary),
          reason: 'an open station with a stale price must not be painted '
              'as though the forecourt were the problem');
    });

    testWidgets('a closed station says Closed, and says it alone', (
      tester,
    ) async {
      await pumpRow(tester, station: _station(isOpen: false));
      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('Fresh price'), findsOneWidget);
    });

    testWidgets('#3198 / #4092 an unknown open state is REPORTED as '
        'unreported, never as open or closed', (tester) async {
      await pumpRow(tester, station: _station(isOpen: null));
      expect(find.text('Not reported'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
      expect(find.text('Closed'), findsNothing);
    });

    testWidgets('#4092 a missing price stamp is not a verdict either', (
      tester,
    ) async {
      await pumpRow(tester, station: _station(updatedAt: 'gestern'));
      expect(find.text('Price age unknown'), findsOneWidget);
      expect(find.text('Fresh price'), findsNothing);
      expect(find.text('Old price'), findsNothing);
    });

    // #3902 glued the two facts into one parameterised phrase to fix a
    // French word-order bug ("Ouvert — < 1 min il y a"). #4092 removes the
    // phrase entirely, which removes the word-order problem with it:
    // separate facts need no sentence built around them. What the locales
    // must still get right is the two words themselves.
    testWidgets('#4092 French says both facts in French', (tester) async {
      await pumpRow(
        tester,
        station: _station(isOpen: true),
        locale: const Locale('fr'),
      );
      expect(find.text('Ouvert'), findsOneWidget);
      expect(find.text('Prix récent'), findsOneWidget);
      expect(find.textContaining('min il y a'), findsNothing,
          reason: 'the old fragment order must not come back');
    });

    testWidgets('#4092 German says both facts in German', (tester) async {
      await pumpRow(
        tester,
        station: _station(isOpen: true),
        locale: const Locale('de'),
      );
      expect(find.text('Geöffnet'), findsOneWidget);
      expect(find.text('Frischer Preis'), findsOneWidget);
    });

    testWidgets('#3902 both facts stay on one line (ellipsis) — the '
        'header height budget has not moved', (tester) async {
      await pumpRow(tester, station: _station(isOpen: true));
      for (final finder in [
        find.text('Open'),
        find.byKey(const Key('station_detail_freshness_word')),
      ]) {
        final text = tester.widget<Text>(finder);
        expect(text.maxLines, 1);
        expect(text.overflow, TextOverflow.ellipsis);
      }
    });

    testWidgets('shows 5 star icons when a rating is present', (tester) async {
      await pumpRow(
        tester,
        station: _station(),
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
        rating: null,
      );
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });
  });
}
