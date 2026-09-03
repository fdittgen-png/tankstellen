// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/location/user_position_provider.dart';
import '../../../../l10n/app_localizations.dart';
import 'results/summary_chip.dart';

/// The **position segment** of the results summary bar (row A, #3926).
///
/// Was a full-width strip of its own ("Your position: GPS (1 min)") with a
/// second refresh icon beside the app bar's. The strip is gone: the readout
/// is now one pill inside row A, and the refresh it carried was merged into
/// the single app-bar refresh (which re-fixes the position *and* re-runs the
/// search). The widget keeps its name and its optional [onUpdatePosition]
/// callback so it can still be driven as a standalone affordance.
class UserPositionBar extends ConsumerWidget {
  /// Optional tap action. Row A leaves this null — the whole band opens the
  /// criteria sheet — and the app-bar refresh owns the GPS re-fix.
  final VoidCallback? onUpdatePosition;

  const UserPositionBar({super.key, this.onUpdatePosition});

  String _formatAge(DateTime updatedAt) {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 1) return '< 1 min';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userPos = ref.watch(userPositionProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final Widget chip;
    if (userPos != null) {
      final value = '${userPos.source} · ${_formatAge(userPos.updatedAt)}';
      chip = SummaryChip(
        key: const Key('user_position_segment'),
        icon: Icon(
          Icons.my_location,
          size: 14,
          color: theme.colorScheme.primary,
        ),
        label: value,
        // #3939 — the pill was already value-only ("GPS · 1 min"); what it
        // gains here is the long-press sentence that names the value.
        tooltip: '${l10n.yourPosition}: $value',
        semanticsLabel: '${l10n.yourPosition}: $value',
      );
    } else {
      chip = SummaryChip(
        key: const Key('user_position_segment'),
        icon: Icon(
          Icons.location_off,
          size: 14,
          color: theme.colorScheme.error,
        ),
        label: l10n.positionUnknown,
        tooltip: '${l10n.positionUnknown} — ${l10n.distancesFromCenter}',
        semanticsLabel: '${l10n.positionUnknown} — ${l10n.distancesFromCenter}',
      );
    }

    final onTap = onUpdatePosition;
    if (onTap == null) return chip;
    return InkWell(onTap: onTap, child: chip);
  }
}
