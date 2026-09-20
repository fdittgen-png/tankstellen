// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The current fleet vehicle, and the only way it ever changes: the
/// driver picking one (#4213, Epic #4211, ADR 0025 D4/D7).
///
/// Three rules this file exists to make unbreakable:
///
///   1. **No auto-switch.** There is no API here that a GPS fix, an
///      OBD2 adapter identity or a VIN read can call. Signals are
///      resolved by `VehicleAttributionResolver` and *proposed* to the
///      driver; only [CurrentFleetVehicle.select] changes the current
///      vehicle, and only from a tap.
///   2. **Only a valid assignment is selectable.** The default is the
///      latest assignment that is open *and* effective right now; an
///      ended or not-yet-effective one is not in the selectable set and
///      a stored selection pointing at one is dropped, not repaired.
///   3. **An expired directory selects nothing.** `FleetScope.expired`
///      (a device copy 7 days or older) keeps showing the vehicle it
///      last knew, badged, with switching disabled — never a silent
///      fallback to a different car.
///
/// Cache-only and synchronous, like `fleetScopeProvider`: a screen must
/// not wait on a network pull to know which car it is logging against.
library;

import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/guarded.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/storage/storage_providers.dart';
import '../../../core/sync/fleet/fleet_directory_sync.dart';
import '../../../core/time/app_clock.dart';
import '../domain/fleet_vehicle.dart';
import '../domain/fleet_scope.dart';
import 'fleet_scope_provider.dart';

part 'current_fleet_vehicle_provider.g.dart';

/// How many explicitly-picked vehicles the "recent first" order keeps.
const int kFleetRecentVehicleLimit = 8;

/// Why no vehicle is current.
enum CurrentVehicleAbsence {
  /// A vehicle IS current — [CurrentVehicleContext.vehicle] is non-null.
  none,

  /// Fleet mode does not apply, or this account is in no fleet.
  notInFleet,

  /// In a fleet, but no assignment is effective right now — a handover
  /// gap, or a driver between cars.
  noValidAssignment,
}

/// Everything a surface needs to render the current-vehicle control,
/// derived in one synchronous pass.
class CurrentVehicleContext {
  const CurrentVehicleContext({
    required this.vehicle,
    required this.selectable,
    required this.scopeState,
    required this.switchingEnabled,
    required this.absence,
  });

  const CurrentVehicleContext.absent(
    CurrentVehicleAbsence absence, {
    FleetScopeState scopeState = FleetScopeState.none,
    List<FleetVehicle> selectable = const <FleetVehicle>[],
    bool switchingEnabled = false,
  }) : this(
          vehicle: null,
          selectable: selectable,
          scopeState: scopeState,
          switchingEnabled: switchingEnabled,
          absence: absence,
        );

  /// The vehicle the next fill-up / recording / expense is attributed
  /// to. Null when [absence] says why there is none.
  final FleetVehicle? vehicle;

  /// The vehicles the driver may switch to, most recently picked first
  /// and the current one included. Empty while switching is disabled.
  final List<FleetVehicle> selectable;

  /// The freshness of the directory this was derived from — what the
  /// control badges.
  final FleetScopeState scopeState;

  /// ADR 0025 D4: false on an expired directory, so the control renders
  /// disabled with its reason instead of offering a stale list.
  final bool switchingEnabled;

  final CurrentVehicleAbsence absence;

  /// Whether the surface should show the offline/stale badge.
  bool get isStale =>
      scopeState == FleetScopeState.stale ||
      scopeState == FleetScopeState.expired;

  /// Whether the control should render at all. A personal (non-fleet)
  /// user never sees it.
  bool get isVisible => absence != CurrentVehicleAbsence.notInFleet;
}

/// The current fleet vehicle. Explicit selection only.
@riverpod
class CurrentFleetVehicle extends _$CurrentFleetVehicle {
  @override
  CurrentVehicleContext build() {
    final scope = ref.watch(fleetScopeProvider);
    final sync = ref.watch(fleetSyncConfigProvider);
    final userId = sync.userId;
    final orgId = scope.orgId;
    if (!scope.isMember || orgId == null || userId == null) {
      return const CurrentVehicleContext.absent(
          CurrentVehicleAbsence.notInFleet);
    }

    final cached = FleetDirectorySync.cached(
      orgId: orgId,
      userId: userId,
      backendUrl: sync.supabaseUrl,
      cache: ref.watch(fleetDirectoryCacheProvider),
      clock: ref.watch(appClockProvider),
    );
    final directory = cached?.directory;
    if (directory == null || directory.orgId != orgId) {
      return CurrentVehicleContext.absent(CurrentVehicleAbsence.notInFleet,
          scopeState: scope.state);
    }

    final now = ref.watch(appClockProvider).now().toUtc();
    final assigned = _assignedVehicles(directory, userId: userId, now: now);
    if (assigned.isEmpty) {
      return CurrentVehicleContext.absent(
          CurrentVehicleAbsence.noValidAssignment,
          scopeState: scope.state);
    }

    final ordered = _recentFirst(assigned);
    // D4: an expired directory shows what it last knew and disables the
    // switch — the selectable list is withheld, not silently offered.
    final switching = scope.selectionEnabled;
    return CurrentVehicleContext(
      vehicle: _resolveCurrent(ordered),
      selectable: switching ? ordered : const <FleetVehicle>[],
      scopeState: scope.state,
      switchingEnabled: switching,
      absence: CurrentVehicleAbsence.none,
    );
  }

