// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4213 — the current-vehicle chip. Every case is pumped at 360 dp,
// and the layout cases at 1.6× text in GERMAN: German fleet wording is
// the longest of the shipped source locales, so a row that survives it
// survives the fan-out.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/fleet/api.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../fleet_vehicle_test_support.dart';

/// A small phone — the width every fleet surface must survive.
const Size _phone360 = Size(360, 780);

Future<void> _pumpControl(
  WidgetTester tester,
  FleetHarness harness, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  Size size = _phone360,
  VehicleAttributionResolution? proposal,
}) async {
  tester.view.physicalSize = size * tester.view.devicePixelRatio;
  tester.view.devicePixelRatio = tester.view.devicePixelRatio;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: harness.overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: CurrentVehicleControl(proposal: proposal),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  late FleetHarness harness;

  setUp(() => harness = FleetHarness());

  testWidgets('a personal user sees nothing at all', (tester) async {
    await _pumpControl(tester, harness);

    expect(find.byKey(const Key('fleet_current_vehicle_control')),
        findsNothing);
  });

  testWidgets('a fleet driver sees the fleet code and model of the '
      'current vehicle', (tester) async {
    harness.seedTwoAssignedVehicles();

    await _pumpControl(tester, harness);

    expect(find.byKey(const Key('fleet_current_vehicle_control')),
        findsOneWidget);
    expect(find.text('VAN-12 · VW Caddy 2.0 TDI'), findsOneWidget);
    expect(find.byKey(const Key('fleet_current_vehicle_stale_badge')),
        findsNothing);
  });

  testWidgets('the chip is localised — a German driver never reads an '
      'English label', (tester) async {
    harness.seedTwoAssignedVehicles();

    await _pumpControl(tester, harness, locale: const Locale('de'));

    final l10n = await AppLocalizations.delegate.load(const Locale('de'));
    expect(find.text(l10n.fleetVehicleCurrentLabel), findsOneWidget);
    expect(l10n.fleetVehicleCurrentLabel, isNot('Current vehicle'));
  });

  testWidgets('at 360 dp and 1.6x German text the chip still lays out '
      'without an overflow', (tester) async {
    harness.seedTwoAssignedVehicles();

    await _pumpControl(tester, harness,
        locale: const Locale('de'), textScale: 1.6);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('fleet_current_vehicle_control')),
        findsOneWidget);
  });

  testWidgets('an offline (stale) directory renders the copy badge and '
      'still opens the switch', (tester) async {
    harness.seedTwoAssignedVehicles(age: const Duration(days: 3));

    await _pumpControl(tester, harness);

    expect(find.byKey(const Key('fleet_current_vehicle_stale_badge')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('fleet_current_vehicle_control')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fleet_vehicle_switch_search')),
        findsOneWidget);
  });

  testWidgets('an EXPIRED directory disables the chip — tapping opens '
      'nothing (ADR 0025 D4)', (tester) async {
    harness.seedTwoAssignedVehicles(age: const Duration(days: 8));

    await _pumpControl(tester, harness);

    expect(find.text('VAN-12 · VW Caddy 2.0 TDI'), findsOneWidget,
        reason: 'the vehicle it last knew is still shown, not replaced');
    expect(find.byKey(const Key('fleet_current_vehicle_stale_badge')),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('fleet_current_vehicle_control')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fleet_vehicle_switch_search')), findsNothing,
        reason: 'an expired directory must not offer a vehicle to pick');
  });

  testWidgets('a driver between assignments sees the empty label, not a '
      'stale car', (tester) async {
    harness.seedMembership();
    harness.seedDirectory(directoryOf(
      vehicles: const [vanRow],
      assignments: [
        assignment(vanRow.id,
            startedAgo: const Duration(days: 30),
            endedAgo: const Duration(hours: 1)),
      ],
    ));

    await _pumpControl(tester, harness);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.fleetVehicleNoneAssigned), findsOneWidget);
    expect(find.text('VAN-12 · VW Caddy 2.0 TDI'), findsNothing);
  });

  testWidgets('conflicting adapter/VIN evidence renders the '
      '"needs confirmation" state and still names the current vehicle',
      (tester) async {
    harness.seedTwoAssignedVehicles();
    final conflict = VehicleAttributionResolver.resolve(
      [
        VehicleSignal(
          source: VehicleAttributionSource.adapterIdentity,
          fleetVehicleId: vanRow.id,
          confidence: 0.95,
        ),
        VehicleSignal(
          source: VehicleAttributionSource.vin,
          fleetVehicleId: estateRow.id,
          confidence: 0.99,
        ),
      ],
      clock: FixedClock(fleetNow),
    );

    await _pumpControl(tester, harness, proposal: conflict);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.fleetVehicleNeedsConfirmationTitle), findsOneWidget);
    expect(find.text('VAN-12 · VW Caddy 2.0 TDI'), findsNothing,
        reason: 'the chip must not read as a settled attribution while '
            'the signals disagree');

    await tester.tap(find.byKey(const Key('fleet_current_vehicle_control')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fleet_vehicle_switch_search')),
        findsOneWidget,
        reason: 'the way out of the conflict is an explicit pick');
  });

  testWidgets('a CONFIRMED proposal for the other car changes nothing on '
      'the chip — attribution is the caller\'s job, switching is the '
      'driver\'s', (tester) async {
    harness.seedTwoAssignedVehicles();
    final confirmed = VehicleAttributionResolver.resolve(
      [
        VehicleSignal(
          source: VehicleAttributionSource.adapterIdentity,
          fleetVehicleId: estateRow.id,
          confidence: 1,
        ),
      ],
      clock: FixedClock(fleetNow),
    );

    await _pumpControl(tester, harness, proposal: confirmed);

    expect(confirmed.verdict, VehicleAttributionVerdict.confirmed);
    expect(find.text('VAN-12 · VW Caddy 2.0 TDI'), findsOneWidget,
        reason: '#4213: never silently switch because OBD2 suggests '
            'another car');
  });

  testWidgets('the chip announces the vehicle to a screen reader, once',
      (tester) async {
    harness.seedTwoAssignedVehicles();
    final handle = tester.ensureSemantics();

    await _pumpControl(tester, harness);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(
      find.bySemanticsLabel(
          l10n.fleetVehicleSemanticsCurrent('VAN-12 · VW Caddy 2.0 TDI')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
