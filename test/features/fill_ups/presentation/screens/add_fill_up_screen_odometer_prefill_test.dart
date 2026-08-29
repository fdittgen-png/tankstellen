// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3877 — the odometer field is prefilled from the car's last OBD2
// reading so a receipt scan is enough; never below the previous fill-up,
// never over a typed value; an untouched prefill is not "dirty".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/data/storage_repository.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/time/app_clock.dart';
import 'package:tankstellen/features/fill_ups/api.dart';
import 'package:tankstellen/features/vehicle/api.dart';

import '../../../../helpers/pump_app.dart';

class _StubVehicleList extends VehicleProfileList {
  @override
  List<VehicleProfile> build() => const [
        VehicleProfile(
            id: 'veh-1', name: 'Clio', type: VehicleType.combustion),
      ];
}

class _StubFillUps extends FillUpList {
  _StubFillUps(this._items);
  final List<FillUp> _items;
  @override
  List<FillUp> build() => _items;
}

class _Mem implements SettingsStorage {
  final Map<String, dynamic> m = {};
  @override
  dynamic getSetting(String key) => m[key];
  @override
  Future<void> putSetting(String key, dynamic value) async => m[key] = value;
  @override
  bool get isSetupComplete => true;
  @override
  bool get isSetupSkipped => false;
  @override
  Future<void> skipSetup() async {}
  @override
  Future<void> resetSetupSkip() async {}
}

final _now = DateTime(2026, 8, 29, 18, 45);

/// The form's own PopScope (the outermost one — #1693 discard guard).
bool _formCanPop(WidgetTester tester) => (tester
        .widget(find.byWidgetPredicate((w) => w is PopScope).first) as PopScope)
    .canPop;

TextField _odometerField(WidgetTester tester) {
  final f = tester.widget<FillUpNumericField>(find.ancestor(
      of: find.text('Odometer (km)'), matching: find.byType(FillUpNumericField)));
  return tester.widget<TextField>(find.descendant(
      of: find.byWidget(f), matching: find.byType(TextField)));
}

Future<VehicleOdometerSnapshotStore> _storeWith(
    {double? km, VehicleOdometerSource source = VehicleOdometerSource.obd2,
    Duration age = const Duration(minutes: 12)}) async {
  final store = VehicleOdometerSnapshotStore(_Mem());
  if (km != null) {
    await store.write('veh-1',
        VehicleOdometerSnapshot(km: km, at: _now.subtract(age), source: source));
  }
  return store;
}

Future<void> _pump(WidgetTester tester, VehicleOdometerSnapshotStore store,
    {List<FillUp> fillUps = const []}) async {
  await pumpApp(
    tester,
    const AddFillUpScreen(),
    overrides: [
      vehicleProfileListProvider.overrideWith(() => _StubVehicleList()),
      fillUpListProvider.overrideWith(() => _StubFillUps(fillUps)),
      vehicleOdometerSnapshotStoreProvider.overrideWithValue(store),
      appClockProvider.overrideWithValue(FixedClock(_now)),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('prefills the last car reading and shows the note',
      (tester) async {
    await _pump(tester, await _storeWith(km: 123456.4));
    expect(_odometerField(tester).controller!.text, '123456');
    expect(find.byKey(const Key('fillUpOdometerPrefillNote')), findsOneWidget);
    expect(find.textContaining('From your car'), findsOneWidget);
    // An untouched prefill must not arm the discard guard.
    expect(_formCanPop(tester), isTrue);
  });

  testWidgets('an estimate is labelled as such', (tester) async {
    await _pump(tester,
        await _storeWith(km: 123460, source: VehicleOdometerSource.obd2Estimate));
    expect(find.textContaining('Estimated from your car'), findsOneWidget);
  });

  testWidgets('a reading below the previous fill-up is NOT prefilled',
      (tester) async {
    final previous = FillUp(
      id: 'f1',
      vehicleId: 'veh-1',
      date: _now.subtract(const Duration(days: 2)),
      liters: 40,
      totalCost: 60,
      odometerKm: 130000,
      fuelType: FuelType.e10,
    );
    await _pump(tester, await _storeWith(km: 123456), fillUps: [previous]);
    expect(_odometerField(tester).controller!.text, isEmpty);
    expect(find.byKey(const Key('fillUpOdometerPrefillNote')), findsNothing);
  });

  testWidgets('no snapshot → field stays empty', (tester) async {
    await _pump(tester, await _storeWith());
    expect(_odometerField(tester).controller!.text, isEmpty);
  });

  testWidgets('editing the prefilled value drops the note and makes the '
      'form dirty', (tester) async {
    await _pump(tester, await _storeWith(km: 123456));
    await tester.enterText(find.byWidget(_odometerField(tester)), '123470');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fillUpOdometerPrefillNote')), findsNothing);
    expect(_formCanPop(tester), isFalse);
  });
}
