import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/alerts/domain/entities/price_alert.dart';
import 'package:tankstellen/features/alerts/presentation/widgets/create_alert_dialog.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';

import '../../../../helpers/pump_app.dart';

/// Pumps the dialog inside a button-triggered flow so that the surrounding
/// Navigator can deliver the pop value back to us — the same contract the
/// real station detail screen uses when awaiting the dialog's result.
Future<PriceAlert?> _openDialog(
  WidgetTester tester, {
  String stationId = 'station-1',
  String stationName = 'Test Station',
  double? currentPrice,
}) async {
  PriceAlert? result;
  await pumpApp(
    tester,
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async {
          result = await showDialog<PriceAlert>(
            context: context,
            builder: (_) => CreateAlertDialog(
              stationId: stationId,
              stationName: stationName,
              currentPrice: currentPrice,
            ),
          );
        },
        child: const Text('open'),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  group('CreateAlertDialog rendering', () {
    testWidgets('shows the station name prominently', (tester) async {
      await _openDialog(tester, stationName: 'Shell Berlin Mitte');

      expect(find.text('Shell Berlin Mitte'), findsOneWidget);
    });

    testWidgets('shows current price line when price is provided',
        (tester) async {
      await _openDialog(tester, currentPrice: 1.659);

      // Default country is FR → comma as decimal separator.
      expect(find.textContaining('1,659'), findsOneWidget);
    });

    testWidgets('hides current price line when price is null',
        (tester) async {
      await _openDialog(tester, currentPrice: null);

      // The "Current price: ..." label only renders when currentPrice
      // is non-null. We don't assert on € because the target-price
      // input field always carries a €/L suffix.
      expect(find.textContaining('Current price'), findsNothing);
    });

    testWidgets('defaults fuel type to diesel', (tester) async {
      await _openDialog(tester);

      expect(find.text(FuelType.diesel.displayName), findsOneWidget);
    });

    testWidgets('prefills target price at currentPrice - 0.05',
        (tester) async {
      await _openDialog(tester, currentPrice: 1.659);

      // 1.659 - 0.05 = 1.609
      final field = find.byType(TextFormField);
      expect(field, findsOneWidget);
      final controller =
          (tester.widget(field) as TextFormField).controller;
      expect(controller?.text, '1.609');
    });

    testWidgets('leaves target price blank when no currentPrice',
        (tester) async {
      await _openDialog(tester);

      final field = find.byType(TextFormField);
      final controller =
          (tester.widget(field) as TextFormField).controller;
      expect(controller?.text, '');
    });
  });

  group('CreateAlertDialog validation', () {
    testWidgets('rejects an empty target price', (tester) async {
      await _openDialog(tester);

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a price'), findsOneWidget);
    });

    testWidgets('rejects a non-numeric target price', (tester) async {
      await _openDialog(tester);

      await tester.enterText(find.byType(TextFormField), 'abc');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid price'), findsOneWidget);
    });

    testWidgets('rejects zero or negative target price', (tester) async {
      await _openDialog(tester);

      await tester.enterText(find.byType(TextFormField), '0');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid price'), findsOneWidget);
    });

    testWidgets('rejects target price above 10 EUR', (tester) async {
      await _openDialog(tester);

      await tester.enterText(find.byType(TextFormField), '12.5');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Price too high'), findsOneWidget);
    });

    testWidgets('accepts comma as decimal separator', (tester) async {
      final result = await _openDialog(tester);
      // NB: _openDialog returns before dialog closes; we need to drive
      // the form and observe no validation error fires.

      await tester.enterText(find.byType(TextFormField), '1,650');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Comma accepted → dialog dismisses → validation messages are gone.
      expect(find.text('Invalid price'), findsNothing);
      expect(result, isNull); // result was not yet assigned in _openDialog
    });
  });

  group('CreateAlertDialog submit and cancel', () {
    testWidgets('Create returns a PriceAlert with form values',
        (tester) async {
      PriceAlert? returned;
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              returned = await showDialog<PriceAlert>(
                context: context,
                builder: (_) => const CreateAlertDialog(
                  stationId: 'shell-42',
                  stationName: 'Shell 42',
                  currentPrice: 1.700,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '1.500');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(returned, isNotNull);
      expect(returned!.stationId, 'shell-42');
      expect(returned!.stationName, 'Shell 42');
      expect(returned!.fuelType, FuelType.diesel);
      expect(returned!.targetPrice, 1.500);
      expect(returned!.id, contains('shell-42'));
      expect(returned!.id, contains(FuelType.diesel.apiValue));
    });

    testWidgets('Cancel returns null', (tester) async {
      PriceAlert? returned = PriceAlert(
        id: 'sentinel',
        stationId: 's',
        stationName: 'n',
        fuelType: FuelType.diesel,
        targetPrice: 1,
        createdAt: DateTime(2025, 1, 1),
      );

      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              returned = await showDialog<PriceAlert>(
                context: context,
                builder: (_) => const CreateAlertDialog(
                  stationId: 's',
                  stationName: 'n',
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(returned, isNull);
    });

    testWidgets('changing the fuel type updates the returned alert',
        (tester) async {
      PriceAlert? returned;
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              returned = await showDialog<PriceAlert>(
                context: context,
                builder: (_) => const CreateAlertDialog(
                  stationId: 's',
                  stationName: 'n',
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Open the dropdown, pick E10.
      await tester.tap(find.byType(DropdownButtonFormField<FuelType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(FuelType.e10.displayName).last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '1.600');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(returned, isNotNull);
      expect(returned!.fuelType, FuelType.e10);
      expect(returned!.targetPrice, 1.600);
    });
  });
}
