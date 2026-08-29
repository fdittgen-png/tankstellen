// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3869 (Epic #3865, GDPR Art. 20) — the one-ZIP export accounts for every
// Hive box (registry-driven), carries every server table, and is readable
// by a standard ZIP tool.
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/storage/hive_boxes.dart';
import 'package:tankstellen/features/profile/data/full_data_export.dart';

void main() {
  test('every box in HiveBoxes.allBoxes is accounted for', () {
    final unaccounted =
        HiveBoxes.allBoxes.difference(kBoxExportCoverage.keys.toSet());
    expect(unaccounted, isEmpty,
        reason: 'box(es) with no export entry / no documented reason: '
            '$unaccounted');
  });

  test('the ZIP carries every local category, the consent record and every '
      'server table', () {
    final input = FullDataExportInput(
      appVersion: '6.0.5',
      exportedAt: DateTime.utc(2026, 8, 29, 12),
      policyVersion: 3,
      appDataJson: '{"favorites": []}',
      vehicles: const [],
      fillUps: const [],
      trips: const [],
      chargingLogs: const [],
      serviceReminders: const [],
      baselines: const <String, dynamic>{
        'veh-1': <String, dynamic>{'idle': 0.7},
      },
      achievements: const <String, dynamic>{},
      obd2Caches: const <String, dynamic>{'pids': <String, dynamic>{}},
      inProgressTrips: const <String, dynamic>{},
      consent: const <String, dynamic>{'cloudSync': false, 'policyVersion': 3},
      server: const <String, dynamic>{
        'favorites': <dynamic>[<String, dynamic>{'station_id': 'x'}],
        'fill_ups': <dynamic>[],
        'unavailable': <String>['wait_time_pings'],
      },
    );
    final bytes = buildFullDataExportZip(input);
    final names = ZipDecoder().decodeBytes(bytes).map((f) => f.name).toSet();
    for (final path in kBoxExportCoverage.values.whereType<String>()) {
      expect(names, contains(path), reason: 'missing $path');
    }
    expect(names, containsAll(['local/vehicles.json', 'local/fill_ups.json',
      'local/charging_logs.json', 'local/consent.json', 'README.txt',
      'server/favorites.json', 'server/fill_ups.json']));
    expect(names.length, fullDataExportEntryCount(input));
    final readme = utf8.decode(ZipDecoder()
        .decodeBytes(bytes)
        .findFile('README.txt')!
        .content as List<int>);
    expect(readme, contains('Privacy policy version: 3'));
  });

  test('decodeJsonBox decodes JSON strings and passes other values through',
      () {
    final out = decodeJsonBox({'a': '{"x":1}', 'b': 'plain', 'c': 2});
    expect(out['a'], {'x': 1});
    expect(out['b'], 'plain');
    expect(out['c'], 2);
  });
}
