import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/widgets/service_status_banner.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:tankstellen/features/alerts/providers/alert_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('AlertsScreen', () {
    testWidgets('renders Scaffold with app bar', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getAlerts()).thenReturn([]);

      await pumpApp(
        tester,
        const AlertsScreen(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => _EmptyAlerts()),
        ],
      );

      expect(find.byType(Scaffold), findsAtLeast(1));
      expect(find.text('Price Alerts'), findsOneWidget);
    });

    testWidgets('shows empty state when no alerts exist', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getAlerts()).thenReturn([]);

      await pumpApp(
        tester,
        const AlertsScreen(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => _EmptyAlerts()),
        ],
      );

      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
      expect(find.text('No price alerts'), findsOneWidget);
    });

    testWidgets('shows alert list when alerts exist', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getAlerts()).thenReturn([]);

      final alert = PriceAlert(
        id: 'alert-1',
        stationId: 'station-1',
        stationName: 'Shell Berlin',
        fuelType: FuelType.e10,
        targetPrice: 1.50,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      );

      await pumpApp(
        tester,
        const AlertsScreen(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => _FixedAlerts([alert])),
        ],
      );

      expect(find.text('Shell Berlin'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    // #858: the alerts screen now surfaces load failures via
    // ServiceChainErrorWidget instead of letting the exception propagate
    // to a blank ErrorWidget.
    testWidgets('renders ServiceChainErrorWidget when provider throws',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getAlerts()).thenReturn([]);

      await pumpApp(
        tester,
        const AlertsScreen(),
        overrides: [
          ...test.overrides,
          alertsAsyncProvider.overrideWithValue(
            AsyncValue<List<PriceAlert>>.error(
              const ServiceChainExhaustedException(errors: []),
              StackTrace.current,
            ),
          ),
        ],
      );

      expect(find.byType(ServiceChainErrorWidget), findsOneWidget);
      // The widget renders its standard "cloud off" icon + retry button.
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets(
        'renders ServiceChainErrorWidget on arbitrary alert load exception',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getAlerts()).thenReturn([]);

      await pumpApp(
        tester,
        const AlertsScreen(),
        overrides: [
          ...test.overrides,
          alertsAsyncProvider.overrideWithValue(
            AsyncValue<List<PriceAlert>>.error(
              Exception('alerts box corrupted'),
              StackTrace.current,
            ),
          ),
        ],
      );

      expect(find.byType(ServiceChainErrorWidget), findsOneWidget);
    });
  });
}

class _EmptyAlerts extends AlertNotifier {
  @override
  List<PriceAlert> build() => [];
}

class _FixedAlerts extends AlertNotifier {
  final List<PriceAlert> _alerts;
  _FixedAlerts(this._alerts);

  @override
  List<PriceAlert> build() => _alerts;
}
