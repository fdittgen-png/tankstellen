// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../search/domain/entities/brand_registry.dart';
import '../../../search/domain/entities/station.dart';

/// True when the station has a real, displayable brand — i.e. not
/// empty and not one of the sentinel strings that parsers use when
/// they cannot detect a brand (`'Station'` is the legacy sentinel,
/// `BrandRegistry.independentLabel` is the new one from #482). Used
/// everywhere the detail screen decides whether to render the brand
/// text or fall back to the street address as the title.
bool hasRealBrand(Station s) {
  if (s.brand.isEmpty) return false;
  if (s.brand == 'Station') return false;
  if (s.brand == BrandRegistry.independentLabel) return false;
  return true;
}

/// True when the station's brand is the explicit "independent" sentinel
/// (or the legacy `'Station'` value). The detail view uses this to
/// render a localised "Station indépendante" subtitle so users can tell
/// the difference between a genuine independent and a brand-detection
/// bug (#482).
bool isIndependentSentinel(Station s) =>
    s.brand == BrandRegistry.independentLabel || s.brand == 'Station';

/// The bold heading shown at the top of the station-detail body.
///
/// #2161 — French stations from the official `prix-carburants.gouv.fr`
/// feed often carry no `brand`, but their `name` is populated (e.g.
/// `"Intermarché"` arrives via `Station.name`, not `Station.brand`).
/// The home-screen widget already shows the name in that case
/// (`nearest_widget_data_builder` line 279 has the same fallback) —
/// the detail header has to match, otherwise a widget cold-launch
/// renders the street in bold and the name disappears.
String stationDisplayHeading(Station s) {
  if (hasRealBrand(s)) return s.brand;
  final name = s.name.trim();
  if (name.isNotEmpty) return name;
  return s.street;
}
