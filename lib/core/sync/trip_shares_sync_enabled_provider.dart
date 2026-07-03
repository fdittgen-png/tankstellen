// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'trips_sync_enabled_provider.dart';

part 'trip_shares_sync_enabled_provider.g.dart';

/// Whether cross-account trip SHARING is available (#2240).
///
/// Cross-account sharing is a strict superset of the per-account trip
/// sync gate: you can only share a trip that's syncing in the first
/// place, and the same conditions apply (`cloudSync` consent ∧
/// `syncTrips` toggle — #3448 dropped the former email requirement).
/// Rather than duplicate that logic, this derives from
/// [tripsSyncEnabled] — so a future change to the trip-sync gate
/// automatically flows through to the share affordances, and the share
/// Action / "shared with me" section stay hidden for consent-off
/// sessions.
@riverpod
bool tripSharesSyncEnabled(Ref ref) {
  // Degrade to "sharing unavailable" if the trip-sync gate can't be
  // resolved — e.g. the GDPR-consent / sync-settings Hive boxes aren't
  // open yet (early launch, or a widget test that doesn't seed them).
  // A crash here would take down the whole trip-detail screen; the
  // honest fallback is to simply not offer the share affordance.
  try {
    return ref.watch(tripsSyncEnabledProvider);
  } catch (_) {
    return false;
  }
}
