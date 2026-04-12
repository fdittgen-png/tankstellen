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
      // Should have one ListTile per LandingScreen value
      expect(find.byType(ListTile), findsNWidgets(LandingScreen.values.length));
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
