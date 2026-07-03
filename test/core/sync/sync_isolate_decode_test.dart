// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/vehicle_profile.dart';
import 'package:tankstellen/core/sync/fill_ups_sync.dart';
import 'package:tankstellen/core/sync/sync_isolate_decode.dart';
import 'package:tankstellen/core/sync/trips_sync_json.dart';
import 'package:tankstellen/core/sync/vehicles_sync.dart';
import 'package:tankstellen/features/consumption/data/trip_history_repository.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/consumption/domain/trip_recorder.dart';

import '../../helpers/silence_error_logger.dart';

/// #3451 — the off-isolate decode seam.
///
/// The `compute()` entrypoints are top-level PURE functions, so they are
/// unit-tested directly (same code object the isolate executes); a
/// source-level pin guards the "top-level" property itself, because an
/// instance/closure entrypoint would silently capture non-sendable state.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  silenceErrorLoggerSpool();

  tearDown(() => BatchDecode.offloadOverride = null);

  group('decode entrypoints are behaviour-identical to the per-row path',
      () {
    test('decodeFillUpDataRows — valid rows decode, corrupt rows map to '
        'null (never throw)', () {
      final fillUp = FillUp(
        id: 'f-1',
        vehicleId: 'veh-1',
        date: DateTime(2026, 4, 22),
        liters: 5.0,
        totalCost: 9.95,
        odometerKm: 123456,
        fuelType: FuelType.e5,
      );
      final rows = <Map<String, dynamic>>[
        {'id': 'f-1', 'data': fillUp.toJson()},
        {'id': 'no-data'},
        {'id': 'bad-type', 'data': 'not a map'},
        {
          'id': 'corrupt',
          'data': <String, dynamic>{'liters': 'NaN-garbage'}
        },
      ];

      final decoded = decodeFillUpDataRows(rows);

      expect(decoded, hasLength(4));
      expect(decoded.first?.id, 'f-1');
      expect(decoded.sublist(1), everyElement(isNull),
          reason: 'corrupt rows skip (null), matching jsonbDataDecoder');
    });

    test('decodeVehicleDataRows — valid rows decode, corrupt rows map to '
        'null', () {
      final vehicle = VehicleProfile(id: 'veh-1', name: 'Test Car');
      final rows = <Map<String, dynamic>>[
        {'id': 'veh-1', 'data': vehicle.toJson()},
        {'id': 'no-data'},
      ];

      final decoded = decodeVehicleDataRows(rows);

      expect(decoded, hasLength(2));
      expect(decoded.first?.id, 'veh-1');
      expect(decoded.last, isNull);
    });

    test('decodeTripSummaryDataRows — valid blobs decode, corrupt blobs '
        'map to null', () {
      final entry = TripHistoryEntry(
        id: 'trip-1',
        vehicleId: null,
        summary: TripSummary(
          startedAt: DateTime(2026, 5, 10, 10, 0),
          endedAt: DateTime(2026, 5, 10, 10, 30),
          distanceKm: 12.5,
          maxRpm: 3000,
          highRpmSeconds: 5,
          idleSeconds: 30,
          harshBrakes: 0,
          harshAccelerations: 0,
        ),
      );
      final decoded = decodeTripSummaryDataRows([
        entry.toJson(),
        <String, dynamic>{'summary': 'garbage'},
      ]);

      expect(decoded, hasLength(2));
      expect(decoded.first?.id, 'trip-1');
      expect(decoded.last, isNull);
    });

    test('mergeTripRowsOffThread matches TripsSync.mergeRows semantics: '
        'local wins, tombstoned/corrupt skipped', () async {
      BatchDecode.offloadOverride = false; // deterministic inline path
      final local = TripHistoryEntry(
        id: 'local-1',
        vehicleId: null,
        summary: TripSummary(
          startedAt: DateTime(2026, 5, 10),
          endedAt: DateTime(2026, 5, 10, 0, 30),
          distanceKm: 1,
          maxRpm: 1000,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
        ),
      );
      final server = TripHistoryEntry(
        id: 'server-1',
        vehicleId: null,
        summary: TripSummary(
          startedAt: DateTime(2026, 5, 11),
          endedAt: DateTime(2026, 5, 11, 0, 30),
          distanceKm: 2,
          maxRpm: 1000,
          highRpmSeconds: 0,
          idleSeconds: 0,
          harshBrakes: 0,
          harshAccelerations: 0,
        ),
      );
      final rows = <Map<String, dynamic>>[
        {'id': 'server-1', 'data': server.toJson()},
        {'id': 'local-1', 'data': local.toJson()}, // local wins → skipped
        {'id': 'dead-1', 'data': server.toJson()}, // tombstoned → skipped
        {'id': 'corrupt', 'data': <String, dynamic>{'x': 1}}, // dropped
        {'id': 42, 'data': server.toJson()}, // non-string id → skipped
      ];

      final merged = await mergeTripRowsOffThread(
        [local],
        rows,
        tombstoned: {'dead-1'},
      );

      expect(merged.map((e) => e.id), ['local-1', 'server-1']);
    });
  });

  group('BatchDecode.run', () {
    test('below the threshold decodes inline (no isolate overhead for the '
        'steady-state 0-5 row pull)', () async {
      final rows = List.generate(
          BatchDecode.isolateThreshold - 1, (i) => {'i': i});
      // No override: the automatic policy must choose inline for a small
      // batch, which keeps this test isolate-free by construction.
      final result = await BatchDecode.run(rows, _countingEntrypoint);
      expect(result, hasLength(rows.length));
    });

    test('at/above the threshold routes through compute() and returns the '
        'same result shape', () async {
      final rows =
          List.generate(BatchDecode.isolateThreshold, (i) => {'i': i});
      BatchDecode.offloadOverride = true;
      final result = await BatchDecode.run(rows, _countingEntrypoint);
      expect(result, List.generate(rows.length, (i) => i),
          reason: 'the isolate path must be behaviour-identical');
    });
  });

  test('SOURCE PIN — every compute() entrypoint is a TOP-LEVEL function '
      'wired through BatchDecode.run', () {
    const entrypoints = <String, String>{
      'lib/core/sync/fill_ups_sync.dart': 'decodeFillUpDataRows',
      'lib/core/sync/vehicles_sync.dart': 'decodeVehicleDataRows',
      'lib/core/sync/trips_sync_json.dart': 'decodeTripSummaryDataRows',
    };
    entrypoints.forEach((path, fn) {
      final source = File(path).readAsStringSync();
      // Top-level = declared at column 0 (a method would be indented).
      expect(
        RegExp('^List<[A-Za-z?]+> $fn\\(', multiLine: true)
            .hasMatch(source),
        isTrue,
        reason: '$fn in $path must stay a top-level function — compute() '
            'cannot ship an instance method / capturing closure to a '
            'worker isolate (#3451)',
      );
      expect(source, contains('BatchDecode.run'),
          reason: '$path must route its batch decode through the '
              'shared offload seam');
    });
  });
}

/// Top-level entrypoint used by the [BatchDecode.run] tests — must be
/// top-level itself so the compute() path can ship it.
List<int?> _countingEntrypoint(List<Map<String, dynamic>> rows) =>
    [for (final r in rows) r['i'] as int?];
