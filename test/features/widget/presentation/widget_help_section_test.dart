// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/profile/domain/entities/user_profile.dart';
import 'package:tankstellen/features/profile/providers/profile_provider.dart';
import 'package:tankstellen/features/widget/presentation/widget_help_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../helpers/pump_app.dart';

/// Stub that always reports the same active profile. Lets the
/// defaults-editor test (#2106) bypass Hive without wiring the
/// storage repository graph.
class _StubActiveProfile extends ActiveProfile {
  _StubActiveProfile(this._profile);
  final UserProfile? _profile;
  @override
  UserProfile? build() => _profile;
}

void main() {
  testWidgets('WidgetHelpSection renders the home-screen widget help (#1806)', (
    tester,
  ) async {
    await pumpApp(tester, const WidgetHelpSection());

    final l = AppLocalizations.of(
      tester.element(find.byType(WidgetHelpSection)),
    );
    expect(find.text(l.widgetHelpIntro), findsOneWidget);
    expect(find.text(l.widgetHelpAdd), findsOneWidget);
    expect(find.text(l.widgetHelpTap), findsOneWidget);
    // #2106 — without an active profile we fall back to the legacy
    // Reconfigure hint instead of rendering the defaults editor.
    expect(find.text(l.widgetHelpConfigure), findsOneWidget);
  });

  testWidgets(
    '#2106 — active profile swaps the Reconfigure hint for the colour + '
    'variant defaults editor',
    (tester) async {
      const profile = UserProfile(id: 'p1', name: 'Test');
      await pumpApp(
        tester,
        const WidgetHelpSection(),
        overrides: [
          activeProfileProvider.overrideWith(() => _StubActiveProfile(profile)),
        ],
      );

      final l = AppLocalizations.of(
        tester.element(find.byType(WidgetHelpSection)),
      );
      // Legacy hint is suppressed — the editor took its place.
      expect(find.text(l.widgetHelpConfigure), findsNothing);
      expect(find.text(l.widgetDefaultsApplyToAllHint), findsOneWidget);
      expect(find.text(l.widgetDefaultsColorLabel), findsOneWidget);
      expect(find.text(l.widgetDefaultsVariantLabel), findsOneWidget);
      expect(
        find.byKey(const Key('widget_color_scheme_dropdown')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('widget_variant_segmented')), findsOneWidget);
    },
  );
}
