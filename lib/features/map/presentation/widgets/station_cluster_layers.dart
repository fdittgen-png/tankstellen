// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

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

/// The legacy bare count-cluster layer — the #2510 fallback for a genuinely
/// huge non-radar result set, where painting hundreds of overlapping dots
/// would itself be illegible. Unchanged from the pre-#2939 inline builder.
Widget countClusterLayer({
  required List<Marker> markers,
  required ThemeData theme,
}) {
  return MarkerClusterLayerWidget(
    options: MarkerClusterLayerOptions(
      maxClusterRadius: 50,
      markers: markers,
      builder: (context, clusterMarkers) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${clusterMarkers.length}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ),
  );
}
