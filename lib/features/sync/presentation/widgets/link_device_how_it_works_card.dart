// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Explanation card describing how the device-link / merge flow works,
/// rendered at the bottom of the Link Device screen.
///
/// Pulled out of `link_device_screen.dart` so the screen stops carrying
/// the inline 44-line `Card(...)` block, the help text lives in a single
/// place, and the card is exercisable by widget tests in isolation.
class LinkDeviceHowItWorksCard extends StatelessWidget {
  const LinkDeviceHowItWorksCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.linkDeviceHowItWorksTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.linkDeviceHowItWorksBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
