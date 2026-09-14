// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Austria against the shared provider contract (#4157).
///
/// Drives the REAL [EControlStationService] over the recorded Vienna
/// slice captured 2026-06-11 from the live E-Control API (#3197) —
/// byte-for-byte as the API sent it, with only the unread contact
/// fields redacted.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station.dart';

import '../contract/station_service_contract.dart';
import '../support/real_service_search.dart';

void main() {
  late List<Station> stations;

  setUpAll(() async {
    stations = await searchEcontrolRecordedStations(
      dieselBody:
          File('test/fixtures/at_econtrol_die_slice.json').readAsStringSync(),
      superBody:
          File('test/fixtures/at_econtrol_sup_slice.json').readAsStringSync(),
      lat: 48.2082,
      lng: 16.3738,
      radiusKm: 5,
    );
  });

  runStationServiceContract(
    countryCode: 'AT',
    stationsOf: () => stations,
    now: DateTime.utc(2026, 12, 31),
  );
}
