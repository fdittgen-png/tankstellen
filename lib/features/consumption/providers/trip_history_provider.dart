import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/hive_boxes.dart';
import '../data/trip_history_repository.dart';

part 'trip_history_provider.g.dart';

/// App-wide access to the [TripHistoryRepository] (#726).
///
/// Returns null when the underlying Hive box isn't open — widget
/// tests that don't bother initialising Hive get a silent no-op
/// instead of a thrown error from the UI.
@Riverpod(keepAlive: true)
TripHistoryRepository? tripHistoryRepository(Ref ref) {
  if (!Hive.isBoxOpen(HiveBoxes.obd2TripHistory)) return null;
  return TripHistoryRepository(
    box: Hive.box<String>(HiveBoxes.obd2TripHistory),
  );
}

/// List of finalised trips, newest-first. Empty when the box is
/// closed or carries no entries. Refreshed by callers after they
/// save a new trip via [TripHistoryListNotifier.refresh].
@Riverpod(keepAlive: true)
class TripHistoryList extends _$TripHistoryList {
  @override
  List<TripHistoryEntry> build() {
    final repo = ref.watch(tripHistoryRepositoryProvider);
    if (repo == null) return const [];
    return repo.loadAll();
  }

  /// Re-read the Hive box. Called by [TripRecording.stop] after a
  /// save so the UI picks up the new entry without waiting for a
  /// rebuild trigger.
  void refresh() {
    final repo = ref.read(tripHistoryRepositoryProvider);
    if (repo == null) return;
    state = repo.loadAll();
  }

  /// Delete one trip and refresh the list. Exposed so the history
  /// card can support a swipe-to-delete the way the fill-up list
  /// already does.
  Future<void> delete(String id) async {
    final repo = ref.read(tripHistoryRepositoryProvider);
    if (repo == null) return;
    await repo.delete(id);
    state = repo.loadAll();
  }
}
