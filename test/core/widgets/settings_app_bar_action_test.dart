// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/core/widgets/settings_app_bar_action.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Tests for the top-right Settings gear that replaced the Settings
/// bottom-nav tab (#1874).
void main() {
  testWidgets('renders a settings gear icon with a localized tooltip',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en'),
          home: Scaffold(
            appBar: _ActionBar(),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.tooltip, 'Settings');
  });

  testWidgets('tapping it routes to the /profile branch', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(appBar: _ActionBar()),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('PROFILE'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );

    expect(find.text('PROFILE'), findsNothing);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('PROFILE'), findsOneWidget);
  });

  // #3061 — the gear records where the user came from (their shell branch,
  // mapped to its route) so `ProfileScreen`'s back arrow returns there. The
  // two halves of that logic are unit-tested deterministically below; the
  // on-tap wiring (`routeForShellBranch(ref.read(currentShellBranchProvider))`)
  // is exercised end-to-end in the running app.
  test('routeForShellBranch maps each shell branch index to its route', () {
    expect(routeForShellBranch(0), '/'); // Search / home
    expect(routeForShellBranch(1), '/map');
    expect(routeForShellBranch(2), '/favorites');
    expect(routeForShellBranch(3), '/consumption-tab');
    expect(routeForShellBranch(4), '/'); // Settings itself → home fallback
    expect(routeForShellBranch(5), '/trajets-tab');
  });

  test('SettingsReturnLocation defaults to home and records an updated route',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(settingsReturnLocationProvider), '/');
    container
        .read(settingsReturnLocationProvider.notifier)
        .update('/favorites');
    expect(container.read(settingsReturnLocationProvider), '/favorites');
  });
}

/// Minimal AppBar carrying the action under test.
class _ActionBar extends StatelessWidget implements PreferredSizeWidget {
  const _ActionBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) =>
      AppBar(actions: const [SettingsAppBarAction()]);
}
