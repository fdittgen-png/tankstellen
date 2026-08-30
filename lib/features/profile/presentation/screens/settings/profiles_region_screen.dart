// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../widgets/profile_list_section.dart';
import 'settings_topic_scaffold.dart';

/// Settings → Profiles & region (#3884): the profile list. Each profile
/// card opens the edit sheet (country, language, fuel type, search
/// radius, route planning, radar, home postal code, …).
class ProfilesRegionScreen extends StatelessWidget {
  const ProfilesRegionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SettingsTopicScaffold(
      title: l.settingsTopicProfilesTitle,
      children: [
        SettingsGroupHeader(icon: Icons.person, title: l.sectionProfile),
        const ProfileListSection(),
      ],
    );
  }
}
