// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/driving/presentation/widgets/driving_settings_section.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/presentation/screens/profile_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/advanced_developer_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/driving_consumption_screen.dart';

import '../../../../helpers/pump_app.dart';
import 'settings/settings_test_harness.dart';

/// #1447 phase 3 — settings surfaces whose root feature is effectively
/// disabled must vanish. After #3884 the gates live in two places: the
/// root drops the Sync & account / Advanced & developer TILES, and the
/// Driving & consumption SCREEN swaps the consumption section for a hint.
void main() {
  group('Settings gating (#1447 phase 3, #3884)', () {
    Finder tile(String id) =>
        find.byKey(Key('settingsTopic_$id'), skipOffstage: false);

    testWidgets('Sync & account tile hides when Feature.tankSync is off',
        (tester) async {
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: settingsTestOverrides(flags: const <Feature>{}),
      );
      expect(tile('sync'), findsNothing,
          reason: 'Sync & account must not appear when Feature.tankSync '
              'is effectively-disabled (#1447 phase 3).');
      expect(find.text('TankSync'), findsNothing);
    });

    testWidgets('Sync & account tile renders with Feature.tankSync on, '
        'independently of the consumption flags', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: settingsTestOverrides(flags: const {Feature.tankSync}),
      );
      expect(tile('sync'), findsOneWidget);
      // Driving & consumption stays visible regardless (the radar lives
      // there); only its consumption section is gated (below).
      expect(tile('driving'), findsOneWidget);
    });

    testWidgets('Driving & consumption shows the hint (not the section) '
        'when the consumption surface is unreachable', (tester) async {
      await pumpApp(
        tester,
        const DrivingConsumptionScreen(),
        overrides: settingsTestOverrides(flags: const <Feature>{}),
      );
      expect(find.byType(DrivingSettingsSection), findsNothing,
          reason: 'the whole consumption-settings group (vehicles, '
              'eco-coach, fuel club cards) lives behind the '
              'isConsumptionTabReachable gate.');
      expect(find.byKey(const Key('settingsOpenFeaturesLink')), findsOneWidget);
      // The radar tile is NOT gated — it belongs to the active profile.
      expect(find.byKey(const Key('settingsRadarTile')), findsOneWidget);
    });

    testWidgets('Driving & consumption hosts the section when the '
        'consumption surface is reachable', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(
        tester,
        const DrivingConsumptionScreen(),
        overrides: settingsTestOverrides(flags: const {
          Feature.obd2TripRecording,
          // #1520: reachability needs showConsumptionTab + a data source.
          Feature.showConsumptionTab,
        }),
      );
      expect(find.byType(DrivingSettingsSection), findsOneWidget);
      expect(find.byKey(const Key('settingsOpenFeaturesLink')), findsNothing);
    });

    // #2248 — the Developer tools entry is gated on Feature.debugMode and
    // must never render for a production (default) user.
    testWidgets('Advanced & developer tile hides when neither the PAT nor '
        'the debug flag is on (default)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpApp(
        tester,
        const ProfileScreen(),
        overrides: settingsTestOverrides(flags: const <Feature>{}),
      );
      expect(tile('advanced'), findsNothing,
          reason: 'debugMode is default-off, so production users must '
              'never see the Developer tools entry (#2248).');
      expect(find.text('Developer tools', skipOffstage: false), findsNothing);
    });

    testWidgets('Advanced & developer renders the Developer tools tile with '
        'debugMode on (and no PAT section)', (tester) async {
      await pumpApp(
        tester,
        const AdvancedDeveloperScreen(),
        overrides: settingsTestOverrides(flags: const {Feature.debugMode}),
      );
      expect(find.byKey(const Key('settingsDeveloperToolsTile')),
          findsOneWidget);
      expect(find.text('Bad-scan feedback (GitHub)'), findsNothing);
    });

    testWidgets('Advanced & developer renders the PAT section with '
        'developerPatToken on (and no Developer tools tile)',
        (tester) async {
      await pumpApp(
        tester,
        const AdvancedDeveloperScreen(),
        overrides:
            settingsTestOverrides(flags: const {Feature.developerPatToken}),
      );
      expect(find.byKey(const Key('settingsDeveloperToolsTile')),
          findsNothing);
      expect(find.text('Bad-scan feedback (GitHub)'), findsOneWidget);
    });
  });
}
