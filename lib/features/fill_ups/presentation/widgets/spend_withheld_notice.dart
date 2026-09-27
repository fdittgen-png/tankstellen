// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../../core/domain/money_tally.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/comparison_labels.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/consumption_stats.dart';

/// "Total spent" for [stats], in the currency the fills were recorded
/// in (#4437) — or `—` when the history has no single total (#4364).
///
/// An all-unknown (pre-#4136) history keeps the active symbol exactly as
/// it always rendered; a sole foreign currency is printed as itself.
String formatTotalSpent(ConsumptionStats stats) {
  final total = stats.totalSpent;
  if (total == null) return '—';
  final code = stats.spendCurrency;
  return PriceFormatter.formatTotalIn(
      total, code == kUnknownCurrency ? null : code);
}

/// One line under a money tile that says WHY its total is a dash
/// (#4406, #4437 F) — mixed currencies, or fills with none recorded.
/// Renders nothing when the total exists.
class SpendWithheldNotice extends StatelessWidget {
  final ConsumptionStats stats;

  const SpendWithheldNotice({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final label = spendWithheldLabel(l, stats.spend);
    if (label == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Row(
      key: const Key('spend_withheld_notice'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 6),
          child: Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            label,
            style: AppText.label(context)
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
