import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/storage/hive_storage.dart';
import '../../search/domain/entities/fuel_type.dart';
import '../data/models/price_record.dart';
import '../data/repositories/price_history_repository.dart';

part 'price_history_provider.g.dart';

@Riverpod(keepAlive: true)
PriceHistoryRepository priceHistoryRepository(Ref ref) {
  return PriceHistoryRepository(ref.watch(hiveStorageProvider));
}

@riverpod
List<PriceRecord> priceHistory(Ref ref, String stationId, {int days = 30}) {
  final repo = ref.watch(priceHistoryRepositoryProvider);
  return repo.getHistory(stationId, days: days);
}

@riverpod
PriceStats priceStats(Ref ref, String stationId, FuelType fuelType) {
  final repo = ref.watch(priceHistoryRepositoryProvider);
  return repo.getStats(stationId, fuelType);
}
