import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/features/ev/domain/entities/charging_station.dart';
import 'package:tankstellen/features/ev/presentation/widgets/ev_map_overlay.dart';
import 'package:tankstellen/features/ev/providers/ev_providers.dart';

import '../../../../helpers/pump_app.dart';

/// Widget tests for [EvMapLayer] and [EvToggleButton] from
/// `lib/features/ev/presentation/widgets/ev_map_overlay.dart`.
///
/// `EvMapLayer` is a `MarkerLayer`/`MarkerClusterLayerWidget` host that has to
/// live inside a [FlutterMap], so each test wraps it in a real (offline)
/// `FlutterMap` configured with `MapOptions(initialCenter: LatLng(0, 0))` to
/// satisfy the layer's runtime context lookups.
void main() {
  const viewport = EvViewport(latitude: 0, longitude: 0, radiusKm: 5);

  /// Builds a single [ChargingStation] with the supplied [id] so we can
  /// quickly spin up large lists for the cluster threshold (>20).
  ChargingStation buildStation(String id, {double lat = 0.1, double lng = 0.1}) {
    return ChargingStation(
      id: 'ocm-$id',
      name: 'Station $id',
      latitude: lat,
      longitude: lng,
      connectors: const [],
    );
  }

  /// Wraps [child] in a [FlutterMap] sized to a real viewport so map layers
  /// can lay out (FlutterMap requires finite bounds).
  Widget hostInMap(Widget child) {
    return SizedBox(
      width: 400,
      height: 600,
      child: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(0, 0),
          initialZoom: 5,
        ),
        children: [child],
      ),
    );
  }

  group('EvToggleButton', () {
    testWidgets('renders the ev_station icon', (tester) async {
      await pumpApp(
        tester,
        const EvToggleButton(),
        overrides: [
          evShowOnMapProvider.overrideWith(_FakeEvShowOnMap.new),
        ],
      );

      expect(find.byIcon(Icons.ev_station), findsOneWidget);
    });

    testWidgets('off state shows white background and dark icon',
        (tester) async {
      await pumpApp(
        tester,
        const EvToggleButton(),
        overrides: [
          evShowOnMapProvider.overrideWith(() => _FakeEvShowOnMap(initial: false)),
        ],
      );

      final material = tester.widget<Material>(
        find.ancestor(
          of: find.byIcon(Icons.ev_station),
          matching: find.byType(Material),
        ).first,
      );
      expect(material.color, Colors.white);

      final icon = tester.widget<Icon>(find.byIcon(Icons.ev_station));
      expect(icon.color, Colors.black54);
    });

    testWidgets('on state flips background to green and icon to white',
        (tester) async {
      await pumpApp(
        tester,
        const EvToggleButton(),
        overrides: [
          evShowOnMapProvider.overrideWith(() => _FakeEvShowOnMap(initial: true)),
        ],
      );

      final material = tester.widget<Material>(
        find.ancestor(
          of: find.byIcon(Icons.ev_station),
          matching: find.byType(Material),
        ).first,
      );
      expect(material.color, Colors.green);

      final icon = tester.widget<Icon>(find.byIcon(Icons.ev_station));
      expect(icon.color, Colors.white);
    });

    testWidgets('tap calls notifier.toggle() and flips the state',
        (tester) async {
      final fake = _FakeEvShowOnMap(initial: false);
      await pumpApp(
        tester,
        const EvToggleButton(),
        overrides: [
          evShowOnMapProvider.overrideWith(() => fake),
        ],
      );

      await tester.tap(find.byIcon(Icons.ev_station));
      await tester.pumpAndSettle();

      expect(fake.toggleCount, 1);
      // After toggle the icon should reflect the on state (white).
      final icon = tester.widget<Icon>(find.byIcon(Icons.ev_station));
      expect(icon.color, Colors.white);
    });
  });

  group('EvMapLayer', () {
    testWidgets('loading state renders SizedBox.shrink (no marker layer)',
        (tester) async {
      // Never-completing future keeps the AsyncValue in the loading state.
      final completer = Completer<List<ChargingStation>>();
      addTearDown(() {
        if (!completer.isCompleted) completer.complete(const []);
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            evStationsProvider(viewport).overrideWith((_) => completer.future),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: hostInMap(const EvMapLayer(viewport: viewport)),
            ),
          ),
        ),
      );
      // Single pump only — pumpAndSettle would await the never-completing
      // future and time out.
      await tester.pump();

      expect(find.byType(MarkerLayer), findsNothing);
      expect(find.byType(MarkerClusterLayerWidget), findsNothing);
    });

    testWidgets('error state renders SizedBox.shrink (no marker layer)',
        (tester) async {
      await pumpApp(
        tester,
        hostInMap(const EvMapLayer(viewport: viewport)),
        overrides: [
          evStationsProvider(viewport)
              .overrideWith((_) async => throw Exception('boom')),
        ],
      );

      expect(find.byType(MarkerLayer), findsNothing);
      expect(find.byType(MarkerClusterLayerWidget), findsNothing);
    });

    testWidgets('empty data renders SizedBox.shrink (no marker layer)',
        (tester) async {
      await pumpApp(
        tester,
        hostInMap(const EvMapLayer(viewport: viewport)),
        overrides: [
          evStationsProvider(viewport).overrideWith((_) async => const []),
        ],
      );

      expect(find.byType(MarkerLayer), findsNothing);
      expect(find.byType(MarkerClusterLayerWidget), findsNothing);
    });

    testWidgets('non-empty data with <=20 stations renders MarkerLayer',
        (tester) async {
      final stations = List.generate(
        5,
        (i) => buildStation('s$i', lat: i * 0.001, lng: i * 0.001),
      );

      await pumpApp(
        tester,
        hostInMap(const EvMapLayer(viewport: viewport)),
        overrides: [
          evStationsProvider(viewport).overrideWith((_) async => stations),
        ],
      );

      expect(find.byType(MarkerLayer), findsOneWidget);
      expect(find.byType(MarkerClusterLayerWidget), findsNothing);
    });

    testWidgets('non-empty data with >20 stations renders cluster layer',
        (tester) async {
      final stations = List.generate(
        25,
        (i) => buildStation('s$i', lat: i * 0.001, lng: i * 0.001),
      );

      await pumpApp(
        tester,
        hostInMap(const EvMapLayer(viewport: viewport)),
        overrides: [
          evStationsProvider(viewport).overrideWith((_) async => stations),
        ],
      );

      expect(find.byType(MarkerClusterLayerWidget), findsOneWidget);
      // Cluster widget owns its own internal marker rendering — the bare
      // `MarkerLayer` from the <=20 branch must not appear.
      expect(find.byType(MarkerLayer), findsNothing);
    });
  });
}

/// Test double for [EvShowOnMap] that stays purely in-memory so widget tests
/// don't need a Hive-backed [SettingsStorage]. `toggle` is recorded for the
/// tap-callback assertion.
class _FakeEvShowOnMap extends EvShowOnMap {
  _FakeEvShowOnMap({this.initial = false});

  final bool initial;
  int toggleCount = 0;

  @override
  bool build() => initial;

  @override
  Future<void> toggle() async {
    toggleCount++;
    state = !state;
  }

  @override
  Future<void> set(bool value) async {
    state = value;
  }
}
