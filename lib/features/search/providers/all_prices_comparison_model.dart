// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Pure model + maths behind the all-prices fuel COMPARISON TABLE (#3933,
/// Epic #3925).
///
/// No Riverpod, no Flutter — drive every function here directly from a
/// unit test. The Riverpod seams that feed it live in
/// `all_prices_table_provider.dart`; the widgets that render it live in
/// `presentation/widgets/all_prices/`.
///
/// The view this backs answers a question the compact list cannot: *which
/// fuel, at which station, actually costs me least per 100 km*. That means
/// the table has to be scannable **vertically**, so the column set is
/// computed ONCE for the whole result set (country + vehicle + the best
/// price per fuel — all card-independent inputs) and every card renders
/// exactly those columns in exactly that order, an empty cell where the
/// station lacks the fuel. Nothing here depends on the individual station,
/// which is what makes the columns line up.
library;

import '../../../core/domain/fuel_type.dart';
import '../../../core/domain/station.dart';
import '../../../core/utils/station_extensions.dart';

/// Canonical column ORDER — the one place the left-to-right order of the
/// table is decided. Stable across countries and cards: a fuel that is
/// shown always sits in this relative position, so the eye can scan a
/// column down the list.
///
/// Electric / hydrogen / the `all` wildcard are deliberately absent: the
/// all-prices card is the liquid-fuel price table, EV rows have their own
/// card.
const List<FuelType> kAllPricesFuelOrder = <FuelType>[
  FuelType.e5,
  FuelType.e10,
  FuelType.e98,
  FuelType.diesel,
  FuelType.dieselPremium,
  FuelType.e85,
  FuelType.lpg,
  FuelType.cng,
];

/// How many columns fit the card at the narrowest supported width.
///
/// The card body is 320 dp minus the shell's 8 dp side margins and the
/// 12 dp body padding = 280 dp. A cell has to hold a three-decimal price
/// (`1,839`), a signed delta and a money figure, which needs ~66 dp at a
/// 1.3x text scale — four columns and no more. France alone supplies six
/// liquid grades, so the overflow rule below is not hypothetical.
const int kAllPricesMaxColumns = 4;

/// The column set for the whole result list: [visible] renders as the
/// aligned grid on every card, [overflow] hides behind the per-card
/// "＋n" expander.
class AllPricesColumns {
  final List<FuelType> visible;
  final List<FuelType> overflow;

  const AllPricesColumns({
    this.visible = const <FuelType>[],
    this.overflow = const <FuelType>[],
  });

  /// No country fuels resolved yet — the card falls back to whatever the
  /// station itself prices.
  static const empty = AllPricesColumns();

  bool get isEmpty => visible.isEmpty && overflow.isEmpty;

  /// Every column, visible first — the set the per-station verdict is
  /// computed over (an overflow fuel may still be the cheapest here).
  List<FuelType> get all => <FuelType>[...visible, ...overflow];
}

/// Decide which of the active country's fuels get a column.
///
/// * [countryFuels] — `CountryConfig.supportedFuelTypes`, intersected with
///   [kAllPricesFuelOrder] so EV / wildcard entries drop out.
/// * [vehicleFuels] — what the active vehicle can physically be filled
///   with. Empty means "no vehicle" — then no fuel is privileged.
/// * [bestByFuel] — cheapest price per fuel across the current result set;
///   used only to rank the non-vehicle fuels when the country has more
///   grades than fit.
///
/// Rule when the candidates exceed [maxColumns]: keep every
/// vehicle-usable fuel first, then fill the remaining slots with the
/// CHEAPEST of the others (unpriced fuels last), then restore the
/// canonical order so the columns still read left to right the same way
/// on every card. Everything left over goes to [AllPricesColumns.overflow].
AllPricesColumns selectFuelColumns({
  required Set<FuelType> countryFuels,
  required Set<FuelType> vehicleFuels,
  required Map<FuelType, double> bestByFuel,
  int maxColumns = kAllPricesMaxColumns,
}) {
  final candidates = kAllPricesFuelOrder
      .where((f) => countryFuels.contains(f))
      .toList(growable: false);
  if (candidates.isEmpty) return AllPricesColumns.empty;
  if (candidates.length <= maxColumns) {
    return AllPricesColumns(visible: candidates);
  }

  final kept = <FuelType>{
    ...candidates.where(vehicleFuels.contains).take(maxColumns),
  };

  if (kept.length < maxColumns) {
    final rest = candidates.where((f) => !kept.contains(f)).toList()
      ..sort((a, b) {
        final pa = bestByFuel[a];
        final pb = bestByFuel[b];
        if (pa == null && pb == null) {
          return kAllPricesFuelOrder
              .indexOf(a)
              .compareTo(kAllPricesFuelOrder.indexOf(b));
        }
        if (pa == null) return 1;
        if (pb == null) return -1;
        return pa.compareTo(pb);
      });
    for (final f in rest) {
      if (kept.length >= maxColumns) break;
      kept.add(f);
    }
  }

  return AllPricesColumns(
    visible: candidates.where(kept.contains).toList(growable: false),
    overflow: candidates.where((f) => !kept.contains(f)).toList(
          growable: false,
        ),
  );
}

/// One table cell: everything the widget needs to paint it, already
/// resolved. `price == null && !isUnavailable` is the EMPTY cell — the
/// station simply does not sell that fuel, and the column still holds
/// its slot so nothing reflows.
class FuelCellData {
  final FuelType fuel;

