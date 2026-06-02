// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_sample_codec.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

/// #2459 — the consumed-but-previously-unstored signals + the
/// diagnostic-capture raw mixture inputs round-trip through the compact
/// codec, add ZERO bytes when absent, and deserialise as null on legacy
/// trips.
void main() {
  final ts = DateTime(2026, 5, 30, 12);

  group('#2459 new optional signals — round-trip', () {
    test('all six consumed-but-unstored signals round-trip', () {
      final s = TripSample(
        timestamp: ts,
        speedKmh: 80,
        rpm: 2100,
        fuelRateLPerHour: 5.5,
        lambda: 1.12,
        baroKpa: 97.0,
        absLoadPercent: 142.0, // boosted, >100 %
        pedalPercent: 63.0,
        oilTempC: 88.0,
        ambientTempC: 11.0,
      );
      final back = sampleFromJson(sampleToJson(s));
      expect(back.lambda, 1.12);
      expect(back.baroKpa, 97.0);
      expect(back.absLoadPercent, 142.0);
      expect(back.pedalPercent, 63.0);
      expect(back.oilTempC, 88.0);
      expect(back.ambientTempC, 11.0);
    });

    test('absent signals add ZERO keys (zero bytes when unsupported)', () {
      final s = TripSample(timestamp: ts, speedKmh: 50, rpm: 1500);
      final json = sampleToJson(s);
      for (final key in ['lm', 'bp', 'aL', 'pp', 'ot', 'am']) {
        expect(json.containsKey(key), isFalse,
            reason: '$key must be omitted when the field is null');
      }
      // And those round-trip back as null.
      final back = sampleFromJson(json);
      expect(back.lambda, isNull);
      expect(back.baroKpa, isNull);
      expect(back.absLoadPercent, isNull);
      expect(back.pedalPercent, isNull);
      expect(back.oilTempC, isNull);
      expect(back.ambientTempC, isNull);
    });

    test('a legacy sample (no new keys) deserialises every field null', () {
      // Hand-built legacy payload: only the pre-#2459 keys.
      final legacy = <String, dynamic>{
        't': ts.millisecondsSinceEpoch,
        's': 60.0,
        'r': 1700.0,
        'th': 25.0,
      };
      final back = sampleFromJson(legacy);
      expect(back.speedKmh, 60.0);
      expect(back.throttlePercent, 25.0);
      expect(back.lambda, isNull);
      expect(back.absLoadPercent, isNull);
      expect(back.pedalPercent, isNull);
      expect(back.mafGramsPerSecond, isNull);
      expect(back.stft, isNull);
    });
  });

  group('#2459 diagnostic-capture raw mixture inputs', () {
    test('raw inputs round-trip when present (capture on)', () {
      final s = TripSample(
        timestamp: ts,
        speedKmh: 80,
        rpm: 2100,
        mafGramsPerSecond: 12.4,
        mapKpa: 78.0,
        stft: 3.5,
        ltft: -1.5,
      );
      final json = sampleToJson(s);
      expect(json['mf'], 12.4);
      expect(json['mp'], 78.0);
      expect(json['sf'], 3.5);
      expect(json['lf'], -1.5);
      final back = sampleFromJson(json);
      expect(back.mafGramsPerSecond, 12.4);
      expect(back.mapKpa, 78.0);
      expect(back.stft, 3.5);
      expect(back.ltft, -1.5);
    });

    test('capture OFF (raw inputs null) writes NO raw-input keys', () {
      // A normal default-off trip: the six new signals may be present,
      // but the four raw-input keys must be absent → no storage growth.
      final s = TripSample(
        timestamp: ts,
        speedKmh: 80,
        rpm: 2100,
        fuelRateLPerHour: 5.5,
        lambda: 1.0,
      );
      final json = sampleToJson(s);
      for (final key in ['mf', 'mp', 'sf', 'lf']) {
        expect(json.containsKey(key), isFalse,
            reason: '$key must be omitted when diagnostic capture is off');
      }
    });
  });

  group('#2692 C4-G — nullable rpm round-trip', () {
    test('a GPS-only sample (rpm null) omits the "r" key entirely', () {
      final s = TripSample(timestamp: ts, speedKmh: 50, rpm: null);
      final json = sampleToJson(s);
      expect(json.containsKey('r'), isFalse,
          reason: 'rpm null must add zero bytes (no "r" key)');
      final back = sampleFromJson(json);
      expect(back.rpm, isNull);
      expect(back.speedKmh, 50);
    });

    test('an OBD2 sample (rpm present) writes "r" and round-trips identically',
        () {
      final s = TripSample(timestamp: ts, speedKmh: 80, rpm: 2100);
      final json = sampleToJson(s);
      expect(json['r'], 2100);
      expect(sampleFromJson(json).rpm, 2100);
    });

    test('a legacy trip with a stored "r" still reads back unchanged', () {
      final legacy = <String, dynamic>{
        't': ts.millisecondsSinceEpoch,
        's': 60.0,
        'r': 1700.0,
      };
      expect(sampleFromJson(legacy).rpm, 1700.0);
    });
  });
}
