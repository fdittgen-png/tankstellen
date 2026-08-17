// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/data/trip_sample_codec.dart';
import 'package:tankstellen/features/consumption/data/trip_summary_codec.dart';
import 'package:tankstellen/features/consumption/domain/imu_event_record.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/obd2/data/active_trip_repository.dart';
import 'package:tankstellen/features/obd2/data/paused_trip_repository.dart';

import '../../../helpers/silence_error_logger.dart';

/// #3739 — ONE canonical TripSummary/TripSample codec for every
/// persistence path.
///
/// TripSummary/TripSample used to be serialised by THREE hand-rolled
/// codecs: the canonical `trip_summary_codec.dart`/`trip_sample_codec.dart`
/// pair (history), plus private drifted copies in
/// `active_trip_repository.dart` (WAL, missing 13 summary keys) and
/// `paused_trip_repository.dart` (missing 16 — including `kind` and
/// `distanceSource`, whose absence made every paused→finalised trip fall
/// back to the suspicious `'virtual'` default). This suite round-trips a
/// FULLY-populated summary + sample (every serialised field non-default)
/// through all three paths and asserts key-set + value equality against
/// the canonical encoding, so any future codec fork goes red immediately.
///
/// Not covered on purpose: `TripSummary.fuelRateSuspect` is not persisted
/// by the canonical codec either (it is re-derived from the breadcrumb
/// collector at trip end) — the unification target is the canonical
/// key set, not a new schema.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  silenceErrorLoggerSpool();

  final start = DateTime.utc(2026, 7, 1, 8, 30);

  /// Every field the canonical codec serialises set to a NON-default
  /// value, so an omit-when-default codec fork cannot hide behind
  /// defaults matching.
  final summary = TripSummary(
    distanceKm: 42.5,
    maxRpm: 4321,
    highRpmSeconds: 12.5,
    idleSeconds: 33,
    harshBrakes: 3,
    harshAccelerations: 2,
    avgLPer100Km: 6.4,
    fuelLitersConsumed: 2.72,
    estimatedAvgLPer100Km: 6.9,
    estimatedFuelLitersConsumed: 2.93,
    startedAt: start,
    endedAt: start.add(const Duration(minutes: 39)),
    distanceSource: 'real',
    coldStartSurcharge: true,
    secondsBelowOptimalGear: 41.0,
    volumetricEfficiencyUsed: 0.87,
    kind: TripKind.gpsOnly,
    harshEvents: [
      HarshEvent(
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          start.millisecondsSinceEpoch,
          isUtc: true,
        ),
        magnitudeG: 0.45,
        speedKmh: 80,
        type: HarshEventType.brake,
      ),
    ],
    isVirtual: true,
    imuHardAccelCount: 4,
    imuHardBrakeCount: 5,
    sharpCornerCount: 6,
    imuActive: true,
    imuEventRecords: const [
      ImuEventRecord(
        outcome: 'brake',
        peakMps2: 5.25,
        durationSec: 1.5,
        startSpeedKmh: 62.0,
        netSpeedDeltaKmh: -18.0,
        peakYawRadPerSec: 0.12,
      ),
    ],
    imuEventRecordsDropped: 7,
    engineRunningSeconds: 1234.0,
  );

  /// Every serialised per-tick field non-null.
  final sample = TripSample(
    timestamp: start.add(const Duration(seconds: 5)),
    speedKmh: 63.0,
    rpm: 2200,
    fuelRateLPerHour: 5.5,
    estimatedFuelRateLPerHour: 5.7,
    throttlePercent: 31.0,
    engineLoadPercent: 44.0,
    coolantTempC: 88.0,
    latitude: 43.4,
    longitude: 3.5,
    altitudeM: 12.0,
    hAccuracyM: 4.2,
    bearingDeg: 117.5,
    accelG: 0.11,
    lambda: 0.98,
    measuredPhi: 1.02,
    ethanolPercent: 27.0,
    fuelSource: 'pid5e',
    baroKpa: 101.2,
    absLoadPercent: 39.0,
    pedalPercent: 28.0,
    oilTempC: 92.0,
    ambientTempC: 21.0,
    mafGramsPerSecond: 8.4,
    mapKpa: 55.0,
    stft: 1.5,
    ltft: -2.0,
    iatC: 25.0,
    timingAdvanceDeg: 14.0,
  );

  final canonicalSummaryJson = tripSummaryToJson(summary);
  final canonicalSampleJson = sampleToJson(sample);
  const deepEq = DeepCollectionEquality();

  void expectCanonicalSummary(TripSummary restored, {required String path}) {
    final restoredJson = tripSummaryToJson(restored);
    expect(
      restoredJson.keys.toSet(),
      canonicalSummaryJson.keys.toSet(),
      reason: '$path: summary key set drifted from the canonical codec — '
          'a field was dropped on the round-trip (#3739)',
    );
    expect(
      deepEq.equals(restoredJson, canonicalSummaryJson),
      isTrue,
      reason: '$path: summary values drifted on the round-trip (#3739).\n'
          'restored: $restoredJson\ncanonical: $canonicalSummaryJson',
    );
    // The two fields whose loss was field-visible (#3739): the paused
    // codec dropped both, so a paused→finalised trip surfaced as a
    // 'virtual'-distance gpsPlusObd2 trip.
    expect(restored.distanceSource, 'real', reason: path);
    expect(restored.kind, TripKind.gpsOnly, reason: path);
  }

  void expectCanonicalSample(TripSample restored, {required String path}) {
    final restoredJson = sampleToJson(restored);
    expect(
      restoredJson.keys.toSet(),
      canonicalSampleJson.keys.toSet(),
      reason: '$path: sample key set drifted from the canonical codec '
          '(#3739)',
    );
    expect(
      deepEq.equals(restoredJson, canonicalSampleJson),
      isTrue,
      reason: '$path: sample values drifted on the round-trip (#3739).\n'
          'restored: $restoredJson\ncanonical: $canonicalSampleJson',
    );
  }

  group('one canonical trip codec across all persistence paths (#3739)', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('trip_codec_unification_');
      Hive.init(tmpDir.path);
    });

    tearDown(() async {
      await Hive.close();
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test('history path — TripHistoryRepository save/loadById', () async {
      final box = await Hive.openBox<String>('codec_history');
      addTearDown(box.deleteFromDisk);
      final repo = TripHistoryRepository(box: box);

      await repo.save(TripHistoryEntry(
        id: 'trip-1',
        vehicleId: 'veh-1',
        summary: summary,
        samples: [sample],
      ));

      final restored = repo.loadById('trip-1');
      expect(restored, isNotNull);
      expectCanonicalSummary(restored!.summary, path: 'history');
      expect(restored.samples, hasLength(1));
      expectCanonicalSample(restored.samples.single, path: 'history');
    });

    test('WAL path — ActiveTripRepository save/loadSnapshot', () async {
      final box = await Hive.openBox<String>('codec_wal');
      addTearDown(box.deleteFromDisk);
      final repo = ActiveTripRepository(box: box);

      await repo.saveSnapshot(ActiveTripSnapshot(
        id: 'trip-1',
        vehicleId: 'veh-1',
        vin: 'VIN-3739',
        automatic: true,
        phase: 'recording',
        summary: summary,
        samples: [sample],
        odometerStartKm: 100.0,
        odometerLatestKm: 142.5,
        startedAt: start,
        lastFlushedAt: start.add(const Duration(minutes: 5)),
      ));

      final restored = repo.loadSnapshot();
      expect(restored, isNotNull);
      expectCanonicalSummary(restored!.summary, path: 'WAL');
      expect(restored.samples, hasLength(1));
      expectCanonicalSample(restored.samples.single, path: 'WAL');
    });

    test('paused path — PausedTripRepository save/load', () async {
      final box = await Hive.openBox<String>('codec_paused');
      addTearDown(box.deleteFromDisk);
      final repo = PausedTripRepository(box: box);

      await repo.save(PausedTripEntry(
        id: 'trip-1',
        vehicleId: 'veh-1',
        vin: 'VIN-3739',
        summary: summary,
        odometerStartKm: 100.0,
        odometerLatestKm: 142.5,
        pausedAt: start.add(const Duration(minutes: 20)),
        automatic: true,
      ));

      final restored = repo.load('trip-1');
      expect(restored, isNotNull);
      expectCanonicalSummary(restored!.summary, path: 'paused');
    });
  });
}
