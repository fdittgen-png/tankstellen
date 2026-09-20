// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/fleet/fleet_directory.dart';
import 'package:tankstellen/features/fleet/data/fleet_metrics_reader.dart';
import 'package:tankstellen/features/fleet/presentation/screens/fleet_overview_screen.dart';
import 'package:tankstellen/features/fleet/presentation/screens/fleet_reports_screen.dart';
import 'package:tankstellen/features/fleet/presentation/screens/fleet_vehicle_detail_screen.dart';
import 'package:tankstellen/features/fleet/providers/fleet_manager_providers.dart';

import '../../../helpers/pump_app.dart';
import '../data/fake_fleet_review_transport.dart';

/// #4216 — what the manager surfaces say, and what they refuse to say.
///
/// The arithmetic is proved in `fleet_kpis_test.dart`; these tests are
/// about the four claims a screen makes that a domain test cannot:
/// that "needs attention" comes first, that a suppressed row names the
/// threshold instead of showing a zero, that a CO2 figure never
/// appears without its factor, and that the vehicle page offers no
/// journey.
void main() {
  final fetched = DateTime.utc(2026, 9, 1);

  FleetDirectory directory({int minSamples = 5}) => FleetDirectory(
        orgId: 'org-1',
        orgName: 'Nordwind Logistik',
        vehicles: const [
          FleetVehicleRow(
            id: 'veh-1',
            orgId: 'org-1',
            fleetCode: 'NW-01',
            displayName: 'Transporter NW-01',
            plateMasked: null,
            data: {},
          ),
          FleetVehicleRow(
            id: 'veh-2',
            orgId: 'org-1',
            fleetCode: 'NW-02',
            displayName: 'Kombi NW-02',
            plateMasked: null,
            data: {},
          ),
        ],
        assignments: const [],
        policy: {'aggregationMinSamples': minSamples},
        fetchedAt: fetched,
      );

  Map<String, dynamic> metricsRow({
    String id = 'veh-1',
    bool suppressed = false,
    Object? co2 = 372.0,
    String? version = 'ADEME Base Carbone v23.6 (2026) WtW',
    String currency = 'EUR',
    double spend = 240.5,
  }) =>
      {
        'fleet_vehicle_id': id,
        'suppressed': suppressed,
        'spend': spend,
        'litres': 120.0,
        'km': 1500.0,
        'co2e_kg': co2,
        'co2_factor_version': version,
        'measured_share': 0.75,
        'sample_count': 9,
        'currency': currency,
      };

  List<Object> overrides(
    List<Map<String, dynamic>> rows, {
    FleetDirectory? dir,
    bool haveFleet = true,
  }) {
    final wire = FakeFleetReviewTransport()..metricsRows = rows;
    return [
      fleetManagerDirectoryProvider
          .overrideWithValue(haveFleet ? (dir ?? directory()) : null),
      fleetMetricsReaderProvider
          .overrideWithValue(FleetMetricsReader(transport: wire)),
    ];
  }

  Future<void> pump(
    WidgetTester tester,
    Widget screen,
    List<Object> providerOverrides, {
    Size size = const Size(360, 900),
  }) async {
    tester.view.physicalSize = size * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      MediaQuery(data: MediaQueryData(size: size), child: screen),
      overrides: providerOverrides,
    );
  }

  group('fleet overview', () {
    testWidgets('"Needs attention" is the first card, before any '
        'total', (tester) async {
      await pump(tester, const FleetOverviewScreen(),
          overrides([metricsRow(), metricsRow(id: 'veh-2', spend: 900)]));

      final attention = tester.getTopLeft(find.text('Needs attention')).dy;
      final spend = tester.getTopLeft(find.text('Fuel spend')).dy;
      expect(attention, lessThan(spend),
          reason: '#4216 asks for exceptions before totals');
    });

    testWidgets('a suppressed vehicle names the threshold instead of '
        'showing a zero (ADR 0025 D5.3)', (tester) async {
      await pump(
        tester,
        const FleetOverviewScreen(),
        overrides([
          metricsRow(),
          {'fleet_vehicle_id': 'veh-2', 'suppressed': true},
        ]),
      );

      expect(find.textContaining('Fewer than 5 expenses'), findsOneWidget);
      expect(find.text('Kombi NW-02'), findsOneWidget,
          reason: 'the vehicle is named; only its figures are withheld');
      expect(find.textContaining('1 vehicle is hidden'), findsOneWidget);
    });

    testWidgets('the org\'s own threshold is what the row names, not '
        'the placeholder default', (tester) async {
      await pump(
        tester,
        const FleetOverviewScreen(),
        overrides(
          [
            {'fleet_vehicle_id': 'veh-2', 'suppressed': true},
          ],
          dir: directory(minSamples: 12),
        ),
      );
      expect(find.textContaining('Fewer than 12 expenses'), findsOneWidget);
    });

    testWidgets('a period that mixes currencies shows the breakdown '
        'and NO total', (tester) async {
      await pump(
          tester,
          const FleetOverviewScreen(),
          overrides([
            metricsRow(),
            metricsRow(id: 'veh-2', currency: 'CHF', spend: 300),
          ]));

      expect(find.text('Totals by currency'), findsOneWidget);
      expect(find.textContaining('mixes currencies'), findsWidgets);
      // The spend tile is present, and says the figure is absent.
      expect(find.text('Fuel spend'), findsOneWidget);
      expect(find.text('Not calculated'), findsWidgets);
    });

    testWidgets('an unreachable server is NOT rendered as an empty '
        'fleet', (tester) async {
      await pump(tester, const FleetOverviewScreen(), [
        fleetManagerDirectoryProvider.overrideWithValue(directory()),
        fleetMetricsReaderProvider.overrideWithValue(
          FleetMetricsReader(
              transport: FakeFleetReviewTransport()
                ..failure = Exception('offline')),
        ),
      ]);

      expect(find.text('Figures not loaded'), findsOneWidget);
      expect(find.text('Nothing reported in this period'), findsNothing);
    });

    testWidgets('an organisation with no expenses in the window gets '
        'the OTHER empty state, which explains what is missing',
        (tester) async {
      await pump(tester, const FleetOverviewScreen(), overrides(const []));

      expect(find.text('Nothing reported in this period'), findsOneWidget);
      expect(find.textContaining('No confirmed expenses'), findsOneWidget);
    });

    testWidgets('no fleet on the device is its own state', (tester) async {
      await pump(tester, const FleetOverviewScreen(),
          overrides(const [], haveFleet: false));
      expect(find.text('No fleet on this device'), findsOneWidget);
    });
  });

  group('vehicle detail', () {
    testWidgets('offers no journey, and says so', (tester) async {
      await pump(
        tester,
        const FleetVehicleDetailScreen(fleetVehicleId: 'veh-1'),
        overrides([metricsRow()]),
      );

      expect(find.textContaining('Journeys are not shown here'),
          findsOneWidget);
      for (final forbidden in const ['Route', 'Map', 'Trip', 'Journey']) {
        expect(find.text(forbidden), findsNothing,
            reason: 'ADR 0025 D5.1 leaves no journey affordance here');
      }
      expect(find.text('Transporter NW-01'), findsOneWidget);
      expect(find.text('Cost per km'), findsOneWidget);
    });

    testWidgets('a one-vehicle fleet under the threshold reveals '
        'nothing but the threshold', (tester) async {
      await pump(
        tester,
        const FleetVehicleDetailScreen(fleetVehicleId: 'veh-1'),
        overrides([
          {'fleet_vehicle_id': 'veh-1', 'suppressed': true},
        ]),
      );

      expect(find.textContaining('Fewer than 5 expenses'), findsOneWidget);
      expect(find.text('Cost per km'), findsNothing);
      expect(find.textContaining('Journeys are not shown here'),
          findsOneWidget);
    });
  });

  group('reports', () {
    testWidgets('a CO2 figure prints its scope and factor version '
        '(#4219)', (tester) async {
      await pump(tester, const FleetReportsScreen(),
          overrides([metricsRow()]));

      expect(find.text('CO₂e'), findsOneWidget);
      expect(find.textContaining('372'), findsOneWidget);
      expect(find.text('Scope'), findsOneWidget);
      expect(find.textContaining('Well-to-wheel'), findsOneWidget);
      expect(find.text('ADEME Base Carbone v23.6 (2026) WtW'),
          findsOneWidget);
    });

    testWidgets('no factor means "Not calculated" with the reason — '
        'never a number', (tester) async {
      await pump(tester, const FleetReportsScreen(),
          overrides([metricsRow(co2: null, version: null)]));

      expect(find.text('Not calculated'), findsWidgets);
      expect(find.textContaining('no published emission factor'),
          findsOneWidget);
      expect(find.text('Scope'), findsNothing,
          reason: 'a boundary label with no figure under it would imply '
              'one exists');
    });

    testWidgets('two factor versions in one period produce no figure, '
        'and say which absence it is', (tester) async {
      await pump(
          tester,
          const FleetReportsScreen(),
          overrides([
            metricsRow(),
            metricsRow(id: 'veh-2', version: 'Other v1 (2020) TtW'),
          ]));

      expect(find.textContaining('more than one factor version'),
          findsOneWidget);
      expect(find.textContaining('no published emission factor'),
          findsNothing);
    });

    testWidgets('the export says it is audited and location-free',
        (tester) async {
      await pump(tester, const FleetReportsScreen(),
          overrides([metricsRow()]));

      expect(find.textContaining('recorded in your organisation'),
          findsOneWidget);
      expect(find.textContaining('Location and telemetry are never'),
          findsOneWidget);
    });

    testWidgets('an export the server refused to audit produces no '
        'file (ADR 0025 D5.4)', (tester) async {
      final wire = FakeFleetReviewTransport()
        ..metricsRows = [metricsRow()]
        ..exportAudited = false;
      await pump(tester, const FleetReportsScreen(), [
        fleetManagerDirectoryProvider.overrideWithValue(directory()),
        fleetMetricsReaderProvider
            .overrideWithValue(FleetMetricsReader(transport: wire)),
      ]);

      await tester.tap(find.widgetWithText(FilledButton, 'Export CSV'));
      await tester.pumpAndSettle();

      expect(find.textContaining('was not recorded'), findsOneWidget);
      expect(find.text('Export ready'), findsNothing);
    });

    testWidgets('an audited export reports ready, and the audit came '
        'first', (tester) async {
      final wire = FakeFleetReviewTransport()..metricsRows = [metricsRow()];
      await pump(tester, const FleetReportsScreen(), [
        fleetManagerDirectoryProvider.overrideWithValue(directory()),
        fleetMetricsReaderProvider
            .overrideWithValue(FleetMetricsReader(transport: wire)),
      ]);

      await tester.tap(find.widgetWithText(FilledButton, 'Export CSV'));
      await tester.pumpAndSettle();

      expect(wire.exportCalls.single.kind, 'period_metrics_csv');
      expect(find.text('Export ready'), findsOneWidget);
    });
  });
}
