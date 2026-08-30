// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/navigation/app_routes.dart';
import '../../../../../l10n/app_localizations.dart';

/// Identity of a Settings root tile (#3884, Epic #3881). The `name` is
/// used in widget keys (`settingsTopic_<name>`) so tests and the search
/// filter address a tile without depending on its localised title.
enum SettingsTopicId {
  profiles,
  vehicles,
  driving,
  prices,
  units,
  features,
  dataSources,
  sync,
  privacy,
  backup,
  advanced,
  about,
}

/// One scannable topic tile on the Settings root: icon, title, a
/// one-line subtitle naming what is inside, the route of its dedicated
/// screen, and search keywords (#3884).
class SettingsTopic {
  final SettingsTopicId id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String keywords;
  final String route;

  const SettingsTopic({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.keywords,
    required this.route,
  });

  /// Case-insensitive substring match of [query] against the title, the
  /// subtitle and the comma-separated keyword list. An empty / blank
  /// query matches everything.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        subtitle.toLowerCase().contains(q) ||
        keywords.toLowerCase().contains(q);
  }
}

/// The ordered topic list for the Settings root. Gated topics are
/// dropped here so the root never shows a tile whose screen would be
/// empty: Sync & account needs `Feature.tankSync`, Advanced & developer
/// needs the PAT or debug flag (#3884).
List<SettingsTopic> buildSettingsTopics(
  AppLocalizations l, {
  required bool tankSyncOn,
  required bool advancedOn,
}) {
  return [
    SettingsTopic(
      id: SettingsTopicId.profiles,
      icon: Icons.person_outline,
      title: l.settingsTopicProfilesTitle,
      subtitle: l.settingsTopicProfilesSubtitle,
      keywords: l.settingsTopicProfilesKeywords,
      route: RoutePaths.settingsProfiles,
    ),
    SettingsTopic(
      id: SettingsTopicId.vehicles,
      icon: Icons.directions_car_outlined,
      title: l.settingsTopicVehiclesTitle,
      subtitle: l.settingsTopicVehiclesSubtitle,
      keywords: l.settingsTopicVehiclesKeywords,
      route: RoutePaths.settingsVehicles,
    ),
    SettingsTopic(
      id: SettingsTopicId.driving,
      icon: Icons.speed_outlined,
      title: l.settingsTopicDrivingTitle,
      subtitle: l.settingsTopicDrivingSubtitle,
      keywords: l.settingsTopicDrivingKeywords,
      route: RoutePaths.settingsDriving,
    ),
    SettingsTopic(
      id: SettingsTopicId.prices,
      icon: Icons.notifications_outlined,
      title: l.settingsTopicPricesTitle,
      subtitle: l.settingsTopicPricesSubtitle,
      keywords: l.settingsTopicPricesKeywords,
      route: RoutePaths.settingsPrices,
    ),
    SettingsTopic(
      id: SettingsTopicId.units,
      icon: Icons.palette_outlined,
      title: l.settingsTopicUnitsTitle,
      subtitle: l.settingsTopicUnitsSubtitle,
      keywords: l.settingsTopicUnitsKeywords,
      route: RoutePaths.settingsUnits,
    ),
    SettingsTopic(
      id: SettingsTopicId.features,
      icon: Icons.dashboard_customize_outlined,
      title: l.settingsTopicFeaturesTitle,
      subtitle: l.settingsTopicFeaturesSubtitle,
      keywords: l.settingsTopicFeaturesKeywords,
      route: RoutePaths.settingsFeatures,
    ),
    SettingsTopic(
      id: SettingsTopicId.dataSources,
      icon: Icons.my_location_outlined,
      title: l.settingsTopicDataSourcesTitle,
      subtitle: l.settingsTopicDataSourcesSubtitle,
      keywords: l.settingsTopicDataSourcesKeywords,
      route: RoutePaths.settingsDataSources,
    ),
    if (tankSyncOn)
      SettingsTopic(
        id: SettingsTopicId.sync,
        icon: Icons.cloud_outlined,
        title: l.settingsTopicSyncTitle,
        // #1696 — the brand-named section carries a localised subtitle.
        subtitle: l.tankSyncSectionSubtitle,
        keywords: l.settingsTopicSyncKeywords,
        route: RoutePaths.settingsSync,
      ),
    SettingsTopic(
      id: SettingsTopicId.privacy,
      icon: Icons.privacy_tip_outlined,
      title: l.sectionPrivacyData,
      subtitle: l.settingsTopicPrivacySubtitle,
      keywords: l.settingsTopicPrivacyKeywords,
      route: RoutePaths.settingsPrivacy,
    ),
    SettingsTopic(
      id: SettingsTopicId.backup,
      icon: Icons.archive_outlined,
      title: l.settingsTopicBackupTitle,
      subtitle: l.settingsTopicBackupSubtitle,
      keywords: l.settingsTopicBackupKeywords,
      route: RoutePaths.settingsBackup,
    ),
    if (advancedOn)
      SettingsTopic(
        id: SettingsTopicId.advanced,
        icon: Icons.developer_mode,
        title: l.sectionAdvancedDeveloper,
        subtitle: l.settingsTopicAdvancedSubtitle,
        keywords: l.settingsTopicAdvancedKeywords,
        route: RoutePaths.settingsAdvanced,
      ),
    SettingsTopic(
      id: SettingsTopicId.about,
      icon: Icons.info_outline,
      title: l.about,
      subtitle: l.settingsTopicAboutSubtitle,
      keywords: l.settingsTopicAboutKeywords,
      route: RoutePaths.settingsAbout,
    ),
  ];
}
