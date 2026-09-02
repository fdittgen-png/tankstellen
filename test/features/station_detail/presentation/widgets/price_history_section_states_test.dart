// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/theme/dark_mode_colors.dart';
import 'package:tankstellen/features/price_history/data/repositories/price_history_repository.dart';
import 'package:tankstellen/features/price_history/domain/entities/price_record.dart';
import 'package:tankstellen/features/price_history/presentation/widgets/price_chart.dart';
import 'package:tankstellen/features/price_history/providers/price_history_provider.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/price_history_section.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/price_history_stats_row.dart';

import '../../../../fakes/fake_hive_storage.dart';
import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// The three honest price-history states (#3928, epic #3925).
///
/// The field report: a first visit drew ONE orange dot in an otherwise
/// empty plot and, under it, `Min 2,329 € · Max 2,329 € · Avg 2,329 € ·
/// Actuel 2,329 €` with Min painted green and Max red. Four identical
/// numbers dressed as statistics and a spread that did not exist.
///
/// History is injected through `priceHistoryProvider` / `priceStatsProvider`
/// rather than seeded into storage on purpose: the repository windows its
/// query against the real wall clock, and a test that seeds "now minus a
/// few days" agrees with the calendar of the machine that runs it.
void main() {
  const stationId = 'station-3928';
  const fuel = FuelType.diesel;

  /// Newest-first, exactly as `PriceHistoryRepository.getHistory` returns.
  PriceRecord record(DateTime at, double diesel) =>
      PriceRecord(stationId: stationId, recordedAt: at, diesel: diesel);

  List<Object> overridesFor(List<PriceRecord> history, PriceStats stats) {
    final standard = standardTestOverrides();
    return [
      ...standard.overrides,
      hiveStorageProvider.overrideWithValue(FakeHiveStorage()),
      priceHistoryRepositoryProvider.overrideWithValue(
        PriceHistoryRepository(FakeHiveStorage()),
      ),
      priceHistoryProvider(stationId).overrideWithValue(history),
      priceStatsProvider(stationId, fuel).overrideWithValue(stats),
    ];
  }

  Future<void> pumpSection(
    WidgetTester tester, {
    required List<PriceRecord> history,
    required PriceStats stats,
  }) async {
    await pumpApp(
      tester,
      const SingleChildScrollView(
        child: PriceHistorySection(
          stationId: stationId,
          station: testStation,
        ),
      ),
      overrides: overridesFor(history, stats),
    );
  }

  group('PriceHistorySection — zero observations', () {
    testWidgets('keeps the chart\'s own empty state, no stats row',
        (tester) async {
      await pumpSection(
        tester,
        history: const [],
        stats: const PriceStats(),
      );

      expect(find.byType(PriceChart), findsOneWidget);
      expect(find.text('No price history yet'), findsOneWidget);
      expect(find.byType(PriceHistoryStatsRow), findsNothing);
      // The way out to the per-fuel screen stays available.
      expect(find.text('Show all fuel types'), findsOneWidget);
    });
  });

  group('PriceHistorySection — exactly one observation', () {
    final single = [record(DateTime(2026, 8, 21, 9, 30), 2.329)];
    const singleStats = PriceStats(
      min: 2.329,
      max: 2.329,
      avg: 2.329,
      current: 2.329,
    );

    testWidgets('draws NO chart and NO stats row — a lone dot is not a '
        'trend and four identical figures are not statistics',
        (tester) async {
      await pumpSection(tester, history: single, stats: singleStats);

      expect(find.byType(PriceChart), findsNothing);
      expect(find.byType(PriceHistoryStatsRow), findsNothing);
      expect(find.text('Min'), findsNothing);
      expect(find.text('Max'), findsNothing);
    });

    testWidgets('says when the price was first seen and what it is now',
        (tester) async {
      await pumpSection(tester, history: single, stats: singleStats);

      expect(
        find.text(
          'First seen on Aug 21, 2026 — the history builds up with '
          'every visit',
        ),
        findsOneWidget,
      );
      // The current price lives on its own line under the sentence.
      expect(find.textContaining('Current price:'), findsOneWidget);
      expect(find.text('Show all fuel types'), findsOneWidget);
    });

    testWidgets('a second visit that carried no diesel figure is still ONE '
        'point — unplottable records never fake a series', (tester) async {
      await pumpSection(
        tester,
        history: [
          record(DateTime(2026, 8, 22, 9, 30), 2.329),
          PriceRecord(
            stationId: stationId,
            recordedAt: DateTime(2026, 8, 21, 9, 30),
            e10: 1.899,
          ),
        ],
        stats: singleStats,
      );

      expect(find.byType(PriceChart), findsNothing);
      expect(find.textContaining('First seen on Aug 22, 2026'), findsOneWidget);
    });
  });

  group('PriceHistorySection — two or more observations', () {
    Color colorOfStat(WidgetTester tester, String stat) {
      final text = tester.widget<Text>(find.byKey(statValueKey(stat)));
      return text.style!.color!;
    }

    testWidgets('chart + stats row are back', (tester) async {
      await pumpSection(
        tester,
        history: [
          record(DateTime(2026, 8, 24), 1.789),
          record(DateTime(2026, 8, 21), 1.759),
        ],
        stats: const PriceStats(
          min: 1.759,
          max: 1.789,
          avg: 1.774,
          current: 1.789,
        ),
      );

      expect(find.byType(PriceChart), findsOneWidget);
      expect(find.byType(PriceHistoryStatsRow), findsOneWidget);
    });

    testWidgets('Min is green and Max red ONLY when they differ',
        (tester) async {
      await pumpSection(
        tester,
        history: [
          record(DateTime(2026, 8, 24), 1.789),
          record(DateTime(2026, 8, 21), 1.759),
        ],
        stats: const PriceStats(
          min: 1.759,
          max: 1.789,
          avg: 1.774,
          current: 1.789,
        ),
      );

      final context = tester.element(find.byType(PriceHistoryStatsRow));
      expect(colorOfStat(tester, 'min'), DarkModeColors.success(context));
      expect(colorOfStat(tester, 'max'), DarkModeColors.error(context));
    });

    testWidgets('equal Min and Max render neutral — no invented spread '
        '(the #3928 report)', (tester) async {
      await pumpSection(
        tester,
        history: [
          record(DateTime(2026, 8, 24), 2.329),
          record(DateTime(2026, 8, 21), 2.329),
        ],
        stats: const PriceStats(
          min: 2.329,
          max: 2.329,
          avg: 2.329,
          current: 2.329,
        ),
      );

      final context = tester.element(find.byType(PriceHistoryStatsRow));
      final neutral = Theme.of(context).colorScheme.onSurface;
      expect(colorOfStat(tester, 'min'), neutral);
      expect(colorOfStat(tester, 'max'), neutral);
      expect(colorOfStat(tester, 'min'),
          isNot(DarkModeColors.success(context)));
      expect(colorOfStat(tester, 'max'), isNot(DarkModeColors.error(context)));
    });

    testWidgets('the current price carries an explicit delta against the '
        'oldest point of the window, not a reference-less arrow',
        (tester) async {
      await pumpSection(
        tester,
        history: [
          record(DateTime(2026, 8, 24), 1.789),
          record(DateTime(2026, 8, 21), 1.759),
        ],
        stats: const PriceStats(
          min: 1.759,
          max: 1.789,
          avg: 1.774,
          current: 1.789,
        ),
      );

      final delta = tester
          .widgetList<Text>(find.textContaining('since Aug 21, 2026'))
          .single;
      expect(delta.data, startsWith('+'));
      expect(delta.data, contains('since Aug 21, 2026'));
    });

    testWidgets('a fallen price reads as a negative delta', (tester) async {
      await pumpSection(
        tester,
        history: [
          record(DateTime(2026, 8, 24), 1.759),
          record(DateTime(2026, 8, 21), 1.789),
        ],
        stats: const PriceStats(
          min: 1.759,
          max: 1.789,
          avg: 1.774,
          current: 1.759,
        ),
      );

      final delta = tester
          .widgetList<Text>(find.textContaining('since Aug 21, 2026'))
          .single;
      // U+2212 MINUS SIGN, so it lines up with the plus.
      expect(delta.data, startsWith('−'));
    });

    testWidgets('an unmoved price says so instead of showing +0', (tester) async {
      await pumpSection(
        tester,
        history: [
          record(DateTime(2026, 8, 24), 2.329),
          record(DateTime(2026, 8, 21), 2.329),
        ],
        stats: const PriceStats(
          min: 2.329,
          max: 2.329,
          avg: 2.329,
          current: 2.329,
        ),
      );

      expect(find.text('Unchanged since Aug 21, 2026'), findsOneWidget);
    });
  });
}
