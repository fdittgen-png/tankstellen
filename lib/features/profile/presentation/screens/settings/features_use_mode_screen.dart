// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../widgets/feature_management_section.dart';
import '../../widgets/use_mode_section.dart';
import 'settings_topic_scaffold.dart';

/// Settings → Features & use mode (#3884): the Use-mode chooser (Basic /
/// Medium / Full / Custom, #1519) ABOVE the per-feature switches it
/// overwrites (#1373 phase 2) — users discover the presets at the same
/// time as the toggles they gate. Both widgets are hosted expanded.
class FeaturesUseModeScreen extends StatelessWidget {
  const FeaturesUseModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SettingsTopicScaffold(
      title: l.settingsTopicFeaturesTitle,
      children: [
        SettingsGroupHeader(
          icon: Icons.tune,
          title: l.featureManagementSectionTitle,
        ),
        const UseModeSection(),
        const SizedBox(height: 12),
        const FeatureManagementSection(),
      ],
    );
  }
}
