import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/core/services/impl/flutter_map_provider.dart';
import 'package:tankstellen/core/services/map_provider.dart';

/// Tests for [FlutterMapProvider] focusing on the 13 `@override` methods.
///
/// Complements the higher-level coverage in
/// `test/core/services/map_provider_test.dart` by exercising the
/// controller-driven methods (`move`, `getZoom`, `getCenter`,
/// `disposeController`) and the custom `clusterBuilder` branch which
/// were previously uncovered (Refs #561).
void main() {
  group('FlutterMapProvider — config getters', () {
    const provider = FlutterMapProvider();

    test('name override returns "OpenStreetMap"', () {
      expect(provider.name, 'OpenStreetMap');
    });

    test('tileConfig wires AppConstants OSM URL/userAgent/attribution', () {
      final config = provider.tileConfig;

      expect(config, isA<TileLayerConfig>());
      expect(config.urlTemplate, AppConstants.osmTileUrl);
      expect(
        config.urlTemplate,
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );
      expect(config.userAgent, AppConstants.osmUserAgent);
      expect(config.userAgent, isNotNull);
      expect(config.userAgent, isNotEmpty);
      expect(config.attribution, AppConstants.osmAttribution);
      expect(config.attribution, contains('OpenStreetMap'));
    });

    test('tileConfig is stable across calls (idempotent getter)', () {
      final c1 = provider.tileConfig;
      final c2 = provider.tileConfig;
      expect(c1.urlTemplate, c2.urlTemplate);
      expect(c1.userAgent, c2.userAgent);
      expect(c1.attribution, c2.attribution);
    });

    test('implements MapProvider interface', () {
      expect(provider, isA<MapProvider>());
    });
  });

  group('FlutterMapProvider — controller lifecycle', () {
    const provider = FlutterMapProvider();

    test('createController returns a flutter_map MapController', () {
      final controller = provider.createController();
      try {
        expect(controller, isA<MapController>());
      } finally {
        provider.disposeController(controller);
      }
    });

    test('createController returns a fresh instance on each call', () {
      final c1 = provider.createController();
      final c2 = provider.createController();
      try {
        expect(identical(c1, c2), isFalse);
      } finally {
        provider.disposeController(c1);
        provider.disposeController(c2);
      }
    });

    test('disposeController completes without error', () {
      final controller = provider.createController();
      expect(() => provider.disposeController(controller), returnsNormally);
    });
  });

  group('FlutterMapProvider — controller mutation/queries', () {
    const provider = FlutterMapProvider();

    testWidgets(
      'move/getZoom/getCenter operate on the controller after the map is mounted',
      (WidgetTester tester) async {
        final controller = provider.createController();
        addTearDown(() => provider.disposeController(controller));

        const initialCenter = LatLng(48.8566, 2.3522); // Paris
        const initialZoom = 10.0;

        final map = provider.buildMapWidget(
          controller: controller,
          initialCenter: initialCenter,
          initialZoom: initialZoom,
          children: [provider.buildTileLayer()],
        );

        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: SizedBox(width: 400, height: 400, child: map))),
        );
        // Allow flutter_map to attach the controller to its internal state.
        await tester.pump();

        // Initial values from MapOptions.
        expect(provider.getZoom(controller), closeTo(initialZoom, 0.001));
        expect(
          provider.getCenter(controller).latitude,
          closeTo(initialCenter.latitude, 0.001),
        );
        expect(
          provider.getCenter(controller).longitude,
          closeTo(initialCenter.longitude, 0.001),
        );

        // Mutate via move() and verify both getters reflect the change.
        const movedCenter = LatLng(43.4775, 3.4933); // Castelnau de Guers
        const movedZoom = 14.0;
        provider.move(controller, movedCenter, movedZoom);
        await tester.pump();

        expect(provider.getZoom(controller), closeTo(movedZoom, 0.001));
        expect(
          provider.getCenter(controller).latitude,
          closeTo(movedCenter.latitude, 0.001),
        );
        expect(
          provider.getCenter(controller).longitude,
          closeTo(movedCenter.longitude, 0.001),
        );
      },
    );
  });

  group('FlutterMapProvider — buildMapWidget', () {
    const provider = FlutterMapProvider();

    testWidgets('returns a FlutterMap with the supplied controller and options',
        (WidgetTester tester) async {
      final controller = provider.createController();
      addTearDown(() => provider.disposeController(controller));

      final widget = provider.buildMapWidget(
        controller: controller,
        initialCenter: const LatLng(52.52, 13.405), // Berlin
        initialZoom: 12,
        children: [provider.buildTileLayer()],
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: widget)),
      );

      final flutterMapFinder = find.byType(FlutterMap);
      expect(flutterMapFinder, findsOneWidget);

      final flutterMap = tester.widget<FlutterMap>(flutterMapFinder);
      expect(flutterMap.mapController, same(controller));
      expect(flutterMap.options.initialCenter, const LatLng(52.52, 13.405));
      expect(flutterMap.options.initialZoom, 12);
      expect(
        flutterMap.options.interactionOptions.flags,
        InteractiveFlag.all,
      );
    });

    testWidgets('forwards children list to the underlying FlutterMap',
        (WidgetTester tester) async {
      final controller = provider.createController();
      addTearDown(() => provider.disposeController(controller));

      final tile = provider.buildTileLayer();
      final attribution = provider.buildAttribution();

      final widget = provider.buildMapWidget(
        controller: controller,
        initialCenter: const LatLng(0, 0),
        initialZoom: 5,
        children: [tile, attribution],
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(TileLayer), findsOneWidget);
      expect(find.byType(RichAttributionWidget), findsOneWidget);
    });
  });

  group('FlutterMapProvider — buildTileLayer', () {
    const provider = FlutterMapProvider();

    testWidgets('configures TileLayer from tileConfig URL and userAgent',
        (WidgetTester tester) async {
      final widget = provider.buildTileLayer();

      await tester.pumpWidget(
        MaterialApp(
          home: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(48.0, 2.0),
              initialZoom: 5,
            ),
            children: [widget],
          ),
        ),
      );

      final tileFinder = find.byType(TileLayer);
      expect(tileFinder, findsOneWidget);

      final tile = tester.widget<TileLayer>(tileFinder);
      expect(tile.urlTemplate, AppConstants.osmTileUrl);
      // flutter_map 8.x folds `userAgentPackageName` into the
      // tileProvider's User-Agent header at construction time.
      expect(
        tile.tileProvider.headers['User-Agent'],
        contains(AppConstants.osmUserAgent),
      );
      expect(
        tile.evictErrorTileStrategy,
        EvictErrorTileStrategy.notVisibleRespectMargin,
      );
    });
  });

  group('FlutterMapProvider — buildMarkerLayer', () {
    const provider = FlutterMapProvider();

    Future<void> pumpInMap(WidgetTester tester, Widget layer) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(48.0, 2.0),
              initialZoom: 10,
            ),
            children: [layer],
          ),
        ),
      );
    }

    testWidgets('returns MarkerLayer when cluster is false',
        (WidgetTester tester) async {
      final markers = List.generate(
        3,
        (i) => MapMarkerConfig(
          point: LatLng(48.0 + i * 0.01, 2.0),
          width: 30,
          height: 30,
          child: const Icon(Icons.location_pin),
        ),
      );

      final widget = provider.buildMarkerLayer(
        markers: markers,
        cluster: false,
      );

      await pumpInMap(tester, widget);
      expect(find.byType(MarkerLayer), findsOneWidget);
      expect(find.byType(MarkerClusterLayerWidget), findsNothing);
    });

    testWidgets('returns MarkerLayer when cluster is true but ≤20 markers',
        (WidgetTester tester) async {
      // Boundary: 20 markers should NOT cluster (>20 condition).
      final markers = List.generate(
        20,
        (i) => MapMarkerConfig(
          point: LatLng(48.0 + i * 0.001, 2.0),
          width: 30,
          height: 30,
          child: const SizedBox(),
        ),
      );

      final widget = provider.buildMarkerLayer(
        markers: markers,
        cluster: true,
      );

      await pumpInMap(tester, widget);
      expect(find.byType(MarkerLayer), findsOneWidget);
      expect(find.byType(MarkerClusterLayerWidget), findsNothing);
    });

    testWidgets('returns MarkerClusterLayerWidget when cluster=true and >20',
        (WidgetTester tester) async {
      final markers = List.generate(
        25,
        (i) => MapMarkerConfig(
          point: LatLng(48.0 + i * 0.001, 2.0),
          width: 30,
          height: 30,
          child: const SizedBox(),
        ),
      );

      final widget = provider.buildMarkerLayer(
        markers: markers,
        cluster: true,
      );

      await pumpInMap(tester, widget);
      expect(find.byType(MarkerClusterLayerWidget), findsOneWidget);
    });

    testWidgets('uses custom clusterBuilder when provided (>20 markers)',
        (WidgetTester tester) async {
      const customKey = Key('custom-cluster-widget');

      final markers = List.generate(
        30,
        (i) => MapMarkerConfig(
          // Pack markers very close together so the clustering algorithm
          // must collapse them into a single visible cluster on screen.
          point: LatLng(48.0 + i * 0.00001, 2.0 + i * 0.00001),
          width: 30,
          height: 30,
          child: const SizedBox(),
        ),
      );

      var customBuilderCallCount = 0;
      final widget = provider.buildMarkerLayer(
        markers: markers,
        cluster: true,
        clusterBuilder: (context, count) {
          customBuilderCallCount += 1;
          return Container(
            key: customKey,
            width: 40,
            height: 40,
            color: Colors.purple,
            child: Center(child: Text('$count')),
          );
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            height: 400,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(48.0, 2.0),
                initialZoom: 10,
              ),
              children: [widget],
            ),
          ),
        ),
      );
      // Pump frames so the cluster manager realizes its visible markers.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(MarkerClusterLayerWidget), findsOneWidget);
      // Cluster builder must have been invoked at least once and produced
      // the custom widget rather than the default theme-coloured one.
      expect(customBuilderCallCount, greaterThan(0));
      expect(find.byKey(customKey), findsWidgets);
    });

    testWidgets('default cluster widget renders the count text when no '
        'clusterBuilder is supplied', (WidgetTester tester) async {
      final markers = List.generate(
        25,
        (i) => MapMarkerConfig(
          point: LatLng(48.0 + i * 0.00001, 2.0 + i * 0.00001),
          width: 30,
          height: 30,
          child: const SizedBox(),
        ),
      );

      final widget = provider.buildMarkerLayer(
        markers: markers,
        cluster: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            height: 400,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(48.0, 2.0),
                initialZoom: 10,
              ),
              children: [widget],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(MarkerClusterLayerWidget), findsOneWidget);
      // The default cluster widget contains a Text with the count and bold
      // styling — find any bold-text widget anywhere in the cluster layer.
      final boldText = find.byWidgetPredicate(
        (w) => w is Text && w.style?.fontWeight == FontWeight.bold,
      );
      expect(boldText, findsWidgets);
    });

    testWidgets('returns MarkerLayer with empty list when no markers',
        (WidgetTester tester) async {
      final widget = provider.buildMarkerLayer(
        markers: const [],
        cluster: true,
      );

      await pumpInMap(tester, widget);
      expect(find.byType(MarkerLayer), findsOneWidget);
      final layer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
      expect(layer.markers, isEmpty);
    });
  });

  group('FlutterMapProvider — buildPolylineLayer', () {
    const provider = FlutterMapProvider();

    testWidgets('builds a PolylineLayer with the supplied points/colors',
        (WidgetTester tester) async {
      final widget = provider.buildPolylineLayer(
        polylines: const [
          MapPolylineConfig(
            points: [LatLng(48.0, 2.0), LatLng(49.0, 3.0)],
            color: Colors.blue,
            strokeWidth: 6.0,
          ),
          MapPolylineConfig(
            points: [LatLng(48.0, 2.0), LatLng(48.5, 2.5)],
            color: Colors.red,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(48.0, 2.0),
              initialZoom: 10,
            ),
            children: [widget],
          ),
        ),
      );

      final layerFinder = find.byType(PolylineLayer<Object>);
      expect(layerFinder, findsOneWidget);

      final layer = tester.widget<PolylineLayer<Object>>(layerFinder);
      expect(layer.polylines, hasLength(2));
      expect(layer.polylines[0].color, Colors.blue);
      expect(layer.polylines[0].strokeWidth, 6.0);
      expect(layer.polylines[0].points, hasLength(2));
      expect(layer.polylines[1].color, Colors.red);
      expect(layer.polylines[1].strokeWidth, 4.0); // default
    });

    testWidgets('handles an empty polylines list', (WidgetTester tester) async {
      final widget = provider.buildPolylineLayer(polylines: const []);

      await tester.pumpWidget(
        MaterialApp(
          home: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(48.0, 2.0),
              initialZoom: 10,
            ),
            children: [widget],
          ),
        ),
      );

      expect(find.byType(PolylineLayer<Object>), findsOneWidget);
    });
  });

  group('FlutterMapProvider — buildCircleLayer', () {
    const provider = FlutterMapProvider();

    testWidgets('builds a CircleLayer using radius-in-meters mode',
        (WidgetTester tester) async {
      final widget = provider.buildCircleLayer(
        circles: const [
          MapCircleConfig(
            center: LatLng(48.0, 2.0),
            radiusMeters: 5000,
            fillColor: Colors.blue,
            borderColor: Colors.red,
            borderStrokeWidth: 3.0,
          ),
          MapCircleConfig(
            center: LatLng(49.0, 3.0),
            radiusMeters: 1000,
            fillColor: Colors.green,
            borderColor: Colors.black,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(48.0, 2.0),
              initialZoom: 10,
            ),
            children: [widget],
          ),
        ),
      );

      final layerFinder = find.byType(CircleLayer<Object>);
      expect(layerFinder, findsOneWidget);

      final layer = tester.widget<CircleLayer<Object>>(layerFinder);
      expect(layer.circles, hasLength(2));
      expect(layer.circles[0].radius, 5000);
      expect(layer.circles[0].useRadiusInMeter, isTrue);
      expect(layer.circles[0].color, Colors.blue);
      expect(layer.circles[0].borderColor, Colors.red);
      expect(layer.circles[0].borderStrokeWidth, 3.0);
      expect(layer.circles[1].borderStrokeWidth, 2.0); // default
    });

    testWidgets('handles an empty circles list', (WidgetTester tester) async {
      final widget = provider.buildCircleLayer(circles: const []);

      await tester.pumpWidget(
        MaterialApp(
          home: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(48.0, 2.0),
              initialZoom: 10,
            ),
            children: [widget],
          ),
        ),
      );

      expect(find.byType(CircleLayer<Object>), findsOneWidget);
    });
  });

  group('FlutterMapProvider — buildAttribution', () {
    const provider = FlutterMapProvider();

    testWidgets('returns a RichAttributionWidget mentioning OSM contributors',
        (WidgetTester tester) async {
      final widget = provider.buildAttribution();

      await tester.pumpWidget(
        MaterialApp(
          home: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(48.0, 2.0),
              initialZoom: 10,
            ),
            children: [widget],
          ),
        ),
      );

      final attributionFinder = find.byType(RichAttributionWidget);
      expect(attributionFinder, findsOneWidget);

      final attribution = tester.widget<RichAttributionWidget>(attributionFinder);
      expect(attribution.attributions, hasLength(1));
      final source =
          attribution.attributions.single as TextSourceAttribution;
      expect(source.text, 'OpenStreetMap contributors');
    });
  });
}
