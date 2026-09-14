// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Spain against the shared provider contract (#4157).
///
/// Drives the REAL [MitecoStationService] over the recorded Barcelona
/// (province 08) response — the same slice the cross-border corridor
/// tests use, which is a live capture of the MITECO Geoportal feed, not
/// a hand-written record. See
/// `contract/station_service_contract.dart` for why that matters.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/station.dart';

import '../contract/station_service_contract.dart';
import '../support/real_service_search.dart';

void main() {
  late List<Station> stations;

  setUpAll(() async {
    final raw = jsonDecode(
      File('test/fixtures/miteco_barcelona_08.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final records = (raw['ListaEESSPrecio'] as List)
        .cast<Map<String, dynamic>>();
    // Barcelona city centre, wide enough that the province slice is not
    // filtered down to a handful by distance.
    stations = await searchMitecoStations(
      records,
      lat: 41.39,
      lng: 2.17,
      radiusKm: 50,
    );
  });

  runStationServiceContract(
    countryCode: 'ES',
    stationsOf: () => stations,
    // The recording was captured in 2026; a fixed clock keeps "not in
    // the future" a stable assertion rather than one that depends on
    // when the suite runs.
    now: DateTime.utc(2026, 12, 31),
  );
}
