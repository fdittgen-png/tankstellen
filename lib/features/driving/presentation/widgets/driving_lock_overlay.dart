// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Full-screen translucent overlay shown after the inactivity timeout.
/// Tapping anywhere dismisses the overlay via [onUnlock].
class DrivingLockOverlay extends StatelessWidget {
  final VoidCallback onUnlock;

  const DrivingLockOverlay({super.key, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // #3994 — theme tokens, and a type role so the prompt follows the
    // text-size setting: the one screen built around glanceability was the
    // one whose text ignored it.
    final onScrim = DarkModeColors.scrimForeground(context);
    return Positioned.fill(
      child: GestureDetector(
        onTap: onUnlock,
        child: Container(
          color: theme.colorScheme.scrim.withValues(alpha: 0.6),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: onScrim.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.drivingTapToUnlock,
                  style: theme.textTheme.headlineMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: onScrim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
