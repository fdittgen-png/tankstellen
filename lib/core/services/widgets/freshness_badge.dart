import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../service_result.dart';

/// Compact badge showing data age and source with color-coded freshness.
///
/// Displays an icon + label like "2 min ago" (fresh) or "Stale — 30 min ago"
/// (stale). Color transitions from green (< 5 min) through amber (5-15 min)
/// to red (stale / > 15 min), giving users an at-a-glance sense of data
/// quality without reading the full [ServiceStatusBanner].
class FreshnessBadge extends StatelessWidget {
  final ServiceResult result;

  const FreshnessBadge({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final age = DateTime.now().difference(result.fetchedAt);

    final _BadgeStyle style = _styleForAge(age, result.isStale);

    final String label;
    if (result.isStale) {
      final stalePrefix = l10n?.freshnessStale ?? 'Stale';
      label = '$stalePrefix — ${result.freshnessLabel}';
    } else {
      final agoSuffix = l10n?.freshnessAgo ?? 'ago';
      label = '${result.freshnessLabel} $agoSuffix';
    }

    return Semantics(
      label: l10n?.freshnessBadgeSemantics(result.freshnessLabel) ??
          'Data freshness: ${result.freshnessLabel}',
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

  static _BadgeStyle _styleForAge(Duration age, bool isStale) {
    if (isStale || age.inMinutes > 15) {
      return const _BadgeStyle(
        icon: Icons.warning_amber_rounded,
        backgroundColor: Colors.red,
        foregroundColor: Colors.red,
      );
    }
    if (age.inMinutes >= 5) {
      return const _BadgeStyle(
        icon: Icons.schedule,
        backgroundColor: Colors.amber,
        foregroundColor: Colors.amber,
      );
    }
    return const _BadgeStyle(
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.green,
      foregroundColor: Colors.green,
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
