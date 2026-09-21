// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4344 — the production [Obd2RecordingPipeline] start, cancelled while
/// the controller's start awaits a held read: by the start watchdog, or by
/// a Stop. When the read finally answers, nothing may come alive — no PID
/// polling, no WAL seed, no `recording` state — and nothing is saved.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/obd2/domain/obd2_connection_errors.dart';
import 'package:tankstellen/features/obd2/providers/obd2_recording_pipeline.dart';
import 'package:tankstellen/features/trips/domain/entities/gps_sample_diagnostic.dart';
import 'package:tankstellen/features/trips/domain/entities/trip_save_stage.dart';
import 'package:tankstellen/features/trips/domain/entities/trip_termination.dart';
import 'package:tankstellen/features/trips/domain/recording_session_journal.dart';
import 'package:tankstellen/features/trips/domain/trip_recorder.dart';
import 'package:tankstellen/features/trips/providers/recording_pipeline.dart';
import 'package:tankstellen/features/trips/providers/trip_baseline_recorder.dart';
import 'package:tankstellen/features/trips/providers/trip_gps_stream_controller.dart';
import 'package:tankstellen/features/trips/providers/trip_haptic_controller.dart';
import 'package:tankstellen/features/trips/providers/trip_oem_fuel_level_controller.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_phase.dart';
import 'package:tankstellen/features/trips/providers/trip_recording_state.dart';

import '../../../helpers/silence_error_logger.dart';

void main() {
  silenceErrorLoggerSpool();

  late ProviderContainer container;
  late _HeldOdometerTransport transport;
  late Obd2Service service;
  late _Host host;

  setUp(() async {
    container = ProviderContainer();
    transport = _HeldOdometerTransport();
    service = Obd2Service(transport);
    await service.connect();
    host = _Host();
  });

  tearDown(() {
    transport.release();
    container.dispose();
  });

  Obd2RecordingPipeline pipeline({Duration? watchdog}) =>
      container.read(_pipeline((host: host, watchdog: watchdog)));

  /// Release the held read and give a live start ample time to poll.
  Future<List<String>> releaseAndWatch() async {
    final releasedAt = transport.attempts.length;
    transport.release();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    return transport.attempts.sublist(releasedAt);
  }

  test('the start watchdog abandons a held start: once the read answers, '
      'the abandoned controller polls nothing', () async {
    final p = pipeline(watchdog: const Duration(milliseconds: 200));
    await expectLater(
        p.start(service), throwsA(isA<Obd2AdapterUnresponsive>()));
    expect(transport.held, isTrue, reason: 'precondition: held in identity');
    expect(p.controller, isNull);

    final after = await releaseAndWatch();

    expect(after.where(_isPoll), isEmpty,
        reason: 'a Future.timeout cancels nothing: the abandoned start must '
            'be told it is over before it is forgotten');
    expect(host.seedCount, 0);
    expect(host.state.phase, isNot(TripRecordingPhase.recording));
  });

  test('a Stop during the start: once the read answers, nothing comes '
      'alive and nothing is saved — twice over', () async {
    final p = pipeline();
    final starting = p.start(service);
    await transport.reached;

    final stopped = await p.stop();
    final again = await p.stop();
    final after = await releaseAndWatch();
    await starting;

    expect(after.where(_isPoll), isEmpty, reason: 'no PID polling');
    expect(host.seedCount, 0, reason: 'no WAL row for a trip never begun');
    expect(host.state.phase, TripRecordingPhase.idle,
        reason: 'no renewed recording state');
    expect(p.controller, isNull);
    expect(host.saveStages, isEmpty, reason: 'nothing to save');
    expect(host.saveCount, 0);
    expect(stopped.summary.distanceKm, 0);
    expect(again.summary.distanceKm, 0);
  });

  test('an unheld start still goes live and polls', () async {
    final p = pipeline();
    final starting = p.start(service);
    await transport.reached;
    final after = await releaseAndWatch();
    await starting;

    expect(host.state.phase, TripRecordingPhase.recording);
    expect(host.seedCount, 1);
    expect(after.where(_isPoll), isNotEmpty);
    await p.stop();
  });
}

