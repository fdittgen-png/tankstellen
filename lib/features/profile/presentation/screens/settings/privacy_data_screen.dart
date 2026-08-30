// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/app_routes.dart';
import '../../../../../core/widgets/section_card.dart';
import '../../../../../core/widgets/settings_menu_tile.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../consent/api.dart'
    show ConsentSettingsSection, PrivacyControlsSection;
import '../../widgets/storage_section.dart';
import 'settings_topic_scaffold.dart';

/// Settings → Privacy & data (#3884): the five consents (incl. the
/// trip-sync consent, back next to Cloud Sync), the privacy controls
/// (#3870), the Privacy Dashboard tile — which owns deletion — and
/// Storage & cache (without its former duplicate Delete-all button).
class PrivacyDataScreen extends StatelessWidget {
  const PrivacyDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SettingsTopicScaffold(
      title: l.sectionPrivacyData,
      children: [
        SettingsGroupHeader(
          icon: Icons.privacy_tip_outlined,
          title: l.gdprTitle,
        ),
        const SectionCard(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Column(children: [
            ConsentSettingsSection(),
            PrivacyControlsSection(), // #3870
          ]),
        ),
        const SizedBox(height: 8),
        SettingsMenuTile(
          key: const Key('settingsPrivacyDashboardTile'),
          icon: Icons.privacy_tip,
          title: l.privacyDashboardTitle,
          subtitle: l.privacyDashboardSubtitle,
          onTap: () => context.push(RoutePaths.privacyDashboard),
        ),
        const SizedBox(height: 16),
        SettingsGroupHeader(icon: Icons.storage, title: l.storageAndCache),
        const StorageSection(),
      ],
    );
  }
}
