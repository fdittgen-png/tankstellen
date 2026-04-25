import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/providers/trip_history_provider.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';

/// Regression test for #1040 — the per-second OBD2 sample buffer must
/// land in the persisted [TripHistoryEntry] so the trip-detail charts
/// have data to plot.
///
/// Without this path the user sees aggregates (distance / duration /
/// avg consumption) but the speed and fuel-rate charts render the
/// "No samples recorded" empty state on every recorded trip.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmpDir;

  setUp(() async {
    tmpDir = Directory.systemTemp.createTempSync('trip_samples_test_');
    Hive.init(tmpDir.path);
    await Hive.openBox<String>(HiveBoxes.obd2TripHistory);
  });

  tearDown(() async {
    await Hive.box<String>(HiveBoxes.obd2TripHistory).deleteFromDisk();
    await Hive.close();
    tmpDir.deleteSync(recursive: true);
  });

  test('TripHistoryEntry persists per-tick samples through save+load', () {
    final start = DateTime(2026, 4, 24, 12);
    final samples = <TripSample>[
      for (int i = 0; i < 5; i++)
        TripSample(
          timestamp: start.add(Duration(seconds: i)),
          speedKmh: 50 + i.toDouble(),
          rpm: 2000 + i * 10,
          fuelRateLPerHour: 6.0 + i * 0.1,
        ),
    ];
    final entry = TripHistoryEntry(
      id: start.toIso8601String(),
      vehicleId: 'veh-1',
      summary: TripSummary(
        distanceKm: 0.5,
        maxRpm: 2040,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        startedAt: start,
        endedAt: start.add(const Duration(seconds: 5)),
      ),
      samples: samples,
    );

    final json = entry.toJson();
    final restored = TripHistoryEntry.fromJson(json);

    expect(restored.samples, hasLength(5));
    expect(restored.samples.first.speedKmh, 50);
    expect(restored.samples.last.speedKmh, 54);
    expect(restored.samples[2].rpm, 2020);
    expect(restored.samples[2].fuelRateLPerHour, closeTo(6.2, 1e-9));
    expect(restored.samples.first.timestamp, start);
  });

  test('TripHistoryEntry samples default to empty for legacy payloads', () {
    // Pre-#1040 payloads carry no `samples` key — make sure the
    // rolling-log loader still deserialises them as empty rather than
    // throwing.
    final legacy = {
      'id': 'legacy-1',
      'vehicleId': 'veh-1',
      'summary': {
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
    expect(restored.samples, isEmpty);
  });

  test(
    'TripRecording.stop() persists the controller sample buffer onto '
    'the saved TripHistoryEntry — the charts read this back',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = Obd2Service(FakeObd2Transport(_elmOk()));
      await service.connect();

      final notifier = container.read(tripRecordingProvider.notifier);
      await notifier.start(service);
      // Inject a deterministic sample buffer through the live stream
      // path. The controller is owned by the provider; we drive its
      // recorder via the visible-for-testing hook so we don't depend
      // on real-clock timing of the 4 Hz emit loop.
      final ctl = notifier.debugController;
      expect(ctl, isNotNull,
          reason: 'provider must own a controller while recording');
      final start = DateTime.now();
      for (int i = 0; i < 6; i++) {
        final sample = TripSample(
          timestamp: start.add(Duration(seconds: i)),
          speedKmh: 40 + i.toDouble(),
          rpm: 1800 + i * 5,
          fuelRateLPerHour: 5.5,
        );
        // Feed the recorder so the resulting summary has a startedAt
        // and a non-zero distance — without this _saveToHistory
        // short-circuits as an "empty" trip.
        ctl!.debugInjectSample(
          speedKmh: sample.speedKmh,
          rpm: sample.rpm,
          at: sample.timestamp,
          fuelRateLPerHour: sample.fuelRateLPerHour,
        );
        // Capture the same sample into the per-tick buffer that the
        // chart layer reads back at display time.
        ctl.debugCaptureSample(sample);
      }
      await notifier.stop();

      final repo = container.read(tripHistoryRepositoryProvider);
      expect(repo, isNotNull);
      final history = repo!.loadAll();
      expect(history, isNotEmpty,
          reason: 'stop() must persist a TripHistoryEntry');
      final saved = history.first;
      expect(saved.samples, hasLength(6),
          reason: 'every captured sample must round-trip into Hive — '
              'without this the trip detail screen renders '
              '"No samples recorded"');
      expect(saved.samples.first.speedKmh, 40);
      expect(saved.samples.last.speedKmh, 45);
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
