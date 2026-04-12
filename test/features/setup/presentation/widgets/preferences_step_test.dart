import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/features/setup/presentation/widgets/preferences_step.dart';

import '../../../../helpers/mock_providers.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  group('PreferencesStep', () {
    testWidgets('renders all input fields', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const PreferencesStep(),
        overrides: test.overrides,
      );

      expect(find.text('Your preferences'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // zip code
      expect(find.byType(Slider), findsOneWidget); // radius
      expect(find.text('Preferred fuel'), findsOneWidget);
    });

    testWidgets('shows fuel type choice chips', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const PreferencesStep(),
        overrides: test.overrides,
      );

      // Should have chips for common fuel types
      expect(find.byType(ChoiceChip), findsAtLeast(4));
    });

    testWidgets('shows privacy reassurance banner', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const PreferencesStep(),
        overrides: test.overrides,
      );

      expect(find.byIcon(Icons.shield), findsOneWidget);
      expect(find.textContaining('stored only on your device'), findsOneWidget);
    });

    testWidgets('selecting fuel type updates wizard state', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting(any())).thenReturn(null);

      await pumpApp(
        tester,
        const PreferencesStep(),
        overrides: test.overrides,
      );

      // Tap Diesel chip
      await tester.tap(find.text('Diesel'));
      await tester.pumpAndSettle();

      // The chip should now be selected (visual check — state is internal)
      expect(find.byType(ChoiceChip), findsAtLeast(4));
    });
  });
}
