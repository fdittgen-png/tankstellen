// Widget tests for `lib/app/app.dart` (#561 — zero-coverage backlog).
//
// `TankstellenApp` is the top-level Material app: it reads three providers
// (`routerProvider`, `activeLanguageProvider`, `themeModeSettingProvider`)
// and assembles a `MaterialApp.router` whose `builder:` wraps every screen
// in a chain of listener widgets:
//
//   NotificationLaunchListener
//     > WidgetClickListener
//       > CountrySwitchListener
//         > TripRecordingBanner
//           > <screen>
//
// These tests verify the parts that are pure widget-tree composition:
//
//   * `MaterialApp.router` is the root, with `title: 'Fuel Prices'`,
//     `debugShowCheckedModeBanner: false`, and `routerConfig` set.
//   * `themeMode` reflects `themeModeSettingProvider`.
//   * `locale` and the `ValueKey` reflect `activeLanguageProvider`.
//   * `localizationsDelegates` and `supportedLocales` come from
//     `AppLocalizations`.
//   * The wrapper chain is mounted in the documented order.
//
// We don't run end-to-end navigation here — `test/app/router_test.dart`
// already covers the `GoRouter` redirect logic. The home-widget /
// notification platform channels are stubbed at the binary messenger
// so the listeners (which probe the plugins in `initState`) mount
// without throwing.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tankstellen/app/app.dart';
import 'package:tankstellen/app/router.dart';
import 'package:tankstellen/core/country/country_switch_listener.dart';
import 'package:tankstellen/core/language/language_provider.dart';
import 'package:tankstellen/core/notifications/notification_launch_listener.dart';
import 'package:tankstellen/core/storage/storage_keys.dart';
import 'package:tankstellen/core/theme/theme_mode_provider.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/trip_recording_banner.dart';
import 'package:tankstellen/features/widget/presentation/widget_click_listener.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../helpers/mock_providers.dart';

/// Fixed [ActiveLanguage] notifier — keeps the language pinned to the
/// passed value so tests can assert locale / key without depending on
/// platform locale or persisted profile state.
class _FixedActiveLanguage extends ActiveLanguage {
  final AppLanguage _language;
  _FixedActiveLanguage(this._language);

  @override
  AppLanguage build() => _language;
}

/// Fixed [ThemeModeSetting] — `ThemeModeSetting.build()` kicks off a
/// background `_load()` that reads SharedPreferences. Overriding the
/// notifier short-circuits that I/O so the tests don't depend on
/// platform-channel stubs for SharedPreferences.
class _FixedThemeMode extends ThemeModeSetting {
  final ThemeMode _mode;
  _FixedThemeMode(this._mode);

  @override
  ThemeMode build() => _mode;
}

/// A trivial single-screen [GoRouter] used in place of the real one.
/// The real router (`routerProvider`) walks the GDPR / setup gating
/// logic and pulls in five tab branches with their full widget trees;
/// none of that is the unit-under-test here. A one-route router is
/// sufficient to verify that `routerConfig` is wired through.
GoRouter _stubRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(
          body: Center(child: Text('home', key: Key('stubHome'))),
        ),
      ),
    ],
  );
}

