// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/user_profile.dart';

/// Fuel-station-radar (approach overlay) controls (#2067 / Epic #2065).
///
/// Three controls, all persisted per `UserProfile`:
/// - **Radius** (km) — slider 0.5–5.0 in 0.5 km steps; the geo-fence
///   distance within which the recording overlay grows and flips to
///   a huge price figure.
/// - **Price mode** — `nearest` (default, stable) vs
///   `cheapestInRadius` (re-evaluates as stations enter/leave).
/// - **Min poll** (s) — floor on the speed-adaptive poll cadence
///   (1–10 s). The detector polls more aggressively at higher speed
///   but never tighter than this.
///
/// #3884 — extracted (move-only, behaviour preserved) from the private
/// `_ApproachOverlaySection` of the profile edit sheet so the same card
/// serves two hosts: the edit sheet (bound to `ProfileEditState`) and
/// Settings → Driving & consumption → Fuel Station Radar (bound to the
/// ACTIVE profile). Plain values in, callbacks out — no state coupling.
class RadarSettingsCard extends StatelessWidget {
  final double radiusKm;
  final ApproachPriceMode priceMode;
  final int minPollSeconds;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<ApproachPriceMode> onPriceModeChanged;
  final ValueChanged<int> onMinPollSecondsChanged;

  const RadarSettingsCard({
    super.key,
    required this.radiusKm,
    required this.priceMode,
    required this.minPollSeconds,
    required this.onRadiusChanged,
    required this.onPriceModeChanged,
    required this.onMinPollSecondsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('${l10n.approachRadiusLabel}:'),
            Expanded(
              child: Slider(
                key: const Key('radarRadiusSlider'),
                value: radiusKm,
                min: 0.5,
                max: 5.0,
                divisions: 9,
                label: UnitFormatter.formatDistance(radiusKm),
                onChanged: onRadiusChanged,
              ),
            ),
            Text(UnitFormatter.formatDistance(radiusKm)),
          ],
        ),
        Text(
          l10n.approachRadiusCaption(UnitFormatter.formatDecimal(radiusKm)),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.md),
        Text(l10n.approachPriceModeLabel, style: theme.textTheme.bodyMedium),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: 6,
          children: [
            ChoiceChip(
              label: Text(l10n.approachPriceModeNearest),
              selected: priceMode == ApproachPriceMode.nearest,
              onSelected: (_) => onPriceModeChanged(ApproachPriceMode.nearest),
              visualDensity: VisualDensity.compact,
            ),
            ChoiceChip(
              label: Text(l10n.approachPriceModeCheapestInRadius),
              selected: priceMode == ApproachPriceMode.cheapestInRadius,
              onSelected: (_) =>
                  onPriceModeChanged(ApproachPriceMode.cheapestInRadius),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Text('${l10n.approachMinPollLabel}:'),
            Expanded(
              child: Slider(
                key: const Key('radarMinPollSlider'),
                value: minPollSeconds.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                label: '$minPollSeconds s',
                onChanged: (v) => onMinPollSecondsChanged(v.round()),
              ),
            ),
            Text('$minPollSeconds s'),
          ],
        ),
        Text(
          l10n.approachMinPollCaption(minPollSeconds),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
