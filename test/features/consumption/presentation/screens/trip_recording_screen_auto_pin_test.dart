// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/cold_start_baselines.dart';
import 'package:tankstellen/features/consumption/domain/entities/recording_profile.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/screens/trip_recording_screen.dart';
import 'package:tankstellen/features/consumption/providers/recording_profile_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/consumption/providers/wakelock_facade.dart';
import '../../../../helpers/silence_error_logger.dart';
import '../../../../helpers/pump_app.dart';

/// #2274 concern 1 — the persisted [RecordingProfile.autoPin], when ON,
/// must pin the recording form automatically on the screen's mount
/// (wake lock acquired, no user tap). Default OFF must NOT auto-pin —
/// preserving the deliberate opt-in-each-drive design of #891.

class _FakeWakelockFacade implements WakelockFacade {
  int enableCalls = 0;
  int disableCalls = 0;

  @override
  Future<void> enable() async => enableCalls++;

  @override
  Future<void> disable() async => disableCalls++;
}

/// Recording-phase fake so the screen treats the trip as active (the
/// gate `_maybeApplyAutoPin` requires).
class _ActiveTripRecording extends TripRecording {
  @override
  TripRecordingState build() => const TripRecordingState(
        phase: TripRecordingPhase.recording,
        situation: DrivingSituation.highwayCruise,
        band: ConsumptionBand.normal,
      );

  @override
  Future<StoppedTripResult> stop({bool automatic = false}) async {
    state = state.copyWith(phase: TripRecordingPhase.finished);
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
  void reset() => state = const TripRecordingState();
}

/// Fake profile controller exposing a fixed global profile + effective
/// override result so the screen's auto-pin read is deterministic
/// without touching Hive.
class _FakeProfile extends RecordingProfileController {
  _FakeProfile(this._profile);
  final RecordingProfile _profile;

  @override
  RecordingProfile build() => _profile;

  @override
  RecordingProfile effectiveFor(String? vehicleId) => _profile;
}

Future<void> _pump(
  WidgetTester tester, {
  required _FakeWakelockFacade facade,
  required RecordingProfile profile,
}) async {
  await pumpApp(
    tester,
    const TripRecordingScreen(),
    overrides: [
      tripRecordingProvider.overrideWith(() => _ActiveTripRecording()),
      wakelockFacadeProvider.overrideWithValue(facade),
      recordingProfileControllerProvider
          .overrideWith(() => _FakeProfile(profile)),
    ],
  );
}

/// #2764 — Pin lives inside the trailing overflow kebab now; open it so
/// the pin item (with its icon) is mounted before asserting the icon.
Future<void> _openOverflow(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('recording_overflow_menu')));
  await tester.pumpAndSettle();
}

void main() {
  silenceErrorLoggerSpool();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TripRecordingScreen auto-pin (#2274 concern 1)', () {
    testWidgets('autoPin ON pins on mount — wake lock + filled pin icon',
        (tester) async {
      final facade = _FakeWakelockFacade();
      await _pump(
        tester,
        facade: facade,
        profile: const RecordingProfile(autoPin: true),
      );

      expect(facade.enableCalls, 1,
          reason: 'autoPin must acquire the wake lock without a user tap');
      await _openOverflow(tester);
      expect(
        find.descendant(
          of: find.byKey(const Key('tripPinButton')),
          matching: find.byIcon(Icons.push_pin),
        ),
        findsOneWidget,
        reason: 'the form renders pinned (filled icon) on mount',
      );
    });

    testWidgets('autoPin OFF (default) does NOT pin — preserves opt-in',
        (tester) async {
      final facade = _FakeWakelockFacade();
      await _pump(
        tester,
        facade: facade,
        profile: RecordingProfile.defaults,
      );

      expect(facade.enableCalls, 0,
          reason: 'default autoPin OFF must not auto-acquire the wake lock');
      await _openOverflow(tester);
      expect(
        find.descendant(
          of: find.byKey(const Key('tripPinButton')),
          matching: find.byIcon(Icons.push_pin_outlined),
        ),
        findsOneWidget,
        reason: 'the form starts unpinned (outlined icon) by default',
      );
    });
  });
}
