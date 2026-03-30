import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/country/country_switch_listener.dart';
import '../core/language/language_provider.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

class TankstellenApp extends ConsumerWidget {
  const TankstellenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final language = ref.watch(activeLanguageProvider);

    return MaterialApp.router(
      key: ValueKey(language.code), // Force full rebuild on language change
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
