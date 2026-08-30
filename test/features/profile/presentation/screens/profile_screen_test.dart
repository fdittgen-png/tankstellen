// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tankstellen/app/routes/profile_routes.dart';
import 'package:tankstellen/core/widgets/settings_menu_tile.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/presentation/screens/profile_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/backup_restore_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/settings_topics.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../helpers/pump_app.dart';
import 'settings/settings_test_harness.dart';

/// Settings root (#3884, Epic #3881): a scannable list of topic tiles
/// plus a search field — no collapsed foldables, no inline controls.
void main() {
  group('ProfileScreen — settings root (#3884)', () {
    /// The topics every install sees (Sync & account needs tankSync,
    /// Advanced & developer needs the PAT/debug flag).
    const alwaysVisible = <SettingsTopicId>[
      SettingsTopicId.profiles,
      SettingsTopicId.vehicles,
      SettingsTopicId.driving,
      SettingsTopicId.prices,
      SettingsTopicId.units,
      SettingsTopicId.features,
      SettingsTopicId.dataSources,
      SettingsTopicId.privacy,
      SettingsTopicId.backup,
      SettingsTopicId.about,
    ];

    Finder tile(SettingsTopicId id) =>
        find.byKey(Key('settingsTopic_${id.name}'), skipOffstage: false);

    testWidgets('renders Scaffold with Settings title and the search field',
        (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: settingsTestOverrides(),
      );

      expect(find.byType(Scaffold), findsAtLeast(1));
      expect(find.text('Settings'), findsOneWidget);
      expect(find.byKey(const Key('settingsSearchField')), findsOneWidget);
    });

    testWidgets('renders every always-visible topic tile, in order, and '
        'hides the gated ones by default', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: settingsTestOverrides(),
      );

      double top(SettingsTopicId id) => tester.getTopLeft(tile(id)).dy;
      for (var i = 0; i < alwaysVisible.length; i++) {
        expect(tile(alwaysVisible[i]), findsOneWidget,
            reason: 'topic ${alwaysVisible[i].name} must render a tile');
        if (i > 0) {
          expect(top(alwaysVisible[i]), greaterThan(top(alwaysVisible[i - 1])),
              reason: '${alwaysVisible[i].name} must follow '
                  '${alwaysVisible[i - 1].name}');
        }
      }
      expect(tile(SettingsTopicId.sync), findsNothing,
          reason: 'Sync & account is gated on Feature.tankSync');
      expect(tile(SettingsTopicId.advanced), findsNothing,
          reason: 'Advanced & developer is gated on the PAT/debug flag');
      // Every tile is a SettingsMenuTile with a one-line subtitle.
      expect(
        tester.widgetList<SettingsMenuTile>(find.byType(SettingsMenuTile)),
        hasLength(alwaysVisible.length),
      );
    });

    testWidgets('has NO collapsed foldables or inline controls at the root',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: settingsTestOverrides(),
      );

      expect(find.byType(ExpansionTile, skipOffstage: false), findsNothing);
      expect(find.byType(SwitchListTile, skipOffstage: false), findsNothing);
      expect(find.byType(Slider, skipOffstage: false), findsNothing);
    });

    testWidgets('search filters the tiles by title, subtitle and keywords',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: settingsTestOverrides(),
      );
      final l = AppLocalizations.of(tester.element(find.byType(ProfileScreen)));

      // Title match.
      await tester.enterText(
          find.byKey(const Key('settingsSearchField')), 'backup');
      await tester.pumpAndSettle();
      expect(tile(SettingsTopicId.backup), findsOneWidget);
      expect(find.byType(SettingsMenuTile), findsOneWidget);

      // Keyword-only match ("gps" is not in the tile title/subtitle of
      // Data sources & location's title but is in its keyword list).
      await tester.enterText(
          find.byKey(const Key('settingsSearchField')), 'GPS');
      await tester.pumpAndSettle();
      expect(tile(SettingsTopicId.dataSources), findsOneWidget);
      expect(tile(SettingsTopicId.backup), findsNothing);

      // No match → empty state naming the query.
      await tester.enterText(
          find.byKey(const Key('settingsSearchField')), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.byType(SettingsMenuTile), findsNothing);
      expect(find.byKey(const Key('settingsSearchEmpty')), findsOneWidget);
      expect(find.text(l.settingsSearchNoResults('zzzz')), findsOneWidget);

      // Clear restores every tile.
      await tester.tap(find.byKey(const Key('settingsSearchClear')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsMenuTile), findsNWidgets(alwaysVisible.length));
    });

    testWidgets('Sync & account tile appears with Feature.tankSync on',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: settingsTestOverrides(flags: {Feature.tankSync}),
      );
      expect(tile(SettingsTopicId.sync), findsOneWidget);
      expect(tile(SettingsTopicId.advanced), findsNothing);
    });

    testWidgets('Advanced & developer tile appears with debugMode on',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: settingsTestOverrides(flags: {Feature.debugMode}),
      );
      expect(tile(SettingsTopicId.advanced), findsOneWidget);
      expect(tile(SettingsTopicId.sync), findsNothing);
    });

    testWidgets('tapping a tile pushes its registered topic route',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (_, _) => const ProfileScreen()),
          ...profileRoutes,
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: settingsTestOverrides().cast(),
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(tile(SettingsTopicId.backup));
      await tester.pumpAndSettle();
      expect(find.byType(BackupRestoreScreen), findsOneWidget);
    });
  });
}
