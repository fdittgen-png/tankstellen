// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The one place the app answers "which fleet am I in, and how fresh is
/// that answer" (#4212 / #4218, ADR 0025 D2–D4).
///
/// Synchronous and cache-only on purpose: the pull
/// ([FleetDirectorySync.pull]) is a network call that a screen must not
/// wait on, and #4218's rule is that a failed pull leaves the previous
/// answer in place *with its age* rather than inventing a fresher one.
/// Nothing here ever chooses a different org or vehicle.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_keys.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/fleet/fleet_directory_sync.dart';
import '../../../core/sync/sync_config.dart';
import '../../../core/sync/sync_provider.dart';
import '../../../core/time/app_clock.dart';
import '../domain/fleet_scope.dart';

part 'fleet_scope_provider.g.dart';

/// The sync facts fleet scope is derived from, as one overridable seam.
///
/// A test states "community backend" or "anonymous identity" by
/// overriding this with a plain [SyncConfig]; production reads the live
/// [syncStateProvider]. Without the seam the identity half would only be
/// reachable through `TankSyncClient`'s statics.
@Riverpod(keepAlive: true)
SyncConfig fleetSyncConfig(Ref ref) => ref.watch(syncStateProvider);

/// The directory cache fleet scope reads. Overridden in tests with an
/// in-memory [FleetDirectoryCache]; production gets the encrypted box.
@Riverpod(keepAlive: true)
FleetDirectoryCache fleetDirectoryCache(Ref ref) =>
    FleetDirectoryCache.hive();

/// The device's current [FleetScope].
///
/// Order of judgement — each step is a different answer, never a
/// fallback to the next:
///
///   1. no configured/enabled sync → `unavailable(syncDisabled)`;
///   2. the community backend → `unavailable(communityBackend)` (D3:
///      an organisation never lives there);
///   3. an anonymous identity → `unavailable(identityRequired)` (D2);
///   4. no stored org membership → `none`;
///   5. no (readable) cached directory for THIS backend + account + org
///      → `none` — an offline device grants nothing;
///   6. otherwise the cache's own three-valued freshness verdict
///      (`fresh` → active, `stale`, `expired`).
@riverpod
FleetScope fleetScope(Ref ref) {
  final sync = ref.watch(fleetSyncConfigProvider);
  final userId = sync.userId;
  if (!sync.enabled || sync.mode == SyncMode.none || userId == null) {
    return const FleetScope.unavailable(FleetScopeReason.syncDisabled);
  }
  if (sync.mode != SyncMode.private && sync.mode != SyncMode.joinExisting) {
    return const FleetScope.unavailable(FleetScopeReason.communityBackend);
  }
  if (!sync.hasEmail) {
    return const FleetScope.unavailable(FleetScopeReason.identityRequired);
  }

  final storage = ref.watch(storageRepositoryProvider);
  final orgId = storage.getSetting(StorageKeys.fleetOrgId) as String?;
  final role = FleetRole.fromWireName(
      storage.getSetting(StorageKeys.fleetRole) as String?);
  if (orgId == null || orgId.isEmpty || role == null) {
    return const FleetScope.none();
  }

  final cached = FleetDirectorySync.cached(
    orgId: orgId,
    userId: userId,
    backendUrl: sync.supabaseUrl,
    cache: ref.watch(fleetDirectoryCacheProvider),
    clock: ref.watch(appClockProvider),
  );
  // A cache read that finds nothing — or, defensively, one that decoded
  // a directory belonging to another org — grants no fleet at all.
  if (cached == null || cached.directory.orgId != orgId) {
    return const FleetScope.none();
  }
  return FleetScope.member(
    state: switch (cached.freshness) {
      FleetDirectoryFreshness.fresh => FleetScopeState.active,
      FleetDirectoryFreshness.stale => FleetScopeState.stale,
      FleetDirectoryFreshness.expired => FleetScopeState.expired,
    },
    orgId: orgId,
    orgName: cached.directory.orgName,
    role: role,
    age: cached.age,
  );
}
