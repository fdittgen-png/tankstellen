// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/approach_detector.dart';
import 'package:tankstellen/core/utils/price_formatter.dart';
import 'package:tankstellen/core/utils/radar_closeness.dart';
import 'package:tankstellen/features/obd2/data/trip_live_reading.dart';
import 'package:tankstellen/features/consumption/domain/live_activity_content.dart';
import 'package:tankstellen/features/consumption/providers/trip_recording_provider.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';

/// Decision-table coverage for [buildLiveActivityContent] (#3170) — the
/// pure mapper from (recorder state, approach state, radar fallback) to
/// the Live Activity payload. Mirrors `TripRecordingPipView`'s layout
/// precedence so the two glanceable surfaces can never disagree.
void main() {
  final now = DateTime(2026, 6, 10, 12);

  Station station({
    String id = 'st1',
    String name = 'ARAL Hauptstr.',
    String brand = 'ARAL',
    double? e10 = 1.789,
    double dist = 0,
  }) =>
      Station(
        id: id,
        name: name,
        brand: brand,
        street: 'Hauptstr. 1',
        postCode: '12345',
        place: 'Teststadt',
        lat: 50.0,
        lng: 8.0,
        dist: dist,
        e10: e10,
      );

  TripRecordingState recording({
    TripRecordingPhase phase = TripRecordingPhase.recording,
    TripLiveReading? live,
  }) =>
      TripRecordingState(
        phase: phase,
        live: live ??
            const TripLiveReading(
              distanceKmSoFar: 12.34,
              elapsed: Duration(minutes: 10),
            ),
      );

  LiveActivityContent? build({
    TripRecordingState? state,
    ApproachState? approach,
    Station? radarStation,
    FuelType fuel = FuelType.e10,
    double? radiusMeters = 3000,
  }) =>
      buildLiveActivityContent(
        state: state ?? recording(),
        approach: approach,
        radarStation: radarStation,
        fuel: fuel,
        radiusMeters: radiusMeters,
        l: null, // exercises the English fallbacks (harness convention)
        now: now,
      );

  group('no active trip', () {
    test('idle state yields null (→ coordinator ends the activity)', () {
      expect(build(state: const TripRecordingState()), isNull);
    });
  });

  group('recording mode (consumption hero — PiP branch parity #2601)', () {
    test('OBD2 fuel rate at speed → measured L/100 km figure', () {
      final content = build(
        state: recording(
          live: const TripLiveReading(
            distanceKmSoFar: 12.34,
            elapsed: Duration(minutes: 10),
            fuelRateLPerHour: 3.0,
            speedKmh: 50,
          ),
        ),
      )!;

      expect(content.mode, LiveActivityMode.recording);
      expect(content.bigFigure, '6.0');
      expect(content.bigCaption, 'L/100 km');
      expect(content.isEstimate, isFalse);
      expect(content.distanceText, '12.3 km');
      expect(content.stationName, isNull);
    });

    test('near standstill → L/h fallback', () {
      final content = build(
        state: recording(
          live: const TripLiveReading(
            distanceKmSoFar: 0.5,
            elapsed: Duration(minutes: 2),
            fuelRateLPerHour: 1.2,
            speedKmh: 0,
          ),
        ),
      )!;

      expect(content.bigFigure, '1.2');
      expect(content.bigCaption, 'L/h');
    });

    test('GPS-only live estimate → ~figure under the est caption', () {
      final content = build(
        state: recording(
          live: const TripLiveReading(
            distanceKmSoFar: 5.0,
            elapsed: Duration(minutes: 6),
            gpsEstimatedLPer100Km: 7.12,
          ),
        ),
      )!;

      expect(content.bigFigure, '~7.1');
      expect(content.bigCaption, 'est. L/100 km');
      expect(content.isEstimate, isTrue);
    });

    test('warm-up (no rate, no estimate) → bare ~ placeholder', () {
      final content = build()!;
      expect(content.bigFigure, '~');
      expect(content.isEstimate, isTrue);
    });

    test('paused trip → paused flag set and the measured figure suppressed',
        () {
      final content = build(
        state: recording(
          phase: TripRecordingPhase.paused,
          live: const TripLiveReading(
            distanceKmSoFar: 12.34,
            elapsed: Duration(minutes: 10),
            fuelRateLPerHour: 3.0,
            speedKmh: 50,
          ),
        ),
      )!;

      expect(content.paused, isTrue);
      expect(content.bigFigure, '~');
      expect(content.pausedLabel, 'Paused');
    });

    test('distance under 0.1 km is hidden', () {
      final content = build(
        state: recording(
          live: const TripLiveReading(
            distanceKmSoFar: 0.05,
            elapsed: Duration(seconds: 30),
          ),
        ),
      )!;
      expect(content.distanceText, isNull);
    });

    test('startedAt back-computes now − elapsed, rounded to the second', () {
      final content = build(
        state: recording(
          live: const TripLiveReading(
            distanceKmSoFar: 1.0,
            elapsed: Duration(minutes: 10, milliseconds: 350),
          ),
        ),
      )!;

      final expected = now
          .subtract(const Duration(minutes: 10, milliseconds: 350))
          .millisecondsSinceEpoch;
      expect(content.startedAtEpochMs, (expected ~/ 1000) * 1000);
      expect(content.startedAtEpochMs % 1000, 0);
    });
  });

  group('approach mode — in-radius wins (PiP precedence #2084)', () {
    test('ApproachInRadius → price lead with metres caption + closeness',
        () {
      final content = build(
        approach: ApproachInRadius(station: station(), distanceMeters: 450),
        // The radar fallback must NOT win over the locked target.
        radarStation: station(id: 'other', name: 'Wrong'),
      )!;

      expect(content.mode, LiveActivityMode.approach);
      expect(content.stationName, 'ARAL Hauptstr.');
      expect(content.priceText, PriceFormatter.formatPrice(1.789));
      expect(content.fuelLabel, FuelType.e10.displayName);
      expect(content.stationDistanceText, '450 m');
      expect(content.progress, RadarCloseness.fillFor(450, 3000));
    });

    test('ApproachLeaving keeps the last station, drops distance + bar', () {
      final content = build(
        approach: ApproachLeaving(lastStation: station()),
      )!;

      expect(content.mode, LiveActivityMode.approach);
      expect(content.stationDistanceText, isNull);
      expect(content.progress, isNull);
    });

    test('a station without a name falls back to the brand', () {
      final content = build(
        approach: ApproachInRadius(
          station: station(name: ''),
          distanceMeters: 450,
        ),
      )!;
      expect(content.stationName, 'ARAL');
    });

    test('a station without the fuel price renders the -- placeholder', () {
      final content = build(
        approach: ApproachInRadius(
          station: station(e10: null),
          distanceMeters: 450,
        ),
      )!;
      expect(content.priceText, '--');
    });
  });

  group('approach mode — polling radar fallback (#2661 parity)', () {
    test('radar station leads with a km caption when nothing is in radius',
        () {
      final content = build(radarStation: station(dist: 1.2))!;

      expect(content.mode, LiveActivityMode.approach);
      expect(content.stationDistanceText, '1.2 km');
      expect(content.progress, RadarCloseness.fillFor(1200, 3000));
      // The consumption hero stays populated for the expanded island.
      expect(content.bigFigure, isNotEmpty);
    });

    test('a zero radar distance hides the caption + bar', () {
      final content = build(radarStation: station(dist: 0))!;
      expect(content.stationDistanceText, isNull);
      expect(content.progress, isNull);
    });

    test('no radius collapses the closeness bar only', () {
      final content = build(
        radarStation: station(dist: 1.2),
        radiusMeters: null,
      )!;
      expect(content.stationDistanceText, '1.2 km');
      expect(content.progress, isNull);
    });
  });

  group('channel payload', () {
    test('toChannelMap carries every ContentState key in lock-step', () {
      final content = build(
        approach: ApproachInRadius(station: station(), distanceMeters: 450),
      )!;
      final map = content.toChannelMap();

      expect(map.keys, <String>{
        'mode',
        'paused',
        'startedAtEpochMs',
        'bigFigure',
        'bigCaption',
        'isEstimate',
        'distanceText',
        'pausedLabel',
        'stationName',
        'priceText',
        'fuelLabel',
        'stationDistanceText',
        'progress',
      });
      expect(map['mode'], 'approach');
    });
  });
}
