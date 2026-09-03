// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/domain/brand_logo_manifest.dart';
import '../../../../../core/widgets/section_card.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../widgets/about_section.dart';
import 'logo_credits_screen.dart';
import 'settings_topic_scaffold.dart';

/// Settings → About (#3884): the unchanged [AboutSection] — version,
/// licences, attribution and (outside iOS) the donation links — plus the
/// bundled-logo credits (#3940), which is where the CC-BY / CC-BY-SA
/// attribution for the brand logos is actually discharged.
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
        const SizedBox(height: 8),
        SectionCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: Text(l.logoCreditsTitle),
            subtitle: Text(
              l.logoCreditsAboutSubtitle(BrandLogoManifest.all.length),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const LogoCreditsScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
