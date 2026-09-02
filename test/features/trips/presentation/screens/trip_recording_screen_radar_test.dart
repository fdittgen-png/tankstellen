// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/features/approach/providers/effective_approach_state_provider.dart';
import 'package:tankstellen/features/approach/providers/radar_candidate_list_provider.dart';
import 'package:tankstellen/features/obd2/domain/trip_live_reading.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import 'package:tankstellen/features/trips/presentation/screens/trip_recording_screen.dart';
import 'package:tankstellen/features/trips/presentation/widgets/minimal_drive_summary.dart';
import 'package:tankstellen/features/trips/presentation/widgets/recording/recording_metric_grid.dart';
import 'package:tankstellen/features/trips/presentation/widgets/recording/recording_status_strip.dart';
import 'package:tankstellen/features/trips/presentation/widgets/trip_radar_card.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/trips/providers/wakelock_facade.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/silence_error_logger.dart';
import '../../../../helpers/recording_profile_override.dart';

/// #2380 / #3916 — the live recording column is driver-first: the hero
/// (MinimalDriveSummary: the one live figure + coaching cues) leads, the
/// OBD2 / GPS status strip sits under it, then the compact metric grid,
/// and the closest-station radar card closes the column.
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  // Tall portrait surface so the un-scrolled recording column (radar +
  // five metric cards + coaching card) lays out without a RenderFlex
  // overflow in the default 800×600 test window. Mirrors a phone.
  void useTallPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  const station = Station(
    id: 'stn-1',
    name: 'Tankstelle Mitte',
    brand: 'Aral',
    street: 'Hauptstr',
    postCode: '10115',
    place: 'Berlin',
    lat: 52.5,
    lng: 13.4,
    e10: 1.789,
    diesel: 1.659,
    isOpen: true,
  );

  testWidgets(
      'in-radius station price renders in the radar card BELOW the grid, '
      'under the hero and the status strip', (tester) async {
    useTallPhone(tester);
    // FR is the default active country; pin it so the expected price
    // string is deterministic regardless of test ordering.
    PriceFormatter.setCountry('FR');
    final expectedPrice = PriceFormatter.formatPrice(1.789); // e10

    await pumpApp(
      tester,
      const TripRecordingScreen(),
      overrides: [
        tripRecordingProvider.overrideWith(_LiveFakeTripRecording.new),
        wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
      recordingProfileOverride() as Object,
        // Fake provider override pushing an in-radius approach hit —
        // the radar card renders this station directly (no GPS / search
        // chain needed).
        effectiveApproachStateProvider.overrideWithValue(
          const ApproachInRadius(station: station, distanceMeters: 250),
        ),
        // Deterministic fuel → deterministic price column.
        effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
        // Fallback must stay out of the way while in-radius; empty keeps
        // it idle even if it were watched.
        radarCandidateListProvider.overrideWith((ref) async => const []),
      ],
    );

    // Card title + station name + the e10 price are all on screen.
    expect(find.text('Fuel Station Radar'), findsOneWidget);
    expect(find.text('Tankstelle Mitte'), findsOneWidget);
    expect(find.text(expectedPrice), findsOneWidget);

    // #3916 — hero → status strip → grid → radar, top to bottom.
    final heroTop = tester.getTopLeft(find.byType(MinimalDriveSummary)).dy;
    final stripTop =
        tester.getTopLeft(find.byType(RecordingStatusStrip)).dy;
    final gridTop = tester.getTopLeft(find.byType(RecordingMetricGrid)).dy;
    final radarTop = tester.getTopLeft(find.byType(TripRadarCard)).dy;
    expect(heroTop, lessThan(stripTop),
        reason: 'The hero must lead the column.');
    expect(stripTop, lessThan(gridTop),
        reason: 'The status strip sits directly under the hero.');
    expect(gridTop, lessThan(radarTop),
        reason: 'The radar card moves below the trip-figures grid.');
  });

  testWidgets(
      'idle approach + no nearest station → graceful placeholder closes '
      'the column', (tester) async {
    useTallPhone(tester);
    await pumpApp(
      tester,
      const TripRecordingScreen(),
      overrides: [
        tripRecordingProvider.overrideWith(_LiveFakeTripRecording.new),
        wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
      recordingProfileOverride() as Object,
        effectiveApproachStateProvider.overrideWithValue(null),
        effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
        radarCandidateListProvider.overrideWith((ref) async => const []),
      ],
    );

    expect(find.text('No station nearby'), findsOneWidget);
    final radarTop = tester.getTopLeft(find.byType(TripRadarCard)).dy;
    final heroTop = tester.getTopLeft(find.byType(MinimalDriveSummary)).dy;
    expect(heroTop, lessThan(radarTop),
        reason: 'The placeholder radar card still closes the column.');
  });
}

class _FakeWakelockFacade implements WakelockFacade {
  @override
  Future<void> enable() async {}
  @override
  Future<void> disable() async {}
}

class _LiveFakeTripRecording extends TripRecording {
  @override
  TripRecordingState build() => const TripRecordingState(
        phase: TripRecordingPhase.recording,
        live: TripLiveReading(
          distanceKmSoFar: 5.0,
          fuelLitersSoFar: 0.3,
          elapsed: Duration(minutes: 5),
        ),
      );

  @override
  Future<StoppedTripResult> stop({bool automatic = false}) async {
    return const StoppedTripResult(
      summary: TripSummary(
        distanceKm: 0,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
      ),
      odometerStartKm: null,
      odometerLatestKm: null,
    );
  }

  @override
  void reset() {
    state = const TripRecordingState();
  }
}
