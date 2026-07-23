// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_summary_codec.dart';
import 'package:tankstellen/features/consumption/domain/imu_event_record.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// #3589 — the per-stretch IMU calibration records must survive the Hive
/// JSON round-trip (the #2776 lesson), and record-less trips must
/// round-trip byte-identical (no `ier`/`ierd` keys).
void main() {
  TripSummary mk({
    List<ImuEventRecord> records = const [],
    int dropped = 0,
  }) =>
      TripSummary(
        distanceKm: 12.0,
        maxRpm: 0,
        highRpmSeconds: 0,
        idleSeconds: 10,
        harshBrakes: 0,
        harshAccelerations: 0,
        imuActive: records.isNotEmpty,
        imuEventRecords: records,
        imuEventRecordsDropped: dropped,
        startedAt: DateTime(2026, 7, 23, 8),
      );

  const rec = ImuEventRecord(
    outcome: 'tooShort',
    peakMps2: 5.0,
    durationSec: 0.55,
    startSpeedKmh: 41.0,
    netSpeedDeltaKmh: 1.5,
    peakYawRadPerSec: 0.05,
  );

  test('records + dropped counter round-trip through the codec', () {
    final json = tripSummaryToJson(mk(records: const [rec], dropped: 3));
    final back = tripSummaryFromJson(json);
    expect(back.imuEventRecordsDropped, 3);
    final r = back.imuEventRecords.single;
    expect(r.outcome, 'tooShort');
    expect(r.peakMps2, 5.0);
    expect(r.durationSec, 0.55);
    expect(r.startSpeedKmh, 41.0);
    expect(r.netSpeedDeltaKmh, 1.5);
    expect(r.peakYawRadPerSec, 0.05);
  });

  test('a record-less trip adds no keys (legacy byte-parity)', () {
    final json = tripSummaryToJson(mk());
    expect(json.containsKey('ier'), isFalse);
    expect(json.containsKey('ierd'), isFalse);
    final back = tripSummaryFromJson(json);
    expect(back.imuEventRecords, isEmpty);
    expect(back.imuEventRecordsDropped, 0);
  });

  test('a malformed persisted entry is skipped, not fatal', () {
    final json = tripSummaryToJson(mk(records: const [rec]));
    (json['ier'] as List).add({'p': 'garbage'}); // no outcome string
    final back = tripSummaryFromJson(json);
    expect(back.imuEventRecords, hasLength(1));
  });
}
