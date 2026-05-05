import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'broken_map_warned_vehicles_provider.g.dart';

/// In-memory set of vehicle ids for which the
/// `brokenMapSnackbarUnreliable` warning has already fired this app
/// session (#1423 phase 5).
///
/// Lives only for the lifetime of the [ProviderContainer]: a fresh app
/// launch (or pulling down to "Discard data" in the privacy dashboard
/// which disposes the container) replays a single warning per vehicle
/// once the belief crosses the 0.7 threshold again.
///
/// Intentionally NOT persisted: the spec says "fire ONCE per session
/// per vehicle when crossing into this band", and persisting would
/// silently swallow the warning forever after the user dismissed it
/// once — a regression we'd never know about. A weekly relapse on
/// a flaky adapter is the desired UX.
@Riverpod(keepAlive: true)
class BrokenMapWarnedVehicles extends _$BrokenMapWarnedVehicles {
  @override
  Set<String> build() => <String>{};

  /// Returns true when [vehicleId] has not yet been warned this
  /// session and atomically marks it as warned. Mirrors a check-then-
  /// set guard so the snackbar listener can stay a one-liner.
  bool markIfFirst(String vehicleId) {
    if (state.contains(vehicleId)) return false;
    state = <String>{...state, vehicleId};
    return true;
  }

  /// Drop [vehicleId] from the warned set so a subsequent cross of
  /// the 0.7 threshold fires the snackbar again. Used when the user
  /// switches to a different adapter (or by tests rehearsing the
  /// cross-then-cross-again sequence).
  void clear(String vehicleId) {
    if (!state.contains(vehicleId)) return;
    final next = <String>{...state}..remove(vehicleId);
    state = next;
  }
}
