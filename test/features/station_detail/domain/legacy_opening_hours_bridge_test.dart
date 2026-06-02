// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/station_detail/domain/legacy_opening_hours_bridge.dart';
import 'package:tankstellen/features/station_detail/domain/opening_hours.dart';

Station _station({bool is24h = false}) => Station(
      id: 's1',
      name: 'S',
      brand: 'B',
      street: 'St',
      postCode: '1',
      place: 'P',
      lat: 0,
      lng: 0,
      isOpen: true,
      is24h: is24h,
    );

void main() {
  group('legacyOpeningHoursBridge', () {
    test('returns normally on malformed openingTimes → notAvailable '
        '(fault injection)', () {
      final detail = StationDetail(
        station: _station(),
        openingTimes: const [
          OpeningTime(text: 'x', start: 'garbage', end: ''),
          OpeningTime(text: 'y', start: '99:99', end: '08:00'),
        ],
      );
      expect(() => legacyOpeningHoursBridge(detail), returnsNormally);
      expect(legacyOpeningHoursBridge(detail), WeeklyOpeningHours.notAvailable);
    });

    test('is24h → all-week 24h', () {
      final r =
          legacyOpeningHoursBridge(StationDetail(station: _station(is24h: true)));
      expect(r.availability, OpeningHoursAvailability.full);
      expect(r.dayFor(OpeningDay.mon)!.state, DayState.open24h);
    });

    test('valid openingTimes → partial whole-week ranges', () {
      final detail = StationDetail(
        station: _station(),
        openingTimes: const [
          OpeningTime(text: 'Mo-Fr', start: '06:30', end: '19:30'),
        ],
      );
      final r = legacyOpeningHoursBridge(detail);
      expect(r.availability, OpeningHoursAvailability.partial);
      final mon = r.dayFor(OpeningDay.mon)!;
      expect(mon.state, DayState.openRanges);
      expect(mon.ranges.single.startMinutes, 6 * 60 + 30);
    });

    test('already-populated openingHours is returned unchanged', () {
      final w = WeeklyOpeningHours.allWeek24h(rawSource: 'x');
      final detail = StationDetail(station: _station(), openingHours: w);
      expect(legacyOpeningHoursBridge(detail), w);
    });

    test('no legacy data → notAvailable', () {
      expect(
        legacyOpeningHoursBridge(StationDetail(station: _station())),
        WeeklyOpeningHours.notAvailable,
      );
    });
  });
}
