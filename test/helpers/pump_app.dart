import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Pumps a widget wrapped in ProviderScope + MaterialApp with localization.
///
/// Use [overrides] to inject mock providers for isolated testing.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<Object>? overrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides?.cast() ?? [],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
