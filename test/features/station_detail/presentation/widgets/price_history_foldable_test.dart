// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/price_history_foldable.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/pump_app.dart';
import 'package:tankstellen/features/price_history/domain/entities/price_stats.dart';
import 'package:tankstellen/features/price_history/providers/price_history_provider.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/price_history_stats_row.dart';

/// A [FeatureFlags] notifier whose enabled set is the manifest default
/// minus [_disabled] — the same test double the #1638 gate tests use.
class _FlagsWithout extends FeatureFlags {
  _FlagsWithout(this._disabled);

  final Set<Feature> _disabled;

  @override
  Set<Feature> build() =>
      FeatureManifest.defaultManifest.defaultEnabledSet().difference(_disabled);
}

void main() {
  group('PriceHistoryFoldable — Feature.priceHistory gate '
      '(dead-code finding 6)', () {
    testWidgets('renders the collapsed foldable when the feature is enabled '
        '(manifest default)', (tester) async {
      await pumpApp(
        tester,
        PriceHistoryFoldable(
          stationId: testStation.id,
          station: testStation,
        ),
        // #4076 — the collapsed header watches priceStatsProvider; no
        // history in this harness → plain title.
        overrides: [
          priceStatsProvider.overrideWith(
              (ref, args) => const PriceStats()),
        ],
      );

      expect(find.byType(ExpansionTile), findsOneWidget);
    });

    testWidgets('disappears entirely when Feature.priceHistory is disabled',
        (tester) async {
      await pumpApp(
        tester,
        PriceHistoryFoldable(
          stationId: testStation.id,
          station: testStation,
        ),
        overrides: [
          featureFlagsProvider.overrideWith(
            () => _FlagsWithout({Feature.priceHistory}),
          ),
        ],
      );

      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.byType(Card), findsNothing);
    });
  });

  // #4076 — the most useful numbers on the page used to sit behind the
  // tap. With history present the COLLAPSED header carries the stats row.
  group('collapsed header (#4076)', () {
    testWidgets('shows the stats row while collapsed when history exists',
        (tester) async {
      await pumpApp(
        tester,
        PriceHistoryFoldable(stationId: testStation.id, station: testStation),
        overrides: [
          priceStatsProvider.overrideWith((ref, args) =>
              const PriceStats(
                  min: 1.65, max: 1.85, avg: 1.75, current: 1.72)),
        ],
      );
      expect(find.byType(ExpansionTile), findsOneWidget);
      expect(find.byType(PriceHistoryStatsRow), findsOneWidget,
          reason: 'the stats row is visible without expanding');
    });

    testWidgets('stays a plain title when there is no history',
        (tester) async {
      await pumpApp(
        tester,
        PriceHistoryFoldable(stationId: testStation.id, station: testStation),
        overrides: [
          priceStatsProvider.overrideWith(
              (ref, args) => const PriceStats()),
        ],
      );
      expect(find.byType(PriceHistoryStatsRow), findsNothing);
    });
  });
}
