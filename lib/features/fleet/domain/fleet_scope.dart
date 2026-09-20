// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// What fleet the device is currently scoped to, and how much that
/// answer can be trusted (#4212 / #4218, ADR 0025 D2–D4).
///
/// Every fleet surface reads this one value. It is deliberately NOT a
/// nullable org id: "no fleet", "a fleet whose directory is 6 days old"
/// and "fleet mode cannot apply on this backend" are three different
/// answers, and #4218's rule — *never silently fall back* — only holds
/// if the difference survives all the way to the UI.
library;

import '../../../core/sync/fleet/fleet_membership_sync.dart' show FleetRole;

export '../../../core/sync/fleet/fleet_membership_sync.dart'
    show FleetMembership, FleetRole;

/// The five states a fleet scope can be in.
enum FleetScopeState {
  /// Fleet mode could apply here, but this account is in no fleet (or
  /// has never pulled its org directory). Not an error.
  none,

  /// A fleet, with a directory younger than 24 h (ADR 0025 D4).
  active,

  /// A fleet, with a directory between 24 h and 7 d old. Usable, and
  /// every surface that shows it says so.
  stale,

  /// A fleet, with a directory 7 d or older. Vehicle selection is
  /// **disabled** until a pull succeeds — never silently replaced by a
  /// different vehicle or org.
  expired,

  /// Fleet mode cannot apply at all right now — see [FleetScope.reason].
  unavailable,
}

/// Why a scope is [FleetScopeState.unavailable] or
/// [FleetScopeState.none]. Named so the UI can explain the block
/// instead of showing an inert control (ADR 0025 D2/D3).
enum FleetScopeReason {
  /// The community backend never hosts an organisation (D3). Fleet mode
  /// is offered only on `SyncMode.private` / `SyncMode.joinExisting`.
  communityBackend,

  /// Cloud sync is off or unconfigured — there is no backend at all.
  syncDisabled,

  /// The TankSync identity is still anonymous. Joining or creating a
  /// fleet requires the e-mail-upgraded identity (D2); the control is
  /// shown disabled **with this reason**, never hidden.
  identityRequired,

  /// The backend and identity are fine; this account simply belongs to
  /// no organisation.
  notInFleet,
}

/// The device's current fleet scope.
///
/// Immutable value type, no codegen: it is derived per read from the
/// sync config plus the cached directory, never persisted as a whole.
class FleetScope {
  const FleetScope._({
    required this.state,
    this.orgId,
    this.orgName,
    this.role,
    this.reason,
    this.age,
  });

  /// Fleet mode applies, but this account is in no organisation.
  const FleetScope.none()
      : this._(
          state: FleetScopeState.none,
          reason: FleetScopeReason.notInFleet,
        );

  /// Fleet mode does not apply here — [reason] says why.
  const FleetScope.unavailable(FleetScopeReason reason)
      : this._(state: FleetScopeState.unavailable, reason: reason);

  /// A fleet whose directory is fresh, stale or expired — [state] is
  /// the freshness verdict the cache already made.
  const FleetScope.member({
    required FleetScopeState state,
    required String orgId,
    required String orgName,
    required FleetRole role,
    required Duration age,
  }) : this._(
          state: state,
          orgId: orgId,
          orgName: orgName,
          role: role,
          age: age,
        );

  final FleetScopeState state;

  /// The organisation, when [state] is [FleetScopeState.active],
  /// [FleetScopeState.stale] or [FleetScopeState.expired]. Null in every
  /// other state — there is no "last known org" to fall back to.
  final String? orgId;
  final String? orgName;

  /// The caller's role in [orgId]. Null whenever [orgId] is.
  final FleetRole? role;

  /// Why the scope is [FleetScopeState.unavailable] / [FleetScopeState.none].
  final FleetScopeReason? reason;

  /// Age of the cached directory this verdict was made from.
  final Duration? age;

  /// Whether the user is in a fleet at all (however old the directory).
  bool get isMember =>
      state == FleetScopeState.active ||
      state == FleetScopeState.stale ||
      state == FleetScopeState.expired;

  /// ADR 0025 D4: a vehicle may be picked only from a directory that is
  /// not expired.
  bool get selectionEnabled =>
      state == FleetScopeState.active || state == FleetScopeState.stale;

  /// Whether the manager surfaces may be offered. Role alone — the
  /// `fleetManagerTools` flag is the second, independent gate.
  bool get isManager => role?.isManager ?? false;

  @override
  bool operator ==(Object other) =>
      other is FleetScope &&
      other.state == state &&
      other.orgId == orgId &&
      other.orgName == orgName &&
      other.role == role &&
      other.reason == reason &&
      other.age == age;

  @override
  int get hashCode => Object.hash(state, orgId, orgName, role, reason, age);

  @override
  String toString() => 'FleetScope(${state.name}'
      '${orgId == null ? '' : ', $orgId'}'
      '${role == null ? '' : ', ${role!.wireName}'}'
      '${reason == null ? '' : ', ${reason!.name}'})';
}