  /// Switch to [fleetVehicleId]. The ONE mutator, and it refuses
  /// anything the driver could not legitimately have tapped: a disabled
  /// switch (expired directory) or a vehicle outside the selectable
  /// set. Returns whether the selection changed.
  ///
  /// Records made before the switch keep the attribution they were
  /// stamped with — this writes a setting, never a past record.
  Future<bool> select(String fleetVehicleId) async {
    final context = state;
    if (!context.switchingEnabled) return false;
    if (!context.selectable.any((v) => v.fleetVehicleId == fleetVehicleId)) {
      return false;
    }

    final storage = ref.read(storageRepositoryProvider);
    final recents = <String>[
      fleetVehicleId,
      for (final id in _storedRecents(storage.getSetting(
          StorageKeys.fleetRecentVehicleIds)))
        if (id != fleetVehicleId) id,
    ];
    await storage.putSetting(StorageKeys.fleetCurrentVehicleId, fleetVehicleId);
    await storage.putSetting(
      StorageKeys.fleetRecentVehicleIds,
      jsonEncode(recents.take(kFleetRecentVehicleLimit).toList()),
    );
    // #4388 — both settings are already written, so the switch HAPPENED.
    // If this provider was disposed while those awaits were in flight
    // (the driver left the screen), `invalidateSelf` throws and the
    // `return true` below never runs: the caller would be told the
    // switch failed while storage says it succeeded, and a later record
    // would be attributed to a vehicle the UI never acknowledged. There
    // is also nothing to refresh — a disposed provider rebuilds from
    // storage next time it is read.
    if (!ref.mounted) return true;
    ref.invalidateSelf();
    return true;
  }

  /// The vehicles an open, currently-effective assignment gives the
  /// driver, newest assignment first.
  List<FleetVehicle> _assignedVehicles(
    FleetDirectory directory, {
    required String userId,
    required DateTime now,
  }) {
    final rows = {for (final v in directory.vehicles) v.id: v};
    final mine = [
      for (final a in directory.assignments)
        // `isOpen` alone would keep a not-yet-effective assignment; the
        // effective-dated check is what makes a handover instant in
        // both directions.
        if (a.userId == userId && a.isOpen && a.isActiveAt(now)) a,
    ]..sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));
    final out = <FleetVehicle>[];
    for (final a in mine) {
      final row = rows[a.fleetVehicleId];
      if (row == null || row.orgId != directory.orgId) continue;
      if (out.any((v) => v.fleetVehicleId == row.id)) continue;
      out.add(FleetVehicle.fromRow(row));
    }
    return out;
  }

  /// [assigned] reordered so the vehicles the driver picked most
  /// recently come first; everything else keeps assignment order.
  List<FleetVehicle> _recentFirst(List<FleetVehicle> assigned) {
    final storage = ref.watch(storageRepositoryProvider);
    final recents =
        _storedRecents(storage.getSetting(StorageKeys.fleetRecentVehicleIds));
    final byId = {for (final v in assigned) v.fleetVehicleId: v};
    final out = <FleetVehicle>[
      for (final id in recents)
        if (byId.containsKey(id)) byId[id]!,
    ];
    for (final v in assigned) {
      if (!out.any((o) => o.fleetVehicleId == v.fleetVehicleId)) out.add(v);
    }
    return out;
  }

  /// The stored explicit pick when it is still assigned, otherwise the
  /// latest valid assignment. A stored id that has been handed over is
  /// dropped — never mapped onto a neighbouring vehicle.
  FleetVehicle _resolveCurrent(List<FleetVehicle> ordered) {
    final storage = ref.watch(storageRepositoryProvider);
    final stored =
        storage.getSetting(StorageKeys.fleetCurrentVehicleId) as String?;
    for (final v in ordered) {
      if (v.fleetVehicleId == stored) return v;
    }
    return ordered.first;
  }
}

/// The persisted recents list, or empty for anything unreadable.
List<String> _storedRecents(Object? raw) {
  if (raw is! String || raw.isEmpty) return const <String>[];
  Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (e, st) {
    // A corrupt recents list costs the driver an ordering, nothing
    // more — the selectable set still comes from the assignments.
    _logRecentsFault(e, st);
    return const <String>[];
  }
  if (decoded is! List) return const <String>[];
  return [
    for (final id in decoded)
      if (id is String && id.isNotEmpty) id,
  ];
}

void _logRecentsFault(Object e, StackTrace st) {
  logFailure(e, st,
      where: 'CurrentFleetVehicle: unreadable recent-vehicle list',
      layer: ErrorLayer.storage);
}
