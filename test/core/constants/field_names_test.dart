// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/field_names.dart';

void main() {
  group('TankerkoenigFields', () {
    test('fuel type constants match API values', () {
      expect(TankerkoenigFields.e5, 'e5');
      expect(TankerkoenigFields.e10, 'e10');
      expect(TankerkoenigFields.diesel, 'diesel');
    });

    test('status constants match API values', () {
      expect(TankerkoenigFields.statusOpen, 'open');
      expect(TankerkoenigFields.statusNoPrices, 'no prices');
    });

    test('response field constants match API values', () {
      expect(TankerkoenigFields.ok, 'ok');
      expect(TankerkoenigFields.prices, 'prices');
      expect(TankerkoenigFields.status, 'status');
      expect(TankerkoenigFields.isOpen, 'isOpen');
    });
  });

  group('SyncFields', () {
    test('table names are valid', () {
      expect(SyncFields.usersTable, 'users');
      expect(SyncFields.favoritesTable, 'favorites');
      expect(SyncFields.alertsTable, 'alerts');
      expect(SyncFields.reportsTable, 'price_reports');
      expect(SyncFields.routesTable, 'saved_routes');
    });

    test('common column names are consistent', () {
      expect(SyncFields.stationId, 'station_id');
      expect(SyncFields.userId, 'user_id');
      expect(SyncFields.fuelType, 'fuel_type');
      expect(SyncFields.countryCode, 'country_code');
    });
  });

  group('Field names adoption regression', () {
    test('background scan runner uses TankerkoenigFields', () {
      // #2411 — the background price fetch+parse moved out of the now-thin
      // background_service.dart into background_scan_runners.dart (the
      // shared scan path every trigger funnels through). The regression
      // follows the code: the runner must still use the typed field
      // constants, never bare Tankerkönig strings.
      final source = File(
        'lib/core/background/background_scan_runners.dart',
      ).readAsStringSync();

      expect(source, contains('TankerkoenigFields.'));
      // Should not contain bare 'no prices' or 'open' status strings
      expect(
        source.contains("== 'no prices'"),
        isFalse,
        reason: 'Should use TankerkoenigFields.statusNoPrices',
      );
      expect(
        source.contains("== 'open'"),
        isFalse,
        reason: 'Should use TankerkoenigFields.statusOpen',
      );
    });

    test('community_report_service uses SyncFields', () {
      final source = File(
        'lib/features/report/data/community_report_service.dart',
      ).readAsStringSync();

      expect(source, contains('SyncFields.'));
      expect(
        source.contains("from('price_reports')"),
        isFalse,
        reason: 'Should use SyncFields.reportsTable',
      );
    });
  });
}
