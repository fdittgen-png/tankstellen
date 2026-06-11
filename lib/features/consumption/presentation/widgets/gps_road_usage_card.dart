// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/gps_driving_features.dart';
import '../../domain/gps_driving_features_shares.dart';

/// Coast share at or above which the road-use panel surfaces its
/// positive coaching line (#2796 C7). ~25 % of moving time spent
/// coasting (foot off, gentle deceleration / engine-braking) is a
/// genuinely eco-positive pattern worth praising — letting the car roll
/// instead of accelerating-then-braking. Conservative default: well
/// above the coast share a typical stop-and-go town drive produces, so
/// the praise reads as earned rather than automatic. Lives beside the
/// widget so the threshold is one obvious tunable.
const double kGpsRoadUseCoastPraiseThreshold = 0.25;

/// "How you used the road" panel on the Trip detail screen for GPS-only
/// trips (#2796 C7 / Epic #2789). Replaces the throttle/RPM histogram —
/// which can never fill without an engine signal — with a speed-only
/// view the GPS track CAN produce: where the time went across speed
/// bands (stopped / town / cruise / fast) and how the car moved across
/// the three movement phases (accelerating / holding speed / coasting),
/// plus a positive coasting-coaching line when coasting was high.
///
/// Purely presentational. Every share comes pre-computed off
/// [GpsDrivingFeatures]; the speed-band edges are the SAME ones
/// [GpsDrivingFeatures.from] integrates against (5 / 50 / 110 km/h), so
/// the bar labels never drift from the maths.
///
/// Mirrors [GpsEfficiencyKpiCard] / [ImuAccelBrakeCard]: lives in its
/// own file so the trip-detail body holds only a one-line reference.
class GpsRoadUsageCard extends StatelessWidget {
  /// Pre-computed GPS features for the trip. Non-null is the caller's
  /// contract — the trip-detail body only builds this card when it has
  /// resolved features (i.e. a real GPS-only trip).
  final GpsDrivingFeatures features;

  const GpsRoadUsageCard({super.key, required this.features});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final speedBars = <_ShareBar>[
      _ShareBar(
        key: const Key('gps_road_use_speed_idle'),
        label: l.gpsRoadUseSpeedIdle,
        share: features.idleShare,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      _ShareBar(
        key: const Key('gps_road_use_speed_low'),
        label: l.gpsRoadUseSpeedLow,
        share: features.lowSpeedShare,
        color: theme.colorScheme.primary,
      ),
      _ShareBar(
        key: const Key('gps_road_use_speed_cruise'),
        label: l.gpsRoadUseSpeedCruise,
        share: features.cruiseShare,
        color: theme.colorScheme.primary,
      ),
      _ShareBar(
        key: const Key('gps_road_use_speed_high'),
        label: l.gpsRoadUseSpeedHigh,
        share: features.highSpeedShare,
        color: theme.colorScheme.tertiary,
      ),
    ];

    final phaseBars = <_ShareBar>[
      _ShareBar(
        key: const Key('gps_road_use_phase_accel'),
        label: l.gpsRoadUsePhaseAccel,
        share: features.accelShare,
        color: theme.colorScheme.tertiary,
      ),
      _ShareBar(
        key: const Key('gps_road_use_phase_steady'),
        label: l.gpsRoadUsePhaseSteady,
        share: features.steadyShare,
        color: theme.colorScheme.primary,
      ),
      _ShareBar(
        key: const Key('gps_road_use_phase_coast'),
        label: l.gpsRoadUsePhaseCoast,
        share: features.coastShare,
        color: theme.colorScheme.primary,
      ),
    ];

    final showCoastPraise =
        features.coastShare >= kGpsRoadUseCoastPraiseThreshold;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.gpsRoadUseCardTitle,
              key: const Key('gps_road_use_card_title'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _SectionHeader(label: l.gpsRoadUseSpeedSection),
            const SizedBox(height: 8),
            for (final b in speedBars) b,
            const SizedBox(height: 16),
            _SectionHeader(label: l.gpsRoadUsePhaseSection),
            const SizedBox(height: 8),
            for (final b in phaseBars) b,
            if (showCoastPraise) ...[
              const SizedBox(height: 12),
              _CoastPraise(message: l.gpsRoadUseCoastPraise),
            ],
            const SizedBox(height: 8),
            Text(
              l.gpsRoadUseSource,
              key: const Key('gps_road_use_source'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section label above each bar group. Mirrors the throttle/RPM card's
/// idiom so the two trip-detail panels read consistently.
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

/// One share row — label on the left, a proportional bar in the middle,
/// and the trailing whole-percent share on the right. [share] is the
/// bucket's fraction in `[0, 1]`. Flex factors keep the bar inside the
/// card padding regardless of parent constraints (the same approach the
/// throttle/RPM card uses).
class _ShareBar extends StatelessWidget {
  final String label;
  final double share;
  final Color color;

  const _ShareBar({
    super.key,
    required this.label,
    required this.share,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final pct = (share.clamp(0.0, 1.0) * 100).toStringAsFixed(0);
    final pctLabel = l.gpsRoadUseShare(pct);

    final filled = (share.clamp(0.0, 1.0) * 1000).round();
    final empty = 1000 - filled;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
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
                    Flexible(flex: empty, child: const SizedBox.shrink()),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
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

/// Green positive-coaching row shown when coasting was high. Mirrors the
/// green-praise polarity the smooth-driving lesson adopted (#2791): a
/// leaf-icon + a one-line affirmation, NOT the error-red waste idiom.
class _CoastPraise extends StatelessWidget {
  final String message;

  const _CoastPraise({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      key: const Key('gps_road_use_coast_praise'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.eco_outlined, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
