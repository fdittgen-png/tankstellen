// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/exporters/gpx_exporter.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';
import 'package:tankstellen/l10n/app_localizations.dart';
import 'package:tankstellen/l10n/app_localizations_en.dart';
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
  double? secondsBelowOptimalGear,
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
      secondsBelowOptimalGear: secondsBelowOptimalGear,
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

  group('driving-lessons <extensions> (#2251)', () {
    final AppLocalizations l = AppLocalizationsEn();
    final start = DateTime.utc(2026, 5, 24, 14, 0);

    // A 20-minute idle trip with GPS fixes — fires the idling lesson AND
    // produces trkpts.
    List<TripSample> idleSamplesWithGps() {
      final samples = <TripSample>[];
      for (var i = 0; i <= 20; i++) {
        samples.add(TripSample(
          timestamp: start.add(Duration(minutes: i)),
          speedKmh: 0,
          rpm: 800,
          latitude: 48.0 + i * 0.0001,
          longitude: 2.0 + i * 0.0001,
        ));
      }
      return samples;
    }

    test('embeds a parseable lessons block for a trip with insights', () {
      final entry = _entry(
        startedAt: start,
        samples: idleSamplesWithGps(),
      );

      final gpx = buildGpxXml(entry, l: l);

      // The document remains valid XML.
      final doc = XmlDocument.parse(gpx);
      // Vendor namespace is declared on the root.
      expect(gpx, contains('xmlns:tankstellen='));
      expect(gpx, contains('<extensions>'));

      final lessons = doc.findAllElements('tankstellen:lesson').toList();
      expect(lessons, isNotEmpty);
      // The idling lesson is present with id / value / impact attrs.
      final idling = lessons.firstWhere((e) => e.getAttribute('id') == 'idling');
      expect(idling.getAttribute('value'), isNotNull);
      expect(idling.getAttribute('impact'), isNotNull);
      // Per-lesson localized title + advice message.
      final title = idling.findElements('tankstellen:title').single.innerText;
      expect(title, contains('Idling'));
      final message =
          idling.findElements('tankstellen:message').single.innerText;
      expect(message, isNotEmpty);
    });

    test('low-gear lesson is embedded when the summary metric fires', () {
      final entry = _entry(
        startedAt: start,
        samples: idleSamplesWithGps(),
        secondsBelowOptimalGear: 180,
      );

      final gpx = buildGpxXml(entry, l: l);
      final doc = XmlDocument.parse(gpx);
      final ids = doc
          .findAllElements('tankstellen:lesson')
          .map((e) => e.getAttribute('id'))
          .toList();
      expect(ids, contains('lowGear'));
      expect(ids, contains('idling'));
    });

    test('no lessons block for a trip with no insights', () {
      // A short clean cruise — no rule fires.
      final entry = _entry(
        startedAt: start,
        samples: [
          _sample(start, lat: 48.0, lon: 2.0),
          _sample(start.add(const Duration(seconds: 5)), lat: 48.001, lon: 2.0),
        ],
      );

      final gpx = buildGpxXml(entry, l: l);
      expect(gpx, isNot(contains('<extensions>')));
      expect(gpx, isNot(contains('tankstellen:lesson')));
      // Namespace not declared when there are no lessons.
      expect(gpx, isNot(contains('xmlns:tankstellen=')));
      // Still a valid, GPS-bearing document.
      final doc = XmlDocument.parse(gpx);
      expect(doc.findAllElements('trkpt'), isNotEmpty);
    });

    test('no lessons block when no localizer is supplied (legacy path)', () {
      final entry = _entry(
        startedAt: start,
        samples: idleSamplesWithGps(),
        secondsBelowOptimalGear: 180,
      );

      final gpx = buildGpxXml(entry); // no l:
      expect(gpx, isNot(contains('<extensions>')));
      expect(gpx, isNot(contains('xmlns:tankstellen=')));
      XmlDocument.parse(gpx); // still valid
    });

    test('aggregate export embeds per-track lessons', () {
      final t1 = _entry(
        id: 'trip-1',
        startedAt: start,
        samples: idleSamplesWithGps(),
      );
      final t2 = _entry(
        id: 'trip-2',
        startedAt: start.add(const Duration(days: 1)),
        samples: [
          _sample(start.add(const Duration(days: 1)), lat: 48.0, lon: 2.0),
          _sample(start.add(const Duration(days: 1, seconds: 5)),
              lat: 48.001, lon: 2.0),
        ],
      );

      final gpx = buildAggregateGpxXml([t1, t2], l: l);
      final doc = XmlDocument.parse(gpx);
      // Two tracks, only the idle one carries a lessons block.
      expect(doc.findAllElements('trk').length, 2);
      final lessons = doc.findAllElements('tankstellen:lesson').toList();
      expect(lessons.map((e) => e.getAttribute('id')), contains('idling'));
    });
  });
}
