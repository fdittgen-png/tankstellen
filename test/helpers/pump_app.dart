import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Pumps a widget wrapped in ProviderScope + MaterialApp with localization.
///
/// Use [overrides] to inject mock providers for isolated testing.
/// Use [locale] to override the default English locale (e.g. for RTL testing).
/// Use [textDirection] to force a specific text direction independent of locale.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Object>? overrides,
  Locale locale = const Locale('en'),
  TextDirection? textDirection,
}) async {
  Widget body = child;
  if (textDirection != null) {
    body = Directionality(
      textDirection: textDirection,
      child: body,
    );
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides?.cast() ?? [],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: Scaffold(body: body),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Convenience wrapper that pumps a widget in an RTL text direction.
///
/// Useful for verifying that layouts, alignment, and icon placement
/// behave correctly for RTL languages like Arabic and Hebrew.
Future<void> pumpRtlApp(
  WidgetTester tester,
  Widget child, {
  List<Object>? overrides,
}) async {
  await pumpApp(
    tester,
    child,
    overrides: overrides,
    textDirection: TextDirection.rtl,
  );
}
