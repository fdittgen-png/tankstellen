// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/features/approach/providers/effective_approach_state_provider.dart';
import 'package:tankstellen/features/approach/providers/radar_candidate_list_provider.dart';
import 'package:tankstellen/features/obd2/data/trip_live_reading.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_recording_screen.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/minimal_drive_summary.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_radar_card.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_recording_landscape_body.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/consumption/providers/wakelock_facade.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/recording_profile_override.dart';
import '../../../../helpers/silence_error_logger.dart';

/// #2903 — the LANDSCAPE recording layout is a dedicated glanceable,
/// zero-touch split distinct from portrait: live feedback (instant
/// consumption + eco-coaching cues + speed) on the LEFT, trip + radar
/// (Fuel Station Radar on top, then a 2×2 Distance/Avg/Elapsed/Fuel
/// grid) on the RIGHT. Every key metric is visible at once with NO
/// scrolling. Portrait stays the scrolling vertical list.
///
/// The layout body ([TripRecordingLandscapeBody]) is tested directly in
/// a phone-landscape-sized box so the assertion isolates the new layout
/// from the always-on-in-debug OBD2 breadcrumb diagnostic overlay (which
/// the host screen floats in a Stack and is unrelated to this layout).
/// A separate, lighter screen-level test confirms the orientation
/// routing (landscape mounts the body; portrait does not).
void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

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

  const reading = TripLiveReading(
    distanceKmSoFar: 5.0,
    fuelLitersSoFar: 0.3,
    elapsed: Duration(minutes: 5),
    speedKmh: 88.0,
  );

  List<Object> bodyOverrides() => [
        wakelockFacadeProvider.overrideWithValue(_FakeWakelockFacade()),
        recordingProfileOverride() as Object,
        effectiveApproachStateProvider.overrideWithValue(
          const ApproachInRadius(station: station, distanceMeters: 250),
        ),
        effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
        radarCandidateListProvider.overrideWith((ref) async => const []),
      ];

  /// Pumps [TripRecordingLandscapeBody] inside a fixed phone-landscape
  /// box (≈ a 6" phone in landscape, minus chrome) so RenderFlex
  /// overflow is asserted against a realistic glanceable surface.
  Future<void> pumpLandscapeBody(
    WidgetTester tester, {
    double textScaleFactor = 1.0,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: bodyOverrides().cast(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(textScaleFactor),
            ),
            // ≈ a 6"-class phone in landscape, minus the AppBar + the
            // 16-dp body padding the host scaffold applies.
            child: const Scaffold(
              body: SizedBox(
                width: 860,
                height: 320,
                child: TripRecordingLandscapeBody(
                  reading: reading,
                  brokenMapOverride: null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
      'landscape body shows instant-consumption + speed on the left and '
      'radar + distance/avg/elapsed/fuel on the right, with NO overflow',
      (tester) async {
    await pumpLandscapeBody(tester);

    // LEFT zone — live driving feedback.
    expect(find.byType(MinimalDriveSummary), findsOneWidget);
    expect(
        find.byKey(const Key('minimal_drive_instant_value')), findsOneWidget);
    expect(find.byKey(const Key('landscapeSpeedTile')), findsOneWidget);
    expect(find.text('Speed'), findsOneWidget);

    // RIGHT zone — radar on top.
    expect(find.byType(TripRadarCard), findsOneWidget);
    expect(find.text('Fuel Station Radar'), findsOneWidget);

    // 2×2 grid — Distance / Avg / Elapsed / Fuel used all present.
    expect(find.byKey(const Key('landscapeDistanceTile')), findsOneWidget);
    expect(find.byKey(const Key('landscapeAvgTile')), findsOneWidget);
    expect(find.byKey(const Key('landscapeElapsedTile')), findsOneWidget);
    expect(find.byKey(const Key('landscapeFuelTile')), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('Avg'), findsOneWidget);
    expect(find.text('Elapsed'), findsOneWidget);
    expect(find.text('Fuel used'), findsOneWidget);

    // The metric values render (not just labels).
    expect(find.text('5.00 km'), findsOneWidget);
    expect(find.text('88 km/h'), findsOneWidget);

    // No scrolling: the body must NOT introduce a scroll view of its own.
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byType(ListView), findsNothing);

    // Layout contract: the live-feedback zone is LEFT of the radar zone.
    final radarLeft = tester.getTopLeft(find.byType(TripRadarCard)).dx;
    final speedLeft =
        tester.getTopLeft(find.byKey(const Key('landscapeSpeedTile'))).dx;
    expect(speedLeft, lessThan(radarLeft),
        reason: 'Live-feedback zone must sit left of the trip/radar zone.');

    // No RenderFlex overflow at a phone-landscape size.
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape body does not overflow at a 1.3x text scale',
      (tester) async {
    await pumpLandscapeBody(tester, textScaleFactor: 1.3);

    expect(find.byType(TripRecordingLandscapeBody), findsOneWidget);
    expect(find.byKey(const Key('landscapeSpeedTile')), findsOneWidget);
    expect(find.byKey(const Key('landscapeFuelTile')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'screen routes to the landscape body in landscape and to the '
      'scrolling list in portrait (portrait unchanged)', (tester) async {
    final overrides = <Object>[
      tripRecordingProvider.overrideWith(_LiveFakeTripRecording.new),
      ...bodyOverrides(),
    ];

    // Portrait — taller than wide: the scrolling list, NOT the split.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester, const TripRecordingScreen(), overrides: overrides);
    expect(find.byType(TripRecordingLandscapeBody), findsNothing,
        reason: 'Portrait must keep the existing scrolling list.');
    // The portrait scrolling list is present (the screen's own
    // SingleChildScrollView; the debug overlay also has one, so we only
    // assert the landscape split is absent and the radar still renders).
    expect(find.byType(TripRadarCard), findsOneWidget);
    expect(find.byType(MinimalDriveSummary), findsOneWidget);

    // Landscape — wider than tall: the dedicated split body is mounted.
    tester.view.physicalSize = const Size(2400, 1080);
    await tester.pumpAndSettle();
    expect(find.byType(TripRecordingLandscapeBody), findsOneWidget,
        reason: 'Landscape must render the dedicated split body.');
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
          speedKmh: 88.0,
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
