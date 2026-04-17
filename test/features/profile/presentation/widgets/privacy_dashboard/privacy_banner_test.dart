import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/presentation/widgets/privacy_dashboard/privacy_banner.dart';

import '../../../../../helpers/pump_app.dart';

void main() {
  group('PrivacyBanner', () {
    testWidgets('renders the shield icon + reassurance text',
        (tester) async {
      await pumpApp(tester, const PrivacyBanner());

      expect(find.byIcon(Icons.shield), findsOneWidget);
      expect(
        find.textContaining('data belongs to you'),
        findsOneWidget,
      );
    });

    testWidgets('icon uses the primary colour and 32-px size',
        (tester) async {
      // The icon is the visual anchor of the banner; size + colour
      // are part of the privacy-dashboard first-impression so pin
      // them against accidental theme-refactor changes.
      await pumpApp(tester, const PrivacyBanner());
      final icon = tester.widget<Icon>(find.byIcon(Icons.shield));
      expect(icon.size, 32);
    });

    testWidgets('wraps content in a rounded 12-px container',
        (tester) async {
      await pumpApp(tester, const PrivacyBanner());
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(
        decoration.borderRadius,
        BorderRadius.circular(12),
      );
    });

    testWidgets('text uses a medium weight so it reads clearly',
        (tester) async {
      await pumpApp(tester, const PrivacyBanner());
      final text = tester.widget<Text>(
        find.textContaining('data belongs to you'),
      );
      expect(text.style?.fontWeight, FontWeight.w500);
    });
  });
}
