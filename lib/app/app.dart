import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/country/country_switch_listener.dart';
import '../core/language/language_provider.dart';
import '../core/notifications/notification_launch_listener.dart';
import '../core/theme/theme_mode_provider.dart';
import '../features/consumption/presentation/widgets/trip_recording_banner.dart';
import '../features/consumption/providers/trip_recording_provider.dart';
import '../features/widget/presentation/widget_click_listener.dart';
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
class TankstellenApp extends ConsumerStatefulWidget {
  const TankstellenApp({super.key});

  @override
  ConsumerState<TankstellenApp> createState() => _TankstellenAppState();
}

class _TankstellenAppState extends ConsumerState<TankstellenApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // #1303 phase C — observe app lifecycle so the in-progress
    // trip can force-flush its snapshot before the OS kills us.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.inactive) {
      return;
    }
    // Force-flush ONLY on `paused` — `inactive` fires on every
    // brief interruption (notifications, picker dialogs) and would
    // be wasteful. We still listen so a `paused` arriving via the
    // `inactive → paused` path routes through this observer.
    if (state != AppLifecycleState.paused) return;
    try {
      final notifier = ref.read(tripRecordingProvider.notifier);
      unawaited(notifier.onAppBackgrounded());
    } catch (e, st) {
      debugPrint('TankstellenApp: onAppBackgrounded failed: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final language = ref.watch(activeLanguageProvider);
    final themeMode = ref.watch(themeModeSettingProvider);

    return MaterialApp.router(
      // Keying on language.code forces a full rebuild whenever the user
      // changes locale, so AppLocalizations lookups everywhere refresh.
      key: ValueKey(language.code),
      title: 'Fuel Prices',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      locale: language.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        // #726 — TripRecordingBanner renders a thin "recording…"
        // strip above every screen whenever the trip provider is
        // active. Zero-height when idle.
        //
        // #1012 phase 3 — NotificationLaunchListener routes price-
        // alert notification taps to the cheapest matching station's
        // detail screen. Sits at the same layer as the home-widget
        // click listener so both deep-link sources share the same
        // post-builder navigation context.
        return NotificationLaunchListener(
          child: WidgetClickListener(
            child: CountrySwitchListener(
              child: TripRecordingBanner(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
