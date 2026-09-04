// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

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

/// One stat of the panel (#3950): icon + label in the label role above
/// the figure, which is the tile's focal number — a display-derived
/// style scaled by [_StatTile.valueScale] so two tiles fit a 320 dp row.
///
/// The figure never wraps: it is `softWrap: false` and, as a last resort
/// (a wide total at a 1.3× font setting), it scales down inside the tile
/// rather than breaking. The label ellipsises first.
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  /// Fraction of the display role a tile figure renders at. The full
  /// display size (~36 sp) is reserved for the tank card's ONE number;
  /// 0.6 of it (~22 sp) still tops the card title (~16 sp), so the
  /// figure is the largest text on the panel, and two tiles share a
  /// 320 dp row without scaling at a 1.0× font setting.
  static const double valueScale = 0.6;

  /// The tile figure style — [AppText.display] scaled by [valueScale].
  static TextStyle valueStyle(BuildContext context) {
    final display = AppText.display(context);
    return display.copyWith(fontSize: display.fontSize! * valueScale);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppText.label(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              softWrap: false,
              maxLines: 1,
              style: valueStyle(context),
            ),
          ),
        ),
      ],
    );
  }
}
