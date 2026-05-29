// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';

import '../../../helpers/silence_error_logger.dart';

/// #2274 concern 2 — start-now-connect-later. The provider exposes a
/// transient `connecting` phase so the recording screen can be pushed
/// IMMEDIATELY and resolve the connect+prime in-place. These tests pin
/// the phase semantics: connecting is observable but NOT active, a
/// stage can be advanced, a cancel rolls back to idle, and a successful
/// start clears the stage and goes live.

Map<String, String> _elmOk() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '01A6': '41 A6 00 01 6A 2C>',
    };

void main() {
  silenceErrorLoggerSpool();

  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('enterConnecting flips to the connecting phase (not active)', () {
    final c = makeContainer();
    final notifier = c.read(tripRecordingProvider.notifier);

    notifier.enterConnecting(vehicleId: 'v1');

    final state = c.read(tripRecordingProvider);
    expect(state.isConnecting, isTrue);
    expect(state.isActive, isFalse,
        reason: 'no trip exists yet during connect — the banner must not show');
    expect(state.connectStage, TripStartStage.connectingAdapter);
    expect(notifier.lastTripVehicleId, 'v1');
  });

  test('setConnectStage advances the inline progress while connecting', () {
    final c = makeContainer();
    final notifier = c.read(tripRecordingProvider.notifier);
    notifier.enterConnecting();

    notifier.setConnectStage(TripStartStage.readingVehicleData);
    expect(c.read(tripRecordingProvider).connectStage,
        TripStartStage.readingVehicleData);
  });

  test('setConnectStage is a no-op when not connecting', () {
    final c = makeContainer();
    final notifier = c.read(tripRecordingProvider.notifier);
    // Idle — no connecting phase to advance.
    notifier.setConnectStage(TripStartStage.startingRecording);
    expect(c.read(tripRecordingProvider).connectStage, isNull);
  });

  test('cancelConnecting rolls back to idle', () {
    final c = makeContainer();
    final notifier = c.read(tripRecordingProvider.notifier);
    notifier.enterConnecting();
    expect(c.read(tripRecordingProvider).isConnecting, isTrue);

    notifier.cancelConnecting();
    final state = c.read(tripRecordingProvider);
    expect(state.isConnecting, isFalse);
    expect(state.phase, TripRecordingPhase.idle);
    expect(state.connectStage, isNull);
  });

  test('a successful start() from connecting goes live and clears the stage',
      () async {
    final c = makeContainer();
    final notifier = c.read(tripRecordingProvider.notifier);
    notifier.enterConnecting();

    final service = Obd2Service(FakeObd2Transport(_elmOk()));
    await service.connect();
    await notifier.start(service);

    final state = c.read(tripRecordingProvider);
    expect(state.phase, TripRecordingPhase.recording);
    expect(state.isActive, isTrue);
    expect(state.connectStage, isNull,
        reason: 'going live swaps the inline progress for the live metrics');

    await notifier.stop();
  });

  test('enterConnecting is a no-op once a trip is active', () async {
    final c = makeContainer();
    final notifier = c.read(tripRecordingProvider.notifier);
    final service = Obd2Service(FakeObd2Transport(_elmOk()));
    await service.connect();
    await notifier.start(service);
    expect(c.read(tripRecordingProvider).isActive, isTrue);

    notifier.enterConnecting();
    expect(c.read(tripRecordingProvider).phase, TripRecordingPhase.recording,
        reason: 'cannot re-enter connecting over a live trip');

    await notifier.stop();
  });
}
