import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/features/consumption/presentation/widgets/fill_up_no_vehicle_cta.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Widget tests for [FillUpNoVehicleCta] (#706 / #563 extraction).
/// The CTA owns the whole screen when the vehicle list is empty. It
/// must:
///   * render the localised title + body + button text,
///   * push `/vehicles/edit` when "Add vehicle" is tapped,
///   * pop the route when the back-arrow leading icon is tapped.
///
/// Both navigation paths are exercised through a minimal in-test
/// [GoRouter] so we catch regressions like #695 (an unregistered
/// route silently no-op'ing).
void main() {
  const ctaLanding = ValueKey('cta-landing');
  const editStub = ValueKey('vehicle-edit-stub');
  const senderHome = ValueKey('sender-home');

  GoRouter buildRouter({String initial = '/'}) {
    return GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            key: senderHome,
            body: Center(child: Text('SENDER HOME')),
          ),
        ),
        GoRoute(
          path: '/fill-up/no-vehicle',
          builder: (_, _) => const Scaffold(
            key: ctaLanding,
            body: FillUpNoVehicleCta(),
          ),
        ),
        GoRoute(
          path: '/vehicles/edit',
          builder: (_, _) => const Scaffold(
            key: editStub,
            body: Center(child: Text('VEHICLE EDIT STUB')),
          ),
        ),
      ],
    );
  }

  Future<void> pumpCta(
    WidgetTester tester, {
    String initial = '/fill-up/no-vehicle',
  }) {
    final router = buildRouter(initial: initial);
    return tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    );
  }

  testWidgets('renders the localised title, body and Add-vehicle button',
      (tester) async {
    await pumpCta(tester);
    await tester.pumpAndSettle();

    expect(find.text('Add fill-up'), findsOneWidget,
        reason: 'PageScaffold app-bar title');
    expect(find.text('Add a vehicle first'), findsOneWidget,
        reason: 'consumptionNoVehicleTitle');
    expect(
      find.textContaining('Fill-ups are attributed to a vehicle'),
      findsOneWidget,
      reason: 'consumptionNoVehicleBody intro',
    );
    expect(find.widgetWithText(FilledButton, 'Add vehicle'), findsOneWidget);
    expect(find.byIcon(Icons.directions_car_outlined), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('tapping "Add vehicle" pushes /vehicles/edit', (tester) async {
    await pumpCta(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(editStub), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Add vehicle'));
    await tester.pumpAndSettle();

    expect(find.byKey(editStub), findsOneWidget,
        reason:
            'Tapping the Add-vehicle FilledButton must push the vehicle '
            'editor — guards against the #695-class regression where a '
            'wrong route key silently no-ops');
    expect(find.text('VEHICLE EDIT STUB'), findsOneWidget);
  });

  testWidgets(
      'tapping the leading back-arrow pops the CTA off the navigator',
      (tester) async {
    final router = buildRouter(initial: '/');
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();

    // Push the CTA on top of the home so there is something to pop back to.
    unawaited(router.push('/fill-up/no-vehicle'));
    await tester.pumpAndSettle();
    expect(find.byKey(ctaLanding), findsOneWidget);

    // Use the tooltip to disambiguate from any other IconButtons.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byKey(ctaLanding), findsNothing,
        reason: 'Back-arrow must pop the CTA off the stack');
    expect(find.byKey(senderHome), findsOneWidget,
        reason: 'And we land back on the home route');
  });
}
