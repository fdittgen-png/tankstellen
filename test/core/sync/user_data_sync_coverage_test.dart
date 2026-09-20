// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT
//
// #3868 / #3869 (Epic #3865) — the server export set is a superset of the
// server deletion set (the app never deletes rows it would not show), the
// deletion set covers every table the wizard SQL creates, and the
// `erase_my_data()` RPC covers the same tables as the client fallback.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/sync/schema_verifier.dart';
import 'package:tankstellen/core/sync/user_data_sync.dart';
import 'package:tankstellen/features/fleet/data/fleet_document_store.dart';

void main() {
  test('export set ⊇ delete set', () {
    final notExported = UserDataSync.deletableTables.keys
        .toSet()
        .difference(UserDataSync.readableTables.keys.toSet());
    expect(notExported, isEmpty,
        reason: 'deleted but never shown/exported: $notExported');
  });

  test('every user table the wizard creates is in the delete set', () {
    // Tables without a per-user row are public data, not user data.
    const publicOnly = {'price_snapshots', 'tanksync_meta', 'database_owner',
      'wait_time_aggregates'};
    // #4212 — org-owned rows (ADR 0025 D9 matrix): the organisation, its
    // vehicles and its policies belong to the org, not to any user; the
    // user-linked fleet tables (fleet_members, vehicle_assignments) ARE
    // in the delete set and must stay there.
    const orgOwned = {'fleet_organizations', 'fleet_vehicles',
      'fleet_policies'};
    final schemaTables = SchemaVerifier.allTables.toSet()
      ..removeAll(publicOnly)
      ..removeAll(orgOwned);
    final deletable = UserDataSync.deletableTables.keys.toSet()
      ..addAll(['trip_summaries', 'trip_details']); // via forgetAllForUser
    final missing = schemaTables.difference(deletable);
    expect(missing, isEmpty,
        reason: 'synced user table(s) with no erasure path: $missing');
  });

  // #4215 — `lib/core/` may not import `lib/features/` (epic #3129 pins
  // the fleet pair at zero), so UserDataSync spells the receipt bucket
  // out instead of importing FleetDocumentStore.bucket. That is a
  // duplicated constant, and this is what stops it becoming a drifted
  // one: the account-deletion path and the feature-side store must
  // name the same bucket, or one of them erases nothing.
  test('the receipt bucket is the same string on both sides of the '
      'core/feature boundary (#4215)', () {
    expect(UserDataSync.fleetDocumentsBucket, FleetDocumentStore.bucket);
    expect(UserDataSync.fleetDocumentsBucket, 'fleet-documents');
  });

  test('erase_my_data() RPC and the client fallback cover the same tables',
      () {
    // The LATEST migration that (re)defines erase_my_data() is the source
    // of truth — v13 (#4212) redefined it to add the fleet tables.
    final defining = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.sql'))
        .where((f) => f
            .readAsStringSync()
            .contains('FUNCTION public.erase_my_data()'))
        .map((f) => f.path)
        .toList()
      ..sort();
    expect(defining, isNotEmpty);
    final sql = File(defining.last).readAsStringSync();
    final inRpc = RegExp(r"ARRAY\['([a-z0-9_]+)',\s*'[a-z0-9_]+'\]")
        .allMatches(sql)
        .map((m) => m.group(1)!)
        .toSet();
    final client = UserDataSync.deletableTables.keys.toSet()
      ..addAll(['trip_summaries', 'trip_details']);
    expect(inRpc, client,
        reason: 'RPC and per-table fallback must erase the same tables');
    // The wizard SQL ships the same function (HARD RULE #5).
    final wizard = SchemaVerifier.getMigrationSql(const {});
    expect(wizard, contains('FUNCTION public.erase_my_data()'));
    for (final t in inRpc) {
      expect(wizard, contains("ARRAY['$t'"), reason: 'wizard SQL lacks $t');
    }
  });
}
