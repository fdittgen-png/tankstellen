// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/services/voice_announcement_providers.dart';
import 'package:tankstellen/core/services/voice_announcement_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/trip_live_reading.dart';
import 'package:tankstellen/features/consumption/domain/driving_coaching.dart'
    show DrivingCoachingHint;
import 'package:tankstellen/features/consumption/domain/harsh_event.dart';
import 'package:tankstellen/features/consumption/domain/situation_classifier.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/features/driving/providers/driving_coach_voice_listener_provider.dart';
import 'package:tankstellen/features/driving/providers/live_harsh_event_bus_provider.dart';
import 'package:tankstellen/features/driving/providers/voice_coaching_enabled_provider.dart';
import 'package:tankstellen/l10n/app_localizations_en.dart';

import '../../../helpers/silence_error_logger.dart';

/// Wiring test for `drivingCoachVoiceListenerProvider` (#2663).
///
/// The dead-link bug: every driving cue (harsh events, OBD2/GPS hints,
/// GlideCoach lift) dead-ended without speech because the coach was NEVER
/// wired to TTS. This test drives a real harsh event through the live bus
/// during recording and asserts the listener spoke it — RED on master (no
/// listener, no speakLine, no bus), GREEN once the wire is built.

/// Fake TTS service capturing every speakLine / announce call.
class _FakeVoiceAnnouncementService implements VoiceAnnouncementService {
  final List<String> spokenLines = [];
  final List<AnnouncementCandidate> announced = [];
  bool initialized = false;

  @override
  Future<void> initialize() async => initialized = true;

  @override
  Future<void> announce(AnnouncementCandidate candidate) async =>
      announced.add(candidate);

  @override
  Future<void> speakLine(String text) async => spokenLines.add(text);

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> setLanguage(String languageCode) async {}
}

/// Toggle stub returning a fixed enabled value (default-ON or forced OFF)
/// without touching SharedPreferences.
class _FakeVoiceCoachingEnabled extends VoiceCoachingEnabled {
  _FakeVoiceCoachingEnabled(this._value);
  final bool _value;

  @override
  bool build() => _value;
}

/// Language stub returning English without touching Hive / profile
/// storage (the listener resolves cue strings via the active language).
class _FakeActiveLanguage extends ActiveLanguage {
  @override
  AppLanguage build() => const AppLanguage('en', 'English', 'English');
}

/// TripRecording stub seeded with a state we can mutate to drive hint
/// transitions through the listener's `ref.listen`.
class _FakeTripRecording extends TripRecording {
  @override
  TripRecordingState build() => const TripRecordingState();

  void emit(TripRecordingState next) => state = next;
}

final _enCues = AppLocalizationsEn();

