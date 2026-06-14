// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/feature_management/application/feature_flags_provider.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/feature_management/domain/feature_manifest.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_detail_app_bar_actions.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// A [FeatureFlags] notifier whose enabled set is the manifest default
/// minus [_disabled] — lets a test switch specific gates off (#1638).
class _FlagsWithout extends FeatureFlags {
  _FlagsWithout(this._disabled);

  final Set<Feature> _disabled;

  @override
  Set<Feature> build() =>
      FeatureManifest.defaultManifest.defaultEnabledSet().difference(_disabled);
}

void main() {
  group('StationDetailAppBarActions', () {
    testWidgets('renders the four action buttons with tooltips (#3337)',
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

      // Four icon buttons: alert, scan QR, report, favorite. (#3337 moved
      // directions out of this cluster to the prominent StationDirectionsFab.)
      expect(find.byIcon(Icons.directions), findsNothing);
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

    testWidgets(
        '#1638 — shows the scan-QR and report actions when their features '
        'are enabled (manifest default)', (tester) async {
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

      expect(find.byKey(const Key('scan_payment_qr')), findsOneWidget);
      expect(find.byKey(const Key('report_price')), findsOneWidget);
    });

    testWidgets(
        '#1638 — hides the scan-QR and report actions when their features '
        'are disabled', (tester) async {
      await pumpApp(
        tester,
        const StationDetailAppBarActions(
          stationId: '51d4b477-a095-1aa0-e100-80009459e03a',
          station: testStation,
        ),
        overrides: [
          favoritesOverride(const []),
          isFavoriteOverride('51d4b477-a095-1aa0-e100-80009459e03a', false),
          featureFlagsProvider.overrideWith(
            () => _FlagsWithout(
              {Feature.paymentQrScan, Feature.communityPriceReports},
            ),
          ),
        ],
      );

      // The two gated actions are gone; the ungated ones remain.
      expect(find.byKey(const Key('scan_payment_qr')), findsNothing);
      expect(find.byKey(const Key('report_price')), findsNothing);
      expect(find.byIcon(Icons.qr_code_scanner), findsNothing);
      expect(find.byIcon(Icons.flag_outlined), findsNothing);
      expect(find.byIcon(Icons.directions), findsNothing,
          reason: 'directions is the FAB now, not an app-bar icon (#3337)');
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });
  });
}
