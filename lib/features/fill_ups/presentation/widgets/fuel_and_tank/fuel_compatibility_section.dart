// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../core/domain/fuel/fuel_grade.dart';
import '../../../../../core/theme/app_text.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/widgets/panel_card.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/services/fuel_and_tank_view.dart';
import 'fuel_and_tank_labels.dart';

/// Which fuels the vehicle's settings approve, and which merely fit
/// (#4278). An unknown capability is stated as unknown, never as "none".
class FuelCompatibilitySection extends StatelessWidget {
  const FuelCompatibilitySection({super.key, required this.compatibility});

  final CompatibilityView compatibility;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = compatibility;
    return PanelCard(
      key: const Key('fuel_and_tank_compatibility'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.fuelAndTankCompatTitle, style: AppText.title(context)),
          const SizedBox(height: Spacing.md),
          if (c.isUnknown)
            Text(l.fuelAndTankCompatUnknown, style: AppText.body(context))
          else ...[
            Text(l.fuelAndTankCompatApproved, style: AppText.label(context)),
            for (final g in c.approved)
              _GradeLine(grade: g, icon: Icons.check_circle_outline),
          ],
          if (c.unconfirmed.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            Text(l.fuelAndTankCompatUnconfirmed,
                style: AppText.label(context)),
            for (final g in c.unconfirmed)
              _GradeLine(grade: g, icon: Icons.help_outline),
          ],
          const SizedBox(height: Spacing.md),
          Text(l.fuelAndTankCompatHint, style: AppText.label(context)),
        ],
      ),
    );
  }
}

class _GradeLine extends StatelessWidget {
  const _GradeLine({required this.grade, required this.icon});

  final FuelGrade grade;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              FuelAndTankLabels.grade(l, grade),
              key: ValueKey('fuel_and_tank_compat_${grade.key}'),
              style: AppText.body(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// General technical facts from the fuel standards (#4278) — visually a
/// secondary panel with an explicit "general information" label, so a
/// generic ethanol claim never reads as something measured on this car.
class FuelFactsSection extends StatelessWidget {
  const FuelFactsSection({super.key, required this.facts});

  final List<GradeFactView> facts;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lines = [
      for (final f in facts)
        if (FuelAndTankLabels.fact(l, f) case final String text) text,
    ];
    if (lines.isEmpty) return const SizedBox.shrink();
    return PanelCard(
      key: const Key('fuel_and_tank_facts'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: Spacing.md),
              Expanded(
                child:
                    Text(l.fuelAndTankFactsTitle, style: AppText.title(context)),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            '${l.fuelAndTankProvenanceGeneral} · ${l.fuelAndTankFactsSubtitle}',
            key: const Key('fuel_and_tank_facts_label'),
            style: AppText.label(context),
          ),
          for (final text in lines) ...[
            const SizedBox(height: Spacing.sm),
            Text(text, style: AppText.body(context)),
          ],
        ],
      ),
    );
  }
}
