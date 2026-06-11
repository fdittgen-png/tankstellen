// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// iOS-only honest "best effort" disclosure on the alerts screen (#3169).
///
/// The alert SLA (1-3x/day, ≤3-4h) is structurally unreachable on iOS
/// Tier-1: BGTask wakes are OS-budgeted and guaranteed delivery would need
/// push (excluded — no paid services). Rather than implying Android-grade
/// delivery, this note tells the user exactly what to expect and what
/// helps: iOS decides when checks run; opening the app always runs a
/// fresh check. Rendered only when [defaultTargetPlatform] is iOS —
/// Android's WorkManager pipeline meets the SLA, so no caveat is shown
/// there. (UI-level platform *adaptation* via `defaultTargetPlatform` is
/// the sanctioned idiom; the scheduling seams live behind the
/// BackgroundPriceFetcher / SlcWakeMonitor facades.)
class AlertsBestEffortNote extends StatelessWidget {
  const AlertsBestEffortNote({super.key});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.alertsIosBestEffortNote,
              key: const ValueKey('alerts-best-effort-note'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
