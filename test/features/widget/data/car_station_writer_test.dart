// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';
import 'package:tankstellen/features/widget/data/car_station_data.dart';
import 'package:tankstellen/features/widget/data/car_station_writer.dart';

/// Android Auto v1 (#2948) — channel-level + never-throws coverage for the
/// car-data writer.
///
/// Drives the real `home_widget` MethodChannel via `setMockMethodCallHandler`:
///   1. the happy path writes the car Search / Radar JSON under the expected
///      keys (the bytes the native car screens read), and
///   2. a THROWING channel makes the writer degrade gracefully — the
///      documented never-throws contract (#2948): a SharedPreferences write
///      fault never propagates into the search / radar provider.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('home_widget');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  Station station() => const Station(
        id: 'de-shell-01',
        name: 'Shell Berlin',
        brand: 'Shell',
        street: 'Oranienstr. 1',
        postCode: '10969',
        place: 'Berlin',
        lat: 52.5041,
        lng: 13.4081,
        dist: 1.2,
        e10: 1.849,
        isOpen: true,
      );

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('happy path — JSON crosses the channel under the car keys', () {
    test('writeSearch writes car_search_json; writeRadar writes car_radar_json',
        () async {
      final saved = <String, Object?>{};
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'saveWidgetData') {
          final args = (call.arguments as Map).cast<String, Object?>();
          saved[args['id']! as String] = args['data'];
        }
        return true;
      });

      await const CarStationWriter().writeSearch([station()], FuelType.e10);
      await const CarStationWriter().writeRadar([station()], FuelType.e10);

      final search = saved[CarStationData.searchKey] as String?;
      final radar = saved[CarStationData.radarKey] as String?;
      expect(search, isNotNull);
      expect(radar, isNotNull);
      final searchRows =
          (jsonDecode(search!) as List).cast<Map<String, dynamic>>();
      expect(searchRows.single['id'], 'de-shell-01');
      expect(searchRows.single['priceText'], '1.849');
      expect(searchRows.single['fuelLabel'], 'E10');
    });
  });

  group('never-throws fault path (#2948)', () {
    test('a throwing channel does not propagate out of writeSearch', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'boom', message: 'channel exploded');
      });
      // The documented never-throws contract: the call completes normally.
      await expectLater(
        const CarStationWriter().writeSearch([station()], FuelType.e10),
        completes,
      );
    });

    test('a throwing channel does not propagate out of writeRadar', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'boom', message: 'channel exploded');
      });
      await expectLater(
        const CarStationWriter().writeRadar([station()], FuelType.e10),
        completes,
      );
    });
  });
}
