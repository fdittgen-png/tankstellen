// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/map/presentation/widgets/inline_map.dart';
import 'package:tankstellen/features/map/presentation/widgets/station_map_layers.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/radar_search_provider.dart';
import 'package:tankstellen/features/search/providers/selected_station_provider.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

/// #2939 — the landscape Fuel Station Radar split map: render the RADAR
/// results (not the stale/empty regular search), cluster-always so the narrow
/// pane never overlaps, fit the camera to the actual result bounds, and
/// two-way list↔map selection sync.
///
/// RED-before: `InlineMap` watched `searchStateProvider`, so the radar's
/// stations never reached the map and the layer rendered the regular search
/// (empty here) — these assertions on the radar set would have failed.
void main() {
  Station station(String id, double lat, double lng, {double? e10}) => Station(
        id: id,
        name: 'Station $id',
        brand: 'TEST',
        street: 'Teststr.',
        postCode: '00000',
        place: 'Test',
        lat: lat,
        lng: lng,
        dist: 1,
        e10: e10,
        isOpen: true,
      );

  final radarStations = [
    station('r1', 52.520, 13.405, e10: 1.799),
    station('r2', 52.530, 13.420, e10: 1.659),
    station('r3', 52.510, 13.390, e10: 1.999),
    station('r4', 52.540, 13.430, e10: 1.729),
  ];

  Widget host() => const SizedBox(width: 800, height: 600, child: InlineMap());

  List<Object> radarOverrides({
    required List<Station> stations,
    String? selected,
  }) {
    final test = standardTestOverrides();
    return [
      ...test.overrides,
      radarSearchProvider.overrideWith(() => _ActiveRadar(stations)),
      if (selected != null)
        selectedStationProvider.overrideWith(() => _SelectedStub(selected)),
    ];
  }

  testWidgets(
      'landscape radar map renders ALL radarSearchProvider stations '
      '(StationMapLayers fed the radar set, cluster-always)', (tester) async {
    await pumpApp(
      tester,
      host(),
      overrides: radarOverrides(stations: radarStations).cast(),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 50));

    final layer =
        tester.widget<StationMapLayers>(find.byType(StationMapLayers));
    // The map is fed the RADAR stations — all of them — not the (empty)
    // regular search result set.
    expect(layer.stations.map((s) => s.id).toList(),
        radarStations.map((s) => s.id).toList());
    // #2939 — the split pane always clusters by proximity.
    expect(layer.clusterAlways, isTrue);
    // The radius circle is suppressed for the radar fit-to-results framing.
    expect(layer.showSearchRadius, isFalse);
  });

  testWidgets('fits the camera to the ACTUAL result bounds, not the radius',
      (tester) async {
    await pumpApp(
      tester,
      host(),
      overrides: radarOverrides(stations: radarStations).cast(),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 50));

    final layer =
        tester.widget<StationMapLayers>(find.byType(StationMapLayers));
    final bounds = layer.cameraFitBounds;
    expect(bounds, isNotNull, reason: 'fit-to-results must pass result bounds');

    // The bounds frame exactly the result set's lat/lng extent.
    final expected = LatLngBounds.fromPoints(
        [for (final s in radarStations) LatLng(s.lat, s.lng)]);
    expect(bounds!.south, closeTo(expected.south, 1e-9));
    expect(bounds.north, closeTo(expected.north, 1e-9));
    expect(bounds.west, closeTo(expected.west, 1e-9));
    expect(bounds.east, closeTo(expected.east, 1e-9));
  });

  testWidgets(
      'two-way sync: a marker tap selects the row (selectedStationProvider) '
      'WITHOUT navigating; the map stays visible', (tester) async {
    await pumpApp(
      tester,
      host(),
      overrides: radarOverrides(stations: radarStations).cast(),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 50));

    final layer =
        tester.widget<StationMapLayers>(find.byType(StationMapLayers));
    // The inline map wires a marker tap to row selection rather than the
    // default push-to-detail navigation.
    expect(layer.onStationTap, isNotNull,
        reason: 'marker tap must select the row, not navigate away');

    // Read the live container so we can assert the provider really updates.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StationMapLayers)),
    );
    expect(container.read(selectedStationProvider), isNull);

    // Simulate the marker tap → it must SELECT the row, not navigate.
    layer.onStationTap!('r2');
    await tester.pump();

    expect(container.read(selectedStationProvider), 'r2');
    // The map is still mounted (not swapped for a detail card).
    expect(find.byType(StationMapLayers), findsOneWidget);
  });

  testWidgets(
      'the selected station is forwarded so its marker can be emphasised',
      (tester) async {
    await pumpApp(
      tester,
      host(),
      overrides: radarOverrides(stations: radarStations, selected: 'r2').cast(),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 50));

    final layer =
        tester.widget<StationMapLayers>(find.byType(StationMapLayers));
    expect(layer.selectedStationIds, contains('r2'));
  });
}

/// An active radar with a fixed, already-resolved station list.
class _ActiveRadar extends RadarSearch {
  _ActiveRadar(this._stations);
  final List<Station> _stations;

  @override
  RadarSearchState build() => RadarSearchState(
        active: true,
        stations: AsyncData<List<Station>>(_stations),
      );
}

class _SelectedStub extends SelectedStation {
  _SelectedStub(this._id);
  final String _id;

  @override
  String? build() => _id;
}
