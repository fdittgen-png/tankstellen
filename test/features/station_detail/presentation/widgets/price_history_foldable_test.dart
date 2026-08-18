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
}
