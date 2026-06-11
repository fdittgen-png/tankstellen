// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Final step of the TankSync setup wizard — confirms a successful
/// connection. The parent screen pops the route after a short delay.
class SyncDoneStep extends StatelessWidget {
  const SyncDoneStep({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final successTitle = l10n.syncSuccessTitle;
    final successDescription = l10n.syncSuccessDescription;
    return Column(
      children: [
        const SizedBox(height: 40),
        Semantics(
          label: '$successTitle $successDescription',
          liveRegion: true,
          child: Column(
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.check_circle,
                  size: 64,
                  color: DarkModeColors.success(context),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                successTitle,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                successDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
