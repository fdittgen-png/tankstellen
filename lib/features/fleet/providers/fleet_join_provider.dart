// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// The join / create action behind the onboarding fleet-identity step
/// and the Settings → Fleet screen (#4217, ADR 0025 D2/D3/D7).
///
/// One busy flag and one nameable failure — no thrown exception ever
/// reaches a widget from here, so every screen renders a reason instead
/// of an error SnackBar (#4217's UX rule).
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/fleet/fleet_transport.dart';
import '../../../core/time/app_clock.dart';
import '../application/fleet_join_service.dart';
import 'fleet_scope_provider.dart';

part 'fleet_join_provider.g.dart';

/// The wire seam. Null when TankSync is not initialised or nobody is
/// signed in; tests override it with `FakeFleetTransport`.
@Riverpod(keepAlive: true)
FleetTransport? fleetTransport(Ref ref) =>
    SupabaseFleetTransport.currentOrNull();

/// The join service for the current session, or null when there is no
/// transport to talk through.
@Riverpod(keepAlive: true)
FleetJoinService? fleetJoinService(Ref ref) {
  final transport = ref.watch(fleetTransportProvider);
  if (transport == null) return null;
  return FleetJoinService(
    transport: transport,
    storage: ref.watch(storageRepositoryProvider),
    cache: ref.watch(fleetDirectoryCacheProvider),
    clock: ref.watch(appClockProvider),
  );
}

/// What the join surface is currently showing.
class FleetJoinState {
  const FleetJoinState({
    this.busy = false,
    this.failure,
    this.joined = false,
  });

  /// An RPC is in flight — the action is disabled, not re-entrant.
  final bool busy;

  /// The last refusal, or null when nothing has been refused since the
  /// last attempt started.
  final FleetJoinFailure? failure;

  /// A join or create succeeded in this session.
  final bool joined;

  @override
  bool operator ==(Object other) =>
      other is FleetJoinState &&
      other.busy == busy &&
      other.failure == failure &&
      other.joined == joined;

  @override
  int get hashCode => Object.hash(busy, failure, joined);
}

/// Drives [FleetJoinService] and republishes the fleet scope on success.
@riverpod
class FleetJoinController extends _$FleetJoinController {
  @override
  FleetJoinState build() => const FleetJoinState();

  /// Redeem an invite code.
  Future<void> joinWithInviteCode(String code) =>
      _run((service) => service.joinWithInviteCode(code));

  /// Create a fleet and become its administrator.
  Future<void> createOrganization(String name) =>
      _run((service) => service.createOrganization(name));

  Future<void> _run(
    Future<FleetJoinOutcome> Function(FleetJoinService) action,
  ) async {
    if (state.busy) return;
    final service = ref.read(fleetJoinServiceProvider);
    if (service == null) {
      state = const FleetJoinState(failure: FleetJoinFailure.unavailable);
      return;
    }
    state = const FleetJoinState(busy: true);
    final outcome = await action(service);
    // #4388 — this controller is auto-dispose, so the driver leaving the
    // join screen while the request is in flight disposes it; touching
    // `ref` or `state` on the resume then throws.
    //
    // Nothing is lost by returning here. The join, if it succeeded, is
    // already persisted (the membership row and the warmed directory are
    // written by the service, not by this notifier), and
    // `fleetScopeProvider` is itself auto-dispose — with no listener it
    // is already gone and recomputes from that persisted state the next
    // time something reads it. The invalidation below only matters while
    // somebody is watching.
    if (!ref.mounted) return;
    switch (outcome) {
      case FleetJoined():
        // The membership row and the warmed directory are already
        // persisted; re-deriving the scope is what makes the screen
        // show the org instead of the join form.
        ref.invalidate(fleetScopeProvider);
        state = const FleetJoinState(joined: true);
      case FleetJoinRefused(:final failure):
        state = FleetJoinState(failure: failure);
    }
  }
}
