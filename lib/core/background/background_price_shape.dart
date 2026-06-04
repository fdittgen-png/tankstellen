// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../features/search/domain/entities/station.dart';
import '../constants/field_names.dart';
import '../services/station_service.dart';

/// Adapters from the country-agnostic price models ([StationPrices], [Station])
/// back to the legacy Tankerkönig-shaped `id → {status, e5, e10, diesel, …}`
/// map the per-station / velocity alert runners read today (#2862 / #2863).
///
/// Both the polled ([PolledAlertStrategy]) and bulk
/// ([BulkDatasetAlertStrategy]) strategies emit this one shape so the price
/// evaluation downstream stays untouched — making it country/currency/fuel-set
/// aware is child #2864, which can widen this shape without re-touching either
/// strategy. Every priced fuel is carried, not just E5/E10/diesel, so that
/// widening needs no upstream change.

/// Adapt a [StationPrices] (the polled `getPrices` result) to the Tankerkönig
/// shape.
Map<String, dynamic> stationPricesToTankerkoenigShape(StationPrices prices) => {
      TankerkoenigFields.status:
          prices.isOpen ? TankerkoenigFields.statusOpen : 'closed',
      TankerkoenigFields.e5: prices.e5,
      TankerkoenigFields.e10: prices.e10,
      TankerkoenigFields.diesel: prices.diesel,
      'e98': prices.e98,
      'dieselPremium': prices.dieselPremium,
      'e85': prices.e85,
      'lpg': prices.lpg,
      'cng': prices.cng,
    };

/// Adapt a priced [Station] (a bulk-dataset local-filter result) to the
/// Tankerkönig shape, so a [BulkDatasetAlertStrategy] can answer per-station
/// price alerts from its cached whole-country dataset — the bulk primaries'
/// `getPrices` returns empty by design (prices live on the dataset rows the
/// search emits, not behind a per-station endpoint).
Map<String, dynamic> stationToTankerkoenigShape(Station station) => {
      TankerkoenigFields.status:
          station.isOpen ? TankerkoenigFields.statusOpen : 'closed',
      TankerkoenigFields.e5: station.e5,
      TankerkoenigFields.e10: station.e10,
      TankerkoenigFields.diesel: station.diesel,
      'e98': station.e98,
      'dieselPremium': station.dieselPremium,
      'e85': station.e85,
      'lpg': station.lpg,
      'cng': station.cng,
    };
