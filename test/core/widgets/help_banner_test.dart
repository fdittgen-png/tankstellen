import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/core/storage/hive_storage.dart';
import 'package:tankstellen/core/widgets/help_banner.dart';

import '../../helpers/mock_providers.dart';
import '../../helpers/pump_app.dart';

void main() {
  group('HelpBanner', () {
    testWidgets('shows banner on first open', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting('test_banner')).thenReturn(null);
      when(() => test.mockStorage.putSetting(any(), any()))
          .thenAnswer((_) async {});

      await pumpApp(
        tester,
        const HelpBanner(
          storageKey: 'test_banner',
          icon: Icons.info,
          message: 'Test help message',
        ),
        overrides: test.overrides,
      );

      expect(find.text('Test help message'), findsOneWidget);
    });

    testWidgets('does not show banner when already dismissed', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting('test_banner')).thenReturn(true);

      await pumpApp(
        tester,
        const HelpBanner(
          storageKey: 'test_banner',
          icon: Icons.info,
          message: 'Test help message',
        ),
        overrides: test.overrides,
      );

      expect(find.text('Test help message'), findsNothing);
    });

    testWidgets('dismissing banner stores the flag', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting('test_banner')).thenReturn(null);
      when(() => test.mockStorage.putSetting(any(), any()))
          .thenAnswer((_) async {});

      await pumpApp(
        tester,
        const HelpBanner(
          storageKey: 'test_banner',
          icon: Icons.info,
          message: 'Test help message',
        ),
        overrides: test.overrides,
      );

      // Tap "Got it" button
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();

      verify(() => test.mockStorage.putSetting('test_banner', true)).called(1);
      expect(find.text('Test help message'), findsNothing);
    });

    testWidgets('shows correct icon', (tester) async {
      final test = standardTestOverrides();
      when(() => test.mockStorage.getSetting('test_banner')).thenReturn(null);

      await pumpApp(
        tester,
        const HelpBanner(
          storageKey: 'test_banner',
          icon: Icons.lightbulb_outline,
          message: 'Test',
        ),
        overrides: test.overrides,
      );

      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    });
  });
}
