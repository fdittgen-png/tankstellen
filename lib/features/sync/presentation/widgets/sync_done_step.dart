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
    return Column(
      children: [
        const SizedBox(height: 40),
        Semantics(
          label:
              'Successfully connected. Your data will now sync automatically.',
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
                l10n?.syncSuccessTitle ?? 'Successfully connected!',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.syncSuccessDescription ??
                    'Your data will now sync automatically.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
