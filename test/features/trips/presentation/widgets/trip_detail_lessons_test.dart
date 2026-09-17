// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/features/driving_score/api.dart';
import 'package:tankstellen/features/driving_score/data/lessons/rules/combustion_health_rule.dart';
import 'package:tankstellen/features/fill_ups/domain/entities/fill_up.dart';
import 'package:tankstellen/features/fill_ups/providers/consumption_providers.dart';
import 'package:tankstellen/features/trips/api.dart';
import 'package:tankstellen/features/trips/presentation/widgets/trip_detail_lessons.dart';
import 'package:tankstellen/features/vehicle/providers/vehicle_providers.dart';
import 'package:tankstellen/l10n/app_localizations_en.dart';

/// #4322 / #3701 — the trip lessons' ethanol share, driven through the REAL
/// fill-up log → tank blend → tankMixProvider → CombustionHealthRule path.
///
/// Excusing a lean trim needs the ethanol that could PLAUSIBLY explain it
/// (an upper bound), so a pure E85 tank must keep the #3701 fix: no
/// "lean +25 %" alarm on every trip of an E85 conversion.
class _Vehicles extends VehicleProfileList {
  _Vehicles(this._value);
  final VehicleProfile _value;
  @override
  List<VehicleProfile> build() => [_value];
}

class _FillUps extends FillUpList {
  _FillUps(this._value);
  final List<FillUp> _value;
  @override
  List<FillUp> build() => _value;
}

class _Trips extends TripHistoryList {
  @override
  List<TripHistoryEntry> build() => const [];
}

void main() {
  final start = DateTime.utc(2026, 9, 1, 8);

  final entry = TripHistoryEntry(
    id: 't1',
    vehicleId: 'v1',
    summary: TripSummary(
      distanceKm: 30,
      maxRpm: 3000,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      startedAt: start,
    ),
  );

  List<TripSample> warm({required double stft, required double ltft}) => [
        for (var i = 0; i < 14; i++)
          TripSample(
            timestamp: start.add(Duration(seconds: i)),
            speedKmh: 80,
            rpm: 2200,
            coolantTempC: 90,
            stft: stft,
            ltft: ltft,
          ),
      ];

  FillUp fill(String id, int day, FuelType fuel, double litres,
          {bool full = true}) =>
      FillUp(
        id: id,
        date: DateTime.utc(2026, 8, day),
        liters: litres,
        totalCost: litres * 1.2,
        odometerKm: 1000.0 + day * 300,
        fuelType: fuel,
        vehicleId: 'v1',
        isFullTank: full,
      );

  const flexE85 = VehicleProfile(
    id: 'v1',
    name: '107 E85',
    tankCapacityL: 35,
    preferredFuelType: 'e85',
    multiFuelCapable: true,
  );
  const e10Only = VehicleProfile(
    id: 'v1',
    name: 'E10',
    tankCapacityL: 35,
    preferredFuelType: 'e10',
    multiFuelCapable: true,
  );

  /// The lesson ids the real combustion-health rule fires for [samples].
  Future<List<String>> lessons(WidgetTester tester, VehicleProfile vehicle,
      List<FillUp> fills, List<TripSample> samples) async {
    late List<DrivingLesson> out;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        vehicleProfileListProvider.overrideWith(() => _Vehicles(vehicle)),
        fillUpListProvider.overrideWith(() => _FillUps(fills)),
        tripHistoryListProvider.overrideWith(_Trips.new),
      ],
      child: Consumer(builder: (context, ref, _) {
        out = buildTripDetailLessons(
          ref: ref,
          registry: DrivingLessonRegistry([const CombustionHealthRule()]),
          entry: entry,
          samples: samples,
          score: DrivingScore.perfect,
          insights: const [],
          l: AppLocalizationsEn(),
        );
        return const SizedBox.shrink();
      }),
    ));
    return [for (final l in out) l.id];
  }

  group('#3701 regression — a pure E85 tank from real fill events', () {
    final e85Tank = [fill('a', 1, FuelType.e85, 35)];

    testWidgets('+25 % and +30 % lean trims are the fuel: no warning',
        (tester) async {
      expect(await lessons(tester, flexE85, e85Tank, warm(stft: 5, ltft: 25)),
          isEmpty);
      expect(await lessons(tester, flexE85, e85Tank, warm(stft: 5, ltft: 30)),
          isEmpty);
    });

    testWidgets('lean beyond 0.85 × 34 % + 8 % still fires', (tester) async {
      expect(await lessons(tester, flexE85, e85Tank, warm(stft: 5, ltft: 40)),
          [combustionHealthLessonId]);
    });

    testWidgets('rich-side trims still fire', (tester) async {
      expect(
          await lessons(tester, flexE85, e85Tank, warm(stft: -6, ltft: -16)),
          [combustionHealthLessonId]);
    });
  });

  testWidgets('an E10-only car with +25 % lean still warns', (tester) async {
    expect(
        await lessons(tester, e10Only, [fill('a', 1, FuelType.e10, 35)],
            warm(stft: 5, ltft: 25)),
        [combustionHealthLessonId]);
  });

  testWidgets('an unknown residual with no E85 history gets no E85 excuse',
      (tester) async {
    // A partial E10 fill: most of the tank is unattributed, but nothing in
    // the log or the approvals was ever E85.
    expect(
        await lessons(tester, e10Only,
            [fill('a', 1, FuelType.e10, 10, full: false)],
            warm(stft: 5, ltft: 25)),
        [combustionHealthLessonId]);
  });
}
