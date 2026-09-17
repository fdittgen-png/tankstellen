// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/navigation/app_routes.dart';
import 'package:tankstellen/features/fill_ups/domain/services/tank_level_estimator.dart';
import 'package:tankstellen/features/fill_ups/presentation/screens/fuel_and_tank_screen.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/fuel_and_tank/fuel_and_tank_entry_button.dart';
import 'package:tankstellen/features/fill_ups/presentation/widgets/tank_level_card.dart';
import 'package:tankstellen/features/fill_ups/providers/tank_level_provider.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/never_truncates.dart';
import '../fuel_and_tank_test_support.dart';

/// #4278 — the Fuel & Tank surface survives the two text-expansion axes
/// (1.3× text at 320 dp, and the en_XA pseudo-locale), meets the Android
/// tap-target guideline, and is reachable from its one entry point on the
/// tank level card. The app ships no RTL locale (`supportedLocales`), so
/// there is no RTL case.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Every scenario that renders a different set of sections.
  final scenarios = <String, List<Object> Function()>{
    'recommend (all sections)': fuelAndTankOverrides,
    'unknown mix': () => fuelAndTankOverrides(tank: unknownTank()),
    'estimated, uncontrolled': () =>
        fuelAndTankOverrides(vehicle: e10Car, profile: estimatedProfile()),
    'compatibility unknown': () => fuelAndTankOverrides(vehicle: bareCar),
  };

  for (final entry in scenarios.entries) {
    testWidgets('${entry.key}: 320 dp at 1.3× text, expanded, no overflow',
        (tester) async {
      await pumpSurface(tester, const FuelAndTankBody(vehicleId: kVehicleId),
          overrides: entry.value(),
          size: const Size(320, 9000),
          textScale: 1.3);
      await expandAll(tester);
      expect(tester.takeException(), isNull);
      expectNoTextTruncates(tester);
    });

    testWidgets('${entry.key}: en_XA pseudo-locale at 320 dp, no overflow',
        (tester) async {
      await pumpSurface(tester, const FuelAndTankBody(vehicleId: kVehicleId),
          overrides: entry.value(),
          size: const Size(320, 9000),
          locale: const Locale('en', 'XA'));
      await expandAll(tester);
      expect(tester.takeException(), isNull);
      expectNoTextTruncates(tester);
    });
  }

  testWidgets('tap targets meet the Android guideline', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpSurface(tester, const FuelAndTankBody(vehicleId: kVehicleId),
        overrides: fuelAndTankOverrides(), size: const Size(420, 5000));
    await expandAll(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });

  group('entry point', () {
    final estimate = TankLevelEstimate(
      levelL: 32.4,
      capacityL: 50,
      lastFillUpDate: DateTime(2026, 9, 1),
      source: TankLevelSource.fillUp,
      sensorReadAt: null,
      rangeKm: 462,
    );

    Future<void> pumpCard(WidgetTester tester, VehicleProfile vehicle) async {
      tester.view.physicalSize = const Size(420, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(routes: [
        GoRoute(
            path: '/',
            builder: (_, _) =>
                const Scaffold(body: SingleChildScrollView(child: TankLevelCard()))),
        GoRoute(
            path: RoutePaths.fuelAndTank,
            builder: (_, _) => const FuelAndTankScreen()),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          ...fuelAndTankOverrides(vehicle: vehicle),
          tankLevelProvider(kVehicleId).overrideWith((ref) => estimate),
        ].cast(),
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('the tank level card opens the Fuel & Tank surface',
        (tester) async {
      await pumpCard(tester, flexCar);
      expect(find.text("What's in my tank?"), findsOneWidget);
      await tester.tap(find.byKey(const Key('fuel_and_tank_entry')));
      await tester.pumpAndSettle();
      expect(find.byType(FuelAndTankScreen), findsOneWidget);
      expect(find.text('Fuel & Tank'), findsOneWidget);
      expect(
          find.text('≥ 62 % E85 Bioethanol · ≥ 30 % Super E10 · 8 % unknown'),
          findsOneWidget);
    });

    testWidgets('an EV gets no entry point', (tester) async {
      await pumpCard(
          tester,
          const VehicleProfile(
              id: kVehicleId,
              name: 'EV',
              type: VehicleType.ev,
              tankCapacityL: 50));
      expect(find.byType(FuelAndTankEntryButton), findsOneWidget);
      expect(find.byKey(const Key('fuel_and_tank_entry')), findsNothing);
      expect(find.text("What's in my tank?"), findsNothing);
    });
  });
}
