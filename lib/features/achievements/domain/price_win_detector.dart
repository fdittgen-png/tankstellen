import '../../consumption/domain/entities/fill_up.dart';
import '../../price_history/data/repositories/price_history_repository.dart';

/// Pure predicate: did this fill-up beat the station's 30-day
/// average price for the fuel type by at least [winMarginPct]? (#781)
///
/// Split out from the Riverpod layer so the engine stays
/// testable with a fake [PriceHistoryRepository] injected. The
/// engine itself receives only the resulting bool, keeping its
/// inputs to simple data.
///
/// Returns false when:
/// - The station has no recorded history yet (stats.avg is 0)
/// - The fill-up's own `pricePerLiter` is 0 (malformed entry)
/// - The fill-up carries no `stationId` (user didn't attribute it)
bool isPriceWin(
  FillUp fillUp,
  PriceHistoryRepository repo, {
  double winMarginPct = 0.05,
}) {
  final stationId = fillUp.stationId;
  if (stationId == null || stationId.isEmpty) return false;
  final paid = fillUp.pricePerLiter;
  if (paid <= 0) return false;
  final stats = repo.getStats(stationId, fillUp.fuelType, days: 30);
  final avg = stats.avg;
  if (avg == null || avg <= 0) return false;
  final margin = (avg - paid) / avg;
  return margin >= winMarginPct;
}

/// Scan [fillUps] for any entry that qualifies as a price win.
/// Short-circuits on the first win — we only need to know whether
/// the badge is earned, not how many fill-ups contributed.
bool anyPriceWin(
  Iterable<FillUp> fillUps,
  PriceHistoryRepository repo, {
  double winMarginPct = 0.05,
}) {
  for (final f in fillUps) {
    if (isPriceWin(f, repo, winMarginPct: winMarginPct)) return true;
  }
  return false;
}
