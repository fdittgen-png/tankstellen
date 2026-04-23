import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';
import 'package:tankstellen/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/radius_alert_create_sheet.dart';
import 'package:tankstellen/features/alerts/providers/alert_provider.dart';
import 'package:tankstellen/features/alerts/providers/radius_alerts_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('AlertsScreen radius empty state (#578 phase 2)', () {
    testWidgets(
        'shows empty state CTA when no radius alerts are configured',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getAlerts()).thenReturn([]);

      await pumpApp(
        tester,
        const AlertsScreen(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => _EmptyAlerts()),
          radiusAlertsProvider.overrideWith(() => _EmptyRadiusAlerts()),
        ],
      );

      expect(find.text('Radius alerts (0)'), findsOneWidget);
      expect(find.text('No radius alerts yet'), findsOneWidget);
      expect(find.text('Create a radius alert'), findsOneWidget);
    });

    testWidgets('tapping empty-state CTA opens the create sheet',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getAlerts()).thenReturn([]);

      await pumpApp(
        tester,
        const AlertsScreen(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => _EmptyAlerts()),
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

class _EmptyAlerts extends AlertNotifier {
  @override
  List<PriceAlert> build() => const [];
}

class _EmptyRadiusAlerts extends RadiusAlerts {
  @override
  Future<List<RadiusAlert>> build() async => const [];
}
