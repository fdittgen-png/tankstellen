import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/shell/settings_app_bar_action.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

/// Tests for the top-right Settings gear that replaced the Settings
/// bottom-nav tab (#1874).
void main() {
  testWidgets('renders a settings gear icon with a localized tooltip',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: const Scaffold(
          appBar: _ActionBar(),
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
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        routerConfig: router,
      ),
    );

    expect(find.text('PROFILE'), findsNothing);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('PROFILE'), findsOneWidget);
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
