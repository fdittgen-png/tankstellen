// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/dark_mode_colors.dart';
import '../service_result.dart';

/// Compact badge showing data age and source with color-coded freshness.
///
/// Displays an icon + label like "2 min ago" (fresh) or "Stale — 30 min ago"
/// (stale). Color transitions from green (< 5 min) to amber as the data
/// ages (5-15 min) and stays in the amber/warning family once stale or
/// > 15 min — staleness is an *attention* state, not an error, so it never
/// escalates to the error red (which carries "expensive / failed"). This
/// matches the badge's `warning_amber_rounded` icon (#2492) and gives users
/// an at-a-glance sense of data quality without the full [ServiceStatusBanner].
class FreshnessBadge extends StatelessWidget {
  final ServiceResult<dynamic> result;

  const FreshnessBadge({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final age = DateTime.now().difference(result.fetchedAt);

    final _BadgeStyle style = _styleForAge(context, age, result.isStale);

    final String label;
    if (result.isStale) {
      final stalePrefix = l10n.freshnessStale;
      label = '$stalePrefix — ${result.freshnessLabel}';
    } else {
      final agoSuffix = l10n.freshnessAgo;
      label = '${result.freshnessLabel} $agoSuffix';
    }

    return Semantics(
      label: l10n.freshnessBadgeSemantics(result.freshnessLabel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: style.backgroundColor.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: style.backgroundColor.withAlpha(80),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 14, color: style.foregroundColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: style.foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _BadgeStyle _styleForAge(
    BuildContext context,
    Duration age,
    bool isStale,
  ) {
    if (isStale || age.inMinutes > 15) {
      // #2492 — very-stale stays amber (warning family), NOT error red.
      // Staleness is an attention state matching the warning_amber_rounded
      // icon; the error red is reserved for "expensive / failed".
      return _BadgeStyle(
        icon: Icons.warning_amber_rounded,
        backgroundColor: DarkModeColors.warning(context),
        foregroundColor: DarkModeColors.warning(context),
      );
    }
    if (age.inMinutes >= 5) {
      return _BadgeStyle(
        icon: Icons.schedule,
        backgroundColor: DarkModeColors.warning(context),
        foregroundColor: DarkModeColors.warning(context),
      );
    }
    return _BadgeStyle(
      icon: Icons.check_circle_outline,
      backgroundColor: DarkModeColors.success(context),
      foregroundColor: DarkModeColors.success(context),
    );
  }
}

class _BadgeStyle {
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const _BadgeStyle({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });
}
