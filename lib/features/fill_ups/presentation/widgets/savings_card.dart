// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/savings_provider.dart';

/// What this driver saved against their own normal price (#4136).
///
/// Fuel comparison is episodic — open the app, close the app — and a
/// running total is the reason to come back. It is also the easiest
/// number in this app to fake, so this one is built to be checkable:
/// the reference is named, the fill count is shown, and the total is
/// NET.
///
/// Net, not wins-only. A card that added up only the cheap fills would
/// be a marketing number and its total a lie of omission; the honest
/// figure is sometimes small, and a small honest figure is worth more
/// than a large one the user can disprove once.
class SavingsCard extends ConsumerWidget {
  const SavingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ledger = ref.watch(savingsLedgerProvider);

    if (!ledger.isAvailable || ledger.entries.isEmpty) {
      // No invented number. Below the minimum sample count there is
      // nothing honest to measure against (trust rule 1).
      return SectionCard(
        child: Text(
          l10n.savingsNeedsHistory,
          style: AppText.body(context)
              .copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final baseline = ledger.baseline!;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.savingsTitle, style: AppText.title(context)),
          const SizedBox(height: Spacing.xs),
          Text(
            l10n.savingsNet(
              PriceFormatter.formatPrice(ledger.total),
              ledger.entries.length,
            ),
            style: AppText.unit(context).copyWith(
              fontWeight: FontWeight.w700,
              // Green for a win, the error colour for a loss — this is
              // one of the few places a red number is genuinely the
              // right answer, because it IS bad news about money.
              color: ledger.total >= 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          // The reference, stated — without it the number above is not
          // reproducible, which trust rule 4 forbids.
          Text(
            l10n.savingsReference(
              PriceFormatter.formatPrice(baseline.typicalPricePerLitre),
              UnitFormatter.formatVolume(baseline.typicalLitres),
            ),
            style: AppText.label(context)
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
