import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_detail_charts.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_detail_share_payload.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vehicle_profile.dart';

/// #561 — coverage for [tripDetailSharePayload].
///
/// The share payload is JSON header (indented two spaces) + blank line
/// + CSV block (`timestamp,speedKmh,rpm,fuelRateLPerHour`). These
/// tests assert the JSON field gating (omit-when-null), CSV row
/// formatting (fixed decimals, empty string for null), and parity
/// between [tripDetailSharePayload] and the `@visibleForTesting`
/// alias [buildTripDetailSharePayload].

TripSummary _summary({
  double distanceKm = 12.5,
  double maxRpm = 5500,
  double highRpmSeconds = 30,
  double idleSeconds = 60,
  int harshBrakes = 1,
  int harshAccelerations = 2,
  double? avgLPer100Km,
  double? fuelLitersConsumed,
  DateTime? startedAt,
  DateTime? endedAt,
  String distanceSource = 'virtual',
}) {
  return TripSummary(
    distanceKm: distanceKm,
    maxRpm: maxRpm,
    highRpmSeconds: highRpmSeconds,
    idleSeconds: idleSeconds,
    harshBrakes: harshBrakes,
    harshAccelerations: harshAccelerations,
    avgLPer100Km: avgLPer100Km,
    fuelLitersConsumed: fuelLitersConsumed,
    startedAt: startedAt,
    endedAt: endedAt,
    distanceSource: distanceSource,
  );
}

TripHistoryEntry _entry({
  String id = 'trip-001',
  String? vehicleId,
  TripSummary? summary,
}) {
  return TripHistoryEntry(
    id: id,
    vehicleId: vehicleId,
    summary: summary ?? _summary(),
  );
}

VehicleProfile _vehicle({String id = 'veh-1', String name = 'My Car'}) {
  return VehicleProfile(id: id, name: name);
}

/// Splits the payload into the `(jsonText, csvBody)` pair on the
/// mandatory blank line. Asserts the separator exists.
({Map<String, dynamic> json, List<String> csvLines}) _split(String payload) {
  final separatorIndex = payload.indexOf('\n\n');
  expect(separatorIndex, greaterThan(0),
      reason: 'payload must contain a blank line between JSON and CSV');
  final jsonText = payload.substring(0, separatorIndex);
  final csvText = payload.substring(separatorIndex + 2);
  final json = jsonDecode(jsonText) as Map<String, dynamic>;
  // Drop trailing empty entry from terminating newline.
  final lines = csvText
      .split('\n')
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  return (json: json, csvLines: lines);
}

