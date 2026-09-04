// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';
import 'package:tankstellen/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/radius_alert_create_sheet.dart';
import 'package:tankstellen/features/alerts/providers/alert_provider.dart';
import 'package:tankstellen/features/alerts/providers/radius_alerts_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// The zone section's own empty state (#578 phase 2) — shown when there is
/// at least one STATION alert and no zone alert. (With zero alerts of
/// either kind the whole page collapses to one empty state, #3951 — see
/// `alerts_body_empty_state_test.dart`.)
void main() {
  group('AlertsScreen radius empty state (#578 phase 2)', () {
    testWidgets(
        'shows the zone section CTA when station alerts exist but no radius '
        'alerts are configured', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      when(() => test.mockStorage.getAlerts()).thenReturn([]);

      await pumpApp(
        tester,
        const AlertsScreen(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => _OneAlert()),
          radiusAlertsProvider.overrideWith(() => _EmptyRadiusAlerts()),
        ],
      );

      // #3951 — the header drops its " (0)" suffix at zero.
      expect(find.text('Radius alerts'), findsOneWidget);
      expect(find.text('Radius alerts (0)'), findsNothing);
      expect(find.text('No radius alerts yet'), findsOneWidget);
      expect(find.text('Create a radius alert'), findsOneWidget);
    });

    testWidgets('tapping empty-state CTA opens the create sheet',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
      when(() => test.mockStorage.getAlerts()).thenReturn([]);

      await pumpApp(
        tester,
        const AlertsScreen(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => _OneAlert()),
          radiusAlertsProvider.overrideWith(() => _EmptyRadiusAlerts()),
          userPositionNullOverride(),
        ],
      );

      // The ListView may push the CTA below the fold on the 800x600
      // test viewport; scroll it into view before tapping.
      await tester.ensureVisible(find.text('Create a radius alert'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create a radius alert'));
      await tester.pumpAndSettle();

      expect(find.byType(RadiusAlertCreateSheet), findsOneWidget);
      expect(find.text('Create radius alert'), findsOneWidget);
    });
  });
}

class _OneAlert extends AlertNotifier {
  @override
  List<PriceAlert> build() => [
        PriceAlert(
          id: 'alert-1',
          stationId: 'station-1',
          stationName: 'Shell Berlin',
          fuelType: FuelType.e10,
          targetPrice: 1.50,
          isActive: true,
          createdAt: DateTime(2026, 1, 1),
        ),
      ];
}

class _EmptyRadiusAlerts extends RadiusAlerts {
  @override
  Future<List<RadiusAlert>> build() async => const [];
}
