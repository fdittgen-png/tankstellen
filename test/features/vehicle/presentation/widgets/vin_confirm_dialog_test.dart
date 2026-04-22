import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/vehicle/domain/entities/vin_data.dart';
import 'package:tankstellen/features/vehicle/presentation/widgets/vin_confirm_dialog.dart';

import '../../../../helpers/pump_app.dart';

/// Widget tests for [VinConfirmDialog] (#812 phase 2).
///
/// Focused on the rendering branches: full vPIC summary, partial
/// offline summary with the "partial info" note, and the two action
/// outcomes.
void main() {
  group('VinConfirmDialog', () {
    const fullVpic = VinData(
      vin: 'VF36B8HZL8R123456',
      make: 'Peugeot',
      model: '107',
      modelYear: 2008,
      displacementL: 1.0,
      cylinderCount: 3,
      fuelTypePrimary: 'Gasoline',
      source: VinDataSource.vpic,
    );

    const partialWmi = VinData(
      vin: 'VF38HKFVZ6R123456',
      make: 'Peugeot',
      country: 'France',
      source: VinDataSource.wmiOffline,
    );

    testWidgets('renders the full vPIC summary with every field',
        (tester) async {
      await pumpApp(tester, const VinConfirmDialog(data: fullVpic));

      expect(find.text('Is this your car?'), findsOneWidget);
      expect(find.textContaining('Peugeot'), findsOneWidget);
      expect(find.textContaining('107'), findsOneWidget);
      expect(find.textContaining('2008'), findsOneWidget);
      expect(find.textContaining('1.0'), findsOneWidget);
      expect(find.textContaining('Gasoline'), findsOneWidget);
      // No partial-info note on a full vPIC result.
      expect(
        find.text('Partial info (offline). You can edit below.'),
        findsNothing,
      );
    });

    testWidgets(
      'renders the partial-info note when source is wmiOffline',
      (tester) async {
        await pumpApp(tester, const VinConfirmDialog(data: partialWmi));

        expect(find.text('Is this your car?'), findsOneWidget);
        expect(
          find.text('Partial info (offline). You can edit below.'),
          findsOneWidget,
        );
        // Missing fields render as em-dashes so the template keeps
        // its shape.
        expect(find.textContaining('—'), findsWidgets);
      },
    );

    testWidgets('offers both Confirm and Modify actions', (tester) async {
      await pumpApp(tester, const VinConfirmDialog(data: fullVpic));

      expect(find.text('Yes, auto-fill'), findsOneWidget);
      expect(find.text('Modify manually'), findsOneWidget);
    });
  });
}