/// Override the [routerProvider] to return [_stubRouter]. Used everywhere
/// instead of the real provider to keep the test surface tight.
Object _stubRouterOverride(GoRouter router) {
  return routerProvider.overrideWithValue(router);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The wrapper widgets ([WidgetClickListener] and
  // [NotificationLaunchListener]) probe their respective plugins in
  // `initState` via `home_widget` and `flutter_local_notifications`.
  // Stub both MethodChannels so the probes return benign values
  // instead of throwing MissingPluginException.
  const homeWidgetChannel = MethodChannel('home_widget');
  const localNotificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');

  setUpAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(homeWidgetChannel, (call) async {
      // `initiallyLaunchedFromHomeWidget` is the only call that fires
      // from `WidgetClickListener.initState`. Returning null = "no
      // launch URI" = no navigation, which is what we want in tests.
      return null;
    });
    messenger.setMockMethodCallHandler(localNotificationsChannel,
        (call) async {
      // `getNotificationAppLaunchDetails` returns a map; null means
      // "app was not launched from a notification". `initialize`
      // returns true. Cover both so the cold-launch probe completes.
      switch (call.method) {
        case 'getNotificationAppLaunchDetails':
          return null;
        case 'initialize':
          return true;
        default:
          return null;
      }
    });
  });

  tearDownAll(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(homeWidgetChannel, null);
    messenger.setMockMethodCallHandler(localNotificationsChannel, null);
  });

  /// Builds the override list that lets [TankstellenApp] mount in
  /// isolation. Tests vary [language] and [themeMode] to exercise the
  /// pass-through behaviour.
  List<Object> buildOverrides({
    required AppLanguage language,
    required ThemeMode themeMode,
    required GoRouter router,
  }) {
    final test = standardTestOverrides();
    when(() => test.mockStorage.hasApiKey()).thenReturn(false);
    when(() => test.mockStorage.isSetupComplete).thenReturn(true);
    when(() => test.mockStorage.getActiveProfileId()).thenReturn(null);
    when(() => test.mockStorage.getAllProfiles()).thenReturn([]);
    when(() => test.mockStorage.getSetting(StorageKeys.gdprConsentGiven))
        .thenReturn(true);
    when(() => test.mockStorage.getSetting(any())).thenReturn(null);

    return <Object>[
      ...test.overrides,
      _stubRouterOverride(router),
      activeLanguageProvider.overrideWith(() => _FixedActiveLanguage(language)),
      themeModeSettingProvider.overrideWith(() => _FixedThemeMode(themeMode)),
    ];
  }

  group('TankstellenApp top-level config (#561)', () {
    testWidgets('mounts without throwing', (tester) async {
      final router = _stubRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: buildOverrides(
            language: AppLanguages.byCode('en')!,
            themeMode: ThemeMode.system,
            router: router,
          ).cast(),
          child: const TankstellenApp(),
        ),
      );
      // Pump once for the router's first frame; pumpAndSettle would
      // wait on the listener widgets' post-frame callbacks, which we
      // don't need to drive for a smoke test.
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('MaterialApp.router has title "Fuel Prices" and '
        'debugShowCheckedModeBanner: false', (tester) async {
      final router = _stubRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: buildOverrides(
            language: AppLanguages.byCode('en')!,
            themeMode: ThemeMode.system,
            router: router,
          ).cast(),
          child: const TankstellenApp(),
        ),
      );
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, 'Fuel Prices');
      expect(app.debugShowCheckedModeBanner, isFalse);
      expect(app.routerConfig, same(router));
    });

    testWidgets('themeMode reflects themeModeSettingProvider', (tester) async {
      final router = _stubRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: buildOverrides(
            language: AppLanguages.byCode('en')!,
            themeMode: ThemeMode.dark,
            router: router,
          ).cast(),
          child: const TankstellenApp(),
        ),
      );
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      expect(app.theme, isNotNull, reason: 'light theme always supplied');
      expect(app.darkTheme, isNotNull, reason: 'dark theme always supplied');
    });

    testWidgets('locale + ValueKey reflect activeLanguageProvider',
        (tester) async {
      final router = _stubRouter();
      addTearDown(router.dispose);
      final french = AppLanguages.byCode('fr')!;
      await tester.pumpWidget(
        ProviderScope(
          overrides: buildOverrides(
            language: french,
            themeMode: ThemeMode.system,
            router: router,
          ).cast(),
          child: const TankstellenApp(),
        ),
      );
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('fr'));
      // Keying the MaterialApp on language.code is what forces the
      // full-tree rebuild on language switch — guard the contract.
      expect(app.key, const ValueKey('fr'));
    });

    testWidgets('localizationsDelegates / supportedLocales come from '
        'AppLocalizations', (tester) async {
      final router = _stubRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: buildOverrides(
            language: AppLanguages.byCode('en')!,
            themeMode: ThemeMode.system,
            router: router,
          ).cast(),
          child: const TankstellenApp(),
        ),
      );
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.localizationsDelegates,
          AppLocalizations.localizationsDelegates);
      expect(app.supportedLocales, AppLocalizations.supportedLocales);
    });

    testWidgets('builder mounts the listener wrapper chain in the '
        'documented order: Notification > WidgetClick > CountrySwitch > '
        'TripRecordingBanner > screen', (tester) async {
      final router = _stubRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: buildOverrides(
            language: AppLanguages.byCode('en')!,
            themeMode: ThemeMode.system,
            router: router,
          ).cast(),
          child: const TankstellenApp(),
        ),
      );
      // Pump twice so the post-frame cold-launch dispatch fires (the
      // listeners both schedule a probe via addPostFrameCallback).
      // Using pump rather than pumpAndSettle avoids waiting on the
      // periodic position / profile detection providers that the
      // listener tree subscribes to indirectly.
      await tester.pump();
      await tester.pump();

      // Each wrapper should appear exactly once.
      expect(find.byType(NotificationLaunchListener), findsOneWidget);
      expect(find.byType(WidgetClickListener), findsOneWidget);
      expect(find.byType(CountrySwitchListener), findsOneWidget);
      expect(find.byType(TripRecordingBanner), findsOneWidget);

      // Ordering guard — a future refactor that swaps two listeners
      // would still pass the four `findsOneWidget`s above. Walking
      // ancestors locks in the *outer* relationship that the comment
      // in `app.dart` documents.
      final widgetClickEl = find.byType(WidgetClickListener).evaluate().single;
      final notificationAncestor = widgetClickEl.findAncestorWidgetOfExactType<
          NotificationLaunchListener>();
      expect(notificationAncestor, isNotNull,
          reason: 'NotificationLaunchListener wraps WidgetClickListener');

      final countrySwitchEl =
          find.byType(CountrySwitchListener).evaluate().single;
      final widgetClickAncestor =
          countrySwitchEl.findAncestorWidgetOfExactType<WidgetClickListener>();
      expect(widgetClickAncestor, isNotNull,
          reason: 'WidgetClickListener wraps CountrySwitchListener');

      final tripBannerEl =
          find.byType(TripRecordingBanner).evaluate().single;
      final countrySwitchAncestor = tripBannerEl
          .findAncestorWidgetOfExactType<CountrySwitchListener>();
      expect(countrySwitchAncestor, isNotNull,
          reason: 'CountrySwitchListener wraps TripRecordingBanner');

      // And the stub home screen actually renders inside it all.
      expect(find.byKey(const Key('stubHome')), findsOneWidget);
    });
  });
}
