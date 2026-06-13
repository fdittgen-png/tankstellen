// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/domain/fuel_type.dart';
import '../../../../core/domain/station.dart';
import '../../../../core/utils/price_utils.dart';
import 'station_cluster_layers.dart';
import 'station_map_geometry.dart';
import 'station_marker.dart';

/// The memoised marker model [StationMapLayers] paints: the ordered [Marker]
/// list, the per-marker [MarkerMeta] (price + station id, keyed by marker
/// identity so the cluster badge can roll up to the cheapest member), and the
/// selected-fuel price range the colour scale uses.
typedef StationMarkerModel = ({
  List<Marker> markers,
  Map<Marker, MarkerMeta> meta,
  (double, double) priceRange,
});

/// #3233 — the pure marker-model builder extracted out of
/// `_StationMapLayersState._recomputeMarkers`, so the widget memoises by
/// calling this instead of carrying the ~70-line price/emphasis/order/build
/// pipeline inline. No widget state, no side effects: same inputs → same model.
class StationMarkerModelBuilder {
  const StationMarkerModelBuilder._();

  /// Compute the [StationMarkerModel] from the current map inputs.
  ///
  /// Mirrors the list's strict per-fuel pricing: a station without the
  /// selected fuel paints grey ("--") rather than being re-coloured by a
  /// fallback fuel (#2510); when a cross-border [fuelResolver] is set each
  /// station is priced for ITS country fuel and the colour range is computed
  /// over those resolved prices (#2631).
  static StationMarkerModel build({
    required BuildContext context,
    required List<Station> stations,
    required FuelType selectedFuel,
    required Set<String>? selectedStationIds,
    required bool byPrice,
    required bool clusterAlways,
    required FuelType Function(Station)? fuelResolver,
    required void Function(String stationId)? onStationTap,
    required StationMarkerVariant markerVariant,
  }) {
    final resolver = fuelResolver;
    final priceRangeValue = resolver == null
        ? priceRange(stations, selectedFuel)
        : resolvedPriceRangeWith(stations, resolver);
    final ids = selectedStationIds;
    final hasSelection = ids != null && ids.isNotEmpty;

    // #2510 — emphasis: the top-ranked stations per the active sort (cheapest
    // for a price sort, closest otherwise) keep the full price bubble; the rest
    // render as compact price-band dots so a bounded result set stays fully
    // visible without the bubbles overlapping into an illegible pile. The set
    // is small, so a Set lookup is cheap.
    final emphasized = StationMapGeometry.rankForEmphasis(
      stations,
      selectedFuel,
      byPrice: byPrice,
    ).take(StationMapGeometry.emphasisCount).map((s) => s.id).toSet();

    // #2434 — order so the cheapest (green) marker paints ON TOP of the
    // more-expensive ones it overlaps. The marker layer paints in source-list
    // order (later = on top), so we sort price-descending: expensive at the
    // bottom, cheapest last/on top, price-less markers beneath everything.
    final ordered = StationMapGeometry.orderedByPriceForPainting(
      stations,
      selectedFuel,
      fuelResolver: resolver,
    );

    // #2974 — a marker tap that selects its list row also fires a selection
    // tick (selectionClick only). Null on the default push-to-detail map → no
    // haptic; the route push owns its own feedback.
    final onTap = onStationTap == null
        ? null
        : (String id) {
            unawaited(HapticFeedback.selectionClick());
            onStationTap(id);
          };

    final meta = <Marker, MarkerMeta>{};
    final markers = ordered.map((station) {
      final isPastel = hasSelection && !ids.contains(station.id);
      final isSelected = hasSelection && ids.contains(station.id);
      final marker = StationMarkerBuilder.build(
        context,
        station,
        selectedFuel,
        priceRangeValue.$1,
        priceRangeValue.$2,
        pastel: isPastel,
        // #2939 — in clusterAlways mode the clustering de-overlaps the pane, so
        // a SINGLETON keeps its full price pill (never a dot); only clustered
        // members roll up. The emphasis-dot scheme stays for non-clustered
        // surfaces.
        compact: !clusterAlways && !emphasized.contains(station.id),
        selected: isSelected,
        onTap: onTap == null ? null : () => onTap(station.id),
        fuelResolver: resolver,
        variant: markerVariant,
      );
      meta[marker] = (
        id: station.id,
        price: priceForFuelType(
            station, resolver != null ? resolver(station) : selectedFuel),
      );
      return marker;
    }).toList();

    return (markers: markers, meta: meta, priceRange: priceRangeValue);
  }
}
