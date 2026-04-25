import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/widgets/empty_state.dart';
import 'package:tankstellen/core/widgets/help_banner.dart';
import 'package:tankstellen/features/alerts/data/models/price_alert.dart';
import 'package:tankstellen/features/alerts/providers/alert_provider.dart';
import 'package:tankstellen/features/favorites/presentation/widgets/alerts_tab.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

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

void main() {
  group('AlertsTab', () {
    testWidgets('shows EmptyState with "No price alerts" when list is empty',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const AlertsTab(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => _RecordingAlerts(const [])),
        ],
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No price alerts'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
      // Empty branch must NOT render the help banner or any list tiles.
      expect(find.byType(HelpBanner), findsNothing);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('renders HelpBanner + one ListTile per alert when non-empty',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      final alerts = [
        _alert(id: 'a1', stationName: 'Shell Berlin'),
        _alert(id: 'a2', stationName: 'Aral Munich'),
        _alert(id: 'a3', stationName: 'TotalEnergies Hamburg'),
      ];

      await pumpApp(
        tester,
        const AlertsTab(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => _RecordingAlerts(alerts)),
        ],
      );

      expect(find.byType(EmptyState), findsNothing);
      expect(find.byType(HelpBanner), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(3));
      expect(find.text('Shell Berlin'), findsOneWidget);
      expect(find.text('Aral Munich'), findsOneWidget);
      expect(find.text('TotalEnergies Hamburg'), findsOneWidget);
    });

    testWidgets('active alert renders notifications_active icon', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const AlertsTab(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(
            () => _RecordingAlerts([_alert(isActive: true)]),
          ),
        ],
      );

      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      expect(find.byIcon(Icons.notifications_off), findsNothing);
      // Switch reflects active state.
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('inactive alert renders notifications_off icon and grey switch',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const AlertsTab(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(
            () => _RecordingAlerts([_alert(isActive: false)]),
          ),
        ],
      );

      expect(find.byIcon(Icons.notifications_off), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active), findsNothing);
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('tapping the Switch invokes notifier.toggleAlert(id)',
        (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      final notifier = _RecordingAlerts([_alert(id: 'alert-42')]);

      await pumpApp(
        tester,
        const AlertsTab(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => notifier),
        ],
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
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      final notifier = _RecordingAlerts(
        [_alert(id: 'alert-99', stationName: 'Shell Berlin')],
      );

      await pumpApp(
        tester,
        const AlertsTab(),
        overrides: [
          ...test.overrides,
          alertProvider.overrideWith(() => notifier),
        ],
      );

      // Swipe right-to-left to trigger DismissDirection.endToStart.
      await tester.drag(
        find.byType(Dismissible),
        const Offset(-600, 0),
      );
      await tester.pumpAndSettle();

      expect(notifier.removeCalls, ['alert-99']);
      // SnackBar text uses l10n alertDeleted with the station name.
      expect(find.text('Alert "Shell Berlin" deleted'), findsOneWidget);
    });

    testWidgets('tapping an alert row pushes /station/:id', (tester) async {
      final mockStorageOverride = mockStorageRepositoryOverride();
      when(() => mockStorageOverride.mock.getSetting(any())).thenReturn(null);

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
          overrides: <Object>[
            mockStorageOverride.override,
            alertProvider.overrideWith(
              () => _RecordingAlerts(
                [_alert(id: 'a1', stationId: 'shell-42')],
              ),
            ),
          ].cast(),
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the ListTile (not the Switch) by tapping the title text.
      await tester.tap(find.text('Shell Berlin'));
      await tester.pumpAndSettle();

      expect(landedOn, '/station/shell-42');
      expect(find.text('station shell-42'), findsOneWidget);
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
