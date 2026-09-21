// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'consumption_stats_card.dart';

/// Grey informational banner — partials are pending a plein-complet
/// close. Non-tappable v1; tap-to-jump to fill-up list is a follow-up.
class _OpenWindowBanner extends StatelessWidget {
  final String text;

  const _OpenWindowBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm + Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: AppRadius.md,
      ),
      child: Row(
        children: [
          Icon(
            Icons.hourglass_bottom,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: Spacing.md),
          Expanded(child: Text(text, style: AppText.label(context))),
        ],
      ),
    );
  }
}

/// Orange-tinted hint — too much of the average comes from auto-
/// corrections. Encourages the user to review the orange entries.
class _CorrectionShareHint extends StatelessWidget {
  final String text;

  const _CorrectionShareHint({required this.text});

  @override
  Widget build(BuildContext context) {
    // Reuse the orange palette established by the correction fill-up
    // card (#1361) so the visual language stays consistent.
    final orange = DarkModeColors.warning(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm + Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: orange.withValues(alpha: 0.10),
        borderRadius: AppRadius.md,
        border: Border.all(color: orange.withValues(alpha: 0.40)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_outlined, size: 18, color: orange),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              text,
              style: AppText.label(context).copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
