import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/services/throttle_rpm_histogram_calculator.dart';

/// Throttle / RPM time-share histogram card on the Trip detail screen
/// (#1041 phase 3a — "Card C").
///
/// Sits directly below [DrivingInsightsCard] (phase 2) and shows the
/// driver — visually — how the trip was distributed across throttle
/// quartiles and RPM bands. Two horizontal bar groups, one per axis;
/// each bar's flex is proportional to that bucket's time-share. The
/// card is purely presentational — the calculator
/// (`throttle_rpm_histogram_calculator.dart`) owns the maths and band
/// edges.
///
/// ## Why two stacked bar groups instead of a single chart widget?
///
/// The card runs immediately under [DrivingInsightsCard] on the same
/// scroll view. Pulling in a chart-library dependency (e.g.
/// `fl_chart`) for two simple stacked-share bars would
/// be a heavy new transitive dep for very little visual benefit and
/// contradicts the must-not-parallelize policy on `pubspec.yaml`. The
/// `Container`/`Flexible` approach also renders identically across
/// platforms and survives golden tests without a TolerantGoldenFileComparator.
///
/// ## Empty state
///
/// When the calculator returns [ThrottleRpmHistogram.empty] (no
/// usable samples on either axis), the card renders a single empty-
/// state caption rather than four flat zero-width bars. Legacy trips
/// recorded before throttle (PID 11) joined the polling rotation will
/// hit the throttle-only-empty path: bars render for RPM, and the
/// throttle row falls back to a per-row empty caption — both behaviours
/// covered by the widget tests.
class ThrottleRpmHistogramCard extends StatelessWidget {
  /// The pre-computed histogram. Caller is expected to derive this
  /// from the per-tick recording profile via
  /// `calculateThrottleRpmHistogram` once per trip — see
  /// `trip_detail_body.dart` for the wiring.
  final ThrottleRpmHistogram histogram;

  const ThrottleRpmHistogramCard({super.key, required this.histogram});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l?.throttleRpmHistogramTitle ?? 'How you used the engine',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (!histogram.hasData)
              _EmptyState(
                message: l?.throttleRpmHistogramEmpty ??
                    'No throttle or RPM samples in this trip.',
              )
            else ...[
              _SectionHeader(
                label: l?.throttleRpmHistogramThrottleSection ??
                    'Throttle position',
              ),
              const SizedBox(height: 8),
              _BarGroup(
                shares: histogram.throttleQuartiles,
                labels: <String>[
                  l?.throttleRpmHistogramThrottleCoast ?? 'Coast (0–25%)',
                  l?.throttleRpmHistogramThrottleLight ?? 'Light (25–50%)',
                  l?.throttleRpmHistogramThrottleFirm ?? 'Firm (50–75%)',
                  l?.throttleRpmHistogramThrottleWide ??
                      'Wide-open (75–100%)',
                ],
                emptyCaption: l?.throttleRpmHistogramEmpty ??
                    'No throttle or RPM samples in this trip.',
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              _SectionHeader(
                label:
                    l?.throttleRpmHistogramRpmSection ?? 'Engine RPM',
              ),
              const SizedBox(height: 8),
              _BarGroup(
                shares: histogram.rpmBands,
                labels: <String>[
                  l?.throttleRpmHistogramRpmIdle ?? 'Idle (≤900)',
                  l?.throttleRpmHistogramRpmCruise ?? 'Cruise (901–2000)',
                  l?.throttleRpmHistogramRpmSpirited ??
                      'Spirited (2001–3000)',
                  l?.throttleRpmHistogramRpmHard ?? 'Hard (>3000)',
                ],
                emptyCaption: l?.throttleRpmHistogramEmpty ??
                    'No throttle or RPM samples in this trip.',
                color: theme.colorScheme.tertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Section label above each bar group ("Throttle position", "Engine
/// RPM"). Kept as a private widget so the card can swap the styling
/// without leaking the helper into the rest of the feature.
class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// One full bar group (4 bars stacked vertically with their labels and
/// trailing percent share). [shares] entries are in `[0, 1]`; the
/// widget multiplies by 100 for display and uses the value directly to
/// drive each bar's width.
class _BarGroup extends StatelessWidget {
  final List<double> shares;
  final List<String> labels;
  final String emptyCaption;
  final Color color;

  const _BarGroup({
    required this.shares,
    required this.labels,
    required this.emptyCaption,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final total = shares.fold<double>(0, (a, b) => a + b);
    if (total <= 0) {
      // This particular axis has no usable data even though the OTHER
      // axis does — render a per-row caption so the user understands
      // why this group is missing instead of seeing four flat bars.
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          emptyCaption,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < shares.length; i++)
          _BarRow(
            label: labels[i],
            share: shares[i],
            color: color,
          ),
      ],
    );
  }
}

/// Single histogram row — label on the left, proportional bar in the
/// middle, percent share on the right. Bar width is split using
/// `Flexible` flex factors so the row never overflows the card padding
/// regardless of the parent constraints.
///
/// `share` is the bucket's fraction of the trip in `[0, 1]`. We also
/// reserve a `Flexible` for the "empty" remainder so a 12 %-share bar
/// renders 12 % of the available bar track, not the full track tinted
/// at 12 % alpha — the latter loses the visual scale.
class _BarRow extends StatelessWidget {
  final String label;
  final double share;
  final Color color;

  const _BarRow({
    required this.label,
    required this.share,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final pctFormatted = (share * 100).toStringAsFixed(0);
    final pctLabel = l?.throttleRpmHistogramBarShare(pctFormatted) ??
        '$pctFormatted%';

    // Convert share to integer flex so Flexible(flex:) stays consistent
    // across rows. 1000 ticks gives 0.1 %-precision — far finer than
    // the whole-percent label.
    final filled = (share * 1000).round().clamp(0, 1000);
    final empty = 1000 - filled;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Fixed-ish label on the left so the bars align across rows.
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // The bar track itself — fixed height, two flex children.
          Expanded(
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (filled > 0)
                    Flexible(
                      flex: filled,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  if (empty > 0)
                    Flexible(
                      flex: empty,
                      child: const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Trailing percent — tabular figures so the column stays
          // visually steady when the values change.
          SizedBox(
            width: 40,
            child: Text(
              pctLabel,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card-level empty-state row — used when neither axis has any usable
/// time-share. Mirrors the visual idiom of [DrivingInsightsCard]'s
/// empty state.
class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
