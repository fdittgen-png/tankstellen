import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/profile/data/models/user_profile.dart';
import 'package:tankstellen/features/setup/presentation/widgets/landing_screen_step.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('LandingScreenStep', () {
    testWidgets('renders all landing screen options', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: LandingScreenStep()),
        overrides: test.overrides,
      );

      expect(find.text('Home screen'), findsOneWidget);
      // #493 — the wizard must offer the same option set as the
      // profile edit sheet, which filters out LandingScreen.map.
      // Previously this rendered 4 tiles including "Map", letting a
      // user pick a preference the profile screen could not display.
      final expectedCount = LandingScreen.values
          .where((s) => s != LandingScreen.map)
          .length;
      expect(find.byType(ListTile), findsNWidgets(expectedCount));
      // Explicitly assert the map tile is NOT present.
      expect(find.byIcon(Icons.map), findsNothing,
          reason: 'Map option must be filtered out to match profile dropdown');
    });

    testWidgets('shows hint text', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const SingleChildScrollView(child: LandingScreenStep()),
        overrides: test.overrides,
      );

      expect(
        find.textContaining('Choose which screen'),
        findsOneWidget,
      );
    });
  });
}
