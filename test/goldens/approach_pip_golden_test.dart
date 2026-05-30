// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_recording_pip_view.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_phase.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_state.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../helpers/pump_app.dart';

/// Golden coverage for the ApproachOverlay / PiP tile (#2163/#2164 — new
/// surface with no goldens). `TripRecordingPipView` is paint-only and
/// flips to the huge-price approach layout when handed an
/// [ApproachInRadius] / [ApproachLeaving] state — the exact surface the
/// approach feature renders on the OS PiP tile.
const _station = Station(
  id: 's-approach',
  name: 'Aral Tankstelle',
  brand: 'ARAL',
  street: 'Leipziger Str. 12',
  postCode: '10117',
  place: 'Berlin',
  lat: 52.5100,
  lng: 13.3900,
  e5: 1.899,
  e10: 1.849,
  diesel: 1.799,
  isOpen: true,
);

void main() {
  group('TripRecordingPipView golden — approach overlay (#2163/#2164)', () {
    testWidgets('in-radius flips to the huge-price layout', (tester) async {
      await pumpApp(
        tester,
        const Center(
          child: RepaintBoundary(
            child: SizedBox(
              width: 220,
              height: 200,
              child: TripRecordingPipView(
                state: TripRecordingState(
                  phase: TripRecordingPhase.recording,
                ),
                backgroundColor: Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                fuelType: FuelType.e10,
                approachState: ApproachInRadius(
                  station: _station,
                  distanceMeters: 320,
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(TripRecordingPipView),
        matchesGoldenFile('approach_pip_in_radius.png'),
      );
    });

    testWidgets('leaving keeps the price through the grace window',
        (tester) async {
      await pumpApp(
        tester,
        const Center(
          child: RepaintBoundary(
            child: SizedBox(
              width: 220,
              height: 200,
              child: TripRecordingPipView(
                state: TripRecordingState(
                  phase: TripRecordingPhase.recording,
                ),
                backgroundColor: Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                fuelType: FuelType.diesel,
                approachState: ApproachLeaving(lastStation: _station),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(TripRecordingPipView),
        matchesGoldenFile('approach_pip_leaving.png'),
      );
    });
  });
}
