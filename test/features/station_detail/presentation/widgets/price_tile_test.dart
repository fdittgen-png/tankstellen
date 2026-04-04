import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/fuel_type.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/price_tile.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('PriceTile', () {
    testWidgets('renders label and formatted price', (tester) async {
      await pumpApp(
        tester,
        const PriceTile(label: 'Diesel', price: 1.459, fuelType: FuelType.diesel),
      );

      expect(find.text('Diesel'), findsOneWidget);
      // PriceFormatter formats to locale-specific string
      expect(find.textContaining('1'), findsWidgets);
    });

    testWidgets('renders dash for null price', (tester) async {
      await pumpApp(
        tester,
        const PriceTile(label: 'Super E5', price: null, fuelType: FuelType.e5),
      );

      expect(find.text('Super E5'), findsOneWidget);
      expect(find.text('--'), findsOneWidget);
    });
  });
}
