// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/widgets/info_card.dart';
import '../../../../l10n/app_localizations.dart';

/// Informational card explaining the benefits of creating an account.
/// Thin binding over the shared [InfoCard] skeleton.
///
/// Displayed below the sign-in/sign-up form for unauthenticated users.
class AuthInfoCard extends StatelessWidget {
  const AuthInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    final bullets = <String>[
      l.authInfoBenefit1,
      l.authInfoBenefit2,
      l.authInfoBenefit3,
      l.authInfoBenefit4,
    ];

    return InfoCard(
      icon: Icons.info_outline,
      iconSize: 18,
      title: l.authInfoTitle,
      titleStyle: theme.textTheme.titleSmall,
      body: bullets.join('\n'),
    );
  }
}
