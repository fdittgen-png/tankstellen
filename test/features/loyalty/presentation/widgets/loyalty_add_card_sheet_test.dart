import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/loyalty/domain/entities/loyalty_card.dart';
import 'package:tankstellen/features/loyalty/presentation/widgets/loyalty_add_card_sheet.dart';

import '../../../../helpers/pump_app.dart';

/// Pumps the sheet inside a host widget with a button that opens it
/// via `showModalBottomSheet`, capturing the popped [LoyaltyCard] (or
/// `null` on cancel) for assertion. Mirrors the production call site
/// in `LoyaltySettingsScreen._openAddSheet`.
class _SheetHost extends StatefulWidget {
  final void Function(LoyaltyCard?) onResult;

  const _SheetHost({required this.onResult});

  @override
  State<_SheetHost> createState() => _SheetHostState();
}

class _SheetHostState extends State<_SheetHost> {
  Future<void> _open() async {
    final card = await showModalBottomSheet<LoyaltyCard>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const LoyaltyAddCardSheet(),
    );
    widget.onResult(card);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: _open,
        child: const Text('open'),
      ),
    );
  }
}

void main() {
  group('LoyaltyAddCardSheet', () {
    testWidgets(
        'renders the brand dropdown, label, discount field and action row',
        (tester) async {
      await pumpApp(
        tester,
        _SheetHost(onResult: (_) {}),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Add fuel club card'), findsOneWidget);
      expect(find.text('Brand'), findsOneWidget);
      expect(find.text('Label (optional)'), findsOneWidget);
      expect(find.text('Discount (per litre)'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    });

    testWidgets('Save with an empty discount surfaces the validator error',
        (tester) async {
      LoyaltyCard? captured;
      var resolved = false;
      await pumpApp(
        tester,
        _SheetHost(onResult: (c) {
          captured = c;
          resolved = true;
        }),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a positive number'), findsOneWidget);
      // Sheet stayed open — onResult was not invoked yet.
      expect(resolved, isFalse);
      expect(captured, isNull);
    });

    testWidgets('Save with a valid discount pops the sheet with a card',
        (tester) async {
      LoyaltyCard? captured;
      await pumpApp(
        tester,
        _SheetHost(onResult: (c) => captured = c),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Discount (per litre)'),
        '0.07',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Label (optional)'),
        'Personal',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.discountPerLiter, 0.07);
      expect(captured!.label, 'Personal');
      expect(captured!.brand, LoyaltyBrand.totalEnergies);
      expect(captured!.enabled, isTrue);
    });

    testWidgets('comma-decimal input is accepted (German/French keyboard)',
        (tester) async {
      LoyaltyCard? captured;
      await pumpApp(
        tester,
        _SheetHost(onResult: (c) => captured = c),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Discount (per litre)'),
        '0,08',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.discountPerLiter, 0.08);
    });

    testWidgets('Cancel pops the sheet with null', (tester) async {
      LoyaltyCard? captured;
      var resolved = false;
      await pumpApp(
        tester,
        _SheetHost(onResult: (c) {
          captured = c;
          resolved = true;
        }),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(resolved, isTrue);
      expect(captured, isNull);
    });
  });
}
