// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/exporters/trip_detail_exporter.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/data/trip_sample_codec.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// A fully-populated sample exercising every CSV column.
TripSample _fullSample(DateTime ts) => TripSample(
      timestamp: ts,
      speedKmh: 52.3,
      rpm: 2100,
      fuelRateLPerHour: 6.4,
      estimatedFuelRateLPerHour: 6.1,
      throttlePercent: 24.0,
      engineLoadPercent: 41.0,
      coolantTempC: 88.0,
      latitude: 48.8566,
      longitude: 2.3522,
      altitudeM: 35.0,
      hAccuracyM: 4.5,
      bearingDeg: 123.4,
      accelG: 0.12,
      lambda: 0.99,
      baroKpa: 101.0,
      absLoadPercent: 55.0,
      pedalPercent: 30.0,
      oilTempC: 95.0,
      ambientTempC: 18.0,
      mafGramsPerSecond: 12.3,
      mapKpa: 95.0,
      stft: -1.5,
      ltft: 2.0,
    );

/// A minimal sample — only the three required fields. Every optional
/// signal is null, so its CSV row carries empty cells.
TripSample _minimalSample(DateTime ts) =>
    TripSample(timestamp: ts, speedKmh: 12.0, rpm: 900);

TripHistoryEntry _entry(List<TripSample> samples) => TripHistoryEntry(
      id: 'trip-1',
      vehicleId: 'v1',
      summary: TripSummary(
        distanceKm: 5.0,
        maxRpm: 2500,
        highRpmSeconds: 0,
        idleSeconds: 0,
        harshBrakes: 0,
        harshAccelerations: 0,
        avgLPer100Km: 7.5,
        fuelLitersConsumed: 0.4,
        startedAt: DateTime.utc(2026, 5, 24, 14, 0),
        endedAt: DateTime.utc(2026, 5, 24, 14, 30),
      ),
      samples: samples,
    );

void main() {
  group('buildTripDetailCsv (#2652)', () {
    final ts = DateTime.utc(2026, 5, 24, 14, 0, 1);

    test('first row is the exact 24-column machine-stable header', () {
      final csv = buildTripDetailCsv(_entry([_minimalSample(ts)]));
      final firstLine = csv.split('\r\n').first;
      expect(firstLine, tripDetailCsvHeader.join(','));
      // Spot-check the contract endpoints + ordering.
      expect(tripDetailCsvHeader.length, 24);
      expect(tripDetailCsvHeader.first, 'timestamp_iso8601');
      expect(tripDetailCsvHeader.last, 'ltft_pct');
    });

    test('emits one data row per sample', () {
      final csv = buildTripDetailCsv(_entry([
        _fullSample(ts),
        _minimalSample(ts.add(const Duration(seconds: 1))),
      ]));
      // 1 header + 2 data rows + trailing CRLF → split yields 4 with a
      // trailing empty element.
      final lines = csv.split('\r\n');
      expect(lines.length, 4);
      expect(lines.last, isEmpty); // trailing CRLF
    });

    test('uses CRLF line endings (RFC 4180 / Excel-friendly)', () {
      final csv = buildTripDetailCsv(_entry([_minimalSample(ts)]));
      expect(csv, contains('\r\n'));
      // No bare LF that isn't part of a CRLF pair.
      expect(csv.replaceAll('\r\n', ''), isNot(contains('\n')));
    });

    test('timestamp column is an ISO-8601 UTC instant', () {
      final csv = buildTripDetailCsv(_entry([_minimalSample(ts)]));
      final dataRow = csv.split('\r\n')[1];
      expect(dataRow.split(',').first, '2026-05-24T14:00:01.000Z');
    });

    test('a fully-populated sample fills every column', () {
      final csv = buildTripDetailCsv(_entry([_fullSample(ts)]));
      final cells = csv.split('\r\n')[1].split(',');
      expect(cells.length, 24);
      // No empty cell — every signal was present.
      expect(cells.where((c) => c.isEmpty), isEmpty);
      // bearing_deg is column index 12, h_accuracy_m index 11.
      expect(cells[11], '4.5'); // h_accuracy_m
      expect(cells[12], '123.4'); // bearing_deg
      expect(cells[7], '88.0'); // coolant_temp_c
    });

    test('absent signals render as empty cells', () {
      final csv = buildTripDetailCsv(_entry([_minimalSample(ts)]));
      final cells = csv.split('\r\n')[1].split(',');
      expect(cells.length, 24);
      // Only timestamp/speed/rpm populated; the 21 optionals are empty.
      expect(cells[1], '12.0'); // speed_kmh
      expect(cells[2], '900.0'); // rpm
      for (var i = 3; i < 24; i++) {
        expect(cells[i], isEmpty, reason: 'column $i should be empty');
      }
    });
  });

  group('buildTripDetailJson (#2652)', () {
    final ts = DateTime.utc(2026, 5, 24, 14, 0, 1);

    test('round-trips through the persisted sample codec', () {
      final original = _fullSample(ts);
      final json = buildTripDetailJson(_entry([original]));
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['id'], 'trip-1');
      expect(decoded['vehicleId'], 'v1');
      final samples = decoded['samples'] as List;
      expect(samples, hasLength(1));

      // The serialized sample re-decodes to the original via the
      // canonical codec — the export is re-importable.
      final restored = sampleFromJson(samples.single as Map<String, dynamic>);
      expect(restored.speedKmh, original.speedKmh);
      expect(restored.bearingDeg, original.bearingDeg);
      expect(restored.coolantTempC, original.coolantTempC);
      expect(restored.ltft, original.ltft);
      // The codec persists epoch millis (the instant), so compare the
      // instant rather than the DateTime object's isUtc/wall-clock.
      expect(
        restored.timestamp.millisecondsSinceEpoch,
        original.timestamp.millisecondsSinceEpoch,
      );
    });

    test('matches sampleToJson for each sample (single source of truth)', () {
      final s = _fullSample(ts);
      final json = buildTripDetailJson(_entry([s]));
      final samples = (jsonDecode(json) as Map<String, dynamic>)['samples']
          as List;
      expect(samples.single, sampleToJson(s));
    });
  });
}
