// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #2792 — surface the dongle-less IMU hard-accel/brake/sharp-corner counts
// (persisted on TripSummary, previously read by nothing) on a GPS-only trip.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/domain/trip_summary.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/imu_accel_brake_card.dart';

import '../../../../helpers/pump_app.dart';

TripSummary _summary({
  TripKind kind = TripKind.gpsOnly,
  int accel = 0,
  int brake = 0,
  int corner = 0,
  double distanceKm = 10,
}) =>
    TripSummary(
      distanceKm: distanceKm,
      maxRpm: 0,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      kind: kind,
      imuHardAccelCount: accel,
      imuHardBrakeCount: brake,
      sharpCornerCount: corner,
    );

void main() {
  group('ImuAccelBrakeCard.summaryFor gating (#2792)', () {
    test('GPS-only trip with at least one IMU event → shows the card', () {
      expect(ImuAccelBrakeCard.summaryFor(_summary(accel: 2)), isNotNull);
      expect(ImuAccelBrakeCard.summaryFor(_summary(brake: 1)), isNotNull);
      expect(ImuAccelBrakeCard.summaryFor(_summary(corner: 1)), isNotNull);
    });

    test('GPS-only calm trip (all IMU counts 0) → hidden (no false "0" claim)',
        () {
      expect(ImuAccelBrakeCard.summaryFor(_summary()), isNull);
    });

    test('OBD2 trip → hidden even with non-zero counts (no IMU on OBD2)', () {
      expect(
        ImuAccelBrakeCard.summaryFor(
            _summary(kind: TripKind.gpsPlusObd2, accel: 3)),
        isNull,
      );
    });
  });

  testWidgets('renders the three counts with per-km for a GPS-only trip',
      (tester) async {
    await pumpApp(
      tester,
      ImuAccelBrakeCard(summary: _summary(accel: 2, brake: 1, corner: 0)),
    );
    expect(find.byKey(const Key('accel_brake_card_title')), findsOneWidget);
    // 2 hard accels over 10 km → "2 (0.2/km)".
    expect(find.text('2 (0.2/km)'), findsOneWidget);
    expect(find.text('1 (0.1/km)'), findsOneWidget); // 1 brake
    expect(find.byKey(const Key('accel_brake_source')), findsOneWidget);
  });
}
