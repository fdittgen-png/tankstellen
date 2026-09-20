// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #4213 — the explicit switch. Recent-first, searchable by code, model
// or plate fragment, and never a route to a car the driver is not
// assigned. Pumped at 360 dp; the layout case at 1.6x German text.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/features/fleet/api.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../fleet_vehicle_test_support.dart';

const Size _phone360 = Size(360, 780);

/// Pumps a host screen whose one button opens the sheet, then opens it.
Future<void> _openSheet(
  WidgetTester tester,
  FleetHarness harness, {
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  tester.view.physicalSize = _phone360 * tester.view.devicePixelRatio;
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
            body: Center(
              child: Builder(
                builder: (inner) => TextButton(
                  key: const Key('open_sheet'),
                  onPressed: () => VehicleSwitchSheet.show(inner),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.byKey(const Key('open_sheet')));
  await tester.pumpAndSettle();
}

void main() {
  late FleetHarness harness;

  setUp(() => harness = FleetHarness());

  testWidgets('the sheet lists exactly the assigned vehicles, newest '
      'assignment first', (tester) async {
    harness.seedTwoAssignedVehicles();

    await _openSheet(tester, harness);

    expect(find.byKey(Key('fleet_vehicle_tile_${vanRow.id}')), findsOneWidget);
    expect(
        find.byKey(Key('fleet_vehicle_tile_${estateRow.id}')), findsOneWidget);
    expect(find.byKey(Key('fleet_vehicle_tile_${poolRow.id}')), findsNothing,
        reason: 'the unassigned pool car is not the driver\'s to pick');

    final van = tester.getTopLeft(find.byKey(
        Key('fleet_vehicle_tile_${vanRow.id}')));
    final estate = tester.getTopLeft(find.byKey(
        Key('fleet_vehicle_tile_${estateRow.id}')));
    expect(van.dy, lessThan(estate.dy));
  });

  testWidgets('the vehicle the driver picked last is first', (tester) async {
    harness.seedTwoAssignedVehicles();
    harness.seedSelection(estateRow.id, recents: [estateRow.id, vanRow.id]);

    await _openSheet(tester, harness);

    final van =
        tester.getTopLeft(find.byKey(Key('fleet_vehicle_tile_${vanRow.id}')));
    final estate = tester
        .getTopLeft(find.byKey(Key('fleet_vehicle_tile_${estateRow.id}')));
    expect(estate.dy, lessThan(van.dy));
    expect(find.byKey(const Key('fleet_vehicle_current_badge')),
        findsOneWidget);
  });

  testWidgets('search narrows by fleet code, model and plate fragment',
      (tester) async {
    harness.seedTwoAssignedVehicles();

    await _openSheet(tester, harness);
    final field = find.byKey(const Key('fleet_vehicle_switch_search'));

    await tester.enterText(field, 'octavia');
    await tester.pumpAndSettle();
    expect(
        find.byKey(Key('fleet_vehicle_tile_${estateRow.id}')), findsOneWidget);
    expect(find.byKey(Key('fleet_vehicle_tile_${vanRow.id}')), findsNothing);

    await tester.enterText(field, '1234');
    await tester.pumpAndSettle();
    expect(find.byKey(Key('fleet_vehicle_tile_${vanRow.id}')), findsOneWidget,
        reason: 'B-XY 1234 is found by its last plate group');

    await tester.enterText(field, 'van12');
    await tester.pumpAndSettle();
    expect(find.byKey(Key('fleet_vehicle_tile_${vanRow.id}')), findsOneWidget,
        reason: 'the hyphen a driver does not type must not matter');
  });

  testWidgets('a search that matches nothing shows the empty state, never '
      'an unfiltered list', (tester) async {
    harness.seedTwoAssignedVehicles();

    await _openSheet(tester, harness);
    await tester.enterText(
        find.byKey(const Key('fleet_vehicle_switch_search')), 'sprinter');
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.fleetVehicleSearchEmpty), findsOneWidget);
    expect(find.byKey(Key('fleet_vehicle_tile_${vanRow.id}')), findsNothing);
  });

  testWidgets('tapping a vehicle switches and closes the sheet',
      (tester) async {
    harness.seedTwoAssignedVehicles();

    await _openSheet(tester, harness);
    await tester.tap(find.byKey(Key('fleet_vehicle_tile_${estateRow.id}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fleet_vehicle_switch_search')), findsNothing);
    expect(harness.storage.getSetting(StorageKeys.fleetCurrentVehicleId),
        estateRow.id);
  });

  testWidgets('a stale directory says so, and still switches',
      (tester) async {
    harness.seedTwoAssignedVehicles(age: const Duration(days: 3));

    await _openSheet(tester, harness);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.fleetVehicleStaleNotice), findsOneWidget);
    expect(find.byKey(const Key('fleet_vehicle_switch_search')),
        findsOneWidget);
  });

  testWidgets('an expired directory shows the reason INSTEAD of a list',
      (tester) async {
    harness.seedTwoAssignedVehicles(age: const Duration(days: 8));

    await _openSheet(tester, harness);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.fleetVehicleExpiredNotice), findsOneWidget);
    expect(find.byKey(const Key('fleet_vehicle_switch_search')), findsNothing);
    expect(find.byKey(Key('fleet_vehicle_tile_${vanRow.id}')), findsNothing);
  });

  testWidgets('the fresh sheet states that switching does not rewrite '
      'history', (tester) async {
    harness.seedTwoAssignedVehicles();

    await _openSheet(tester, harness);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.fleetVehicleSwitchHelper), findsOneWidget);
  });

  testWidgets('at 360 dp and 1.6x German text the sheet lays out without '
      'an overflow', (tester) async {
    harness.seedTwoAssignedVehicles();

    await _openSheet(tester, harness,
        locale: const Locale('de'), textScale: 1.6);

    expect(tester.takeException(), isNull);
    final l10n = await AppLocalizations.delegate.load(const Locale('de'));
    expect(find.text(l10n.fleetVehicleSwitchTitle), findsOneWidget);
  });
}
