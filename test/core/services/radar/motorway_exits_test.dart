// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/core/services/radar/motorway_exits.dart';

/// #3633 — pure unit tests for the exit-aware v2 layer.
///
/// Geometry: the driver sits at (43.30, 3.40) heading due EAST (90°).
/// At this latitude 0.01° of longitude ≈ 0.81 km east; 0.01° of
/// latitude ≈ 1.11 km north. Assertions use generous tolerances so the
/// spherical math never fights the flat-earth approximations here.
void main() {
  const lat = 43.30, lng = 3.40, heading = 90.0;

  Station station(String id, double la, double lo) => Station(
        id: id,
        name: 'S$id',
        brand: 'B',
        street: '',
        place: '',
        postCode: '',
        lat: la,
        lng: lo,
        dist: 0,
        isOpen: true,
      );

  MotorwayExit exit(double la, double lo, {String? ref, String? name}) =>
      MotorwayExit(lat: la, lng: lo, ref: ref, name: name);

  group('parse', () {
    test('compact asset parses; malformed entries are skipped', () {
      final exits = parseMotorwayExits({
        'v': 1,
        'exits': [
          {'la': 43.31, 'lo': 3.41, 'r': '36', 'n': 'Saint-Thibéry'},
          {'la': 'garbage', 'lo': 3.5},
          {'lo': 3.6},
          {'la': 43.32, 'lo': 3.42},
        ],
      });
      expect(exits, hasLength(2));
      expect(exits.first.ref, '36');
      expect(exits.first.label, '36');
      expect(exits.last.label, isNull, reason: 'no ref, no name');
    });

    test('a hostile payload NEVER throws — skip, do not fail (the cache '
        'layer contract)', () {
      expect(
        () => parseMotorwayExits({'exits': 'not-a-list'}),
        returnsNormally,
      );
      expect(parseMotorwayExits({'exits': 'not-a-list'}), isEmpty);
      expect(() => parseMotorwayExits(const {}), returnsNormally);
    });

    test('a ref-less named exit labels by name', () {
      expect(exit(1, 2, name: 'Pézenas').label, 'Pézenas');
    });
  });

  group('annotateStationsViaExits (#3633)', () {
    test('an off-axis station is annotated with the LAST exit before its '
        'along-track position, with the straight-line detour', () {
      // Exit 36 is 4 km ahead ON the road; the station sits 8 km ahead
      // and ~1.1 km off to the north (off-axis).
      final exits = [
        exit(43.30, 3.449, ref: '36'), // ~4.0 km east
        exit(43.30, 3.548, ref: '38'), // ~12 km east — BEYOND the station
      ];
      final stations = [station('a', 43.31, 3.499)]; // ~8 km east, 1.1 km north

      final ann = annotateStationsViaExits(
        stations: stations,
        exits: exits,
        lat: lat,
        lng: lng,
        headingDegrees: heading,
      );

      final info = ann.infoByStationId['a'];
      expect(info, isNotNull);
      expect(info!.exitLabel, '36',
          reason: 'exit 38 lies beyond the station — you take 36');
      // Exit→station straight line: ~4 km east + ~1.1 km north ≈ 4.2 km.
      expect(info.detourKm, closeTo(4.2, 0.5));
      expect(info.alongKm, closeTo(8.0, 0.5));
    });

    test('an ON-ROAD service area gets NO exit annotation but still '
        'drives the along-track sort', () {
      final exits = [exit(43.30, 3.449, ref: '36')];
      final stations = [
        station('services', 43.30, 3.474), // ~6 km dead ahead, on-road
        station('near-off', 43.31, 3.437), // ~3 km east, 1.1 km north
      ];
      final ann = annotateStationsViaExits(
        stations: stations,
        exits: exits,
        lat: lat,
        lng: lng,
        headingDegrees: heading,
      );
      expect(ann.infoByStationId.containsKey('services'), isFalse,
          reason: 'reachable without exiting — no "via exit" line');
      // Sort is along-track: the off-axis 3 km station precedes the 6 km
      // services.
      expect(ann.stations.map((s) => s.id).toList(),
          ['near-off', 'services']);
    });

    test('a station BEFORE the first labeled exit gets no annotation '
        '(you cannot reach it without an exit that exists)', () {
      final exits = [exit(43.30, 3.523, ref: '40')]; // ~10 km ahead
      final stations = [station('x', 43.31, 3.437)]; // ~3 km ahead, off-axis
      final ann = annotateStationsViaExits(
        stations: stations,
        exits: exits,
        lat: lat,
        lng: lng,
        headingDegrees: heading,
      );
      expect(ann.infoByStationId, isEmpty);
    });

    test('exits BEHIND the driver are ignored', () {
      final exits = [exit(43.30, 3.351, ref: '34')]; // ~4 km WEST (behind)
      final stations = [station('x', 43.31, 3.499)];
      final ann = annotateStationsViaExits(
        stations: stations,
        exits: exits,
        lat: lat,
        lng: lng,
        headingDegrees: heading,
      );
      expect(ann.infoByStationId, isEmpty);
    });

    test('unlabeled exits never annotate (nothing to signpost)', () {
      final exits = [exit(43.30, 3.449)]; // no ref, no name
      final stations = [station('x', 43.31, 3.499)];
      final ann = annotateStationsViaExits(
        stations: stations,
        exits: exits,
        lat: lat,
        lng: lng,
        headingDegrees: heading,
      );
      expect(ann.infoByStationId, isEmpty);
    });

    test('degenerate inputs preserve order with an empty map — the v1 '
        'degradation contract', () {
      final stations = [station('b', 43.31, 3.499), station('a', 43.30, 3.42)];
      for (final ann in [
        annotateStationsViaExits(
            stations: stations,
            exits: const [],
            lat: lat,
            lng: lng,
            headingDegrees: heading),
        annotateStationsViaExits(
            stations: stations,
            exits: [exit(43.30, 3.449, ref: '36')],
            lat: lat,
            lng: lng,
            headingDegrees: double.nan),
      ]) {
        expect(ann.infoByStationId, isEmpty);
        expect(ann.stations.map((s) => s.id).toList(), ['b', 'a'],
            reason: 'input order untouched — v1 behaviour verbatim');
      }
    });
  });
}
