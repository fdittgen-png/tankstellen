import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/maintenance_snooze_repository.dart';
import '../domain/entities/maintenance_suggestion.dart';
import '../domain/services/maintenance_analyzer.dart';
import 'trip_history_provider.dart';

part 'maintenance_provider.g.dart';

/// Riverpod wiring for the predictive-maintenance heuristics (#1124).
///
/// Three providers:
///
///   * [maintenanceSnoozeRepository] — singleton repository over the
///     `settings` Hive box. Always returns a real instance; the repo
///     itself defends against a closed box.
///   * [maintenanceSuggestions] — derived list. Watches the trip-
///     history provider, runs the analyzer over the last 30 days, and
///     filters out any signal currently in snooze. Empty when the
///     box is empty / not enough trips / nothing fires.
///   * [MaintenanceSuggestionsController] — actions. The card's
///     dismiss + snooze buttons go through this so a press triggers a
///     re-evaluation of the derived provider on the next frame.
///
/// Why a controller instead of `ref.read(snoozeRepositoryProvider).snooze`:
/// the snooze action needs to invalidate the suggestions provider so
/// the dismissed card disappears immediately. Wrapping the snooze in
/// a notifier makes the side effect explicit and lets widget tests
/// assert "tapping snooze removes the card" without timer plumbing.

/// Singleton snooze repository. `keepAlive: true` because the repo
/// itself is cheap (no state beyond the box reference) and we want
/// the same instance for the duration of the app session.
@Riverpod(keepAlive: true)
MaintenanceSnoozeRepository maintenanceSnoozeRepository(Ref ref) {
  return MaintenanceSnoozeRepository();
}

/// List of currently-active maintenance suggestions for the user.
///
/// Pipeline:
///   1. Watch the trip-history provider so a new trip retriggers the
///      analyzer.
///   2. Run [analyzeMaintenance] over the in-window trips.
///   3. Filter out signals whose snooze timestamp is in the future.
///
/// Sorting: confidence descending — the heuristic the analyzer is
/// most sure of lands first. Ties keep the analyzer's natural order
/// (idle creep before MAF deviation), which matches the order they
/// were introduced in the issue body.
@Riverpod(keepAlive: true)
List<MaintenanceSuggestion> maintenanceSuggestions(Ref ref) {
  final trips = ref.watch(tripHistoryListProvider);
  if (trips.isEmpty) return const [];
  final repo = ref.watch(maintenanceSnoozeRepositoryProvider);
  final now = DateTime.now();
  final raw = analyzeMaintenance(trips: trips, now: now);
  if (raw.isEmpty) return const [];
  final visible = <MaintenanceSuggestion>[];
  for (final suggestion in raw) {
    if (repo.isSnoozed(signal: suggestion.signal, now: now)) continue;
    visible.add(suggestion);
  }
  visible.sort((a, b) => b.confidence.compareTo(a.confidence));
  return visible;
}

/// Action surface for the maintenance card. Wraps the snooze repo
/// so widget tests can stub it via the standard Riverpod override
/// path and so a snooze invalidates [maintenanceSuggestionsProvider]
/// on the next frame.
@Riverpod(keepAlive: true)
class MaintenanceSuggestionsController
    extends _$MaintenanceSuggestionsController {
  @override
  void build() {
    // Stateless controller — Riverpod requires a `build` body even
    // for action-only notifiers. The empty body is the contract.
  }

  /// Snooze [signal] for the default 30-day window. Invalidates the
  /// suggestions provider so the dismissed card disappears on the
  /// next frame.
  Future<void> snoozeForDefault(MaintenanceSignal signal) async {
    final repo = ref.read(maintenanceSnoozeRepositoryProvider);
    try {
      await repo.snoozeForDefault(signal: signal, now: DateTime.now());
    } catch (e, st) {
      debugPrint(
          'MaintenanceSuggestionsController.snoozeForDefault(${signal.name}): $e\n$st');
    }
    ref.invalidate(maintenanceSuggestionsProvider);
  }

  /// Dismiss [signal] for a single shorter window (1 day). Tap the
  /// "Dismiss" button to silence the card for the rest of the day —
  /// the card may re-appear tomorrow if the signal is still firing,
  /// so the user gets a second chance to act on it without it being
  /// hidden for 30 days.
  Future<void> dismissForToday(MaintenanceSignal signal) async {
    final repo = ref.read(maintenanceSnoozeRepositoryProvider);
    final now = DateTime.now();
    try {
      await repo.snooze(
        signal: signal,
        until: now.add(const Duration(days: 1)),
      );
    } catch (e, st) {
      debugPrint(
          'MaintenanceSuggestionsController.dismissForToday(${signal.name}): $e\n$st');
    }
    ref.invalidate(maintenanceSuggestionsProvider);
  }
}
