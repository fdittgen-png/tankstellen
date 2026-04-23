import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tankstellen/core/theme/theme_mode_provider.dart';
import 'package:tankstellen/features/profile/presentation/screens/theme_settings_screen.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for the dedicated `ThemeSettingsScreen` introduced in
/// #897. The screen should follow the `PrivacyDashboardScreen` layout
/// conventions (AppBar + ListView + top banner + card-bodied picker),
/// and selecting a theme mode should update the persisted
/// `themeModeSettingProvider` immediately.
void main() {
  group('ThemeSettingsScreen (#897)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
      final container = ProviderContainer(overrides: const []);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('en'),
            home: ThemeSettingsScreen(),
          ),
        ),
      );
      // Let the provider's async `_load` settle to its persisted value
      // before running assertions.
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets(
        'header layout mirrors Privacy Dashboard — Scaffold + AppBar + '
        'ListView body', (tester) async {
      await pumpScreen(tester);

      // AppBar title uses the existing `themeSettingTitle` key.
      expect(find.widgetWithText(AppBar, 'Theme'), findsOneWidget);

      // Body is a single scrollable ListView, matching the privacy /
      // storage dashboards.
      expect(find.byType(ListView), findsOneWidget);

      // Banner icon — palette_outlined glyph, same visual weight as
      // the shield in the privacy dashboard.
      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);

      // The picker renders all three mode labels regardless of which
      // mode is currently selected.
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Follow system'), findsOneWidget);
    });

    testWidgets(
        'picking a new ThemeMode updates the provider live — the card '
        'subtitle surface reads the new value on the next rebuild',
        (tester) async {
      final container = await pumpScreen(tester);

      // Baseline — starts on `system` (nothing persisted).
      expect(container.read(themeModeSettingProvider), ThemeMode.system);

      // Tap Dark.
      await tester.tap(find.byKey(const Key('themeSettingsOptionDark')));
      await tester.pumpAndSettle();
      expect(container.read(themeModeSettingProvider), ThemeMode.dark);

      // Tap Light.
      await tester.tap(find.byKey(const Key('themeSettingsOptionLight')));
      await tester.pumpAndSettle();
      expect(container.read(themeModeSettingProvider), ThemeMode.light);

      // Tap Follow system — returns to default.
      await tester.tap(find.byKey(const Key('themeSettingsOptionSystem')));
      await tester.pumpAndSettle();
      expect(container.read(themeModeSettingProvider), ThemeMode.system);
    });

    test(
        'themeModeLabel returns the ARB-localized fallback for each '
        'ThemeMode when AppLocalizations is null', () {
      expect(themeModeLabel(ThemeMode.light, null), 'Light');
      expect(themeModeLabel(ThemeMode.dark, null), 'Dark');
      expect(themeModeLabel(ThemeMode.system, null), 'Follow system');
    });
  });
}
