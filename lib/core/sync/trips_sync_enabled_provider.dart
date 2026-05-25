// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/app_state_provider.dart';
import 'sync_provider.dart';

part 'trips_sync_enabled_provider.g.dart';

/// Whether recorded trajets sync to TankSync (#1665).
///
/// The single source of truth for the trajet-sync gate — `A ∧ B ∧ C`:
///  - **A** — a non-anonymous (email-backed) TankSync account
///    (`SyncConfig.hasEmail`);
///  - **B** — the master `cloudSync` GDPR consent;
///  - **C** — the `syncTrips` toggle.
///
/// Consulted at both trigger points — the `_saveToHistory` upload hook
/// in `trip_recording_provider` and the app-launch `_runTripsSyncMerge`
/// — so an anonymous session neither uploads nor merges trip rows.
/// `TripsSync` stays a pure I/O helper (its `currentUser == null`
/// early-return is a safety net); the gate lives here, not in the wire
/// layer.
///
/// `cloudSync` and `syncTrips` are checked explicitly rather than
/// relying on `GdprConsent.save()`'s `effectiveSyncTrips` coupling —
/// a fresh `build()` reads the raw stored values, so a stale
/// `syncTrips = true` under `cloudSync = false` must still gate off.
@riverpod
bool tripsSyncEnabled(Ref ref) {
  final syncConfig = ref.watch(syncStateProvider);
  final consent = ref.watch(gdprConsentProvider);
  return syncConfig.hasEmail && consent.cloudSync && consent.syncTrips;
}
