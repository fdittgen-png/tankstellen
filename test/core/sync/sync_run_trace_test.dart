// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/fill_ups_sync.dart';
import 'package:tankstellen/core/sync/sync_run_trace.dart';
import 'package:tankstellen/core/telemetry/collectors/breadcrumb_collector.dart';
import 'package:tankstellen/features/consumption/domain/entities/fill_up.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import 'fake_sync_transport.dart';

/// #3126 — sync-run ID + per-table counts in the exportable trace.
///
/// The sync success path logged via `debugPrint` only (a release no-op),
/// so "my fill-up disappeared after sync" had zero on-device evidence.
/// These tests pin the new pipeline: a run id minted per sync pass and
/// per-table up/down/tombstone counts, both landing in the breadcrumb
/// ring that every recorded error trace snapshots.
void main() {
  setUp(() {
    BreadcrumbCollector.clear();
    SyncRunTrace.resetForTest();
  });

  tearDown(BreadcrumbCollector.clear);

  group('SyncRunTrace (#3126)', () {
    test('begin mints a fresh run id and breadcrumbs the trigger', () {
      final id = SyncRunTrace.begin('launch');

      expect(id, hasLength(6));
      expect(SyncRunTrace.currentRunId, id);
      final crumb = BreadcrumbCollector.snapshot().single;
      expect(crumb.action, 'sync:run');
      expect(crumb.detail, contains('run=$id'));
      expect(crumb.detail, contains('trigger=launch'));

      // A second pass mints a NEW id — runs stay distinguishable.
      final second = SyncRunTrace.begin('connect');
      expect(second, isNot(id));
    });

    test('table records per-table counts under the current run id', () {
      final id = SyncRunTrace.begin('connect');
      SyncRunTrace.table('fill_ups',
          uploaded: 2, downloaded: 3, tombstoned: 1);

      final crumb = BreadcrumbCollector.snapshot().last;
      expect(crumb.action, 'sync:fill_ups');
      expect(crumb.detail, 'run=$id up=2 down=3 tomb=1');
    });

    test('a merge without a surrounding run reports run=untracked', () {
      SyncRunTrace.table('alerts', uploaded: 1);
      expect(BreadcrumbCollector.snapshot().single.detail,
          contains('run=untracked'));
    });

    test(
        'RED for #3126: a real fill-ups merge leaves a per-table count '
        'breadcrumb in the exportable trace', () async {
      final runId = SyncRunTrace.begin('launch');
      final localOnly = FillUp(
        id: 'f-local',
        vehicleId: 'veh-1',
        date: DateTime.utc(2026, 6, 1),
        liters: 40,
        totalCost: 72,
        odometerKm: 120000,
        fuelType: FuelType.e10,
      );
      final fake = FakeSyncTransport(tables: {
        'fill_ups': [
          {
            'id': 'f-server',
            'user_id': 'user-1',
            'data': localOnly.copyWith(id: 'f-server').toJson(),
            'updated_at': DateTime.utc(2026, 1, 1).toIso8601String(),
          },
        ],
      });

      await FillUpsSync.merge([localOnly], transport: fake);

      final crumb = BreadcrumbCollector.snapshot()
          .where((c) => c.action == 'sync:fill_ups')
          .single;
      expect(crumb.detail, contains('run=$runId'));
      expect(crumb.detail, contains('up=1'),
          reason: 'one local-only fill-up was uploaded');
      expect(crumb.detail, contains('down=1'),
          reason: 'one server-only fill-up was downloaded');
      expect(crumb.detail, contains('tomb=0'));
    });
  });
}
