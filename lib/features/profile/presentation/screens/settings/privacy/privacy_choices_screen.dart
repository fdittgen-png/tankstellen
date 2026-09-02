// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../../core/widgets/section_card.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../consent/api.dart'
    show ConsentRecordFooter, ConsentSwitchRows, PrivacyControlRows;
import '../settings_topic_scaffold.dart';

/// Privacy & data → Your choices (#3909, Epic #3907): ONE list — the
/// five consents, then the two privacy controls — every row the same
/// shape (icon, title, a short subtitle that wraps instead of
/// truncating), closed by the consent record + policy link. The
/// write paths are the consent feature's own row widgets, unchanged.
class PrivacyChoicesScreen extends StatelessWidget {
  const PrivacyChoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SettingsTopicScaffold(
      title: l.privacyTopicChoicesTitle,
      children: [
        SectionCard(
          key: const Key('privacyChoicesList'),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  l.gdprSettingsHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const ConsentSwitchRows(),
              const PrivacyControlRows(), // #3870
              const Divider(indent: 16, endIndent: 16),
              const ConsentRecordFooter(), // #3866
            ],
          ),
        ),
      ],
    );
  }
}
