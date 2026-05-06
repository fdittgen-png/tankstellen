import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/gps_sample_diagnostic.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';

/// Regression coverage for #1458 phase 2 — the GPS cadence
/// diagnostics buffer captured during a recording must round-trip
/// through `TripHistoryRepository.save` + `loadAll` so a future
/// diagnostics sheet (and any user inspecting the persisted JSON) can
/// see exactly when each fix arrived and what app-lifecycle state was
/// in effect at the time.
///
/// Three contracts:
///   1. `TripHistoryEntry.toJson` + `fromJson` round-trip the
///      diagnostics list with every field preserved (timestamp to ms,
///      lifecycle state string, monotonic index).
///   2. Legacy entries (no `gpsd` key) deserialise with an empty
///      diagnostics list so trips recorded before #1458 phase 2 don't
///      throw on load.
///   3. `TripRecording.stop()` plumbs the controller's captured
///      diagnostics buffer onto the saved entry — i.e. the in-memory
///      observation channel is durable, not lost at trip-stop.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('gps_diagnostics_test_');
    Hive.init(tmpDir.path);
    await Hive.openBox<String>(HiveBoxes.obd2TripHistory);
  });

  tearDown(() async {
    await Hive.box<String>(HiveBoxes.obd2TripHistory).deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  test('TripHistoryEntry round-trips GpsSampleDiagnostic list', () {
    // Use a local-time DateTime so the millisecondsSinceEpoch
    // serialisation round-trip is exact — UTC DateTimes deserialise as
    // local-time on the wire-format the entity uses (matches the
    // existing per-sample TripSample convention).
    final start = DateTime(2026, 5, 1, 8);
    final diagnostics = <GpsSampleDiagnostic>[
      GpsSampleDiagnostic(
        timestamp: start,
        lifecycleState: AppLifecycleState.resumed.name,
        index: 0,
      ),
      GpsSampleDiagnostic(
        timestamp: start.add(const Duration(seconds: 10)),
        lifecycleState: AppLifecycleState.inactive.name,
        index: 1,
      ),
      GpsSampleDiagnostic(
        timestamp: start.add(const Duration(seconds: 25)),
        lifecycleState: AppLifecycleState.paused.name,
        index: 2,
      ),
    ];
    final entry = TripHistoryEntry(
      id: start.toIso8601String(),
      vehicleId: 'veh-1',
      summary: TripSummary(
        distanceKm: 1.2,
        maxRpm: 2000,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: start,
        endedAt: start.add(const Duration(seconds: 25)),
      ),
      gpsSampleDiagnostics: diagnostics,
    );

    final json = entry.toJson();
    final restored = TripHistoryEntry.fromJson(json);

    expect(restored.gpsSampleDiagnostics, hasLength(3));
    expect(restored.gpsSampleDiagnostics[0].timestamp, start);
    expect(
      restored.gpsSampleDiagnostics[0].lifecycleState,
      AppLifecycleState.resumed.name,
    );
    expect(restored.gpsSampleDiagnostics[0].index, 0);
    expect(
      restored.gpsSampleDiagnostics[1].lifecycleState,
      AppLifecycleState.inactive.name,
    );
    expect(restored.gpsSampleDiagnostics[1].index, 1);
    expect(
      restored.gpsSampleDiagnostics[2].lifecycleState,
      AppLifecycleState.paused.name,
    );
    expect(
      restored.gpsSampleDiagnostics[2].timestamp,
      start.add(const Duration(seconds: 25)),
    );
  });

  test('legacy entries without `gpsd` key deserialise to empty list', () {
    // A pre-#1458 phase 2 payload — no `gpsd` field. Must NOT throw
    // and must surface an empty diagnostics list rather than null,
    // matching the convention used for the per-tick samples list.
    final legacy = <String, dynamic>{
      'id': 'legacy-2',
      'vehicleId': 'veh-1',
      'summary': <String, dynamic>{
        'distanceKm': 12.0,
        'maxRpm': 3000.0,
        'highRpmSeconds': 0.0,
        'idleSeconds': 0.0,
        'harshBrakes': 0,
        'harshAccelerations': 0,
        'distanceSource': 'virtual',
      },
    };
    final restored = TripHistoryEntry.fromJson(legacy);
    expect(restored.gpsSampleDiagnostics, isEmpty);
  });

  test(
    'TripRecording.stop() persists the controller diagnostics buffer '
    'onto the saved TripHistoryEntry',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final notifier = container.read(tripRecordingProvider.notifier);
      await notifier.start(service);
      final ctl = notifier.debugController;
      expect(ctl, isNotNull,
          reason: 'provider must own a controller while recording');

      // Drive the recorder so the resulting summary has a startedAt
      // and a non-zero distance — `_saveToHistory` short-circuits
      // empty trips and would never reach the persistence path
      // without this.
      final start = DateTime.now();
      for (int i = 0; i < 4; i++) {
        ctl!.debugInjectSample(
          speedKmh: 40 + i.toDouble(),
          rpm: 1800 + i * 5,
          at: start.add(Duration(seconds: i)),
          fuelRateLPerHour: 5.5,
        );
        ctl.debugCaptureSample(TripSample(
          timestamp: start.add(Duration(seconds: i)),
          speedKmh: 40 + i.toDouble(),
          rpm: 1800 + i * 5,
          fuelRateLPerHour: 5.5,
        ));
      }

      // Pre-seed a diagnostic buffer that mixes lifecycle states —
      // this simulates "recording started while the user was looking
      // at the screen, then they backgrounded the app halfway through".
      ctl!.debugCaptureGpsSampleDiagnostic(GpsSampleDiagnostic(
        timestamp: start,
        lifecycleState: AppLifecycleState.resumed.name,
        index: 0,
      ));
      ctl.debugCaptureGpsSampleDiagnostic(GpsSampleDiagnostic(
        timestamp: start.add(const Duration(seconds: 1)),
        lifecycleState: AppLifecycleState.inactive.name,
        index: 1,
      ));
      ctl.debugCaptureGpsSampleDiagnostic(GpsSampleDiagnostic(
        timestamp: start.add(const Duration(seconds: 3)),
        lifecycleState: AppLifecycleState.paused.name,
        index: 2,
      ));

      await notifier.stop();

      final repo = container.read(tripHistoryRepositoryProvider);
      expect(repo, isNotNull);
      final history = repo!.loadAll();
      expect(history, isNotEmpty,
          reason: 'stop() must persist a TripHistoryEntry');
      final saved = history.first;
      expect(saved.gpsSampleDiagnostics, hasLength(3),
          reason:
              'every captured GPS diagnostic must round-trip into Hive');
      expect(
        saved.gpsSampleDiagnostics[0].lifecycleState,
        AppLifecycleState.resumed.name,
      );
      expect(
        saved.gpsSampleDiagnostics[1].lifecycleState,
        AppLifecycleState.inactive.name,
      );
      expect(
        saved.gpsSampleDiagnostics[2].lifecycleState,
        AppLifecycleState.paused.name,
      );
      // Indices must be monotonic + preserved.
      expect(saved.gpsSampleDiagnostics.map((d) => d.index).toList(),
          equals([0, 1, 2]));
    },
  );

  test(
    'onAppLifecycleStateChanged updates the provider field tagged onto '
    'subsequent diagnostics',
    () async {
      // Pure provider-level test — no Geolocator stream needed. We
      // verify that pushing a new lifecycle state into the provider
      // makes it the value the GPS listener WOULD tag onto a future
      // diagnostic.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(tripRecordingProvider.notifier);
      // Default is resumed — the first sample on a freshly-started
      // recording is tagged optimistically.
      expect(notifier.debugLifecycleState, AppLifecycleState.resumed);

      notifier.onAppLifecycleStateChanged(AppLifecycleState.paused);
      expect(notifier.debugLifecycleState, AppLifecycleState.paused);

      notifier.onAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(notifier.debugLifecycleState, AppLifecycleState.inactive);

      notifier.onAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(notifier.debugLifecycleState, AppLifecycleState.resumed);
    },
  );
}

Map<String, String> _elmOk() => const {
      'ATZ': 'ELM327 v1.5>',
      'ATE0': 'OK>',
      'ATL0': 'OK>',
      'ATH0': 'OK>',
      'ATSP0': 'OK>',
      '01A6': '41 A6 00 01 6A 2C>',
    };