bool _isPoll(String cmd) => cmd == '010C' || cmd == '010D';

/// A live car whose odometer read (the first identity read of a start)
/// waits on [release]. Connect-time traffic is never held, and the link
/// never closes.
class _HeldOdometerTransport extends FakeObd2Transport {
  _HeldOdometerTransport()
      : super(const {
          'ATZ': 'ELM327 v1.5>',
          'ATE0': 'OK>',
          'ATL0': 'OK>',
          'ATH0': 'OK>',
          'ATSP0': 'OK>',
          '0100': '41 00 BE 1F A8 13>',
          '01A6': '41 A6 00 01 6A 2C>',
        });

  final Completer<void> _reached = Completer<void>();
  final Completer<void> _release = Completer<void>();
  bool held = false;

  /// Every command the recording tried to send, even after a disconnect.
  final List<String> attempts = [];

  Future<void> get reached => _reached.future;

  void release() {
    if (!_release.isCompleted) _release.complete();
  }

  /// The link outlives the abandoned start (a close that races the late
  /// read, or a supervisor-kept link): polling would reach the car.
  @override
  Future<void> disconnect() async {}

  @override
  Future<String> sendCommand(String command) async {
    final cmd = command.trim();
    attempts.add(cmd);
    if (cmd == '01A6' && !held) {
      held = true;
      _reached.complete();
      await _release.future;
    }
    return super.sendCommand(command);
  }
}

final _pipeline = Provider.family<Obd2RecordingPipeline,
    ({Obd2RecordingPipelineHost host, Duration? watchdog})>(
  (ref, args) => Obd2RecordingPipeline(
    ref: ref,
    host: args.host,
    haptics: TripHapticController(),
    gps: TripGpsStreamController(
      ref: ref,
      lifecycleState: () => AppLifecycleState.resumed,
    ),
    baselines: TripBaselineRecorder(ref),
    oemFuel: TripOemFuelLevelController(),
    readActiveVehicle: () => null,
    readOemPidsFlag: () => false,
    readDiagnosticCaptureFlag: () => false,
    startWatchdog: args.watchdog ?? const Duration(minutes: 1),
  ),
);

class _Host implements Obd2RecordingPipelineHost {
  @override
  TripRecordingState state = const TripRecordingState();
  @override
  String? lastTripVehicleId;
  @override
  DateTime? lastTripStartedAt;

  int seedCount = 0;
  int saveCount = 0;
  final List<TripSaveStage> saveStages = [];

  @override
  String? readActiveVehicleId() => null;
  @override
  void setSaveStage(TripSaveStage stage) {
    saveStages.add(stage);
    state = state.copyWith(phase: TripRecordingPhase.saving, saveStage: stage);
  }

  @override
  void seedActiveSnapshot() => seedCount++;
  @override
  void maybeFlushActiveSnapshot() {}
  @override
  Future<void> flushActiveSnapshot({bool force = false}) async {}
  @override
  Future<void> clearActiveSnapshot() async {}
  @override
  void tearDownFinalisedTrip() {}
  @override
  Future<List<TripSample>> readAllCapturedSamples() async => const [];

  @override
  Future<TripPersistOutcome> saveToHistory(
    TripSummary summary, {
    String? tripId,
    bool automatic = false,
    List<TripSample> samples = const [],
    List<GpsSampleDiagnostic> gpsSampleDiagnostics = const [],
    String? vehicleId,
    String? adapterMac,
    String? adapterName,
    String? adapterFirmware,
    int gpsFixCount = 0,
    TripTermination? termination,
    RecordingSessionJournal? sessionJournal,
  }) async {
    saveCount++;
    return TripPersistOutcome.saved;
  }
}
