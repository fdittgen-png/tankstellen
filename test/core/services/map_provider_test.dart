import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/core/services/impl/flutter_map_provider.dart';
import 'package:tankstellen/core/services/map_provider.dart';

void main() {
  group('TileLayerConfig', () {
    test('stores url template, user agent, and attribution', () {
      const config = TileLayerConfig(
        urlTemplate: 'https://example.com/{z}/{x}/{y}.png',
        userAgent: 'test-agent',
        attribution: 'Test Attribution',
      );

      expect(config.urlTemplate, 'https://example.com/{z}/{x}/{y}.png');
      expect(config.userAgent, 'test-agent');
      expect(config.attribution, 'Test Attribution');
    });

    test('userAgent is optional', () {
      const config = TileLayerConfig(
        urlTemplate: 'https://example.com/{z}/{x}/{y}.png',
        attribution: 'Test',
      );

      expect(config.userAgent, isNull);
    });
  });

  group('MapMarkerConfig', () {
    test('stores point, dimensions, and child widget', () {
      const child = SizedBox(width: 10, height: 10);
      const config = MapMarkerConfig(
        point: LatLng(48.0, 2.0),
        width: 40,
        height: 40,
        child: child,
      );

      expect(config.point.latitude, 48.0);
      expect(config.point.longitude, 2.0);
      expect(config.width, 40);
      expect(config.height, 40);
      expect(config.child, child);
    });
  });

  group('MapPolylineConfig', () {
    test('stores points, color, and stroke width', () {
      const config = MapPolylineConfig(
        points: [LatLng(48.0, 2.0), LatLng(49.0, 3.0)],
        color: Colors.blue,
        strokeWidth: 3.0,
      );

      expect(config.points, hasLength(2));
      expect(config.color, Colors.blue);
      expect(config.strokeWidth, 3.0);
    });

    test('default stroke width is 4.0', () {
      const config = MapPolylineConfig(
        points: [LatLng(48.0, 2.0)],
        color: Colors.red,
      );

      expect(config.strokeWidth, 4.0);
    });
  });

  group('MapCircleConfig', () {
    test('stores center, radius, colors, and border width', () {
      const config = MapCircleConfig(
        center: LatLng(48.0, 2.0),
        radiusMeters: 5000,
        fillColor: Colors.blue,
        borderColor: Colors.red,
        borderStrokeWidth: 3.0,
      );

      expect(config.center.latitude, 48.0);
      expect(config.radiusMeters, 5000);
      expect(config.fillColor, Colors.blue);
      expect(config.borderColor, Colors.red);
      expect(config.borderStrokeWidth, 3.0);
    });

    test('default border stroke width is 2.0', () {
      const config = MapCircleConfig(
        center: LatLng(48.0, 2.0),
        radiusMeters: 1000,
        fillColor: Colors.blue,
        borderColor: Colors.red,
      );

      expect(config.borderStrokeWidth, 2.0);
    });
  });

  group('FlutterMapProvider', () {
    late FlutterMapProvider provider;

    setUp(() {
      provider = const FlutterMapProvider();
    });

    test('name is OpenStreetMap', () {
      expect(provider.name, 'OpenStreetMap');
    });

    test('tileConfig returns OSM tile URL from AppConstants', () {
      final config = provider.tileConfig;
      expect(config.urlTemplate, AppConstants.osmTileUrl);
      expect(config.userAgent, AppConstants.osmUserAgent);
      expect(config.attribution, AppConstants.osmAttribution);
    });

    test('createController returns a MapController', () {
      final controller = provider.createController();
      expect(controller, isA<MapController>());
      provider.disposeController(controller);
    });

    test('implements MapProvider interface', () {
      expect(provider, isA<MapProvider>());
    });

    group('buildMarkerLayer', () {
      testWidgets('returns MarkerLayer for few markers',
          (WidgetTester tester) async {
        final markers = List.generate(
          5,
          (i) => MapMarkerConfig(
            point: LatLng(48.0 + i * 0.01, 2.0),
            width: 40,
            height: 40,
            child: const SizedBox(),
          ),
        );

        final widget = provider.buildMarkerLayer(
          markers: markers,
          cluster: false,
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

        expect(find.byType(MarkerLayer), findsOneWidget);
      });

      testWidgets('returns MarkerLayer when cluster is false even with many markers',
          (WidgetTester tester) async {
        final markers = List.generate(
          30,
          (i) => MapMarkerConfig(
            point: LatLng(48.0 + i * 0.001, 2.0),
            width: 40,
            height: 40,
            child: const SizedBox(),
          ),
        );

        final widget = provider.buildMarkerLayer(
          markers: markers,
          cluster: false,
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

        expect(find.byType(MarkerLayer), findsOneWidget);
      });

      testWidgets('returns cluster widget when cluster is true and >20 markers',
          (WidgetTester tester) async {
        final markers = List.generate(
          25,
          (i) => MapMarkerConfig(
            point: LatLng(48.0 + i * 0.001, 2.0),
            width: 40,
            height: 40,
            child: const SizedBox(),
          ),
        );

        final widget = provider.buildMarkerLayer(
          markers: markers,
          cluster: true,
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

        expect(find.byType(MarkerClusterLayerWidget), findsOneWidget);
      });
    });

    testWidgets('buildTileLayer returns a TileLayer',
        (WidgetTester tester) async {
      final widget = provider.buildTileLayer();

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

      expect(find.byType(TileLayer), findsOneWidget);
    });

    testWidgets('buildAttribution returns a RichAttributionWidget',
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

      expect(find.byType(RichAttributionWidget), findsOneWidget);
    });

    testWidgets('buildPolylineLayer renders polylines',
        (WidgetTester tester) async {
      final widget = provider.buildPolylineLayer(
        polylines: [
          const MapPolylineConfig(
            points: [LatLng(48.0, 2.0), LatLng(49.0, 3.0)],
            color: Colors.blue,
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

      expect(find.byType(PolylineLayer), findsOneWidget);
    });

    testWidgets('buildCircleLayer renders circles',
        (WidgetTester tester) async {
      final widget = provider.buildCircleLayer(
        circles: [
          const MapCircleConfig(
            center: LatLng(48.0, 2.0),
            radiusMeters: 5000,
            fillColor: Colors.blue,
            borderColor: Colors.red,
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

      expect(find.byType(CircleLayer), findsOneWidget);
    });

    testWidgets('buildMapWidget renders a FlutterMap',
        (WidgetTester tester) async {
      final controller = provider.createController();

      try {
        final widget = provider.buildMapWidget(
          controller: controller,
          initialCenter: const LatLng(48.0, 2.0),
          initialZoom: 10,
          children: [provider.buildTileLayer()],
        );

        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

        expect(find.byType(FlutterMap), findsOneWidget);
      } finally {
        provider.disposeController(controller);
      }
    });
  });

  group('MapProvider contract', () {
    test('FlutterMapProvider satisfies MapProvider interface', () {
      // Compile-time check: FlutterMapProvider implements MapProvider
      const MapProvider provider = FlutterMapProvider();
      expect(provider.name, isNotEmpty);
      expect(provider.tileConfig.urlTemplate, isNotEmpty);
      expect(provider.tileConfig.attribution, isNotEmpty);
    });
  });
}