  /// Language-neutral grade label (`E10`, or the PEMEX name in Mexico).
  final String label;

  final double? price;

  /// The station explicitly reports this fuel as out of stock.
  final bool isUnavailable;

  /// This price is the cheapest for its fuel across the current results.
  final bool isBestInResults;

  /// `price - best` for this fuel across the results. Null when there is
  /// no price or no reference. Zero on the best cell.
  final double? deltaToBest;

  /// Price x the vehicle's measured litres/100 km for this fuel, i.e.
  /// what 100 km on this fuel costs at this pump. Null whenever the
  /// vehicle cannot take the fuel, has no measured consumption for it,
  /// or the station has no price.
  final double? costPer100km;

  /// The measured litres/100 km behind [costPer100km] (for the semantics
  /// label). Null under the same conditions.
  final double? litersPer100km;

  /// False when the active vehicle cannot be filled with this fuel — the
  /// cell renders dimmed. Always true when there is no active vehicle.
  final bool isUsable;

  const FuelCellData({
    required this.fuel,
    required this.label,
    required this.price,
    this.isUnavailable = false,
    this.isBestInResults = false,
    this.deltaToBest,
    this.costPer100km,
    this.litersPer100km,
    this.isUsable = true,
  });

  /// True when the cell has nothing to say — no price and not flagged
  /// out of stock. It still occupies its column.
  bool get isBlank => price == null && !isUnavailable;
}

/// One station's row of the table plus its verdict.
class StationFuelComparison {
  /// One entry per [AllPricesColumns.visible], in order.
  final List<FuelCellData> cells;

  /// One entry per [AllPricesColumns.overflow], in order.
  final List<FuelCellData> overflowCells;

  /// The fuel that costs least per 100 km AT THIS STATION. Null when no
  /// cell carries a [FuelCellData.costPer100km] (no vehicle, or no
  /// consumption history yet) — the verdict line then disappears.
  final FuelType? verdictFuel;

  /// [verdictFuel]'s cost per 100 km here.
  final double? verdictCostPer100km;

  /// True when [verdictFuel]'s price at this station is also the cheapest
  /// for that fuel across the whole result set — the station wins outright.
  final bool winsResults;

  const StationFuelComparison({
    this.cells = const <FuelCellData>[],
    this.overflowCells = const <FuelCellData>[],
    this.verdictFuel,
    this.verdictCostPer100km,
    this.winsResults = false,
  });

  bool get hasVerdict => verdictFuel != null && verdictCostPer100km != null;
}

/// Build one station's row.
///
/// [bestByFuel] is the cheapest price per fuel across the visible result
/// set; [litersPer100kmByFuel] the vehicle's measured consumption per fuel
/// (empty = degrade to a price-only table); [usableFuels] what the vehicle
/// can take (empty = no vehicle, nothing dimmed).
StationFuelComparison buildStationComparison({
  required Station station,
  required AllPricesColumns columns,
  required Map<FuelType, double> bestByFuel,
  Map<FuelType, double> litersPer100kmByFuel = const <FuelType, double>{},
  Set<FuelType> usableFuels = const <FuelType>{},
  String? countryCode,
}) {
  FuelCellData cellFor(FuelType fuel) {
    final price = station.priceFor(fuel);
    final unavailable = station.unavailableFuels.contains(fuel.apiValue);
    final usable = usableFuels.isEmpty || usableFuels.contains(fuel);
    final best = bestByFuel[fuel];
    final l100 = usable ? litersPer100kmByFuel[fuel] : null;
    final hasPrice = price != null && price > 0 && !unavailable;
    return FuelCellData(
      fuel: fuel,
      label: fuelDisplayLabel(fuel, countryCode: countryCode),
      price: price,
      isUnavailable: unavailable,
      isBestInResults: hasPrice && best != null && price <= best,
      deltaToBest: hasPrice && best != null ? price - best : null,
      costPer100km:
          hasPrice && l100 != null && l100 > 0 ? price * l100 : null,
      litersPer100km: hasPrice && l100 != null && l100 > 0 ? l100 : null,
      isUsable: usable,
    );
  }

  final cells = columns.visible.map(cellFor).toList(growable: false);
  final overflow = columns.overflow.map(cellFor).toList(growable: false);

  FuelCellData? winner;
  for (final c in <FuelCellData>[...cells, ...overflow]) {
    final cost = c.costPer100km;
    if (cost == null) continue;
    if (winner == null || cost < winner.costPer100km!) winner = c;
  }

  return StationFuelComparison(
    cells: cells,
    overflowCells: overflow,
    verdictFuel: winner?.fuel,
    verdictCostPer100km: winner?.costPer100km,
    winsResults: winner?.isBestInResults ?? false,
  );
}

/// Cheapest price per fuel across [stations] — the reference every cell's
/// delta and every "cheapest of the results" emphasis is measured against.
Map<FuelType, double> bestPriceByFuel(Iterable<Station> stations) {
  final best = <FuelType, double>{};
  for (final s in stations) {
    for (final fuel in kAllPricesFuelOrder) {
      if (s.unavailableFuels.contains(fuel.apiValue)) continue;
      final price = s.priceFor(fuel);
      if (price == null || price <= 0) continue;
      final current = best[fuel];
      if (current == null || price < current) best[fuel] = price;
    }
  }
  return best;
}
