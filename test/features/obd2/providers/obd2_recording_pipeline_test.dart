// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/obd2_transport.dart';
import 'package:tankstellen/features/consumption/domain/entities/gps_sample_diagnostic.dart';
import 'package:tankstellen/features/consumption/domain/entities/trip_save_stage.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/obd2/providers/obd2_recording_pipeline.dart';
import 'package:tankstellen/features/consumption/providers/recording_pipeline.dart';
import 'package:tankstellen/features/consumption/providers/trip_baseline_recorder.dart';
import 'package:tankstellen/features/consumption/providers/trip_gps_stream_controller.dart';
import 'package:tankstellen/features/consumption/providers/trip_haptic_controller.dart';
import 'package:tankstellen/features/consumption/providers/trip_oem_fuel_level_controller.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_phase.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_state.dart';

import '../../../helpers/silence_error_logger.dart';

/// Direct unit tests for the #2227 [Obd2RecordingPipeline] — the OBD2
/// recording strategy extracted from the [TripRecording] notifier behind
/// the [RecordingPipeline] seam #2190 opened.
///
/// These drive the pipeline against a fake [Obd2RecordingPipelineHost] +
/// a real [Obd2Service] over a [FakeObd2Transport], so the start / sample
/// / WAL-hook / stop / summary behaviour is pinned at the strategy level
/// without spinning up the whole notifier. The notifier-level regression
/// suite (trip_recording_provider_*) covers the same behaviour through
/// the public API and proves the extraction is byte-identical.
void main() {
  silenceErrorLoggerSpool();

  group('Obd2RecordingPipeline (#2227)', () {
    test('isGpsOnly is false — it is the dongle-backed strategy', () async {
      final h = await _Harness.started();
      addTearDown(h.dispose);
      expect(h.pipeline.isGpsOnly, isFalse);
    });

    test('start() owns a live controller and seeds the WAL snapshot '
        'through the host hook', () async {
      final h = await _Harness.started();
      addTearDown(h.dispose);

      expect(h.pipeline.controller, isNotNull,
          reason: 'the pipeline must own the controller while recording');
      expect(h.host.state.phase, TripRecordingPhase.recording);
      expect(h.host.seedCount, 1,
          reason: 'start must seed the active-trip WAL snapshot exactly '
              'once (#1303), as the inline path did');
    });

    test('a live sample flows through to the host state + drives the '
        'debounced WAL flush gate', () async {
      final h = await _Harness.started();
      addTearDown(h.dispose);

      final ctl = h.pipeline.controller!;
      final t = DateTime.now();
      ctl.debugInjectSample(
        speedKmh: 50,
        rpm: 2200,
        at: t,
        fuelRateLPerHour: 6.0,
      );
      ctl.debugEmitNow();
      await _pump();

      expect(h.host.state.live, isNotNull,
          reason: 'the live reading must reach the host state');
      expect(h.host.maybeFlushCount, greaterThan(0),
          reason: 'every live sample must tick the debounced WAL gate');
    });

    test('stop() tears down, saves to history with the adapter identity, '
        'clears the WAL, and finishes', () async {
      final h = await _Harness.started();
      addTearDown(h.dispose);

      final ctl = h.pipeline.controller!;
      final start = DateTime.now();
      for (var i = 0; i < 6; i++) {
        final at = start.add(Duration(seconds: i));
        // Feed the recorder so the summary has a startedAt; feed the
        // virtual odometer so it has a non-zero distance — without both,
        // the host's save path discards it as a stub trip (#1923).
        ctl.debugInjectSample(
          speedKmh: 40 + i.toDouble(),
          rpm: 1800,
          at: at,
          fuelRateLPerHour: 5.5,
        );
        ctl.debugRecordSpeedSample(speedKmh: 40 + i.toDouble(), at: at);
        ctl.debugCaptureSample(TripSample(
          timestamp: at,
          speedKmh: 40 + i.toDouble(),
          rpm: 1800,
          fuelRateLPerHour: 5.5,
        ));
      }

      final result = await h.pipeline.stop();

      expect(h.pipeline.controller, isNull,
          reason: 'stop must release the controller');
      expect(h.host.state.phase, TripRecordingPhase.finished);
      expect(h.host.clearCount, 1,
          reason: 'a finalised trip must clear the WAL snapshot so '
              'recovery does not resurrect it (#1303)');
      expect(h.host.saved, hasLength(1),
          reason: 'every real trip is persisted to history (#726)');
      // The captured per-tick buffer round-trips into the saved entry
      // (#1040 — the trip-detail charts read this back).
      expect(h.host.saved.single.samples, hasLength(6));
      // #1312 — the adapter identity snapshotted at start is handed to
      // the save so it survives the service being disconnected.
      expect(h.host.saved.single.adapterMac, _Harness.fakeMac);
      expect(result.summary.distanceKm, greaterThan(0),
          reason: 'a moving trip integrates a non-zero distance');
      expect(h.service.isConnected, isFalse,
          reason: 'stop must disconnect the owned service');
      // #2548 — the stop drives the staged save-progress: finalize then
      // save-to-history. The syncing beat is gated on cloud sync, which
      // is off in this anonymous test container, so it is skipped.
      expect(h.host.saveStages, [
        TripSaveStage.finalizingSummary,
        TripSaveStage.savingToHistory,
      ]);
    });

    test('stop() on an unstarted pipeline returns an empty result and '
        'resets the state (safe to over-call)', () async {
      final h = _Harness();
      addTearDown(h.dispose);

      final result = await h.pipeline.stop();
      expect(result.summary.distanceKm, 0);
      expect(h.host.state.phase, TripRecordingPhase.idle);
      expect(h.host.saved, isEmpty,
          reason: 'a stub / never-started trip is never persisted');
    });

    test('pause() / resume() forward to the controller and report '
        'whether a live recording was affected', () async {
      final h = await _Harness.started();
      addTearDown(h.dispose);

      expect(h.pipeline.pause(), isTrue);
      expect(h.pipeline.controller!.isPaused, isTrue);
      expect(h.pipeline.resume(), isTrue);
      expect(h.pipeline.controller!.isPaused, isFalse);
    });
  });
}

