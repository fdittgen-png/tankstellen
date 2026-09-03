// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/domain/brand_logo_manifest.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/about_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/logo_credits_screen.dart';

import '../../../../../helpers/pump_app.dart';

/// #3940 — the credits screen only discharges the CC-BY attribution if a
/// user can actually reach it. About is where the app's other legal and
/// attribution content lives, so that is where the entry point belongs.
void main() {
  testWidgets('About links to the logo credits and names how many logos '
      'are bundled', (tester) async {
    await pumpApp(tester, const AboutScreen());

    final entry = find.textContaining('brand logos from Wikimedia Commons');
    await tester.scrollUntilVisible(entry, 400);
    expect(entry, findsOneWidget);
    expect(
      find.textContaining('${BrandLogoManifest.all.length} brand logos'),
      findsOneWidget,
    );

    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.byType(LogoCreditsScreen), findsOneWidget);
  });
}
