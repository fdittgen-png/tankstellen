import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/storage_providers.dart';
import '../data/repositories/fill_up_repository.dart';
import '../domain/entities/consumption_stats.dart';
import '../domain/entities/fill_up.dart';

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

  Future<void> add(FillUp fillUp) async {
    final repo = ref.read(fillUpRepositoryProvider);
    await repo.save(fillUp);
    state = repo.getAll();
  }

  Future<void> update(FillUp fillUp) async {
    final repo = ref.read(fillUpRepositoryProvider);
    await repo.save(fillUp);
    state = repo.getAll();
  }

  Future<void> remove(String id) async {
    final repo = ref.read(fillUpRepositoryProvider);
    await repo.delete(id);
    state = repo.getAll();
  }

  Future<void> clearAll() async {
    final repo = ref.read(fillUpRepositoryProvider);
    await repo.clear();
    state = repo.getAll();
  }
}

/// Aggregated stats derived from the current fill-up list.
@riverpod
ConsumptionStats consumptionStats(Ref ref) {
  final fillUps = ref.watch(fillUpListProvider);
  return ConsumptionStats.fromFillUps(fillUps);
}
