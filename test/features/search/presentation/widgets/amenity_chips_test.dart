import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/search/domain/entities/station_amenity.dart';
import 'package:tankstellen/features/search/presentation/widgets/amenity_chips.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AmenityChips', () {
    testWidgets('renders nothing when amenities is empty', (tester) async {
      await pumpApp(
        tester,
        const AmenityChips(amenities: {}),
      );

      expect(find.byType(AmenityChips), findsOneWidget);
      // Should render SizedBox.shrink
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('renders icon chip for single amenity', (tester) async {
      await pumpApp(
        tester,
        const AmenityChips(amenities: {StationAmenity.shop}),
      );

      expect(find.byIcon(Icons.store), findsOneWidget);
      expect(find.text('Shop'), findsOneWidget);
    });

    testWidgets('renders multiple amenity chips', (tester) async {
      await pumpApp(
        tester,
        const AmenityChips(amenities: {
          StationAmenity.shop,
          StationAmenity.carWash,
          StationAmenity.toilet,
        }),
      );

      expect(find.byIcon(Icons.store), findsOneWidget);
      expect(find.byIcon(Icons.local_car_wash), findsOneWidget);
      expect(find.byIcon(Icons.wc), findsOneWidget);
    });

    testWidgets('shows overflow indicator when exceeding maxVisible',
        (tester) async {
      await pumpApp(
        tester,
        const AmenityChips(
          amenities: {
            StationAmenity.shop,
            StationAmenity.carWash,
            StationAmenity.toilet,
            StationAmenity.airPump,
            StationAmenity.restaurant,
            StationAmenity.atm,
          },
          maxVisible: 4,
        ),
      );

      // Should show +2 overflow
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('does not show overflow when within maxVisible',
        (tester) async {
      await pumpApp(
        tester,
        const AmenityChips(
          amenities: {
            StationAmenity.shop,
            StationAmenity.carWash,
          },
          maxVisible: 4,
        ),
      );

      // Should not have overflow indicator
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('respects custom maxVisible value', (tester) async {
      await pumpApp(
        tester,
        const AmenityChips(
          amenities: {
            StationAmenity.shop,
            StationAmenity.carWash,
            StationAmenity.toilet,
          },
          maxVisible: 2,
        ),
      );

      // Should show +1 overflow
      expect(find.text('+1'), findsOneWidget);
    });
  });
}