void main() {
  silenceErrorLoggerSpool();

  late _FakeVoiceAnnouncementService fakeTts;
  late DateTime fakeNow;

  setUp(() {
    fakeTts = _FakeVoiceAnnouncementService();
    fakeNow = DateTime.utc(2026, 6, 1, 12);
    DrivingCoachVoiceListener.clockOverride = () => fakeNow;
  });

  tearDown(() {
    DrivingCoachVoiceListener.clockOverride = null;
  });

  ProviderContainer makeContainer({
    required bool enabled,
    _FakeTripRecording? recording,
  }) {
    final c = ProviderContainer(
      overrides: [
        voiceCoachingEnabledProvider
            .overrideWith(() => _FakeVoiceCoachingEnabled(enabled)),
        voiceAnnouncementServiceProvider.overrideWithValue(fakeTts),
        activeLanguageProvider.overrideWith(_FakeActiveLanguage.new),
        if (recording != null)
          tripRecordingProvider.overrideWith(() => recording),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Activate the keepAlive listener so its subscriptions attach.
  Future<void> startListener(ProviderContainer c) async {
    final sub = c.listen(drivingCoachVoiceListenerProvider, (_, _) {});
    addTearDown(sub.close);
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  HarshEvent harshAccel(DateTime at) => HarshEvent(
        timestamp: at,
        magnitudeG: 0.35,
        speedKmh: 60,
        type: HarshEventType.acceleration,
      );

  Future<void> pushHarsh(ProviderContainer c, HarshEvent e) async {
    c.read(liveHarshEventBusProvider.notifier).add(e);
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  test('setting ON + a harsh-accel event during recording → speaks the '
      'hard-acceleration cue (RED on master — chain broken)', () async {
    final c = makeContainer(enabled: true);
    await startListener(c);

    expect(fakeTts.initialized, isTrue,
        reason: 'the listener warms the TTS engine when coaching is on');

    await pushHarsh(c, harshAccel(fakeNow));

    expect(fakeTts.spokenLines, isNotEmpty,
        reason: 'the dead link is closed: speakLine WAS called');
    expect(fakeTts.spokenLines, contains(_enCues.coachingVoiceHardAcceleration));
  });

  test('setting OFF → never subscribes, stays silent', () async {
    final c = makeContainer(enabled: false);
    await startListener(c);

    await pushHarsh(c, harshAccel(fakeNow));

    expect(fakeTts.spokenLines, isEmpty);
    expect(fakeTts.initialized, isFalse,
        reason: 'the off path must not even touch the TTS engine');
  });

  test('per-type cooldown suppresses a rapid repeat, then re-speaks once the '
      'event clock has elapsed', () async {
    final c = makeContainer(enabled: true);
    await startListener(c);

    // First event speaks.
    await pushHarsh(c, harshAccel(fakeNow));
    expect(fakeTts.spokenLines, hasLength(1));

    // A second accel event a few seconds later (within the cooldown) is
    // suppressed — the cooldown keys on the event's own wall clock.
    await pushHarsh(c, harshAccel(fakeNow.add(const Duration(seconds: 3))));
    expect(fakeTts.spokenLines, hasLength(1),
        reason: 'rapid repeat of the same cue type is throttled');

    // Past the cooldown window → speaks again.
    await pushHarsh(c, harshAccel(fakeNow.add(const Duration(seconds: 30))));
    expect(fakeTts.spokenLines, hasLength(2),
        reason: 'the throttle clears once the event clock elapses');
  });

  test('a brake event speaks the harsh-braking cue (distinct from accel)',
      () async {
    final c = makeContainer(enabled: true);
    await startListener(c);

    await pushHarsh(
      c,
      HarshEvent(
        timestamp: fakeNow,
        magnitudeG: 0.5,
        speedKmh: 80,
        type: HarshEventType.brake,
      ),
    );

    expect(fakeTts.spokenLines, contains(_enCues.coachingVoiceHarshBraking));
  });

  test('a GPS coaching-hint transition (GlideCoach lift) speaks its cue',
      () async {
    final recording = _FakeTripRecording();
    final c = makeContainer(enabled: true, recording: recording);
    await startListener(c);

    // Transition the recording state to surface a GPS lift-off-coast hint.
    recording.emit(const TripRecordingState(
      gpsCoachingHint: DrivingCoachingHint.gpsLiftOffCoast,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(fakeTts.spokenLines, contains(_enCues.coachingVoiceLiftOff));
  });

  test('an OBD2-derived shift-up hint transition speaks its cue', () async {
    final recording = _FakeTripRecording();
    final c = makeContainer(enabled: true, recording: recording);
    await startListener(c);

    // A live reading that classifies as shiftUp: high RPM, real cruise
    // speed, moderate throttle.
    recording.emit(const TripRecordingState(
      situation: DrivingSituation.highwayCruise,
      live: TripLiveReading(
        rpm: 3200,
        speedKmh: 80,
        throttlePercent: 30,
        distanceKmSoFar: 5,
        elapsed: Duration(minutes: 5),
      ),
    ));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(fakeTts.spokenLines, contains(_enCues.coachingVoiceShiftUp));
  });
}
