import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/country/country_switch_listener.dart';
import '../core/language/language_provider.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

/// Top-level Material app for Tankstellen. This is the *only* widget
/// constructed directly from `main()` (via [AppInitializer]); everything
/// else is reached through `routerProvider`'s `GoRouter` config.
///
/// Three pieces of state are wired in here that affect the whole app:
///
///   * `routerProvider` — the [GoRouter] instance that owns navigation
///     and the consent/setup gating redirects (see `lib/app/router.dart`).
///   * `activeLanguageProvider` — exposes the user-selected [Locale]. The
///     widget is keyed on `language.code` so changing the language tears
///     down and rebuilds the entire tree (the easiest way to flush
///     `AppLocalizations` lookups everywhere).
///   * `CountrySwitchListener` — wraps the navigator so that switching
///     country in Settings invalidates the search cache and pops back to
///     the search shell. Lives in `builder` (not as a child of the
///     `MaterialApp`) so it can use `context.go` against the router.
///
/// Theme/dark mode follow the system. Light/dark themes live in
/// `lib/app/theme.dart`. Localization delegates come from the generated
/// `AppLocalizations`.
class TankstellenApp extends ConsumerWidget {
  const TankstellenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final language = ref.watch(activeLanguageProvider);

    return MaterialApp.router(
      // Keying on language.code forces a full rebuild whenever the user
      // changes locale, so AppLocalizations lookups everywhere refresh.
      key: ValueKey(language.code),
      title: 'Fuel Prices',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: language.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return CountrySwitchListener(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
