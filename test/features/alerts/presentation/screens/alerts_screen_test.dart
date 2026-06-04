// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/error/exceptions.dart';
import 'package:tankstellen/core/services/widgets/service_status_banner.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/presentation/screens/alerts_screen.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/create_alert_dialog.dart';
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

      // #2819 — the empty station section now shows a LABELLED header +
      // a compact inline hint, not a full-screen "No price alerts" state.
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
      expect(find.textContaining('Station alerts'), findsOneWidget);
      expect(find.textContaining("station's detail page"), findsOneWidget);
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

  // #2857 — the Station-alerts "+" must reach a real add flow, not re-show
  // the "create from a station's detail page" snackbar.
  group('AlertsScreen — Station "+" add flow (#2857)', () {
    Map<String, dynamic> stationJson(String id, String brand) => {
          'id': id,
          'name': brand,
          'brand': brand,
          'street': 'Hauptstr. 1',
          'postCode': '10115',
          'place': 'Berlin',
          'lat': 52.5,
          'lng': 13.4,
          'isOpen': true,
          'diesel': 1.55,
        };

    testWidgets('tapping the Station "+" opens the station picker, not a '
        'snackbar', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getAlerts()).thenReturn([]);
      when(() => test.mockStorage.getFavoriteIds()).thenReturn(['fav-1']);
      when(() => test.mockStorage.getFavoriteStationData('fav-1'))
          .thenReturn(stationJson('fav-1', 'Shell Berlin'));

      await pumpApp(
        tester,
        const AlertsScreen(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => _EmptyAlerts()),
        ],
      );

      // The Station section "+" is the first add button (Zone "+" is second).
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      // The picker is shown with the favorite station — NOT the dead-end
      // snackbar from the old implementation.
      expect(find.text('Pick a station'), findsOneWidget);
      expect(find.text('Shell Berlin'), findsOneWidget);
      expect(
        find.byKey(const Key('alert_pick_station_tile_fav-1')),
        findsOneWidget,
      );
    });

    testWidgets('selecting a station opens CreateAlertDialog', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getAlerts()).thenReturn([]);
      when(() => test.mockStorage.getFavoriteIds()).thenReturn(['fav-1']);
      when(() => test.mockStorage.getFavoriteStationData('fav-1'))
          .thenReturn(stationJson('fav-1', 'Shell Berlin'));

      await pumpApp(
        tester,
        const AlertsScreen(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => _EmptyAlerts()),
        ],
      );

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('alert_pick_station_tile_fav-1')));
      await tester.pumpAndSettle();

      expect(find.byType(CreateAlertDialog), findsOneWidget);
    });

    testWidgets('with no favorites the picker offers a Search fallback, not a '
        'dead-end', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.hasApiKey()).thenReturn(false);
      when(() => test.mockStorage.getAlerts()).thenReturn([]);
      when(() => test.mockStorage.getFavoriteIds()).thenReturn(<String>[]);

      await pumpApp(
        tester,
        const AlertsScreen(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => _EmptyAlerts()),
        ],
      );

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      // Picker is shown with the empty hint + a real Search CTA — the user
      // can still reach a station's detail page from here.
      expect(find.text('Pick a station'), findsOneWidget);
      expect(
        find.byKey(const Key('alert_pick_station_search')),
        findsOneWidget,
      );
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
