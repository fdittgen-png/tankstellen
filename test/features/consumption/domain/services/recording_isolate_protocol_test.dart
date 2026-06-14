// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/domain/services/recording_isolate_protocol.dart';

/// #3321 — the port-safe codec that crosses the recording-isolate boundary.
void main() {
  group('RecordingFixMessage codec', () {
    test('round-trips a full GPS fix through the map form', () {
      const fix = RecordingFixMessage(
        epochMs: 1734000000000,
        speedKmh: 53.4,
        latitude: 48.137,
        longitude: 11.575,
        altitudeM: 519.0,
        hAccuracyM: 4.5,
        bearingDeg: 270.0,
      );
      final back = RecordingFixMessage.fromMap(fix.toMap());
      expect(back.epochMs, fix.epochMs);
      expect(back.speedKmh, fix.speedKmh);
      expect(back.latitude, fix.latitude);
      expect(back.longitude, fix.longitude);
      expect(back.altitudeM, fix.altitudeM);
      expect(back.hAccuracyM, fix.hAccuracyM);
      expect(back.bearingDeg, fix.bearingDeg);
    });

    test('omits null optionals from the map but decodes them back as null', () {
      const fix = RecordingFixMessage(epochMs: 1, speedKmh: 0);
      final map = fix.toMap();
      expect(map.containsKey('lat'), isFalse);
      expect(map.containsKey('brg'), isFalse);
      final back = RecordingFixMessage.fromMap(map);
      expect(back.latitude, isNull);
      expect(back.bearingDeg, isNull);
      expect(back.speedKmh, 0);
    });

    test('the map carries only primitives (port-safe)', () {
      const fix = RecordingFixMessage(
          epochMs: 1, speedKmh: 2, latitude: 3, longitude: 4);
      for (final v in fix.toMap().values) {
        expect(v is num || v is String, isTrue,
            reason: 'a SendPort only carries primitives — got ${v.runtimeType}');
      }
    });

    test('decodeRecordingFix rejects a non-fix message', () {
      expect(decodeRecordingFix(<String, Object?>{'_t': 'cmd'}), isNull);
      expect(decodeRecordingFix('not a map'), isNull);
    });
  });

  group('command codec', () {
    test('round-trips every command', () {
      for (final c in RecordingIsolateCommand.values) {
        expect(decodeRecordingCommand(encodeRecordingCommand(c)), c);
      }
    });

    test('decodeRecordingCommand rejects a fix / junk', () {
      expect(decodeRecordingCommand(<String, Object?>{'_t': 'fix'}), isNull);
      expect(decodeRecordingCommand(42), isNull);
      expect(
          decodeRecordingCommand(<String, Object?>{'_t': 'cmd', 'cmd': 'x'}),
          isNull);
    });
  });
}
