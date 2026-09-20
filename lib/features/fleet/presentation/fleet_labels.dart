// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The one place a fleet role, a blocked scope or a refused join turns
/// into a sentence (#4217 / #4218).
///
/// Two features render these — the onboarding fleet-identity step and
/// Settings → Fleet — so the mapping lives once, next to the domain it
/// names, rather than twice in two widget trees. Every branch is an
/// explicit `switch`: a role or reason added later fails to compile
/// here instead of silently rendering nothing.
library;

import '../../../l10n/app_localizations.dart';
import '../application/fleet_join_service.dart';
import '../domain/fleet_scope.dart';

/// The user-facing name of [role].
String fleetRoleLabel(AppLocalizations l, FleetRole role) => switch (role) {
      FleetRole.employee => l.fleetRoleEmployee,
      FleetRole.manager => l.fleetRoleManager,
      FleetRole.admin => l.fleetRoleAdmin,
    };

/// Why fleet mode cannot be used here — the text that sits beside a
/// disabled control (ADR 0025 D2/D3). Null for
/// [FleetScopeReason.notInFleet], which is not a block: the user may
/// join, they simply have not yet.
String? fleetBlockedReason(AppLocalizations l, FleetScopeReason? reason) =>
    switch (reason) {
      FleetScopeReason.communityBackend => l.fleetBlockedCommunityBackend,
      FleetScopeReason.syncDisabled => l.fleetBlockedSyncDisabled,
      FleetScopeReason.identityRequired => l.fleetBlockedIdentityRequired,
      FleetScopeReason.notInFleet => null,
      null => null,
    };

/// What to tell the user after a refused join or create.
String fleetJoinFailureMessage(AppLocalizations l, FleetJoinFailure failure) =>
    switch (failure) {
      FleetJoinFailure.invalidCode => l.fleetJoinErrorInvalidCode,
      FleetJoinFailure.alreadyMember => l.fleetJoinErrorAlreadyMember,
      FleetJoinFailure.notSupported => l.fleetJoinErrorNotSupported,
      FleetJoinFailure.identityRequired => l.fleetBlockedIdentityRequired,
      FleetJoinFailure.unavailable => l.fleetJoinErrorUnavailable,
    };

/// The freshness sentence for a member scope (ADR 0025 D4) — null while
/// the directory is fresh, because a fresh directory needs no caption.
String? fleetFreshnessNote(AppLocalizations l, FleetScopeState state) =>
    switch (state) {
      FleetScopeState.stale => l.fleetSettingsStale,
      FleetScopeState.expired => l.fleetSettingsExpired,
      FleetScopeState.active ||
      FleetScopeState.none ||
      FleetScopeState.unavailable =>
        null,
    };
