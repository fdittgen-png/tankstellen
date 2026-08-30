// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../widgets/api_key_section.dart';
import '../../widgets/location_section_widget.dart';
import 'settings_topic_scaffold.dart';

/// Settings → Data sources & location (#3884): the API-key setup (gates
/// fuel search working at all) and the GPS position / auto-update /
/// auto-switch-profile section, both expanded.
class DataSourcesLocationScreen extends StatelessWidget {
  const DataSourcesLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SettingsTopicScaffold(
      title: l.settingsTopicDataSourcesTitle,
      children: [
        SettingsGroupHeader(icon: Icons.key, title: l.apiKeySetup),
        const ApiKeySection(),
        const SizedBox(height: 16),
        SettingsGroupHeader(icon: Icons.my_location, title: l.sectionLocation),
        const LocationSectionWidget(),
      ],
    );
  }
}
