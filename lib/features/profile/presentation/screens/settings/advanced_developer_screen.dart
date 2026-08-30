// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/app_routes.dart';
import '../../../../../core/widgets/settings_menu_tile.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../feature_management/api.dart';
import '../../widgets/feedback_token_section.dart';
import 'settings_topic_scaffold.dart';

/// Settings → Advanced & developer (#3884): the bad-scan reporter PAT
/// section (gated on `Feature.developerPatToken`, #952 / #2116-6) and
/// the Developer tools tile (gated on `Feature.debugMode`, #2248). The
/// root tile only renders when at least one of the two is on.
class AdvancedDeveloperScreen extends ConsumerWidget {
  const AdvancedDeveloperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final flags = ref.watch(enabledFeaturesProvider);
    final patOn = flags.contains(Feature.developerPatToken);
    final debugOn = flags.contains(Feature.debugMode);

    return SettingsTopicScaffold(
      title: l.sectionAdvancedDeveloper,
      children: [
        if (patOn) ...[
          SettingsGroupHeader(
            icon: Icons.bug_report_outlined,
            title: l.feedbackTokenSectionTitle,
          ),
          const FeedbackTokenSection(),
          const SizedBox(height: 16),
        ],
        if (debugOn)
          SettingsMenuTile(
            key: const Key('settingsDeveloperToolsTile'),
            icon: Icons.developer_mode,
            title: l.developerToolsSectionTitle,
            subtitle: l.developerToolsMenuSubtitle,
            onTap: () => context.push(RoutePaths.developerTools),
          ),
      ],
    );
  }
}
