import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/map/presentation/widgets/route_info_bar.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('RouteInfoBar', () {
    testWidgets('displays distance and duration', (tester) async {
      await pumpApp(
        tester,
        RouteInfoBar(
          distanceKm: 250.4,
          durationMinutes: 165.7,
          stationCountLabel: '12 stations',
          onSaveRoute: () {},
          onOpenInMaps: () {},
        ),
      );

      expect(find.textContaining('250km'), findsOneWidget);
      expect(find.textContaining('166min'), findsOneWidget);
    });

    testWidgets('displays station count label', (tester) async {
      await pumpApp(
        tester,
        RouteInfoBar(
          distanceKm: 100,
          durationMinutes: 60,
          stationCountLabel: '5 best',
          onSaveRoute: () {},
          onOpenInMaps: () {},
        ),
      );

      expect(find.text('5 best'), findsOneWidget);
    });

    testWidgets('save button triggers callback', (tester) async {
      var saved = false;
      await pumpApp(
        tester,
        RouteInfoBar(
          distanceKm: 100,
          durationMinutes: 60,
          stationCountLabel: '5',
          onSaveRoute: () => saved = true,
          onOpenInMaps: () {},
        ),
      );

      await tester.tap(find.byIcon(Icons.bookmark_add));
      expect(saved, isTrue);
    });

    testWidgets('navigation button triggers callback', (tester) async {
      var opened = false;
      await pumpApp(
        tester,
        RouteInfoBar(
          distanceKm: 100,
          durationMinutes: 60,
          stationCountLabel: '5',
          onSaveRoute: () {},
          onOpenInMaps: () => opened = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.navigation));
      expect(opened, isTrue);
    });

    testWidgets('shows route icon', (tester) async {
      await pumpApp(
        tester,
        RouteInfoBar(
          distanceKm: 100,
          durationMinutes: 60,
          stationCountLabel: '5',
          onSaveRoute: () {},
          onOpenInMaps: () {},
        ),
      );

      expect(find.byIcon(Icons.route), findsOneWidget);
    });
  });
}
