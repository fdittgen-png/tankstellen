// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

// Pins the hardened-tile-loading defaults shipped in #2122 so a
// future TileLayer rewrite can't silently revert them. The fixes
// land on the *rendered* TileLayer, so we inspect its widget
// properties directly.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/map/data/sparkilo_tile_layer.dart';

void main() {
  testWidgets(
      'SparkiloTileLayer renders a TileLayer with the #2122 hardened defaults',
      (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(48, 2),
            initialZoom: 6,
          ),
          children: [
            SparkiloTileLayer(),
          ],
        ),
      ),
    );

    final tile = tester.widget<TileLayer>(find.byType(TileLayer));

    // #2122 — keepBuffer bumped to 4 (flutter_map default is 2) so
    // the previous level's painted tiles stay on screen while the
    // new ones fetch. Any future tweak that loosens this back below
    // 3 must update the comment + this assertion together.
    expect(tile.keepBuffer, 4,
        reason:
            '#2122 — `keepBuffer: 4` is the canonical anti-grey-tile knob.');

    // #2122 — `panBuffer` stays at the flutter_map default. The
    // upstream docs explicitly warn that raising it slows visible
    // tile fetches and adds load to OSM.
    expect(tile.panBuffer, 1,
        reason: 'panBuffer must stay at flutter_map default; raising it '
            'slows visible-tile fetches per the upstream docs.');

    // #2122 — error-tile eviction strategy stays at
    // notVisibleRespectMargin so failed tiles get re-fetched on the
    // next pan rather than caching grey forever (#757).
    expect(tile.evictErrorTileStrategy,
        EvictErrorTileStrategy.notVisibleRespectMargin,
        reason:
            'failed-tile eviction must stay tuned per #757 / #2096 / #2122.');
  });
}
