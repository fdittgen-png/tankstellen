import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/fuel_type_dropdown.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('FuelTypeDropdown', () {
    testWidgets('shows all non-wildcard fuels by displayName', (tester) async {
      await pumpApp(
        tester,
        FuelTypeDropdown(value: FuelType.e10, onChanged: (_) {}),
      );

      await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
      await tester.pumpAndSettle();

      for (final f in FuelType.values.where((t) => t != FuelType.all)) {
        expect(find.text(f.displayName), findsWidgets,
            reason: '${f.displayName} must render with its localized label');
      }
      expect(find.text(FuelType.all.displayName), findsNothing,
          reason: 'The "all" wildcard must never be pickable as a preference');
    });

    testWidgets('selecting a fuel fires onChanged with the FuelType',
        (tester) async {
      FuelType? picked;
      await pumpApp(
        tester,
        FuelTypeDropdown(
          value: FuelType.e10,
          onChanged: (v) => picked = v,
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(FuelType.diesel.displayName).last);
      await tester.pumpAndSettle();

      expect(picked, FuelType.diesel);
    });
  });

  group('NullableFuelTypeDropdown', () {
    testWidgets('includes a "not set" entry plus all fuels by displayName',
        (tester) async {
      await pumpApp(
        tester,
        NullableFuelTypeDropdown(value: null, onChanged: (_) {}),
      );

      await tester.tap(find.byType(DropdownButtonFormField<FuelType?>));
      await tester.pumpAndSettle();

      expect(find.text('Not set'), findsWidgets);
      expect(find.text(FuelType.e10.displayName), findsWidgets);
      expect(find.text(FuelType.electric.displayName), findsWidgets);
    });

    testWidgets('options parameter restricts which fuels appear',
        (tester) async {
      await pumpApp(
        tester,
        NullableFuelTypeDropdown(
          value: null,
          onChanged: (_) {},
          options: const [FuelType.e5, FuelType.diesel],
        ),
      );

      await tester.tap(find.byType(DropdownButtonFormField<FuelType?>));
      await tester.pumpAndSettle();

      expect(find.text(FuelType.e5.displayName), findsWidgets);
      expect(find.text(FuelType.diesel.displayName), findsWidgets);
      expect(find.text(FuelType.electric.displayName), findsNothing,
          reason: 'Restricted list must hide fuels not in [options]');
    });
  });
}
