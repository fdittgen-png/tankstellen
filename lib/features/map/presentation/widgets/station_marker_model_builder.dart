// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/domain/fuel_type.dart';
import '../../../../core/perf/perf_budgets.dart';
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

  /// How many stations inside the CURRENT VIEW got no marker because the
  /// relevance cap bit (#4181) — zero in every ordinary result.
  ///
  /// Deliberately not the same as "stations handed in minus markers
  /// built": a station culled for being off-screen is not an omission
  /// the user needs told about, and counting it here would put a
  /// permanent "showing a subset" pill on every zoomed-in map. This
  /// counts only the real loss — a station the user is looking at that
  /// has no marker, and whose absence makes a cluster badge count fewer
  /// members than exist.
  int omittedCount,
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
    LatLngBounds? cameraBounds,
  }) {
    final resolver = fuelResolver;
    // #2434/#2631 — the colour scale spans the FULL handed-in set, not
    // the bounded one. A station must not change colour because the user
    // panned; the scale describes the search, the markers describe the
    // view.
    final priceRangeValue = resolver == null
        ? priceRange(stations, selectedFuel)
        : resolvedPriceRangeWith(stations, resolver);
    final ids = selectedStationIds;
    final hasSelection = ids != null && ids.isNotEmpty;

    // #4181 — bound the input BEFORE building anything. Nothing used to:
    // `clusterAlways: true` means every marker is constructed even when
    // it collapses into a cluster badge, and the only limit on the count
    // was however many stations a 25 km search returned.
    //
    // Two steps, in this order, because they answer different questions:
    //
    //  1. cull to the camera plus a screen of margin — drops only what
    //     the user cannot see, so a zoomed-in map is bounded by its
    //     viewport rather than by the search;
    //  2. then cap what is left by relevance, which is what actually
    //     makes [kMapMarkerBudget] a derived bound instead of a guard.
    //     It can only bite when more than the cap share ONE viewport —
    //     a zoomed-out view where clustering has already collapsed
    //     every marker into a badge.
    //
    // Step 2 is a real loss of information (a cluster badge then counts
    // fewer members than exist), which is why the model reports
    // `omittedCount` and the map says so rather than quietly drawing a
    // smaller world.
    // Below the cap there is nothing to bound, so neither step runs and
    // the map behaves exactly as it did — including not rebuilding on
    // pan. That is deliberate: every existing map is under the cap, and
    // a fix for an unbounded count must not make the bounded case worse.
    final cap = kMapMarkerBudget.limit!.toInt();
    final visible = stations.length <= cap
        ? stations
        : StationMapGeometry.withinCameraBounds(stations, cameraBounds);
    final bounded = StationMapGeometry.capByRelevance(
      visible,
      selectedFuel,
      cap: cap,
      byPrice: byPrice,
      selectedIds: ids,
    );

    // #2510 — emphasis: the top-ranked stations per the active sort (cheapest
    // for a price sort, closest otherwise) keep the full price bubble; the rest
    // render as compact price-band dots so a bounded result set stays fully
    // visible without the bubbles overlapping into an illegible pile. The set
    // is small, so a Set lookup is cheap.
    final emphasized = StationMapGeometry.rankForEmphasis(
      bounded,
      selectedFuel,
      byPrice: byPrice,
    ).take(StationMapGeometry.emphasisCount).map((s) => s.id).toSet();

    // #2434 — order so the cheapest (green) marker paints ON TOP of the
    // more-expensive ones it overlaps. The marker layer paints in source-list
    // order (later = on top), so we sort price-descending: expensive at the
    // bottom, cheapest last/on top, price-less markers beneath everything.
    final ordered = StationMapGeometry.orderedByPriceForPainting(
      bounded,
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

    return (
      markers: markers,
      meta: meta,
      priceRange: priceRangeValue,
      omittedCount: visible.length - bounded.length,
    );
  }
}
