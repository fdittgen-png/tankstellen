// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/sync/trip_shares_sync.dart';
import '../../../core/sync/trip_shares_sync_enabled_provider.dart';
import '../data/trip_history_repository.dart';

part 'shared_trips_provider.g.dart';

/// Trips shared WITH me by another TankSync account (#2240), surfaced
/// read-only on the Trajets tab.
///
/// Distinct from [tripHistoryListProvider], which holds the user's own
/// recorded trips. These entries are fetched live from the server via
/// the recipient-read RLS path and are NEVER persisted to the local
/// Hive box — sharing only grants read access, so a revoked share
/// simply disappears on the next refresh rather than leaving a stale
/// local copy the recipient can't account for.
///
/// Gated on [tripSharesSyncEnabled]: an anonymous / consent-off session
/// returns an empty list without a wire call, so the "Shared with me"
/// section stays hidden exactly when sharing itself is unavailable.
@riverpod
class SharedTrips extends _$SharedTrips {
  @override
  Future<List<TripHistoryEntry>> build() async {
    if (!ref.watch(tripSharesSyncEnabledProvider)) return const [];
    return TripSharesSync.fetchSharedWithMe();
  }

  /// Re-fetch the shared-with-me list. Called after claiming a share
  /// link or pull-to-refresh on the Trajets tab.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (!ref.read(tripSharesSyncEnabledProvider)) {
        return const <TripHistoryEntry>[];
      }
      return TripSharesSync.fetchSharedWithMe();
    });
  }
}
