// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/announcement_engine.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/core/services/voice_announcement_providers.dart';
import 'package:tankstellen/core/services/voice_announcement_service.dart';
import 'package:tankstellen/features/approach/providers/approach_state_provider.dart';
import 'package:tankstellen/features/driving/providers/voice_announcement_listener_provider.dart';
import 'package:tankstellen/features/driving/providers/voice_announcement_settings_provider.dart';
import 'package:tankstellen/features/profile/providers/effective_fuel_type_provider.dart';
import 'package:tankstellen/features/profile/providers/voice_announcements_enabled_provider.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../../../helpers/silence_error_logger.dart';

/// Integration/wiring test for `voiceAnnouncementListenerProvider` (#2569).
///
/// The engine itself is unit-tested in
/// `test/core/services/announcement_engine_test.dart`; this test proves
/// the *wiring*: the listener feeds the live `approachStateProvider`
/// signal into the engine only when the feature flag is on, honours the
/// user's price threshold + radius, and never fires when the flag is off.

/// Fake TTS service capturing every announce call.
class _FakeVoiceAnnouncementService implements VoiceAnnouncementService {
  final List<AnnouncementCandidate> announced = [];
  bool initialized = false;

  @override
  Future<void> initialize() async => initialized = true;

  @override
  Future<void> announce(AnnouncementCandidate candidate) async =>
      announced.add(candidate);

  @override
  Future<void> speakLine(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> setLanguage(String languageCode) async {}

  @override
  Future<void> setAppLocale(String languageCode) async {}
}

/// Settings notifier stub returning a fixed [AnnouncementConfig].
class _FakeSettings extends VoiceAnnouncementSettings {
  _FakeSettings(this._config);
  final AnnouncementConfig _config;

  @override
  AnnouncementConfig build() => _config;
}

Station _station(String id, {required double e10, double lat = 52.5}) =>
    Station(
      id: id,
      name: 'Station $id',
      brand: 'STAR',
      street: 'Test Street',
      postCode: '10115',
      place: 'Berlin',
      lat: lat,
      lng: 13.4,
      e10: e10,
      isOpen: true,
    );

void main() {
  silenceErrorLoggerSpool();

  late StreamController<ApproachState> approach;
  late _FakeVoiceAnnouncementService fakeTts;

  setUp(() {
    approach = StreamController<ApproachState>.broadcast();
    fakeTts = _FakeVoiceAnnouncementService();
  });

  tearDown(() {
    if (!approach.isClosed) unawaited(approach.close());
  });

  ProviderContainer makeContainer({
    required bool flagEnabled,
    AnnouncementConfig config = const AnnouncementConfig(
      enabled: true,
      proximityRadiusKm: 2.0,
      cooldown: Duration(minutes: 30),
      priceThreshold: 1.80,
    ),
  }) {
    final c = ProviderContainer(
      overrides: [
        voiceAnnouncementsEnabledProvider.overrideWithValue(flagEnabled),
        voiceAnnouncementServiceProvider.overrideWithValue(fakeTts),
        voiceAnnouncementSettingsProvider.overrideWith(
          () => _FakeSettings(config),
        ),
        effectiveFuelTypeProvider.overrideWithValue(FuelType.e10),
        approachStateProvider.overrideWith((ref) => approach.stream),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Activate the keepAlive listener and warm the approach StreamProvider
  /// so it is attached to our broadcast stream before any event is pushed.
  Future<void> startListener(ProviderContainer c) async {
    // A live subscription keeps the listener provider mounted — its
    // internal `ref.listen(approachStateProvider, …)` only fires while the
    // provider itself has a listener (a bare `read` would dispose it).
    final sub = c.listen(voiceAnnouncementListenerProvider, (_, _) {});
    addTearDown(sub.close);
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  /// Pump a single `ApproachInRadius` for [station] at [meters] and let
  /// the listener's async `evaluateAndAnnounce` settle.
  Future<void> emitInRadius(
    ProviderContainer c,
    Station station, {
    double meters = 500,
  }) async {
    approach.add(ApproachInRadius(station: station, distanceMeters: meters));
    // Let the StreamProvider forward the event, the listener callback run,
    // and the engine's async announce settle.
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  test('flag ON + nearby station below threshold within radius → announces '
      'once', () async {
    final c = makeContainer(flagEnabled: true);
    await startListener(c);

    expect(fakeTts.initialized, isTrue,
        reason: 'the listener warms up the TTS engine when the flag is on');

    await emitInRadius(c, _station('cheap', e10: 1.599));

    expect(fakeTts.announced, hasLength(1));
    expect(fakeTts.announced.first.station.id, 'cheap');
    expect(fakeTts.announced.first.price, 1.599);
  });

  test('flag OFF → never announces, never subscribes', () async {
    final c = makeContainer(flagEnabled: false);
    await startListener(c);

    await emitInRadius(c, _station('cheap', e10: 1.599));

    expect(fakeTts.announced, isEmpty);
    expect(fakeTts.initialized, isFalse,
        reason: 'the flag-off path must not even touch the TTS engine');
  });

  test('station above the price threshold is not announced', () async {
    final c = makeContainer(flagEnabled: true);
    await startListener(c);

    // threshold is 1.80; this station is 1.999 → filtered by the engine.
    await emitInRadius(c, _station('pricey', e10: 1.999));

    expect(fakeTts.announced, isEmpty);
  });

  test('cooldown is respected — the same station is announced only once',
      () async {
    final c = makeContainer(flagEnabled: true);
    await startListener(c);

    final s = _station('cheap', e10: 1.599);
    await emitInRadius(c, s);
    expect(fakeTts.announced, hasLength(1));

    // Re-enter the radius of the SAME station within the cooldown window.
    await emitInRadius(c, s);
    expect(fakeTts.announced, hasLength(1),
        reason: 'the engine cooldown suppresses a repeat for the same '
            'station within the window');
  });

  test('the user-facing enable toggle gates announcing even with the flag on',
      () async {
    // Flag (Feature gate) ON but the persisted in-feature toggle is OFF.
    final c = makeContainer(
      flagEnabled: true,
      config: const AnnouncementConfig(enabled: false),
    );
    await startListener(c);

    await emitInRadius(c, _station('cheap', e10: 1.599));

    expect(fakeTts.announced, isEmpty);
  });
}
