// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/core/widgets/labeled_value_slider.dart';
import 'package:tankstellen/core/widgets/scope_badge.dart';
import 'package:tankstellen/features/driving/presentation/widgets/voice_announcements_settings_tile.dart';
import 'package:tankstellen/features/feature_management/domain/feature.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/driving_consumption_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/prices_alerts_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/profiles_region_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/radar_settings_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/units_display_screen.dart';
import 'package:tankstellen/features/profile/presentation/screens/settings/vehicles_obd2_screen.dart';
import 'package:tankstellen/features/profile/presentation/widgets/profile_list_section.dart';
import 'package:tankstellen/features/widget/presentation/widget_help_section.dart';
import 'package:tankstellen/l10n/app_localizations.dart';

import '../../../../../helpers/pump_app.dart';
import 'settings_test_harness.dart';

/// One minimal widget test per Settings topic screen (#3884), part 1:
/// Profiles & region · Vehicles & OBD2 · Driving & consumption · Radar ·
/// Prices & alerts · Units & display. Each pins that the screen renders
/// its hosted sections EXPANDED (no ExpansionTile anywhere).
void main() {
  Future<void> pumpTall(WidgetTester tester, Widget screen,
      {Set<Feature>? flags}) async {
    await tester.binding.setSurfaceSize(const Size(600, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpApp(tester, screen, overrides: settingsTestOverrides(flags: flags));
  }

  AppLocalizations l10n(WidgetTester tester, Type screen) =>
      AppLocalizations.of(tester.element(find.byType(screen)));

  testWidgets('Profiles & region hosts the profile list', (tester) async {
    await pumpTall(tester, const ProfilesRegionScreen());
    final l = l10n(tester, ProfilesRegionScreen);
    expect(find.text(l.settingsTopicProfilesTitle), findsOneWidget);
    expect(find.byType(ProfileListSection), findsOneWidget);
    expect(find.byType(ExpansionTile), findsNothing);
  });

  testWidgets('Vehicles & OBD2 hosts the vehicles tile and the per-vehicle '
      'OBD2 adapter tile with a "This vehicle" badge', (tester) async {
    await pumpTall(tester, const VehiclesObd2Screen());
    expect(find.byKey(const Key('settingsVehiclesTile')), findsOneWidget);
    expect(find.byKey(const Key('settingsObd2AdapterTile')), findsOneWidget);
    final badge = tester.widget<ScopeBadge>(find.byType(ScopeBadge));
    expect(badge.scope, SettingsScope.thisVehicle);
  });

  testWidgets('Driving & consumption hosts the radar tile ("This profile") '
      'above the driving section — coaching, rewards, troubleshooting',
      (tester) async {
    await pumpTall(
      tester,
      const DrivingConsumptionScreen(),
      flags: const {Feature.obd2TripRecording, Feature.showConsumptionTab},
    );
    final l = l10n(tester, DrivingConsumptionScreen);
    expect(find.byKey(const Key('settingsRadarTile')), findsOneWidget);
    expect(find.byKey(const Key('consoleVehiclesTile')), findsOneWidget);
    expect(find.byKey(const Key('hapticEcoCoachToggle')), findsOneWidget);
    expect(find.text(l.consoGroupCoaching), findsOneWidget);
    expect(find.text(l.consoGroupRewards), findsOneWidget);
    expect(find.byKey(const Key('obd2DebugLoggingToggle')), findsOneWidget);
    // The voice-announcement sliders moved to Prices & alerts.
    expect(find.byType(LabeledValueSlider), findsNothing);
    expect(find.byType(ExpansionTile), findsNothing);
    // Radar tile sits above the section (the #3883 slot is above both).
    expect(
      tester.getTopLeft(find.byKey(const Key('settingsRadarTile'))).dy,
      lessThan(
          tester.getTopLeft(find.byKey(const Key('consoleVehiclesTile'))).dy),
    );
  });

  testWidgets('Radar screen shows the no-profile hint and the app-wide '
      'auto-pin switch when there is no active profile', (tester) async {
    await pumpTall(tester, const RadarSettingsScreen());
    final l = l10n(tester, RadarSettingsScreen);
    expect(find.text(l.settingsRadarNoProfileHint), findsOneWidget);
    expect(find.byKey(const Key('settingsRadarAutoPinToggle')), findsOneWidget);
    expect(find.byKey(const Key('radarRadiusSlider')), findsNothing);
    final badges = tester.widgetList<ScopeBadge>(find.byType(ScopeBadge));
    expect(badges.map((b) => b.scope), contains(SettingsScope.allProfiles));
  });

  testWidgets('Prices & alerts hosts the alerts tile, the voice hint (flag '
      'off) and the four price feature switches', (tester) async {
    await pumpTall(tester, const PricesAlertsScreen());
    final l = l10n(tester, PricesAlertsScreen);
    expect(find.byKey(const Key('settingsAlertsTile')), findsOneWidget);
    expect(find.text(l.settingsVoiceAnnouncementsOffHint), findsOneWidget);
    expect(find.byType(VoiceAnnouncementsSettingsTile), findsNothing);
    for (final f in PricesAlertsScreen.priceFeatures) {
      expect(find.byKey(Key('featureToggle_${f.name}')), findsOneWidget,
          reason: '${f.name} must render as a switch bound to its flag');
    }
    expect(find.byType(ExpansionTile), findsNothing);
  });

  testWidgets('Prices & alerts hosts the voice-announcement sliders when '
      'the flag chain is on', (tester) async {
    await pumpTall(
      tester,
      const PricesAlertsScreen(),
      flags: const {
        Feature.approachOverlay,
        Feature.voiceFeedback,
        Feature.voiceAnnouncements,
      },
    );
    expect(find.byType(VoiceAnnouncementsSettingsTile), findsOneWidget);
    expect(find.byKey(const Key('voiceAnnouncementsToggle')), findsOneWidget);
  });

  testWidgets('Units & display hosts the theme tile, the read-only distance '
      'unit row and the widget section badged "This profile"',
      (tester) async {
    await pumpTall(tester, const UnitsDisplayScreen());
    final l = l10n(tester, UnitsDisplayScreen);
    expect(find.byKey(const Key('settingsThemeTile')), findsOneWidget);
    expect(find.text(l.themeCardSubtitleSystem), findsOneWidget);
    expect(find.byKey(const Key('settingsDistanceUnitRow')), findsOneWidget);
    expect(find.text(l.settingsDistanceUnitSubtitle), findsOneWidget);
    // No active profile → the km default; the row is display-only.
    expect(find.text('km'), findsOneWidget);
    expect(find.byType(WidgetHelpSection), findsOneWidget);
    final badge = tester.widget<ScopeBadge>(find.byType(ScopeBadge));
    expect(badge.scope, SettingsScope.thisProfile);
    expect(find.byType(ExpansionTile), findsNothing);
  });
}
