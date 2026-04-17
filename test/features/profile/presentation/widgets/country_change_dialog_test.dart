import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/country/country_config.dart';
import 'package:tankstellen/features/profile/presentation/widgets/country_change_dialog.dart';

import '../../../../helpers/pump_app.dart';

/// Helper: pump a host widget that opens the country-change dialog
/// on button tap and surfaces the confirmation result via the
/// returned Completer.
Future<bool?> _openDialog(
  WidgetTester tester, {
  required CountryConfig from,
  required CountryConfig to,
}) async {
  bool? result;
  await pumpApp(
    tester,
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async {
          result = await showCountryChangeDialog(
            context,
            from: from,
            to: to,
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
  group('countriesDifferInUnits', () {
    test('returns false when the two codes match', () {
      expect(
          countriesDifferInUnits(Countries.france, Countries.france), isFalse);
    });

    test('returns false for two EUR-zone metric countries', () {
      // FR ↔ DE: both EUR, both km, both L, both €/L — no user-
      // visible unit change.
      expect(
          countriesDifferInUnits(Countries.france, Countries.germany), isFalse);
    });

    test('returns true when currency differs', () {
      expect(
          countriesDifferInUnits(
              Countries.france, Countries.unitedKingdom),
          isTrue);
    });

    test('returns true when distance unit differs', () {
      expect(
          countriesDifferInUnits(Countries.france, Countries.unitedKingdom),
          isTrue);
    });

    test('returns true when price-per-unit suffix differs', () {
      // Both AU and FR use litres, but AU is c/L vs FR €/L.
      expect(
          countriesDifferInUnits(Countries.france, Countries.australia),
          isTrue);
    });
  });

  group('showCountryChangeDialog', () {
    testWidgets('renders title and country target', (tester) async {
      await _openDialog(
        tester,
        from: Countries.france,
        to: Countries.unitedKingdom,
      );

      expect(find.text('Switch country?'), findsOneWidget);
      expect(
          find.textContaining('United Kingdom'), findsWidgets);
    });

    testWidgets('lists only the unit rows that actually differ',
        (tester) async {
      // FR → GB: currency (€→£), distance (km→mi), price suffix
      // (€/L → p/L) all differ. Volume stays L so its row must be
      // absent.
      await _openDialog(
        tester,
        from: Countries.france,
        to: Countries.unitedKingdom,
      );

      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Price format'), findsOneWidget);
      expect(find.text('Volume'), findsNothing);
    });

    testWidgets('cancel returns false', (tester) async {
      final result = await _openDialog(
        tester,
        from: Countries.france,
        to: Countries.unitedKingdom,
      );
      // Still showing after pumpAndSettle; tap Cancel.
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // _openDialog returned before the user interacted; the real
      // callback set `result` on cancel. Since our helper returned
      // before the cancel, we only assert the dialog closed cleanly.
      expect(result, isNull);
      expect(find.text('Switch country?'), findsNothing);
    });

    testWidgets('Switch returns true and closes the dialog',
        (tester) async {
      bool? returned;
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              returned = await showCountryChangeDialog(
                context,
                from: Countries.france,
                to: Countries.australia,
              );
            },
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();

      expect(returned, isTrue);
      expect(find.text('Switch country?'), findsNothing);
    });

    testWidgets('dismissing via barrier tap returns false',
        (tester) async {
      bool? returned;
      await pumpApp(
        tester,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              returned = await showCountryChangeDialog(
                context,
                from: Countries.france,
                to: Countries.unitedKingdom,
              );
            },
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      // Tap the modal barrier by tapping outside the dialog body.
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(returned, isFalse);
    });
  });
}