void main() {
  group('tripDetailSharePayload', () {
    test('JSON header carries the always-present trip metrics', () {
      final payload = tripDetailSharePayload(
        entry: _entry(
          id: 'trip-001',
          summary: _summary(
            distanceKm: 42.5,
            maxRpm: 6100,
            highRpmSeconds: 33.5,
            idleSeconds: 90.25,
            harshBrakes: 3,
            harshAccelerations: 4,
            distanceSource: 'real',
          ),
        ),
        vehicle: null,
        samples: const [],
      );

      final parts = _split(payload);
      final json = parts.json;
      expect(json['id'], 'trip-001');
      expect(json['distanceKm'], 42.5);
      expect(json['distanceSource'], 'real');
      expect(json['maxRpm'], 6100);
      expect(json['highRpmSeconds'], 33.5);
      expect(json['idleSeconds'], 90.25);
      expect(json['harshBrakes'], 3);
      expect(json['harshAccelerations'], 4);
      expect(json['sampleCount'], 0);
    });

    test('omits vehicle key when vehicle is null', () {
      final payload = tripDetailSharePayload(
        entry: _entry(),
        vehicle: null,
        samples: const [],
      );
      final json = _split(payload).json;
      expect(json.containsKey('vehicle'), isFalse);
    });

    test('includes vehicle name when vehicle is non-null', () {
      final payload = tripDetailSharePayload(
        entry: _entry(),
        vehicle: _vehicle(name: 'Peugeot 107'),
        samples: const [],
      );
      final json = _split(payload).json;
      expect(json['vehicle'], 'Peugeot 107');
    });

    test('omits vehicleId when entry.vehicleId is null', () {
      final payload = tripDetailSharePayload(
        entry: _entry(),
        vehicle: null,
        samples: const [],
      );
      final json = _split(payload).json;
      expect(json.containsKey('vehicleId'), isFalse);
    });

    test('includes vehicleId when entry.vehicleId is set', () {
      final payload = tripDetailSharePayload(
        entry: _entry(vehicleId: 'veh-42'),
        vehicle: null,
        samples: const [],
      );
      final json = _split(payload).json;
      expect(json['vehicleId'], 'veh-42');
    });

    test('omits startedAt and endedAt when both are null', () {
      final payload = tripDetailSharePayload(
        entry: _entry(),
        vehicle: null,
        samples: const [],
      );
      final json = _split(payload).json;
      expect(json.containsKey('startedAt'), isFalse);
      expect(json.containsKey('endedAt'), isFalse);
    });

    test('serialises startedAt and endedAt as ISO 8601 strings', () {
      final started = DateTime.utc(2026, 4, 22, 10, 0, 0);
      final ended = DateTime.utc(2026, 4, 22, 10, 30, 0);
      final payload = tripDetailSharePayload(
        entry: _entry(
          summary: _summary(startedAt: started, endedAt: ended),
        ),
        vehicle: null,
        samples: const [],
      );
      final json = _split(payload).json;
      expect(json['startedAt'], started.toIso8601String());
      expect(json['endedAt'], ended.toIso8601String());
    });

    test('omits avgLPer100Km and fuelLitersConsumed when both are null', () {
      final payload = tripDetailSharePayload(
        entry: _entry(),
        vehicle: null,
        samples: const [],
      );
      final json = _split(payload).json;
      expect(json.containsKey('avgLPer100Km'), isFalse);
      expect(json.containsKey('fuelLitersConsumed'), isFalse);
    });

    test('includes avgLPer100Km and fuelLitersConsumed when set', () {
      final payload = tripDetailSharePayload(
        entry: _entry(
          summary: _summary(
            avgLPer100Km: 6.4,
            fuelLitersConsumed: 0.8,
          ),
        ),
        vehicle: null,
        samples: const [],
      );
      final json = _split(payload).json;
      expect(json['avgLPer100Km'], 6.4);
      expect(json['fuelLitersConsumed'], 0.8);
    });

    test('CSV block opens with the canonical header line', () {
      final payload = tripDetailSharePayload(
        entry: _entry(),
        vehicle: null,
        samples: const [],
      );
      final lines = _split(payload).csvLines;
      expect(lines, isNotEmpty);
      expect(lines.first, 'timestamp,speedKmh,rpm,fuelRateLPerHour');
    });

    test('CSV row uses fixed decimals: speed 2dp, rpm 0dp, fuel 3dp', () {
      final ts = DateTime.utc(2026, 4, 22, 10, 0, 0);
      final payload = tripDetailSharePayload(
        entry: _entry(),
        vehicle: null,
        samples: [
          TripDetailSample(
            timestamp: ts,
            speedKmh: 12.345,
            rpm: 1500,
            fuelRateLPerHour: 5.123456,
          ),
        ],
      );
      final lines = _split(payload).csvLines;
      // [0] header, [1] data row
      expect(lines.length, 2);
      expect(lines[1], '${ts.toIso8601String()},12.35,1500,5.123');
    });

    test('CSV row emits empty rpm field when sample.rpm is null', () {
      final ts = DateTime.utc(2026, 4, 22, 10, 0, 0);
      final payload = tripDetailSharePayload(
        entry: _entry(),
        vehicle: null,
        samples: [
          TripDetailSample(
            timestamp: ts,
            speedKmh: 30.0,
            fuelRateLPerHour: 4.0,
          ),
        ],
      );
      final lines = _split(payload).csvLines;
      expect(lines[1], '${ts.toIso8601String()},30.00,,4.000');
    });

    test('CSV row emits empty trailing field when fuelRateLPerHour is null',
        () {
      final ts = DateTime.utc(2026, 4, 22, 10, 0, 0);
      final payload = tripDetailSharePayload(
        entry: _entry(),
        vehicle: null,
        samples: [
          TripDetailSample(
            timestamp: ts,
            speedKmh: 30.0,
            rpm: 1500,
          ),
        ],
      );
      final lines = _split(payload).csvLines;
      expect(lines[1], '${ts.toIso8601String()},30.00,1500,');
    });

    test('empty samples list yields a CSV block with only the header', () {
      final payload = tripDetailSharePayload(
        entry: _entry(),
        vehicle: null,
        samples: const [],
      );
      final lines = _split(payload).csvLines;
      expect(lines.length, 1);
      expect(lines.first, 'timestamp,speedKmh,rpm,fuelRateLPerHour');
    });

    test('JSON header and CSV block are separated by exactly one blank line',
        () {
      final payload = tripDetailSharePayload(
        entry: _entry(),
        vehicle: null,
        samples: const [],
      );
      // The JSON block ends with `}` (no trailing newline), then
      // `\n\n`, then the CSV header. Confirm the boundary signature.
      final boundary = payload.indexOf('}\n\ntimestamp,');
      expect(boundary, greaterThan(0),
          reason: 'expected `}\\n\\ntimestamp,...` separator, got: $payload');
    });

    test('JSON header is pretty-printed with two-space indent', () {
      final payload = tripDetailSharePayload(
        entry: _entry(id: 'trip-x'),
        vehicle: null,
        samples: const [],
      );
      // Two-space indent means every nested key starts with `  "`.
      expect(payload, contains('  "id": "trip-x"'));
    });

    test('sampleCount reflects the length of the samples list', () {
      final ts = DateTime.utc(2026, 4, 22, 10, 0, 0);
      final samples = [
        for (var i = 0; i < 5; i++)
          TripDetailSample(
            timestamp: ts.add(Duration(seconds: i)),
            speedKmh: 20.0 + i,
            rpm: 1500.0 + i,
            fuelRateLPerHour: 4.0 + i,
          ),
      ];
      final payload = tripDetailSharePayload(
        entry: _entry(),
        vehicle: null,
        samples: samples,
      );
      final json = _split(payload).json;
      expect(json['sampleCount'], 5);
      expect(_split(payload).csvLines.length, 6); // header + 5 rows
    });

    test('buildTripDetailSharePayload produces identical output to the alias',
        () {
      final ts = DateTime.utc(2026, 4, 22, 10, 0, 0);
      final entry = _entry(
        id: 'trip-parity',
        vehicleId: 'veh-1',
        summary: _summary(
          startedAt: ts,
          endedAt: ts.add(const Duration(minutes: 30)),
          avgLPer100Km: 5.5,
          fuelLitersConsumed: 1.6,
          distanceSource: 'real',
        ),
      );
      final samples = [
        TripDetailSample(
          timestamp: ts,
          speedKmh: 50.0,
          rpm: 2000,
          fuelRateLPerHour: 4.5,
        ),
      ];
      final vehicle = _vehicle(name: 'Peugeot 107');

      final canonical = tripDetailSharePayload(
        entry: entry,
        vehicle: vehicle,
        samples: samples,
      );
      final alias = buildTripDetailSharePayload(
        entry: entry,
        vehicle: vehicle,
        samples: samples,
      );
      expect(alias, canonical);
    });
  });
}
