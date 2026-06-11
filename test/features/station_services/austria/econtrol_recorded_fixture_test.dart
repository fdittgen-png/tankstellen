// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3197 — Austria pinned by a RECORDED live E-Control payload.
//
// Fixtures `test/fixtures/at_econtrol_die_slice.json` /
// `at_econtrol_sup_slice.json` were recorded 2026-06-11 from
// `https://api.e-control.at/sprit/1.0/search/gas-stations/by-address`
// (latitude=48.2082, longitude=16.3738 — Vienna city centre,
// fuelType=DIE / SUP, includeClosed=true). Structure untouched; only the
// `contact` telephone/fax/mail/website values are redacted (the parser
// never reads them). 10 stations per fuel — the API itself caps at the
// nearest ~10.
//
// These tests drive the REAL [EControlStationService.searchStations]
// (the #2776 / feedback_fake_services_false_green lesson: a hand-built
// record that echoes the parser's expectations can never catch a field
// the real feed doesn't send).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';

import '../support/real_service_search.dart';

void main() {
  late List<Station> stations;

  setUpAll(() async {
    final die = File('test/fixtures/at_econtrol_die_slice.json')
        .readAsStringSync();
    final sup = File('test/fixtures/at_econtrol_sup_slice.json')
        .readAsStringSync();
    stations = await searchEcontrolRecordedStations(
      dieselBody: die,
      superBody: sup,
      lat: 48.2082,
      lng: 16.3738,
      radiusKm: 5,
    );
  });

  Station byId(String id) => stations.firstWhere((s) => s.id == id);

  group('recorded E-Control Vienna slice through the REAL service (#3197)',
      () {
    test('all 10 recorded stations parse and merge by id', () {
      expect(stations, hasLength(10));
      expect(stations.map((s) => s.id), everyElement(startsWith('at-')));
    });

    test('DIE + SUP queries merge into one station with both prices', () {
      // TMC Werkstatt & Tankstelle, Rechte Wienzeile 43 — present in both
      // recorded responses: DIE 1.759, SUP 1.689.
      final s = byId('at-1494440');
      expect(s.diesel, 1.759);
      expect(s.e5, 1.689);
    });

    test('the real feed carries ONE petrol grade — e10 stays null (#3198)',
        () {
      // The recorded SUP response prices it as "Super 95"; E-Control
      // publishes no E10 series, so nothing may invent one.
      expect(stations.map((s) => s.e10), everyElement(isNull));
    });

    test('location fields map from the real location envelope', () {
      final s = byId('at-1494440');
      expect(s.name, 'TMC Werkstatt & Tankstelle');
      expect(s.street, 'Rechte Wienzeile 43');
      expect(s.postCode, '1050');
      expect(s.place, 'Wien');
      expect(s.lat, closeTo(48.1963966, 1e-6));
      expect(s.lng, closeTo(16.358812, 1e-6));
    });

    test('brand is extracted from a real branded name', () {
      // The Turmöl station at Margaretenstraße 28 (recorded DIE 1.834,
      // SUP 1.734).
      final s = byId('at-1476471');
      expect(s.brand, 'Turmöl');
      expect(s.diesel, 1.834);
      expect(s.e5, 1.734);
    });

    test('the real open flag and structured openingHours[] survive parsing',
        () {
      final s = byId('at-1494440');
      expect(s.isOpen, isTrue);
      // The recorded payload carries 8 openingHours rows (MO–SO + FE);
      // the structured adapter must produce a non-null weekly schedule —
      // AT has no detail endpoint, so this Station is the only carrier.
      expect(s.openingHours, isNotNull);
      expect(s.openingHoursText, isNotNull);
    });

    test('every recorded station carries a usable coordinate and distance',
        () {
      for (final s in stations) {
        expect(s.lat, inInclusiveRange(48.0, 48.4), reason: s.id);
        expect(s.lng, inInclusiveRange(16.2, 16.5), reason: s.id);
        expect(s.dist, lessThan(5), reason: s.id);
      }
    });
  });
}
