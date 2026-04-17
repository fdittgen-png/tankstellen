import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_top_bar.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../../helpers/pump_app.dart';

/// The bar uses `Positioned`, which only works inside a Stack.
Widget _host(Widget bar) => Stack(
      children: [
        const SizedBox.expand(child: ColoredBox(color: Colors.grey)),
        bar,
      ],
    );

void main() {
  group('DrivingTopBar', () {
    testWidgets('renders the drive icon and "Driving Mode" title',
        (tester) async {
      await pumpApp(
        tester,
        _host(const DrivingTopBar(selectedFuel: FuelType.diesel)),
      );

      expect(find.byIcon(Icons.drive_eta), findsOneWidget);
      expect(find.text('Driving Mode'), findsOneWidget);
    });

    testWidgets('shows the selected fuel type as the chip label',
        (tester) async {
      await pumpApp(
        tester,
        _host(const DrivingTopBar(selectedFuel: FuelType.e10)),
      );
      expect(find.text(FuelType.e10.displayName), findsOneWidget);
    });

    testWidgets('updates chip label when fuel type changes',
        (tester) async {
      await pumpApp(
        tester,
        _host(const DrivingTopBar(selectedFuel: FuelType.e5)),
      );
      expect(find.text(FuelType.e5.displayName), findsOneWidget);
      expect(find.text(FuelType.diesel.displayName), findsNothing);
    });

    testWidgets('pins to the top of the Stack so the map flows under it',
        (tester) async {
      await pumpApp(
        tester,
        _host(const DrivingTopBar(selectedFuel: FuelType.diesel)),
      );
      final positioned = tester.widget<Positioned>(find.byType(Positioned));
      expect(positioned.top, 0);
      expect(positioned.left, 0);
      expect(positioned.right, 0);
    });

    testWidgets('chip uses the primary container colour scheme',
        (tester) async {
      // Pins the fuel-chip visual contract against a theme refactor
      // that levels it back to the default neutral background.
      await pumpApp(
        tester,
        _host(const DrivingTopBar(selectedFuel: FuelType.diesel)),
      );

      // The chip is the Container nearest to the fuel-type Text.
      final chipContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text(FuelType.diesel.displayName),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = chipContainer.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(12));
      expect(decoration.color, isNotNull);
    });
  });
}
