// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/consumption_estimate.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_analyzer.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_evidence.dart';
import 'package:tankstellen/core/domain/fuel/fuel_behaviour_profile.dart';
import 'package:tankstellen/core/domain/fuel/fuel_grade.dart';
import 'package:tankstellen/core/domain/fuel/next_fill_request.dart';
import 'package:tankstellen/core/domain/fuel/tank_blend_snapshot.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/storage/storage_providers.dart';
import 'package:tankstellen/features/fill_ups/providers/fuel_and_tank_provider.dart';
import 'package:tankstellen/features/fill_ups/providers/fuel_behaviour_provider.dart';
import 'package:tankstellen/features/fill_ups/providers/tank_blend_provider.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../core/domain/fuel/fuel_behaviour_fixtures.dart';
import '../../../fakes/fake_storage_repository.dart';

/// Shared SYNTHETIC scenarios for the Fuel & Tank widget tests (#4278).
///
/// Only the LEAF providers are replaced — the vehicle list, the tank blend,
/// the behaviour profile, the offers and the settings box. The request, the
/// real `NextFillDecider` and the view model all run, so a widget test can
/// never pass on a fake that echoes what it was asked.

const kVehicleId = 'v1';

const flexCar = VehicleProfile(
  id: kVehicleId,
  name: 'Flex',
  tankCapacityL: 50,
  preferredFuelType: 'e85',
  multiFuelCapable: true,
);

const e10Car = VehicleProfile(
  id: kVehicleId,
  name: 'E10',
  tankCapacityL: 50,
  preferredFuelType: 'e10',
);

const bareCar = VehicleProfile(id: kVehicleId, name: 'Bare', tankCapacityL: 50);

final _factors = <FuelGrade, Co2eFactor>{
  FuelGrade.e10: Co2eFactor(
      kgCo2ePerLitre: 2.27,
      source: 'test',
      version: 't1',
      boundary: Co2eBoundary.wellToWheel),
  FuelGrade.e85: Co2eFactor(
      kgCo2ePerLitre: 1.40,
      source: 'test',
      version: 't1',
      boundary: Co2eBoundary.wellToWheel),
};

/// E10 ×1.0 and E85 ×1.3 over residual-controlled measured trips, with
/// two priced full-to-full windows each when [windows].
FuelBehaviourProfile flexProfile({bool windows = true}) =>
    FuelBehaviourAnalyzer.analyze(
      timeline: referenceTimeline(),
      trips: [
        ...tripsOn('e10-', 0.5, 10, factor: 1.0),
        ...tripsOn('e85-', 11.5, 10, factor: 1.3),
      ],
      windows: windows
          ? [
              window('w10a', 0, 5, lPer100Km: 6.0),
              window('w10b', 5, 10, lPer100Km: 6.2),
              window('w85a', 11, 16, lPer100Km: 7.8, pricePerLitre: 1.1),
              window('w85b', 16, 21, lPer100Km: 8.0, pricePerLitre: 1.1),
            ]
          : const [],
      tankCapacityLitres: kCapacity,
      co2eFactors: (g) => _factors[g],
    );

/// Ten estimated E10 trips without an expected figure: uncontrolled.
FuelBehaviourProfile estimatedProfile() => FuelBehaviourAnalyzer.analyze(
      timeline: referenceTimeline(),
      trips: tripsOn('e10-', 0.5, 10,
          factor: 1.0,
          withExpected: false,
          source: ConsumptionSourceClass.estimated),
      windows: const [],
      tankCapacityLitres: kCapacity,
    );

/// Three E10 trips: below every minimum-evidence threshold.
FuelBehaviourProfile thinProfile() => FuelBehaviourAnalyzer.analyze(
      timeline: referenceTimeline(),
      trips: tripsOn('e10-', 0.5, 3, factor: 1.0),
      windows: const [],
      tankCapacityLitres: kCapacity,
    );

TankBlendSnapshot tankOf(Map<FuelGrade, double> shares,
        {double min = 20, double? max = 30}) =>
    TankBlendSnapshot(
      gradeShares: shares,
      minLitres: min,
      maxLitres: max,
      tankCapacityLitres: kCapacity,
      appliedEventIds: const [],
      logFingerprint: 0,
    );

/// ≥ 62 % E85 · ≥ 30 % E10 · 8 % unknown, 20–30 L.
TankBlendSnapshot partialTank() => tankOf(
    {FuelGrade.e85: 0.62, FuelGrade.e10: 0.30, FuelGrade.unknown: 0.08});

TankBlendSnapshot unknownTank() =>
    tankOf({FuelGrade.unknown: 1}, min: 0, max: 50);

List<FuelOffer> offers({double? e10 = 1.80, double? e85 = 1.10}) => [
      if (e10 != null) FuelOffer(grade: FuelGrade.e10, pricePerLitre: e10),
      if (e85 != null) FuelOffer(grade: FuelGrade.e85, pricePerLitre: e85),
    ];

class _Vehicles extends VehicleProfileList {
  _Vehicles(this._value);
  final VehicleProfile _value;
  @override
  List<VehicleProfile> build() => [_value];
}

class _Active extends ActiveVehicleProfile {
  _Active(this._value);
  final VehicleProfile _value;
  @override
  VehicleProfile? build() => _value;
}

/// The leaf overrides of one scenario.
List<Object> fuelAndTankOverrides({
  VehicleProfile vehicle = flexCar,
  TankBlendSnapshot? tank,
  FuelBehaviourProfile? profile,
  List<FuelOffer>? offerList,
  FillObjective? objective,
  FakeStorageRepository? storage,
}) {
  final settings = storage ?? FakeStorageRepository();
  if (objective != null) {
    unawaited(settings.putSetting(StorageKeys.fillObjective, objective.name));
  }
  return [
    storageRepositoryProvider.overrideWithValue(settings),
    vehicleProfileListProvider.overrideWith(() => _Vehicles(vehicle)),
    activeVehicleProfileProvider.overrideWith(() => _Active(vehicle)),
    tankBlendProvider(kVehicleId).overrideWithValue(tank ?? partialTank()),
    fuelBehaviourProfileProvider(kVehicleId)
        .overrideWithValue(profile ?? flexProfile()),
    nextFillOffersProvider(kVehicleId).overrideWithValue(offerList ?? offers()),
  ];
}

/// Pumps [child] at [size] with [textScale] under [locale], every section
/// built (tall surfaces keep the lazy list from skipping any).
Future<void> pumpSurface(
  WidgetTester tester,
  Widget child, {
  required List<Object> overrides,
  Size size = const Size(420, 5000),
  double textScale = 1.0,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: MediaQuery(
        data: MediaQueryData(
            size: size, textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: child),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

/// Expands every disclosure on the surface.
Future<void> expandAll(WidgetTester tester) async {
  for (final key in const [
    Key('fuel_and_tank_candidates'),
    Key('fuel_and_tank_behaviour_details'),
  ]) {
    final f = find.byKey(key);
    if (f.evaluate().isEmpty) continue;
    await tester.ensureVisible(f);
    await tester.tap(find.descendant(of: f, matching: find.byType(ListTile)));
    await tester.pumpAndSettle();
  }
}
