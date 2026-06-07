// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../core/theme/price_band_colors.dart';
import 'cluster_badge.dart';

/// The per-marker side data the cheapest-labelled cluster builder needs to
/// roll a cluster up to its cheapest member price and detect a selected
/// member (#2939). Built alongside the marker list in [StationMapLayers].
typedef MarkerMeta = ({String id, double? price});

/// Build the "Clustered + cheapest-labelled" cluster layer used by the radar
/// split pane (#2939).
///
/// Every result set is clustered by proximity (so the narrow pane never
/// overlaps); each badge surfaces the CHEAPEST member price + a count via
/// [ClusterBadge], coloured on the shared cheap→expensive ramp, and rings in
/// brand-primary when the cluster contains a member in [selectedIds] so a
/// list-row tap still emphasises a still-clustered marker. Un-clustered
/// singletons keep their own full price pill (the badge only renders for
/// ≥2 members, per flutter_map_marker_cluster).
///
/// Extracted from [StationMapLayers] so that widget stays under the file-length
/// cap; the marker side-data is passed in via [metaOf].
Widget cheapestLabelledClusterLayer({
  required List<Marker> markers,
  required MarkerMeta? Function(Marker) metaOf,
  required (double, double) priceRange,
  required Set<String> selectedIds,
}) {
  return MarkerClusterLayerWidget(
    options: MarkerClusterLayerOptions(
      // A tighter radius than the legacy 50 px so the narrow pane fans
      // clusters apart sooner as the user zooms in.
      maxClusterRadius: 44,
      size: kClusterBadgeSize,
      markers: markers,
      builder: (context, clusterMarkers) {
        final metas = [
          for (final m in clusterMarkers)
            if (metaOf(m) != null) metaOf(m)!,
        ];
        final cheapest = ClusterBadge.cheapestOf(metas.map((e) => e.price));
        final highlight = metas.any((e) => selectedIds.contains(e.id));
        return ClusterBadge.build(
          context,
          cheapest: cheapest,
          count: clusterMarkers.length,
          minPrice: priceRange.$1,
          maxPrice: priceRange.$2,
          highlight: highlight,
        );
      },
    ),
  );
}

/// #3000 (Epic #2997) — selection-aware clustering for the ROUTE map.
///
/// PARTITIONS [markers] into the SELECTED stations (those whose [metaOf] id is
/// in [selectedIds]) and the REST, then returns two layers:
///   1. a [cheapestLabelledClusterLayer] over the UNSELECTED markers (the
///      radar grammar — proximity clusters with a cheapest badge), and
///   2. a plain [MarkerLayer] over the SELECTED markers, painted ON TOP so the
///      Best/All vivid full price pills are never hidden behind a cluster.
///
/// This keeps the route map's multi-select highlighting and its
/// `RouteBestStopsList`↔marker 1:1 mapping intact — a blanket cluster would
/// otherwise collapse several selected stations into one ringed cheapest badge.
/// The selected markers retain whatever styling [StationMapLayers] built for
/// them (the vivid selected ring + full pill); this only re-homes the
/// already-built [Marker]s into the un-clustered layer.
///
/// Extracted here (rather than inlined into [StationMapLayers]) so that widget
/// stays under its file-length snapshot.
List<Widget> selectionPartitionedClusterLayers({
  required List<Marker> markers,
  required MarkerMeta? Function(Marker) metaOf,
  required (double, double) priceRange,
  required Set<String> selectedIds,
}) {
  final unselected = <Marker>[];
  final selected = <Marker>[];
  for (final m in markers) {
    final meta = metaOf(m);
    if (meta != null && selectedIds.contains(meta.id)) {
      selected.add(m);
    } else {
      unselected.add(m);
    }
  }
  return [
    if (unselected.isNotEmpty)
      cheapestLabelledClusterLayer(
        markers: unselected,
        metaOf: metaOf,
        priceRange: priceRange,
        // The selected stations are NOT in this layer, so no cluster here can
        // contain one — pass an empty set so no badge is spuriously ringed.
        selectedIds: const <String>{},
      ),
    // Selected pills paint ON TOP of the clusters so they are never hidden.
    if (selected.isNotEmpty) MarkerLayer(markers: selected),
  ];
}

/// The count-cluster layer — the #2510 fallback for a genuinely huge non-radar
/// result set, where painting hundreds of overlapping dots would itself be
/// illegible.
///
/// #2975 — the bubble is themed onto the canonical brand price-band ramp
/// ([PriceBandColors.cheap], the forest-green leitmotiv) instead of the
/// plugin-default `colorScheme.primaryContainer`, so a count cluster reads as
/// part of the same map colour language as the cheapest-labelled clusters
/// ([ClusterBadge]), the singleton price pills and the legend. A count cluster
/// carries no per-member price (it is the "too many to label" fallback), so it
/// uses the cheap stop as a neutral brand anchor — white text + hairline +
/// the dark-mode map-overlay shadow token match the [ClusterBadge] grammar.
///
/// STATIC theming only — the builder allocates no animation and runs no
/// per-frame work, so the huge-set path stays cheap.
Widget countClusterLayer({
  required List<Marker> markers,
  required ThemeData theme,
}) {
  return MarkerClusterLayerWidget(
    options: MarkerClusterLayerOptions(
      maxClusterRadius: 50,
      markers: markers,
      builder: (context, clusterMarkers) => DecoratedBox(
        decoration: countClusterDecoration(context),
        child: Center(
          child: Text(
            '${clusterMarkers.length}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    ),
  );
}

/// The brand-themed decoration painted behind a count cluster (#2975).
///
/// Pulled out of the [countClusterLayer] builder so the theming can be
/// asserted in a unit test without forcing real marker overlap, and so the
/// builder stays a thin, allocation-light shell. The fill is the canonical
/// brand price-band [PriceBandColors.cheap] (NOT the plugin-default
/// `colorScheme.primaryContainer`), with the same white hairline + dark-mode
/// map-overlay shadow grammar as [ClusterBadge].
BoxDecoration countClusterDecoration(BuildContext context) => BoxDecoration(
      color: PriceBandColors.cheap.withValues(alpha: 0.94),
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.85),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: DarkModeColors.mapOverlayShadow(context),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
