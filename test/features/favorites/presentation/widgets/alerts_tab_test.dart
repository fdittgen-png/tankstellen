// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// The mocktail Mock* storage doubles are deprecated as a steering hint
// (prefer the stateful fakes) but remain sanctioned for widget tests that
// stub reads exclusively -- see test/helpers/mock_providers.dart (#3742).
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/widgets/empty_state.dart';
import 'package:tankstellen/core/widgets/help_banner.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/domain/entities/radius_alert.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/alert_statistics_card.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/alerts_body.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/alerts_last_checked_footer.dart';
import 'package:tankstellen/features/alerts/providers/alert_provider.dart';
import 'package:tankstellen/features/alerts/providers/radius_alerts_provider.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/alerts_tab.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';
import '../../../../helpers/confirm_delete.dart';
import '../../../../mocks/mocks.dart';

PriceAlert _alert({
  String id = 'alert-1',
  String stationId = 'station-1',
  String stationName = 'Shell Berlin',
  FuelType fuelType = FuelType.e10,
  double targetPrice = 1.50,
  bool isActive = true,
}) {
  return PriceAlert(
    id: id,
    stationId: stationId,
    stationName: stationName,
    fuelType: fuelType,
    targetPrice: targetPrice,
    isActive: isActive,
    createdAt: DateTime(2026, 1, 1),
  );
}

/// Overrides for one tab render: storage stubs the alerts page needs, the
/// seeded station alerts and an empty zone-alert list.
List<Object> _overrides(
  ({List<Object> overrides, MockStorageRepository mockStorage}) test,
  _RecordingAlerts alerts,
) {
  when(() => test.mockStorage.getSetting(any())).thenReturn(null);
  when(() => test.mockStorage.hasApiKey(any())).thenReturn(false);
  when(() => test.mockStorage.getAlerts()).thenReturn([]);
  return [
    ...test.overrides,
    alertProvider.overrideWith(() => alerts),
    radiusAlertsProvider.overrideWith(_NoRadiusAlerts.new),
  ];
}

void main() {
  group('AlertsTab (#3905 — alerts page inlined)', () {
    testWidgets(
        'empty: renders the stats strip, both sections and the footer '
        'directly — no intermediate card, no duplicate empty state',
        (tester) async {
      final test = standardTestOverrides();

      await pumpApp(
        tester,
        const AlertsTab(),
        overrides: _overrides(test, _RecordingAlerts(const [])),
      );

      // The page body itself, not a link to it.
      expect(find.byType(AlertsBody), findsOneWidget);
      expect(find.byType(AlertStatisticsCard), findsOneWidget);
      expect(find.text('Station alerts (0)'), findsOneWidget);
      expect(find.text('Radius alerts (0)'), findsOneWidget);
      expect(find.byType(AlertsLastCheckedFooter), findsOneWidget);
      // The old "Radius alerts & statistics" entry card and the tab's own
      // full-screen empty state are gone; the hint appears ONCE, inline.
      expect(find.byKey(const Key('radiusAlertsEntry')), findsNothing);
      expect(find.text('Radius alerts & statistics'), findsNothing);
      expect(find.text('No price alerts'), findsNothing);
      expect(find.textContaining("station's detail page"), findsOneWidget);
      // The only EmptyState left is the zone section's compact one.
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No radius alerts yet'), findsOneWidget);
      expect(find.byType(HelpBanner), findsNothing);
    });

    testWidgets('renders HelpBanner + one row per alert when non-empty',
        (tester) async {
      final test = standardTestOverrides();
      final alerts = [
        _alert(id: 'a1', stationName: 'Shell Berlin'),
        _alert(id: 'a2', stationName: 'Aral Munich'),
        _alert(id: 'a3', stationName: 'TotalEnergies Hamburg'),
      ];

      await pumpApp(
        tester,
        const AlertsTab(),
        overrides: _overrides(test, _RecordingAlerts(alerts)),
      );

      expect(find.byType(HelpBanner), findsOneWidget);
      expect(find.text('Station alerts (3)'), findsOneWidget);
      expect(find.text('Shell Berlin'), findsOneWidget);
      expect(find.text('Aral Munich'), findsOneWidget);
      expect(find.text('TotalEnergies Hamburg'), findsOneWidget);
    });

    testWidgets('tapping the Switch invokes notifier.toggleAlert(id)',
        (tester) async {
      final test = standardTestOverrides();
      final notifier = _RecordingAlerts([_alert(id: 'alert-42')]);

      await pumpApp(
        tester,
        const AlertsTab(),
        overrides: _overrides(test, notifier),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(notifier.toggleCalls, ['alert-42']);
      expect(notifier.removeCalls, isEmpty);
    });

    testWidgets(
        'swipe-to-dismiss invokes notifier.removeAlert(id) and shows SnackBar',
        (tester) async {
      final test = standardTestOverrides();
      final notifier = _RecordingAlerts(
        [_alert(id: 'alert-99', stationName: 'Shell Berlin')],
      );

      await pumpApp(
        tester,
        const AlertsTab(),
        overrides: _overrides(test, notifier),
      );

      await tester.drag(find.text('Shell Berlin'), const Offset(-600, 0));
      await confirmPendingDelete(tester); // #3682

      expect(notifier.removeCalls, ['alert-99']);
      expect(find.text('Alert "Shell Berlin" deleted'), findsOneWidget);
    });

    testWidgets('tapping an alert row pushes /station/:id', (tester) async {
      final test = standardTestOverrides();

      String? landedOn;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: AlertsTab()),
          ),
          GoRoute(
            path: '/station/:id',
            builder: (_, state) {
              landedOn = '/station/${state.pathParameters['id']}';
              return Scaffold(
                body: Text('station ${state.pathParameters['id']}'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(
            test,
            _RecordingAlerts([_alert(id: 'a1', stationId: 'shell-42')]),
          ).cast(),
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shell Berlin'));
      await tester.pumpAndSettle();

      expect(landedOn, '/station/shell-42');
      expect(find.text('station shell-42'), findsOneWidget);
    });

    // #1699 — the inlined page must survive the en_XA expansion at the
    // narrowest supported width.
    testWidgets('does not overflow under en_XA at 320 dp', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final test = standardTestOverrides();

      await pumpApp(
        tester,
        const AlertsTab(),
        overrides: _overrides(test, _RecordingAlerts([_alert()])),
        locale: const Locale('en', 'XA'),
      );

      expect(tester.takeException(), isNull);
    });
  });
}

/// Test double for [AlertNotifier]. Exposes the seeded alerts through
/// `build()` and records calls to [removeAlert] / [toggleAlert] so widget
/// tests can assert against intent without driving real Hive storage.
class _RecordingAlerts extends AlertNotifier {
  _RecordingAlerts(this._initial);

  final List<PriceAlert> _initial;
  final List<String> removeCalls = [];
  final List<String> toggleCalls = [];

  @override
  List<PriceAlert> build() => _initial;

  @override
  Future<void> removeAlert(String id) async {
    removeCalls.add(id);
  }

  @override
  Future<void> toggleAlert(String id) async {
    toggleCalls.add(id);
  }
}

class _NoRadiusAlerts extends RadiusAlerts {
  @override
  Future<List<RadiusAlert>> build() async => const [];
}
