import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/domain/entities/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/station_detail/presentation/widgets/station_prices_section.dart';

import '../../../../fixtures/stations.dart';
import '../../../../helpers/pump_app.dart';

class _NullActiveProfile extends ActiveProfile {
  @override
  UserProfile? build() => null;
}

void main() {
  group('StationPricesSection', () {
    testWidgets('renders the prices header and the base-fuel tiles',
        (tester) async {
      await pumpApp(
        tester,
        const StationPricesSection(station: testStation),
        overrides: [
          activeProfileProvider.overrideWith(() => _NullActiveProfile()),
        ],
      );

      // The localized "Prices" header should be present.
      expect(find.text('Prices'), findsOneWidget);
      // Each of the three base fuel types must render as a PriceTile.
      expect(find.text('Super E5'), findsOneWidget);
      expect(find.text('Super E10'), findsOneWidget);
      expect(find.text('Diesel'), findsOneWidget);
      // The "Log fill-up" CTA must render (locale = en -> "Add fill-up").
      expect(find.text('Add fill-up'), findsOneWidget);
    });
  });
}
