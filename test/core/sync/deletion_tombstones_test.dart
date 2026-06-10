// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/schema_sql.dart';
import 'package:tankstellen/core/sync/schema_sql_policies.dart';
import 'package:tankstellen/core/sync/schema_verifier.dart';
import 'package:tankstellen/core/sync/sync_helper.dart';

/// #3078 (Epic #3075) — deletion tombstones so a delete doesn't resurrect.
///
/// The union merge re-adds any server row, so a record device A deleted comes
/// back from device B's still-local copy. The fix is a `deletions` tombstone
/// table + a shared tombstone-filter that drops the resurrected id from the
/// **server** set BEFORE the union. These tests pin both the bug-proving merge
/// seam and the self-host schema parity (HARD RULE #5).
void main() {
  group('SyncHelper.removeTombstoned — resurrection prevention (#3078)', () {
    test('Device A deleted X → Device B merge does NOT re-include X', () {
      // Device B still holds X locally; the server also still returns X
      // (the union would re-add it). X is tombstoned (Device A deleted it).
      const local = ['st-1', 'st-X', 'st-3'];
      const serverIds = ['st-1', 'st-X', 'st-3'];
      final tombstoned = {'st-X'};

      // The fix: filter the SERVER rows through the tombstone seam before
      // the union, so the deleted id can never be re-included.
      final liveServer = SyncHelper.removeTombstoned(
        serverIds,
        tombstoned,
        key: (id) => id,
      ).toSet();
      final merged = {...local.where((id) => !tombstoned.contains(id)),
                      ...liveServer};

      expect(merged, isNot(contains('st-X')),
          reason: 'the tombstoned id resurrected through the union merge');
      expect(merged, containsAll(<String>['st-1', 'st-3']));
    });

    test('an empty tombstone set is a pass-through (no behaviour change)', () {
      const serverIds = ['a', 'b', 'c'];
      final result =
          SyncHelper.removeTombstoned(serverIds, <String>{}, key: (id) => id)
              .toList();
      expect(result, equals(serverIds));
    });

    test('filters keyed objects, not just bare id strings', () {
      final rows = [
        {'id': 'keep'},
        {'id': 'gone'},
      ];
      final result = SyncHelper.removeTombstoned(
        rows,
        {'gone'},
        key: (r) => r['id'],
      ).toList();
      expect(result, hasLength(1));
      expect(result.single['id'], 'keep');
    });
  });

  group('deletions table self-host schema parity (HARD RULE #5)', () {
    test('the deletions table is a probed (optional) verifier table', () {
      expect(SchemaVerifier.allTables, contains('deletions'));
    });

    test('schema_sql.tableSql defines an idempotent deletions table', () {
      expect(tableSql.keys, contains('deletions'));
      final block = tableSql['deletions']!;
      expect(block, contains('CREATE TABLE IF NOT EXISTS public.deletions'));
      expect(block, contains('table_name'));
      expect(block, contains('record_id'));
      expect(block, contains('UNIQUE(user_id, table_name, record_id)'));
    });

    test('wizard SQL creates the table, enables RLS and an own-row policy', () {
      final sql = SchemaVerifier.getMigrationSql(const {});
      expect(sql, contains('CREATE TABLE IF NOT EXISTS public.deletions'));
      expect(
          sql, contains('ALTER TABLE public.deletions ENABLE ROW LEVEL SECURITY'));
      expect(rlsSql, contains('CREATE POLICY deletions_own ON public.deletions'));
      expect(rlsSql, contains('USING (user_id = auth.uid())'));
    });

    test('the schema version was bumped past the pre-#3078 value', () {
      // The deletions table is a new schema object self-hosters must re-apply.
      expect(kSupabaseSchemaVersion, greaterThanOrEqualTo(3));
    });
  });
}
