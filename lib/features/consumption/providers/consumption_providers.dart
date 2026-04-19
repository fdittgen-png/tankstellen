import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../data/repositories/fill_up_repository.dart';
import '../domain/entities/consumption_stats.dart';
import '../domain/entities/eco_score.dart';
import '../domain/entities/fill_up.dart';
import '../domain/services/eco_score_calculator.dart';

part 'consumption_providers.g.dart';

/// Repository for reading/writing [FillUp] entries.
@Riverpod(keepAlive: true)
FillUpRepository fillUpRepository(Ref ref) {
  final storage = ref.watch(settingsStorageProvider);
  return FillUpRepository(storage);
}

/// Mutable list of all fill-ups, newest first.
@Riverpod(keepAlive: true)
class FillUpList extends _$FillUpList {
  @override
  List<FillUp> build() {
    final repo = ref.watch(fillUpRepositoryProvider);
    return repo.getAll();
  }

  /// Insert a new fill-up entry and refresh the list.
  Future<void> add(FillUp fillUp) async {
    final repo = ref.read(fillUpRepositoryProvider);
    await repo.save(fillUp);
    state = repo.getAll();
  }

  /// Persist edits to an existing fill-up (matched by id) and refresh.
  Future<void> update(FillUp fillUp) async {
    final repo = ref.read(fillUpRepositoryProvider);
    await repo.save(fillUp);
    state = repo.getAll();
  }

  /// Delete the fill-up with the given [id] and refresh the list.
  Future<void> remove(String id) async {
    final repo = ref.read(fillUpRepositoryProvider);
    await repo.delete(id);
    state = repo.getAll();
  }

  /// Wipe the entire fill-up history. Used by the privacy dashboard.
  Future<void> clearAll() async {
    final repo = ref.read(fillUpRepositoryProvider);
    await repo.clear();
    state = repo.getAll();
  }

  /// Merge [incoming] fill-ups into local storage. Existing ids are
  /// overwritten; new ids are added. Returns the number of new entries
  /// actually inserted. Used by the device-linking flow (#713).
  Future<int> mergeFrom(Iterable<FillUp> incoming) async {
    final repo = ref.read(fillUpRepositoryProvider);
    final localIds = repo.getAll().map((f) => f.id).toSet();
    var added = 0;
    for (final f in incoming) {
      if (!localIds.contains(f.id)) added++;
      await repo.save(f);
    }
    state = repo.getAll();
    return added;
  }
}

/// Aggregated stats derived from the current fill-up list.
@riverpod
ConsumptionStats consumptionStats(Ref ref) {
  final fillUps = ref.watch(fillUpListProvider);
  return ConsumptionStats.fromFillUps(fillUps);
}

/// Per-fill-up eco-score — compares this tank's L/100 km to the
/// rolling average over the last 3 same-fuel-type fill-ups.
///
/// Returns `null` for fill-ups where the score is not meaningful
/// (first-ever fill-up, odometer rollback, no same-fuel history).
/// Callers render nothing when the return is null.
///
/// Keyed by fill-up id so the Riverpod graph invalidates just the
/// affected card when a single fill-up is edited, not the whole list.
/// See #676 and the project leitmotiv in CLAUDE.md.
@riverpod
EcoScore? ecoScoreForFillUp(Ref ref, String fillUpId) {
  final fillUps = ref.watch(fillUpListProvider);
  final current = fillUps.where((f) => f.id == fillUpId).firstOrNull;
  if (current == null) return null;
  return EcoScoreCalculator.compute(
    current: current,
    history: fillUps,
  );
}
