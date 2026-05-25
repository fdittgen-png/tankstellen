// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/exporters/gpx_exporter.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:xml/xml.dart';

TripSample _sample(
  DateTime ts, {
  double? lat,
  double? lon,
  double? alt,
}) =>
    TripSample(
      timestamp: ts,
      speedKmh: 50,
      rpm: 2000,
      latitude: lat,
      longitude: lon,
      altitudeM: alt,
    );

TripHistoryEntry _entry({
  String id = 'trip-1',
  required List<TripSample> samples,
  DateTime? startedAt,
}) {
  return TripHistoryEntry(
    id: id,
    vehicleId: null,
    summary: TripSummary(
      distanceKm: 5.0,
      maxRpm: 2500,
      highRpmSeconds: 0,
      idleSeconds: 0,
      harshBrakes: 0,
      harshAccelerations: 0,
      avgLPer100Km: 7.5,
      fuelLitersConsumed: 0.4,
      startedAt: startedAt,
      endedAt: null,
      distanceSource: 'gps',
      coldStartSurcharge: false,
    ),
    samples: samples,
  );
}

void main() {
  group('buildGpxXml (#2032)', () {
    test('emits a valid GPX 1.1 document with one trkpt per GPS sample',
        () {
      final entry = _entry(
        startedAt: DateTime.utc(2026, 5, 24, 14, 0),
        samples: [
          _sample(DateTime.utc(2026, 5, 24, 14, 0, 1),
              lat: 48.8566, lon: 2.3522, alt: 35.0),
          _sample(DateTime.utc(2026, 5, 24, 14, 0, 2),
              lat: 48.8567, lon: 2.3523, alt: 35.1),
        ],
      );

      final gpx = buildGpxXml(entry);

      expect(gpx, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(gpx, contains('<gpx version="1.1"'));
      expect(gpx, contains('xmlns="http://www.topografix.com/GPX/1/1"'));
      expect(gpx, contains('creator="tankstellen"'));
      expect(gpx, contains('<trk>'));
      expect(gpx, contains('<trkseg>'));
      expect(gpx, contains('lat="48.8566000"'));
      expect(gpx, contains('lon="2.3522000"'));
      expect(gpx, contains('<ele>35.0</ele>'));
      expect(gpx, contains('<time>2026-05-24T14:00:01.000Z</time>'));

      // Must be parseable as XML
      final doc = XmlDocument.parse(gpx);
      final trkpts = doc.findAllElements('trkpt');
      expect(trkpts.length, 2);
    });

    test('skips samples without a GPS fix (no teleport gaps)', () {
      final entry = _entry(
        samples: [
          _sample(DateTime.utc(2026, 5, 24, 14, 0, 1),
              lat: 48.0, lon: 2.0),
          _sample(DateTime.utc(2026, 5, 24, 14, 0, 2)), // no lat/lon
          _sample(DateTime.utc(2026, 5, 24, 14, 0, 3),
              lat: 48.1, lon: 2.1),
        ],
      );

      final gpx = buildGpxXml(entry);
      final doc = XmlDocument.parse(gpx);

      expect(doc.findAllElements('trkpt').length, 2);
    });

    test('countGpsFixes counts only fixed samples', () {
      final entry = _entry(
        samples: [
          _sample(DateTime.utc(2026, 5, 24, 14, 0, 1),
              lat: 1.0, lon: 1.0),
          _sample(DateTime.utc(2026, 5, 24, 14, 0, 2)),
          _sample(DateTime.utc(2026, 5, 24, 14, 0, 3),
              lat: 2.0, lon: 2.0),
        ],
      );
      expect(countGpsFixes(entry), 2);
    });

    test('omits <ele> when altitude is null', () {
      final entry = _entry(
        samples: [
          _sample(DateTime.utc(2026, 5, 24), lat: 1.0, lon: 1.0),
        ],
      );

      final gpx = buildGpxXml(entry);
      expect(gpx, isNot(contains('<ele>')));
    });

    test('emits trip name + start time in metadata when startedAt is set',
        () {
      final entry = _entry(
        startedAt: DateTime.utc(2026, 5, 24, 14, 30),
        samples: [
          _sample(DateTime.utc(2026, 5, 24, 14, 30, 1),
              lat: 1.0, lon: 1.0),
        ],
      );

      final gpx = buildGpxXml(entry);
      expect(gpx, contains('<name>tankstellen 2026-05-24 14:30</name>'));
      expect(gpx, contains('<time>2026-05-24T14:30:00.000Z</time>'));
    });
  });

  group('buildAggregateGpxXml (#2032)', () {
    test('emits one <trk> per trip', () {
      final t1 = _entry(
        id: 'trip-1',
        startedAt: DateTime.utc(2026, 5, 23, 9),
        samples: [
          _sample(DateTime.utc(2026, 5, 23, 9, 0, 1),
              lat: 1.0, lon: 1.0),
        ],
      );
      final t2 = _entry(
        id: 'trip-2',
        startedAt: DateTime.utc(2026, 5, 24, 9),
        samples: [
          _sample(DateTime.utc(2026, 5, 24, 9, 0, 1),
              lat: 2.0, lon: 2.0),
        ],
      );

      final gpx = buildAggregateGpxXml([t1, t2]);
      final doc = XmlDocument.parse(gpx);
      expect(doc.findAllElements('trk').length, 2);
      expect(doc.findAllElements('trkpt').length, 2);
    });
  });

  group('gpxFileNameFor (#2032)', () {
    test('uses the trip start time when present', () {
      final entry = _entry(
        startedAt: DateTime.utc(2026, 5, 24, 14, 30),
        samples: const [],
      );
      expect(gpxFileNameFor(entry),
          'tankstellen-trajet-20260524T1430.gpx');
    });

    test('falls back to id when start time is null', () {
      final entry = _entry(id: 'abc-123', samples: const []);
      expect(gpxFileNameFor(entry), 'tankstellen-trajet-abc-123.gpx');
    });
  });
}
