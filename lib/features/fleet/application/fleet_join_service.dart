// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Joining a fleet — the one write path an employee has into the org
/// tables (#4217, Epic #4211, ADR 0025 D2/D3/D7).
///
/// Everything here goes through an RPC: there is no client INSERT policy
/// on `fleet_members`, so a join is the server re-checking the invite,
/// the identity and the backend's own `fleet_enabled` flag. The client
/// half only decides what the user is told afterwards.
///
/// Two entry points, because a fleet has two first users:
///
///   * [FleetJoinService.joinWithInviteCode] — the employee, with the
///     code their administrator handed them;
///   * [FleetJoinService.createOrganization] — the administrator, via
///     F2's `fleet_create_organization` RPC.
///
/// Faults are **returned**, never thrown: every outcome the UI has to
/// explain is a [FleetJoinOutcome] value, so "the code was wrong",
/// "this backend has no fleets" and "the network died" reach the screen
/// as three different, nameable reasons instead of one red SnackBar
/// (#4217's disabled-with-reason rule). Pinned by the fault-injection
/// test in `test/features/fleet/fleet_join_service_test.dart`.
library;

import '../../../core/data/storage_repository.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/sync/fleet/fleet_directory_sync.dart';
import '../../../core/sync/fleet/fleet_membership_sync.dart';
import '../../../core/sync/fleet/fleet_transport.dart';
import '../../../core/time/app_clock.dart';

/// Why a join or a create did not happen. Each value maps to exactly one
/// ARB sentence — the user is never shown a raw server token.
enum FleetJoinFailure {
  /// The invite code is unknown, spent or expired.
  invalidCode,

  /// This account is already in a fleet (ADR 0025 D1: one org per user
  /// in v1).
  alreadyMember,

  /// The backend does not do fleets: either the operator never set
  /// `tanksync_meta.fleet_enabled`, or the schema predates the fleet
  /// RPCs entirely. Both are the administrator's job, not the user's.
  notSupported,

  /// The RPC refused the identity — anonymous, or no session at all
  /// (ADR 0025 D2). The UI normally blocks before this, but a server
  /// that disagrees still has to be believed.
  identityRequired,

  /// Anything else: offline, a timeout, an unrecognised server error.
  unavailable,
}

/// The result of a join / create attempt.
sealed class FleetJoinOutcome {
  const FleetJoinOutcome();
}

/// The account is now a member of [orgId] with [role]. The org id and
/// role are already persisted, and the directory pull has been
/// attempted, when this is returned.
class FleetJoined extends FleetJoinOutcome {
  const FleetJoined({required this.orgId, required this.role});

  final String orgId;
  final FleetRole role;
}

/// Nothing changed — [failure] says what to tell the user.
class FleetJoinRefused extends FleetJoinOutcome {
  const FleetJoinRefused(this.failure);

  final FleetJoinFailure failure;
}

/// Calls the join / create RPCs and records the resulting membership.
class FleetJoinService {
  const FleetJoinService({
    required this.transport,
    required this.storage,
    this.cache,
    this.clock = const SystemClock(),
  });

  final FleetTransport transport;
  final StorageRepository storage;
  final FleetDirectoryCache? cache;
  final AppClock clock;

  /// The RPC an employee's invite code goes to. Named here rather than
  /// inline so the "this server does not have it" path is testable.
  static const String joinRpc = 'fleet_join';

  /// F2's administrator RPC (ADR 0025 D7).
  static const String createRpc = 'fleet_create_organization';

  /// Redeem [inviteCode] and become a member. Whitespace is trimmed;
  /// an empty code never reaches the wire.
  Future<FleetJoinOutcome> joinWithInviteCode(String inviteCode) {
    final code = inviteCode.trim();
    if (code.isEmpty) {
      return Future.value(
        const FleetJoinRefused(FleetJoinFailure.invalidCode),
      );
    }
    return _call(
      joinRpc,
      {'p_invite_code': code},
      fallbackRole: FleetRole.employee,
    );
  }

  /// Create a fleet named [name] and become its administrator. Fails
  /// with [FleetJoinFailure.notSupported] on a backend whose operator
  /// has not set `fleet_enabled` — the community project always
  /// (ADR 0025 D3).
  Future<FleetJoinOutcome> createOrganization(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const FleetJoinRefused(FleetJoinFailure.unavailable),
      );
    }
    return _call(
      createRpc,
      {'p_name': trimmed},
      fallbackRole: FleetRole.admin,
    );
  }

  Future<FleetJoinOutcome> _call(
    String fn,
    Map<String, dynamic> params, {
    required FleetRole fallbackRole,
  }) async {
    try {
      final response = await transport.rpc(fn, params);
      final decoded = _decode(response, fallbackRole);
      if (decoded == null) {
        return const FleetJoinRefused(FleetJoinFailure.unavailable);
      }
      await _remember(decoded);
      // Warm the directory so the scope answers `active` rather than
      // `none` on the very next frame. A failed pull is not a failed
      // join: the membership is real, the cache simply stays empty and
      // the scope says so (ADR 0025 D4, no invented freshness).
      await FleetDirectorySync.pull(
        orgId: decoded.orgId,
        transport: transport,
        cache: cache,
        clock: clock,
      );
      return decoded;
    } catch (e, st) {
      final failure = _classify(e);
      log.error(e, st, layer: ErrorLayer.sync, context: {
        'where': 'FleetJoinService.$fn REFUSED',
        'failure': failure.name,
      });
      return FleetJoinRefused(failure);
    }
  }

  /// Both RPCs may answer with a bare org id (what
  /// `fleet_create_organization` returns) or with a row carrying the
  /// granted role. Anything else is not a membership.
  FleetJoined? _decode(dynamic response, FleetRole fallbackRole) {
    if (response is String && response.isNotEmpty) {
      return FleetJoined(orgId: response, role: fallbackRole);
    }
    if (response is Map) {
      final orgId = response['org_id'];
      if (orgId is! String || orgId.isEmpty) return null;
      return FleetJoined(
        orgId: orgId,
        role: FleetRole.fromWireName(response['role'] as String?) ??
            fallbackRole,
      );
    }
    if (response is List && response.length == 1) {
      return _decode(response.first, fallbackRole);
    }
    return null;
  }

  Future<void> _remember(FleetJoined joined) async {
    await storage.putSetting(StorageKeys.fleetOrgId, joined.orgId);
    await storage.putSetting(StorageKeys.fleetRole, joined.role.wireName);
  }

  /// Maps a wire error onto the sentence the user gets. The server's
  /// tokens (`already_member`, `fleet_disabled`, …) are matched on the
  /// error's text so this layer stays free of the Postgrest types — the
  /// transport is the only place that knows them.
  static FleetJoinFailure _classify(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('already_member')) return FleetJoinFailure.alreadyMember;
    if (text.contains('identity_required') ||
        text.contains('not_authenticated')) {
      return FleetJoinFailure.identityRequired;
    }
    if (text.contains('fleet_disabled') ||
        // PostgREST: the function is absent from the schema cache;
        // Postgres 42883: undefined_function. A self-host on an older
        // fleet schema, which is the administrator's upgrade to make.
        text.contains('pgrst202') ||
        text.contains('42883') ||
        text.contains('could not find the function')) {
      return FleetJoinFailure.notSupported;
    }
    if (text.contains('invalid_code') ||
        text.contains('invite_not_found') ||
        text.contains('not_found')) {
      return FleetJoinFailure.invalidCode;
    }
    return FleetJoinFailure.unavailable;
  }
}
