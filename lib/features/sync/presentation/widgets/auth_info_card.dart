// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Informational card explaining the benefits of creating an account.
///
/// Displayed below the sign-in/sign-up form for unauthenticated users.
class AuthInfoCard extends StatelessWidget {
  const AuthInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final bullets = <String>[
      l?.authInfoBenefit1 ??
          '• Sync favorites, alerts, and saved routes across devices',
      l?.authInfoBenefit2 ??
          '• Prepare a route on your phone, use it in your car',
      l?.authInfoBenefit3 ?? '• No data is shared with third parties',
      l?.authInfoBenefit4 ?? '• You can delete your account at any time',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Text(l?.authInfoTitle ?? 'Why create an account?',
                    style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              bullets.join('\n'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
