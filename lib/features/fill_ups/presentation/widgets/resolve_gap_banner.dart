// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/pending_reconciliation.dart';
import 'fill_up_reconciliation_launcher.dart';

/// Tappable banner surfacing a deferred-but-unresolved reconciliation gap
/// (#2445). Replaces the passive correction-share hint on the consumption
/// stats card while a gap is pending: tapping re-opens the guided
/// reconciliation workflow for this exact [pending] gap, so the user's
/// "Decide later" decision is never lost.
///
/// Styled with the same orange palette as the correction entries so the
/// visual language stays consistent, but with a chevron + [InkWell] to
/// read as an actionable affordance rather than a passive warning.
class ResolveGapBanner extends ConsumerWidget {
  final PendingReconciliation pending;

  const ResolveGapBanner({super.key, required this.pending});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final orange = DarkModeColors.warning(context);
    final locale = Localizations.localeOf(context).toString();
    final nf = NumberFormat.decimalPattern(locale)..maximumFractionDigits = 1;
    final gapText = nf.format(pending.gap);
    final label = l.reconcileResolveGapBanner(gapText);
    final semanticLabel = l.reconcileResolveGapSemanticLabel;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('resolve-gap-banner'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => runReconciliationWorkflow(
            context: context,
            ref: ref,
            pending: pending,
          ),
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: orange.withValues(alpha: 0.40)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 18, color: orange),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
