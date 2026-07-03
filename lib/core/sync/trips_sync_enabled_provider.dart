// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/app_state_provider.dart';
import 'sync_provider.dart';

part 'trips_sync_enabled_provider.g.dart';

/// Whether recorded trajets sync to TankSync (#1665, #3448).
///
/// The single source of truth for the trajet-sync gate — `B ∧ C`:
///  - **B** — the master `cloudSync` GDPR consent;
///  - **C** — the `syncTrips` toggle.
///
/// #3448 dropped the former **A** (a non-anonymous, email-backed
/// account): an anonymous UUID is a full identity — its trips, vehicles
/// and fill-ups are RLS-scoped to it exactly like an email account's —
/// so requiring email silently disabled trip/vehicle/fill-up sync for
/// every anonymous user even though they had granted both consents.
/// Email remains what makes the identity PORTABLE across devices; the
/// settings copy explains that distinction instead of gating on it.
///
/// Consulted at the trigger points — the `_saveToHistory` upload hook in
/// `trip_recording_provider` and the launch/resume/sync-now pull matrix
/// (`LaunchSyncPulls`). `TripsSync` stays a pure I/O helper (its
/// `currentUser == null` early-return is a safety net); the gate lives
/// here, not in the wire layer.
///
/// `cloudSync` and `syncTrips` are checked explicitly rather than
/// relying on `GdprConsent.save()`'s `effectiveSyncTrips` coupling —
/// a fresh `build()` reads the raw stored values, so a stale
/// `syncTrips = true` under `cloudSync = false` must still gate off.
@riverpod
bool tripsSyncEnabled(Ref ref) {
  // Watching syncStateProvider keeps the gate reactive to connect /
  // disconnect (a disconnected client makes every pull a no-op anyway,
  // but dependents also re-evaluate on reconnect).
  ref.watch(syncStateProvider);
  final consent = ref.watch(gdprConsentProvider);
  return consent.cloudSync && consent.syncTrips;
}
