// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../core/domain/ev/charging_station.dart';

/// Enriches a list of [ChargingStation]s with a country-authoritative
/// price/access signal where one is freely available (#2618).
///
/// Plug-in seam (not an inline `if (country == 'FR')` in shared code):
/// the EV search provider always calls [enrich]; the default
/// implementation is a no-op, and country-specific enrichers (currently
/// only [FrIrvePriceService] for France) layer their signal on top. This
/// keeps the cross-border case correct — a German user searching near
/// the FR border still gets FR rows enriched — and keeps the search
/// provider free of country branching.
abstract interface class EvPriceEnricher {
  /// Returns [stations] augmented with any freely-available authoritative
  /// price/access signal. MUST be graceful: a network/parse failure
  /// returns the input unchanged (logged, never thrown) so EV search is
  /// never blocked by the enrichment.
  Future<List<ChargingStation>> enrich(List<ChargingStation> stations);
}

/// The default enricher — returns stations unchanged. Used everywhere a
/// country-specific enricher does not apply.
class NoopEvPriceEnricher implements EvPriceEnricher {
  const NoopEvPriceEnricher();

  @override
  Future<List<ChargingStation>> enrich(List<ChargingStation> stations) async =>
      stations;
}
