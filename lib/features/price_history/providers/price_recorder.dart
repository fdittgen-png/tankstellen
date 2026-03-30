import 'package:flutter/foundation.dart';
import '../../search/domain/entities/station.dart';
import '../data/models/price_record.dart';
import '../data/repositories/price_history_repository.dart';

/// Call after a successful station search to record price snapshots.
///
/// Creates a [PriceRecord] for each station and persists it via the
/// repository. Deduplication (within 1 hour) is handled by the repository.
void recordSearchResults(
    List<Station> stations, PriceHistoryRepository repo) {
  for (final station in stations) {
    try {
      final record = PriceRecord(
        stationId: station.id,
        recordedAt: DateTime.now(),
        e5: station.e5,
        e10: station.e10,
        e98: station.e98,
        diesel: station.diesel,
        dieselPremium: station.dieselPremium,
        e85: station.e85,
        lpg: station.lpg,
        cng: station.cng,
      );
      repo.recordPrice(record);
    } catch (e) { debugPrint('Silent catch: ');
      // Skip individual failures; don't abort remaining records
    }
  }
}
