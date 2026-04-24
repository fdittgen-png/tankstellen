import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/theme/theme_mode_provider.dart';
import 'package:tankstellen/core/theme/theme_mode_tile.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../helpers/pump_app.dart';

/// Test-only ThemeModeSetting that exposes a fixed `build()` value and
/// skips the real provider's SharedPreferences load — widget tests do
/// not register plugin channels for SharedPreferences.
///
/// `set()` is also instrumented so tests can assert the exact value
/// the tile passed to the notifier when the picker sheet selection
/// resolved.
class _FixedThemeMode extends ThemeModeSetting {
  _FixedThemeMode(this._initial);

  final ThemeMode _initial;
  final List<ThemeMode> setCalls = <ThemeMode>[];

  @override
  ThemeMode build() => _initial;

  @override
  Future<void> set(ThemeMode mode) async {
    setCalls.add(mode);
    state = mode;
  }
}

void main() {
  group('ThemeModeTile (#752)', () {
    testWidgets('renders ListTile with key "themeModeTile" and Theme title',
        (tester) async {
      await pumpApp(
        tester,
        const ThemeModeTile(),
        overrides: [
          themeModeSettingProvider
              .overrideWith(() => _FixedThemeMode(ThemeMode.system)),
        ],
      );

      expect(find.byKey(const Key('themeModeTile')), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('subtitle reads "Follow system" + smartphone icon for system',
        (tester) async {
      await pumpApp(
        tester,
        const ThemeModeTile(),
        overrides: [
          themeModeSettingProvider
              .overrideWith(() => _FixedThemeMode(ThemeMode.system)),
        ],
      );

      expect(find.text('Follow system'), findsOneWidget);
      // Leading icon for ThemeMode.system is Icons.smartphone.
      expect(find.byIcon(Icons.smartphone), findsOneWidget);
    });

    testWidgets('subtitle reads "Light" + light_mode icon for light',
        (tester) async {
      await pumpApp(
        tester,
        const ThemeModeTile(),
        overrides: [
          themeModeSettingProvider
              .overrideWith(() => _FixedThemeMode(ThemeMode.light)),
        ],
      );

      expect(find.text('Light'), findsOneWidget);
      expect(find.byIcon(Icons.light_mode), findsOneWidget);
    });

    testWidgets('subtitle reads "Dark" + dark_mode icon for dark',
        (tester) async {
      await pumpApp(
        tester,
        const ThemeModeTile(),
        overrides: [
          themeModeSettingProvider
              .overrideWith(() => _FixedThemeMode(ThemeMode.dark)),
        ],
      );

      expect(find.text('Dark'), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    });

    testWidgets('renders the chevron_right trailing affordance',
        (tester) async {
      await pumpApp(
        tester,
        const ThemeModeTile(),
        overrides: [
          themeModeSettingProvider
              .overrideWith(() => _FixedThemeMode(ThemeMode.system)),
        ],
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('tap opens the picker bottom sheet with three radio rows',
        (tester) async {
      await pumpApp(
        tester,
        const ThemeModeTile(),
        overrides: [
          themeModeSettingProvider
              .overrideWith(() => _FixedThemeMode(ThemeMode.system)),
        ],
      );

      await tester.tap(find.byKey(const Key('themeModeTile')));
      await tester.pumpAndSettle();

      // Three RadioListTile<ThemeMode> rows, each with a stable key.
      expect(find.byKey(const Key('themeModeOptionLight')), findsOneWidget);
      expect(find.byKey(const Key('themeModeOptionDark')), findsOneWidget);
      expect(find.byKey(const Key('themeModeOptionSystem')), findsOneWidget);

      // The sheet renders a centered "Theme" header above the options;
      // combined with the tile title we now find two "Theme" texts.
      expect(find.text('Theme'), findsNWidgets(2));
      // The active mode label ("Follow system") shows both in the tile
      // subtitle and as the System option label inside the sheet.
      expect(find.text('Follow system'), findsNWidgets(2));
      // The other two option labels appear only inside the sheet.
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets(
        'selecting a different option dismisses the sheet and calls '
        'notifier.set with the picked ThemeMode', (tester) async {
      final fake = _FixedThemeMode(ThemeMode.system);
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeModeSettingProvider.overrideWith(() => fake),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  container = ProviderScope.containerOf(ctx);
                  return const ThemeModeTile();
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Baseline.
      expect(container.read(themeModeSettingProvider), ThemeMode.system);
      expect(fake.setCalls, isEmpty);

      // Open the picker.
      await tester.tap(find.byKey(const Key('themeModeTile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('themeModeOptionDark')), findsOneWidget);

      // Pick "Dark".
      await tester.tap(find.byKey(const Key('themeModeOptionDark')));
      await tester.pumpAndSettle();

      // Sheet popped — the option keys are gone.
      expect(find.byKey(const Key('themeModeOptionDark')), findsNothing);
      expect(find.byKey(const Key('themeModeOptionLight')), findsNothing);
      expect(find.byKey(const Key('themeModeOptionSystem')), findsNothing);

      // Notifier was called exactly once with ThemeMode.dark — and the
      // provider state reflects that selection.
      expect(fake.setCalls, [ThemeMode.dark]);
      expect(container.read(themeModeSettingProvider), ThemeMode.dark);
    });

    testWidgets('selecting the already-active mode does NOT call notifier.set',
        (tester) async {
      final fake = _FixedThemeMode(ThemeMode.dark);

      await pumpApp(
        tester,
        const ThemeModeTile(),
        overrides: [
          themeModeSettingProvider.overrideWith(() => fake),
        ],
      );

      // Open the picker — the sheet's RadioGroup has Dark as groupValue.
      await tester.tap(find.byKey(const Key('themeModeTile')));
      await tester.pumpAndSettle();

      // Tap the already-selected Dark row. RadioGroup's onChanged only
      // fires when the value differs from groupValue, so the sheet must
      // remain open and notifier.set must NOT be invoked.
      await tester.tap(find.byKey(const Key('themeModeOptionDark')));
      await tester.pumpAndSettle();

      expect(fake.setCalls, isEmpty);
      // Sheet still open: option keys remain visible.
      expect(find.byKey(const Key('themeModeOptionDark')), findsOneWidget);
    });

    testWidgets('all interactive targets meet the 48dp tap-target guideline',
        (tester) async {
      await pumpApp(
        tester,
        const ThemeModeTile(),
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
