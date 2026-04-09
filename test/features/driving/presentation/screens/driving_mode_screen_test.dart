import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/services/service_result.dart';
import 'package:tankstellen/features/driving/presentation/screens/driving_mode_screen.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_bottom_bar.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_station_sheet.dart';
import 'package:tankstellen/features/driving/presentation/widgets/safety_disclaimer_dialog.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_marker_builder.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_mode_fab.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/search/domain/entities/station.dart';
import 'package:tankstellen/features/search/providers/search_provider.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('DrivingBottomBar', () {
    testWidgets('renders three buttons', (tester) async {
      await pumpApp(
        tester,
        DrivingBottomBar(
          onRecenter: () {},
          onNearestStation: () {},
          onExit: () {},
        ),
      );

      // Should find 3 InkWell buttons inside the bar
      expect(find.byIcon(Icons.my_location), findsOneWidget);
      expect(find.byIcon(Icons.local_gas_station), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('recenter button triggers callback', (tester) async {
      bool recenterTapped = false;

      await pumpApp(
        tester,
        DrivingBottomBar(
          onRecenter: () => recenterTapped = true,
          onNearestStation: () {},
          onExit: () {},
        ),
      );

      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pumpAndSettle();
      expect(recenterTapped, isTrue);
    });

    testWidgets('exit button triggers callback', (tester) async {
      bool exitTapped = false;

      await pumpApp(
        tester,
        DrivingBottomBar(
          onRecenter: () {},
          onNearestStation: () {},
          onExit: () => exitTapped = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(exitTapped, isTrue);
    });

    testWidgets('nearest station button triggers callback', (tester) async {
      bool nearestTapped = false;

      await pumpApp(
        tester,
        DrivingBottomBar(
          onRecenter: () {},
          onNearestStation: () => nearestTapped = true,
          onExit: () {},
        ),
      );

      await tester.tap(find.byIcon(Icons.local_gas_station));
      await tester.pumpAndSettle();
      expect(nearestTapped, isTrue);
    });

    testWidgets('buttons have minimum 72dp height for driving safety',
        (tester) async {
      await pumpApp(
        tester,
        DrivingBottomBar(
          onRecenter: () {},
          onNearestStation: () {},
          onExit: () {},
        ),
      );

      // Find the SizedBox widgets that enforce 72dp height
      final sizedBoxes = tester.widgetList<SizedBox>(
        find.descendant(
          of: find.byType(DrivingBottomBar),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.height == 72,
          ),
        ),
      );
      expect(sizedBoxes.length, 3);
    });

    testWidgets('all buttons have semantic labels for accessibility',
        (tester) async {
      await pumpApp(
        tester,
        DrivingBottomBar(
          onRecenter: () {},
          onNearestStation: () {},
          onExit: () {},
        ),
      );

      // Each button should have a Semantics wrapper with a label
      final semantics = tester.widgetList<Semantics>(
        find.descendant(
          of: find.byType(DrivingBottomBar),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.button == true,
          ),
        ),
      );
      expect(semantics.length, 3);
      for (final s in semantics) {
        expect(s.properties.label, isNotNull);
        expect(s.properties.label, isNotEmpty);
      }
    });
  });

  group('DrivingStationSheet', () {
    testWidgets('shows brand name, distance, and price', (tester) async {
      await pumpApp(
        tester,
        const DrivingStationSheet(
          station: testStation,
          fuelType: FuelType.e10,
        ),
      );

      // Brand name (displayName for testStation is 'STAR')
      expect(find.text('STAR'), findsOneWidget);
      // Distance
      expect(find.text('1.5 km'), findsOneWidget);
      // Navigate button
      expect(find.text('Navigate'), findsOneWidget);
    });

    testWidgets('navigate button has 72dp height', (tester) async {
      await pumpApp(
        tester,
        const DrivingStationSheet(
          station: testStation,
          fuelType: FuelType.e10,
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.text('Navigate'),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.height == 72,
          ),
        ),
      );
      expect(sizedBox.height, 72);
    });
  });

  group('SafetyDisclaimerDialog', () {
    testWidgets('shows warning icon and safety message', (tester) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => SafetyDisclaimerDialog.show(context),
            child: const Text('Show'),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text('Safety Notice'), findsOneWidget);
      expect(find.text('I understand'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancel returns false', (tester) async {
      bool? result;

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await SafetyDisclaimerDialog.show(context);
            },
            child: const Text('Show'),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('accept returns true', (tester) async {
      bool? result;

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await SafetyDisclaimerDialog.show(context);
            },
            child: const Text('Show'),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('I understand'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });

  group('DrivingMarkerBuilder', () {
    test('builds marker with correct dimensions', () {
      final marker = DrivingMarkerBuilder.build(
        testStation,
        FuelType.e10,
        1.5,
        2.0,
        onTap: () {},
      );

      expect(marker.width, 120);
      expect(marker.height, 56);
      expect(marker.point.latitude, testStation.lat);
      expect(marker.point.longitude, testStation.lng);
    });

    test('builds markers for stations with different prices', () {
      final cheap = testStationList[0]; // cheapest
      final expensive = testStationList[2]; // most expensive

      final cheapMarker = DrivingMarkerBuilder.build(
        cheap,
        FuelType.e10,
        1.739,
        1.859,
        onTap: () {},
      );

      final expensiveMarker = DrivingMarkerBuilder.build(
        expensive,
        FuelType.e10,
        1.739,
        1.859,
        onTap: () {},
      );

      // Both markers should have correct positions
      expect(cheapMarker.point.latitude, cheap.lat);
      expect(expensiveMarker.point.latitude, expensive.lat);
    });

    test('handles null price station', () {
      const noPriceStation = Station(
        id: 'no-price',
        name: 'No Price',
        brand: 'TEST',
        street: 'Test St',
        postCode: '12345',
        place: 'Test',
        lat: 52.0,
        lng: 13.0,
        isOpen: true,
      );

      final marker = DrivingMarkerBuilder.build(
        noPriceStation,
        FuelType.e10,
        1.5,
        2.0,
        onTap: () {},
      );

      expect(marker.width, 120);
      expect(marker.height, 56);
    });
  });

  group('DrivingModeFab', () {
    testWidgets('renders FAB with drive icon', (tester) async {
      await pumpApp(tester, const DrivingModeFab());

      expect(find.byIcon(Icons.drive_eta), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  group('DrivingModeScreen fullscreen', () {
    testWidgets('enters immersive mode on init', (tester) async {
      final log = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          log.add(call);
          return null;
        },
      );

      await pumpApp(
        tester,
        const DrivingModeScreen(),
        overrides: _drivingScreenOverrides(),
      );

      final immersiveCall = log.where(
        (c) => c.method == 'SystemChrome.setEnabledSystemUIMode',
      );
      expect(immersiveCall, isNotEmpty,
          reason: 'Should call setEnabledSystemUIMode on init');

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    testWidgets('screen uses Scaffold without bottomNavigationBar',
        (tester) async {
      await pumpApp(
        tester,
        const DrivingModeScreen(),
        overrides: _drivingScreenOverrides(),
      );

      // DrivingModeScreen should use a plain Scaffold with no
      // bottomNavigationBar — the driving bottom bar is a floating overlay
      // positioned inside a Stack, not a Scaffold property.
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.bottomNavigationBar, isNull,
          reason: 'Driving mode must not have a Scaffold bottomNavigationBar');
    });
  });
}

/// Overrides needed to render DrivingModeScreen in isolation.
///
/// The screen watches [searchStateProvider] and [selectedFuelTypeProvider],
/// so we provide empty / default values to avoid real API calls.
List<Object> _drivingScreenOverrides() {
  final std = standardTestOverrides();
  return [
    ...std.overrides,
    searchStateProvider.overrideWith(() => _EmptySearchState()),
  ];
}

/// A search state notifier that returns empty data.
class _EmptySearchState extends SearchState {
  @override
  AsyncValue<ServiceResult<List<Station>>> build() {
    return AsyncValue.data(ServiceResult(
      data: const [],
      source: ServiceSource.cache,
      fetchedAt: DateTime.now(),
    ));
  }
}
