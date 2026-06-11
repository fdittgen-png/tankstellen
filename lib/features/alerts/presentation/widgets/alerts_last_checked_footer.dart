// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../background/background_scan_dedup_store.dart';
import '../../../../l10n/app_localizations.dart';

/// Footer line showing when the last background alert scan completed
/// (#3147). Reads the [BackgroundScanDedupStore] stamp the coordinator
/// writes after every completed scan; shows a "never ran yet" hint until
/// the first one lands — so the standing alert SLA (1-3x/day) is
/// user-verifiable instead of debugPrint-only. A one-shot read per build
/// is enough: the screen rebuilds on every visit and the stamp changes
/// at most a few times a day.
class AlertsLastCheckedFooter extends StatelessWidget {
  const AlertsLastCheckedFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return FutureBuilder<DateTime?>(
      future: BackgroundScanDedupStore().lastScanAt(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final at = snapshot.data;
        final String label;
        if (at == null) {
          label = l10n?.alertsLastCheckedNever ??
              "Prices haven't been checked in the background yet";
        } else {
          final locale = Localizations.localeOf(context).toString();
          final when = DateFormat.yMd(locale).add_Hm().format(at.toLocal());
          label = l10n?.alertsLastChecked(when) ?? 'Last checked: $when';
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            label,
            key: const ValueKey('alerts-last-checked'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}
