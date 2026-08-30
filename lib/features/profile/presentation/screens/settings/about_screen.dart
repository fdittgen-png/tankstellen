// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../widgets/about_section.dart';
import 'settings_topic_scaffold.dart';

/// Settings → About (#3884): the unchanged [AboutSection] — version,
/// licences, attribution and (outside iOS) the donation links.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SettingsTopicScaffold(
      title: l.about,
      children: [
        SettingsGroupHeader(icon: Icons.info_outline, title: l.about),
        const AboutSection(),
      ],
    );
  }
}
