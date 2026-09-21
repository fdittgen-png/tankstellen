// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import '../../logging/app_log.dart';
import '../../logging/error_logger.dart';
import '../../time/app_clock.dart';
import 'fleet_directory.dart';
import 'fleet_directory_cache.dart';
import 'fleet_transport.dart';

export 'fleet_directory.dart';
export 'fleet_directory_cache.dart'
    show CachedFleetDirectory, FleetDirectoryCache, FleetDirectoryFreshness;

/// Where a [FleetDirectoryPull]'s directory came from.
enum FleetDirectorySource {
  /// Fresh from the backend; the cache was updated.
  server,

  /// The backend could not be reached; the device copy, with its age.
  cache,

  /// Nothing to show — see [FleetDirectoryPull.failure].
  none,
}

/// Why a pull produced no directory at all.
enum FleetPullFailure {
  /// No live session, and nothing cached for this backend/account/org.
  notAuthenticated,

  /// The backend answered, and the caller is not a member of [orgId]
  /// (RLS returned no organisation row). The cache is forgotten — D4:
  /// no fallback to an org the server no longer grants.
  notAMember,

  /// The wire call failed and nothing is cached.
  wireFailed,
}

/// The outcome of [FleetDirectorySync.pull] — explicit about source and
/// age, never a bare directory that looks current when it is not.
class FleetDirectoryPull {
  const FleetDirectoryPull._({
    required this.source,
    this.directory,
    this.freshness,
    this.age,
    this.failure,
  });

  const FleetDirectoryPull.server(FleetDirectory directory)
      : this._(
            source: FleetDirectorySource.server,
            directory: directory,
            freshness: FleetDirectoryFreshness.fresh,
            age: Duration.zero);

  FleetDirectoryPull.cached(CachedFleetDirectory cached)
      : this._(
            source: FleetDirectorySource.cache,
            directory: cached.directory,
            freshness: cached.freshness,
            age: cached.age);

  const FleetDirectoryPull.none(FleetPullFailure failure)
      : this._(source: FleetDirectorySource.none, failure: failure);

  final FleetDirectorySource source;
  final FleetDirectory? directory;
  final FleetDirectoryFreshness? freshness;
  final Duration? age;
  final FleetPullFailure? failure;

  /// D4: a vehicle may be picked only from a directory that is not
  /// expired (a server pull is fresh by definition).
  bool get selectionEnabled =>
      directory != null && freshness != FleetDirectoryFreshness.expired;
}

/// The org-scoped pull (#4212): organisation, vehicles, the assignments
/// RLS lets the caller see, and the policy row — read through
/// [FleetTransport], judged by the injected [AppClock], cached under
/// `SyncContextKey | orgId`.
///
/// Pull-only. Nothing here writes to the backend; the org's writes are
/// RPCs (ADR 0025 D7). No auto-switch, no fallback to another org or
/// vehicle: a failed pull returns the previous cache *with its age*, or
/// nothing.
class FleetDirectorySync {
  FleetDirectorySync._();

  /// The tables one pull reads — the map-routed set the completeness
  /// gate (#4062 rule) checks against the wizard SQL.
  static const Set<String> tables = {
    FleetTables.organizations,
    FleetTables.vehicles,
    FleetTables.assignments,
    FleetTables.policies,
  };

  /// Pull [orgId]'s directory. [transport] / [cache] / [clock] are
  /// injectable; production passes nothing and gets the live session,
  /// the Hive-backed cache and the system clock.
  static Future<FleetDirectoryPull> pull({
    required String orgId,
    FleetTransport? transport,
    FleetDirectoryCache? cache,
    AppClock clock = const SystemClock(),
  }) async {
    final t = transport ?? SupabaseFleetTransport.currentOrNull();
    final store = cache ?? FleetDirectoryCache.hive();
    if (t == null) {
      // No session: there is no account to key the cache under, and a
      // global key is how #4047's leaks happened. A caller that still
      // holds the last account id reads the device copy via [cached].
      return const FleetDirectoryPull.none(FleetPullFailure.notAuthenticated);
    }
    final key = FleetDirectoryCache.keyFor(
        backendUrl: t.backendUrl, userId: t.userId, orgId: orgId);
    try {
      final orgRows = await t.selectOrg(
          FleetTables.organizations, 'id,name', orgId: orgId);
      if (orgRows.isEmpty) {
        await store.forget(key);
        return const FleetDirectoryPull.none(FleetPullFailure.notAMember);
      }
      final vehicles = await t.selectOrg(FleetTables.vehicles,
          'id,org_id,fleet_code,display_name,plate_masked,data',
          orgId: orgId);
      final assignments = await t.selectOrg(FleetTables.assignments,
          'id,org_id,fleet_vehicle_id,user_id,effective_from,effective_to',
          orgId: orgId);
      final policies =
          await t.selectOrg(FleetTables.policies, 'org_id,data', orgId: orgId);
      final policyData = policies.isEmpty ? null : policies.first['data'];
      final directory = FleetDirectory(
        orgId: orgId,
        orgName: '${orgRows.first['name'] ?? ''}',
        vehicles: [
          for (final row in vehicles) ?FleetVehicleRow.fromJson(row),
        ],
        assignments: [
          for (final row in assignments) ?FleetAssignmentRow.fromJson(row),
        ],
        policy: policyData is Map
            ? Map<String, dynamic>.from(policyData)
            : const {},
        fetchedAt: clock.now().toUtc(),
      );
      await store.write(key, directory);
      return FleetDirectoryPull.server(directory);
    } catch (e, st) {
      log.error(e, st, layer: ErrorLayer.sync, context: {
        'where': 'FleetDirectorySync.pull FAILED — serving the cache',
        'entity': FleetTables.organizations,
        'orgId': orgId,
      });
      final cached = store.read(key, clock: clock);
      if (cached == null) {
        return const FleetDirectoryPull.none(FleetPullFailure.wireFailed);
      }
      return FleetDirectoryPull.cached(cached);
    }
  }

  /// The device copy alone — for a screen that must render before (or
  /// without) a pull. Null when nothing is cached for this context.
  static CachedFleetDirectory? cached({
    required String orgId,
    required String userId,
    String? backendUrl,
    FleetDirectoryCache? cache,
    AppClock clock = const SystemClock(),
  }) =>
      (cache ?? FleetDirectoryCache.hive()).read(
        FleetDirectoryCache.keyFor(
            backendUrl: backendUrl, userId: userId, orgId: orgId),
        clock: clock,
      );
}
