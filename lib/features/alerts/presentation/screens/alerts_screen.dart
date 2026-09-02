// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/alerts_body.dart';

/// Standalone `/alerts` route — kept for deep links (#1701).
///
/// #3905 — the page content lives in [AlertsBody], which the Favorites
/// "Price alerts" tab renders directly; this screen only adds the
/// scaffold + back button around it.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PageScaffold(
      title: l10n.priceAlerts,
      bodyPadding: EdgeInsets.zero,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n.tooltipBack,
        onPressed: () => context.pop(),
      ),
      body: const AlertsBody(),
    );
  }
}
