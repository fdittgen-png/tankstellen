// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Lint-style guard (#2096) — fails when any new `TileLayer(`
/// constructor call lands in `lib/` outside the allowlisted call
/// sites that go through `SparkiloTileLayer` or own its lifecycle.
///
/// Background: the grey-map bug came back five times (#757 → #1234
/// → #1316 → #1991 → #2044) because each "fix" patched the main map
/// in isolation while 6 other TileLayer call sites kept using the
/// default `NetworkTileProvider`. The default provider has no
/// retry on transient HTTP errors, no cancellation handling on
/// flutter_map's viewport-abort, and no cold-start reset hook —
/// any of which produces a permanently-grey tile.
///
/// This test makes the architectural rule mechanical: every new
/// `TileLayer(` either belongs in `SparkiloTileLayer`'s build
/// method (the wrapper itself), in `StationMapLayers`' inline
/// setup (the main map needs cold-start event-stream wiring and
/// owns its own provider in state), or it's a regression.
void main() {
  test(
    'every TileLayer in lib/ goes through SparkiloTileLayer or is allowlisted (#2096)',
    () {
      // Allowlist — the SINGLE place a raw TileLayer is allowed
      // (#2398). `station_map_layers.dart` was removed from the
      // allowlist once its parallel inline TileLayer + cold-start
      // reset machinery was deleted and it routed through
      // SparkiloTileLayer. The parallel-TileLayer regression that
      // caused the recurring grey-tile bug cannot recur: any new
      // raw `TileLayer(` outside the wrapper fails this lint.
      const allowlist = <String>{
        // The hardened wrapper itself — the ONE place a raw
        // TileLayer is allowed.
        'lib/features/map/data/sparkilo_tile_layer.dart',
      };

      final offenders = <String>[];
      final lib = Directory('lib');
      for (final entity in lib.listSync(recursive: true)) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('.g.dart') ||
            entity.path.endsWith('.freezed.dart')) {
          continue;
        }
        final rel = entity.path;
        if (allowlist.contains(rel)) continue;
        final text = entity.readAsStringSync();
        // Look for the constructor call specifically. `MapTileLayer`
        // / `_TileLayer` etc. are false positives we accept — the
        // bug is the raw constructor.
        // #2098 — also match `TileLayer.new(` (Dart 2.15+
        // constructor tear-off form). Without the `\.new?` branch a
        // developer using modern Dart syntax could reintroduce the
        // unhardened default `NetworkTileProvider` without the lint
        // firing.
        final regex = RegExp(r'\bTileLayer(\.new)?\s*\(');
        if (regex.hasMatch(text)) {
          offenders.add(rel);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Found `TileLayer(` outside the allowlist. The grey-map bug '
            'regresses every time a new map surface ships with the '
            'default `NetworkTileProvider`. Replace with '
            '`SparkiloTileLayer(...)` from '
            '`lib/features/map/data/sparkilo_tile_layer.dart` — or, if '
            'this site genuinely needs its own provider lifecycle '
            '(cold-start hook, etc.), add it to the allowlist in this '
            'test with a short rationale and a TODO link to the '
            'follow-up that folds it into the wrapper.\n\n'
            'Offenders:\n${offenders.map((p) => '  $p').join('\n')}',
      );
    },
  );

  test(
    '.new constructor tear-off does not bypass the consistency lint (#2098)',
    () {
      // Sanity check: the regex used above must match BOTH the
      // plain-constructor form `TileLayer(` AND the Dart 2.15+
      // tear-off form `TileLayer.new(`. Without `.new` matching,
      // a developer using modern Dart syntax could reintroduce the
      // unhardened default `NetworkTileProvider` without the test
      // firing.
      final regex = RegExp(r'\bTileLayer(\.new)?\s*\(');
      // Plain form — must match.
      expect(regex.hasMatch('TileLayer(urlTemplate: x)'), isTrue);
      // Tear-off form — must match.
      expect(regex.hasMatch('TileLayer.new(urlTemplate: x)'), isTrue);
      // False positives we explicitly DON'T want to catch.
      expect(regex.hasMatch('SparkiloTileLayer(urlTemplate: x)'), isFalse);
      expect(regex.hasMatch('_TileLayer(urlTemplate: x)'), isFalse);
      expect(regex.hasMatch('buildTileLayer(urlTemplate: x)'), isFalse);
    },
  );
}
