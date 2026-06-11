// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_marker.dart';
import 'package:tankstellen/core/domain/fuel_type.dart';
import 'package:tankstellen/core/domain/station.dart';

import '../../helpers/pump_app.dart';

/// LAYER-1 regression suite for the map reimplementation (#2403).
///
/// These are the tests the four prior grey-tile / "--" fixes lacked.
/// They fail loudly if either failure mode returns:
///   - the parallel-TileLayer + reset storm (grey tiles), or
///   - a marker rendering "--" while the station has a price for some
///     other fuel (blank markers after a fuel-chip change).
///
/// The proxy URL + 7-day cache contract test is deferred to LAYER 2
/// (#2397 deploys the edge function; the Deno-side contract test ships
/// with it). The Dart-side proxy-URL/UA shape is already locked by
/// `test/core/constants/app_constants_test.dart`.
void main() {
  group('NO RESET MACHINERY — the grey-tile storm cannot return (#2398)', () {
    late String source;

    setUpAll(() {
      final f = File(
        'lib/features/map/presentation/widgets/station_map_layers.dart',
      );
      expect(f.existsSync(), isTrue,
          reason: 'station_map_layers.dart must exist');
      source = f.readAsStringSync();
    });

    test('station_map_layers.dart has no reset controller', () {
      expect(source.contains('_resetController'), isFalse,
          reason:
              'The reset-stream controller fired TileLayer.reset on every '
              'cold-start camera/size event, evicting tiles before they '
              'painted. It was deleted in #2398 and must not return.');
    });

    test('station_map_layers.dart does not subscribe to mapEventStream', () {
      expect(source.contains('mapEventStream'), isFalse,
          reason:
              'The 12-second cold-start window subscribed to '
              'MapController.mapEventStream and re-fired the reset on every '
              'programmatic move — the root of the recurring grey-tile bug. '
              'No such subscription may exist (#2398).');
      // Belt-and-braces: none of the cold-start machinery names survive.
      for (final banned in const [
        '_coldStartEventSub',
        '_coldStartCloseTimer',
        '_coldStartResetWindow',
        '_onColdStartEvent',
      ]) {
        expect(source.contains(banned), isFalse,
            reason: '$banned is cold-start reset machinery deleted in #2398');
      }
    });

    test('station_map_layers.dart renders the SINGLE SparkiloTileLayer', () {
      // No raw inline TileLayer in the main map any more.
      expect(source.contains('SparkiloTileLayer'), isTrue);
      expect(RegExp(r'\bTileLayer\s*\(').hasMatch(source), isFalse,
          reason:
              'The main map must not instantiate a raw TileLayer — it goes '
              'through SparkiloTileLayer (#2398).');
    });
  });

  group('CONSISTENCY LINT — allowlist is exactly one entry (#2398)', () {
    test('the consistency test allowlists ONLY sparkilo_tile_layer.dart', () {
      final lintSource = File(
        'test/features/map/tile_layer_consistency_test.dart',
      ).readAsStringSync();

      // The single legitimate raw-TileLayer call site.
      expect(
        lintSource.contains(
          "'lib/features/map/data/sparkilo_tile_layer.dart'",
        ),
        isTrue,
      );
      // The main map must NOT be allowlisted any more.
      expect(
        lintSource.contains(
          "'lib/features/map/presentation/widgets/station_map_layers.dart'",
        ),
        isFalse,
        reason:
            'station_map_layers.dart was removed from the allowlist in '
            '#2398 — the parallel-TileLayer regression cannot recur.',
      );
    });
  });

  group('SELECTED-FUEL MARKER — the marker matches the list, no fallback '
      '(#2510)', () {
    // #2510 reverses the #2400 fallback chain: the marker shows STRICTLY
    // the selected fuel's price (exactly like the search LIST card). A
    // station that lacks the selected fuel renders "--" — it must NOT be
    // re-labelled with another fuel's price (the bug where an E85 search
    // map read "E10 2,099" while the list showed the E85 price).

    testWidgets(
        'a marker shows the selected fuel price when the station carries it',
        (tester) async {
      // E85 selected; station has E85 (cheap) plus an E10 default. The
      // marker must show the E85 price, never the E10 default.
      final station = _station(id: 's-e85', e10: 2.099, e85: 0.799);
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        station,
        FuelType.e85,
        0.5,
        2.5,
      );
      await pumpApp(
        tester,
        SizedBox(
          width: marker.width,
          height: marker.height,
          child: (((marker.child as RepaintBoundary).child as Semantics)
                  .child as GestureDetector)
              .child,
        ),
      );
      expect(find.text('0,799'), findsOneWidget);
      expect(find.text('2,099'), findsNothing,
          reason: 'the E10 default must never replace the selected E85 price');
    });

    testWidgets(
        'a station lacking the selected fuel renders "--", NOT a fallback '
        'price', (tester) async {
      // Each station has a non-null price for SOME other fuel but NOT the
      // selected E10 — the list shows a dash here, so the map must too.
      final mismatchedSet = <Station>[
        _station(id: 's-diesel', diesel: 1.699),
        _station(id: 's-e5', e5: 1.859),
        _station(id: 's-lpg', lpg: 0.799),
        _station(id: 's-cng', cng: 1.199),
      ];
      for (final station in mismatchedSet) {
        final marker = StationMarkerBuilder.build(
          tester.element(find.byType(Container).first),
          station,
          FuelType.e10, // selected fuel none of the stations carry
          0.5,
          2.0,
        );
        await pumpApp(
          tester,
          SizedBox(
            width: marker.width,
            height: marker.height,
            child: (((marker.child as RepaintBoundary).child as Semantics)
                    .child as GestureDetector)
                .child,
          ),
        );
        expect(find.text('--'), findsOneWidget,
            reason:
                '${station.id} has no E10 price → "--", matching the list, '
                'no fallback');
      }
    });

    testWidgets('a truly empty station DOES render "--"', (tester) async {
      final marker = StationMarkerBuilder.build(
        tester.element(find.byType(Container).first),
        _station(id: 's-empty'),
        FuelType.e10,
        0.5,
        2.0,
      );
      await pumpApp(
        tester,
        SizedBox(
          width: marker.width,
          height: marker.height,
          child: (((marker.child as RepaintBoundary).child as Semantics)
                  .child as GestureDetector)
              .child,
        ),
      );
      expect(find.text('--'), findsOneWidget,
          reason: 'a station with no usable price renders "--"');
    });
  });
}

Station _station({
  required String id,
  double? e5,
  double? e10,
  double? e85,
  double? diesel,
  double? lpg,
  double? cng,
}) =>
    Station(
      id: id,
      name: id,
      brand: 'TEST',
      street: 'Test St.',
      postCode: '12345',
      place: 'Test',
      lat: 52.0,
      lng: 13.0,
      e5: e5,
      e10: e10,
      e85: e85,
      diesel: diesel,
      lpg: lpg,
      cng: cng,
      isOpen: true,
    );
