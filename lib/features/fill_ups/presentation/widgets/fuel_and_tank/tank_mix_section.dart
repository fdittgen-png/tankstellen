// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../../../core/domain/fuel_type.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_text.dart';
import '../../../../../core/theme/fuel_colors.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/utils/unit_formatter.dart';
import '../../../../../core/widgets/primary_card.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/services/fuel_and_tank_view.dart';
import 'fuel_and_tank_labels.dart';

/// The tank's current mix (#4278) — the surface's primary card. One mix
/// model only: the evidence-only `TankBlendEngine` blend, with guaranteed
/// minimums and the unknown share said out loud.
class TankMixSection extends StatelessWidget {
  const TankMixSection({super.key, required this.mix});

  final TankMixView mix;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final leading = mix.leading;
    if (leading == null) {
      return PrimaryCard(
        key: const Key('fuel_and_tank_mix_unknown'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.fuelAndTankMixTitle, style: AppText.label(context)),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Icon(Icons.help_outline,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(l.fuelAndTankMixUnknownTitle,
                      style: AppText.title(context)),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(l.fuelAndTankMixUnknownBody, style: AppText.body(context)),
          ],
        ),
      );
    }
    final line = FuelAndTankLabels.mixLine(l, mix);
    final percent = leading.percent.toString();
    return PrimaryCard(
      key: const Key('fuel_and_tank_mix'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.fuelAndTankMixTitle, style: AppText.label(context)),
          const SizedBox(height: Spacing.sm),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: Spacing.sm,
            children: [
              Text(
                mix.isExact
                    ? l.fuelAndTankMixFocalExact(percent)
                    : l.fuelAndTankMixFocalAtLeast(percent),
                key: const Key('fuel_and_tank_mix_focal'),
                style: AppText.display(context),
              ),
              Text(FuelAndTankLabels.grade(l, leading.grade),
                  style: AppText.unit(context)),
            ],
          ),
          const SizedBox(height: Spacing.md),
          _MixBar(mix: mix, semanticsLabel: l.fuelAndTankMixBarSemantics(line)),
          const SizedBox(height: Spacing.md),
          Text(line,
              key: const Key('fuel_and_tank_mix_line'),
              style: AppText.body(context)),
          if (_volume(l) case final String volume) ...[
            const SizedBox(height: Spacing.xs),
            Text(volume, style: AppText.label(context)),
          ],
          const SizedBox(height: Spacing.sm),
          Text(
            mix.isExact
                ? l.fuelAndTankMixExplainExact
                : l.fuelAndTankMixExplainPartial,
            style: AppText.label(context),
          ),
        ],
      ),
    );
  }

  String? _volume(AppLocalizations l) {
    final exact = mix.exactLitres;
    if (exact != null) {
      return l.fuelAndTankMixVolumeExact(UnitFormatter.formatVolume(exact));
    }
    final max = mix.maxLitres;
    final min = UnitFormatter.formatVolume(mix.minLitres);
    if (max != null) {
      return l.fuelAndTankMixVolumeRange(min, UnitFormatter.formatVolume(max));
    }
    return mix.minLitres > 0 ? l.fuelAndTankMixVolumeAtLeast(min) : null;
  }
}

/// A proportional bar: one segment per share, the unknown share in the
/// neutral outline tone so it never reads as a fuel.
class _MixBar extends StatelessWidget {
  const _MixBar({required this.mix, required this.semanticsLabel});

  final TankMixView mix;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: AppRadius.sm,
        child: SizedBox(
          height: Spacing.lg,
          child: Row(
            children: [
              for (final s in mix.shares)
                Expanded(
                  flex: s.percent,
                  child: ColoredBox(
                    key: ValueKey('fuel_and_tank_mix_segment_${s.grade.key}'),
                    color: FuelColors.forType(FuelType.fromString(s.grade.key)),
                  ),
                ),
              if (mix.unknownPercent > 0)
                Expanded(
                  flex: mix.unknownPercent,
                  child: ColoredBox(
                    key: const ValueKey('fuel_and_tank_mix_segment_unknown'),
                    color: scheme.outlineVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
