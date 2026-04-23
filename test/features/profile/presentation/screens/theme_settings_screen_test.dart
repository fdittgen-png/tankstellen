import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/theme_mode_provider.dart';
import 'package:tankstellen/features/profile/presentation/screens/theme_settings_screen.dart';

import '../../../../helpers/pump_app.dart';

/// Test-only ThemeModeSetting that exposes a fixed `build()` value and
/// skips the real provider's SharedPreferences load — widget tests do
/// not register plugin channels for SharedPreferences.
class _FixedThemeMode extends ThemeModeSetting {
  final ThemeMode _initial;
  _FixedThemeMode(this._initial);

  @override
  ThemeMode build() => _initial;

  @override
  Future<void> set(ThemeMode mode) async {
    state = mode;
  }
}

void main() {
  group('ThemeSettingsScreen (#897)', () {
    testWidgets('renders Scaffold + AppBar with Theme title',
        (tester) async {
      await pumpApp(
        tester,
        const ThemeSettingsScreen(),
        overrides: [
          themeModeSettingProvider
              .overrideWith(() => _FixedThemeMode(ThemeMode.system)),
        ],
      );

      expect(find.byType(Scaffold), findsAtLeast(1));
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('renders all three theme mode options', (tester) async {
      await pumpApp(
        tester,
        const ThemeSettingsScreen(),
        overrides: [
          themeModeSettingProvider
              .overrideWith(() => _FixedThemeMode(ThemeMode.system)),
        ],
      );

      expect(find.text('Follow system'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      // Each option has a descriptive body underneath.
      expect(
        find.textContaining('Match the current device appearance'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Bright backgrounds'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Dark backgrounds'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Light option updates ThemeModeSetting',
        (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeModeSettingProvider
                .overrideWith(() => _FixedThemeMode(ThemeMode.system)),
          ],
          child: Builder(
            builder: (ctx) {
              container = ProviderScope.containerOf(ctx);
              return const MaterialApp(home: ThemeSettingsScreen());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Baseline — System is active.
      expect(container.read(themeModeSettingProvider), ThemeMode.system);

      // Tap the Light card.
      await tester.tap(find.byKey(const Key('themeSettingsOptionLight')));
      await tester.pumpAndSettle();

      expect(container.read(themeModeSettingProvider), ThemeMode.light);
    });

    testWidgets('tapping Dark option updates ThemeModeSetting',
        (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeModeSettingProvider
                .overrideWith(() => _FixedThemeMode(ThemeMode.system)),
          ],
          child: Builder(
            builder: (ctx) {
              container = ProviderScope.containerOf(ctx);
              return const MaterialApp(home: ThemeSettingsScreen());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(themeModeSettingProvider), ThemeMode.system);

      await tester.tap(find.byKey(const Key('themeSettingsOptionDark')));
      await tester.pumpAndSettle();

      expect(container.read(themeModeSettingProvider), ThemeMode.dark);
    });

    testWidgets('tapping System option from Dark resets to System',
        (tester) async {
      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeModeSettingProvider
                .overrideWith(() => _FixedThemeMode(ThemeMode.dark)),
          ],
          child: Builder(
            builder: (ctx) {
              container = ProviderScope.containerOf(ctx);
              return const MaterialApp(home: ThemeSettingsScreen());
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(themeModeSettingProvider), ThemeMode.dark);

      await tester.tap(find.byKey(const Key('themeSettingsOptionSystem')));
      await tester.pumpAndSettle();

      expect(container.read(themeModeSettingProvider), ThemeMode.system);
    });

    testWidgets('all interactive options meet the 48dp tap-target guideline',
        (tester) async {
      await pumpApp(
        tester,
        const ThemeSettingsScreen(),
        overrides: [
          themeModeSettingProvider
              .overrideWith(() => _FixedThemeMode(ThemeMode.system)),
        ],
      );

      await expectLater(
        tester,
        meetsGuideline(androidTapTargetGuideline),
      );
    });
  });
}
