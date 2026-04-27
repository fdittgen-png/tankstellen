import '../entities/fill_up.dart';
import '../../data/trip_history_repository.dart';

/// Estimates the monetary cost of the fuel consumed on a trip (#1209).
///
/// Uses the price-per-litre from the most recent fill-up to the
/// vehicle's tank that occurred on or before the trip's start. The
/// price is read from [FillUpX.pricePerLiter] (`totalCost / liters`)
/// in the active country's currency, so the returned cost is in the
/// same major-unit currency. Multiplied by [TripSummary.fuelLitersConsumed]
/// to land at a directly-comparable euro / pound / kroner figure.
///
/// Returns `null` when:
/// * the trip has no `fuelLitersConsumed` recorded,
/// * the trip has no `startedAt`,
/// * no eligible fill-up has a usable `pricePerLiter` (zero or no
///   litres recorded — `FillUpX.pricePerLiter` falls back to `0` in
///   that case, which we treat as "no price" so the row stays hidden
///   rather than showing a misleading `0,00 €`).
///
/// [fillUpsForVehicle] is expected newest-first (matches the order
/// produced by `FillUpRepository`). The function walks the list and
/// returns the cost from the first fill-up that satisfies the date
/// and price-validity gates.
double? estimateTripFuelCost({
  required TripHistoryEntry trip,
  required List<FillUp> fillUpsForVehicle,
}) {
  final fuelL = trip.summary.fuelLitersConsumed;
  if (fuelL == null) return null;
  final start = trip.summary.startedAt;
  if (start == null) return null;
  for (final f in fillUpsForVehicle) {
    if (f.date.isAfter(start)) continue;
    final p = f.pricePerLiter;
    // pricePerLiter is `totalCost / liters` and falls back to 0 when
    // liters == 0 — treat zero as "no usable price" so the trip
    // detail row simply hides instead of rendering a misleading 0.
    if (p <= 0) continue;
    return fuelL * p;
  }
  return null;
}
