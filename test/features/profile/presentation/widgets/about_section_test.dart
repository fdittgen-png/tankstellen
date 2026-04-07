import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/constants/app_constants.dart';
import 'package:tankstellen/features/profile/presentation/widgets/about_section.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  group('AboutSection', () {
    testWidgets('renders privacy policy link with correct text',
        (tester) async {
      await pumpApp(
        tester,
        const SingleChildScrollView(child: AboutSection()),
      );

      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('privacy policy URL points to GitHub Pages HTTPS URL',
        (_) async {
      expect(
        AppConstants.privacyPolicyUrl,
        startsWith('https://'),
        reason: 'Privacy policy must be served over HTTPS for Play Store',
      );
      expect(
        AppConstants.privacyPolicyUrl,
        contains('github.io'),
        reason: 'Privacy policy should be hosted on GitHub Pages',
      );
    });

    testWidgets('renders app version', (tester) async {
      await pumpApp(
        tester,
        const SingleChildScrollView(child: AboutSection()),
      );

      expect(find.textContaining(AppConstants.appVersion), findsOneWidget);
    });

    testWidgets('renders developer name', (tester) async {
      await pumpApp(
        tester,
        const SingleChildScrollView(child: AboutSection()),
      );

      expect(find.text(AppConstants.developerName), findsOneWidget);
    });

    testWidgets('renders GitHub link', (tester) async {
      await pumpApp(
        tester,
        const SingleChildScrollView(child: AboutSection()),
      );

      expect(find.text('fdittgen-png/tankstellen'), findsOneWidget);
    });

    testWidgets('renders donation section', (tester) async {
      await pumpApp(
        tester,
        const SingleChildScrollView(child: AboutSection()),
      );

      expect(find.text('PayPal'), findsOneWidget);
      expect(find.text('Revolut'), findsOneWidget);
    });
  });
}