Future<void> _pump() => Future<void>.delayed(Duration.zero);

/// Test harness: a real [Obd2Service] over a [FakeObd2Transport], a fake
/// WAL host that counts the hook calls + records saves, and the four
/// focused collaborators the notifier injects into the pipeline.
class _Harness {
  _Harness() {
    final container = ProviderContainer();
    _container = container;
    service = Obd2Service(FakeObd2Transport(_elmOk()))..adapterMac = fakeMac;
    // A tiny capturing provider hands the pipeline a real [Ref] so the
    // breadcrumb / reconnect / catalog reads exercise the same Riverpod
    // path the production notifier uses.
    pipeline = container.read(_pipelineProvider(host));
  }

  static const fakeMac = 'AA:BB:CC:00:11:22';

  late final ProviderContainer _container;
  final _FakeWalHost host = _FakeWalHost();
  late final Obd2Service service;
  late final Obd2RecordingPipeline pipeline;

  static Future<_Harness> started() async {
    final h = _Harness();
    await h.service.connect();
    // Re-stamp after connect in case the handshake cleared it — the
    // pipeline snapshots adapterMac inside start().
    h.service.adapterMac = fakeMac;
    await h.pipeline.start(h.service);
    return h;
  }

  Future<void> dispose() async {
    // Tear the controller's periodic emit timer down before disposing the
    // container — otherwise a late emit's breadcrumb `state=` fires after
    // the provider graph is gone.
    if (pipeline.controller != null) {
      await pipeline.stop();
    }
    _container.dispose();
  }
}

/// Family provider that constructs the pipeline with the provider's own
/// [Ref] — mirrors the GPS-only pipeline test, so the unit test runs the
/// real Riverpod read path (breadcrumbs, reconnect connection, catalog).
final _pipelineProvider =
    Provider.family<Obd2RecordingPipeline, Obd2RecordingPipelineHost>(
  (ref, host) => Obd2RecordingPipeline(
    ref: ref,
    host: host,
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
  ),
);

class _FakeWalHost implements Obd2RecordingPipelineHost {
  @override
  TripRecordingState state = const TripRecordingState();

  @override
  String? lastTripVehicleId;

  @override
  DateTime? lastTripStartedAt;

  int seedCount = 0;
  int maybeFlushCount = 0;
  int flushCount = 0;
  int clearCount = 0;
  final List<_Saved> saved = [];

  /// #2548 — the ordered save stages the pipeline drove through this host.
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
  void maybeFlushActiveSnapshot() => maybeFlushCount++;

  @override
  Future<void> flushActiveSnapshot({bool force = false}) async => flushCount++;

  @override
  Future<void> clearActiveSnapshot() async => clearCount++;

  @override
  Future<TripPersistOutcome> saveToHistory(
    TripSummary summary, {
    bool automatic = false,
    List<TripSample> samples = const [],
    List<GpsSampleDiagnostic> gpsSampleDiagnostics = const [],
    String? vehicleId,
    String? adapterMac,
    String? adapterName,
    String? adapterFirmware,
    int gpsFixCount = 0,
  }) async {
    // Mirror the notifier's tightened stub-discard guard (#1923 / #2509) so
    // the test asserts the same persistence behaviour the real host
    // applies: discard ONLY when there was no movement AND no usable
    // signal (no start time, or no samples and no GPS fixes).
    final hasNoSignal = summary.startedAt == null ||
        (samples.isEmpty && gpsFixCount == 0);
    if (summary.distanceKm < 0.01 && hasNoSignal) {
      return TripPersistOutcome.discardedNoMovement;
    }
    saved.add(_Saved(
      summary: summary,
      samples: samples,
      adapterMac: adapterMac,
      vehicleId: vehicleId,
    ));
    return TripPersistOutcome.saved;
  }
}

class _Saved {
  _Saved({
    required this.summary,
    required this.samples,
    required this.adapterMac,
    required this.vehicleId,
  });
  final TripSummary summary;
  final List<TripSample> samples;
  final String? adapterMac;
  final String? vehicleId;
}

Map<String, String> _elmOk() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '01A6': '41 A6 00 01 6A 2C>',
    };
