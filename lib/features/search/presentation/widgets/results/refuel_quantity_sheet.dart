// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/domain/refuel_economics.dart';
import '../../../../../core/domain/refuel_profile_provider.dart';
import '../../../../../core/domain/refuel_quantity_provider.dart';
import '../../../../../core/theme/app_text.dart';
import '../../../../../core/theme/spacing.dart';
import '../../../../../core/utils/unit_formatter.dart';
import '../../../../../l10n/app_localizations.dart';

/// "How much do you usually buy?" — the one assumption worth offering to
/// change (#4095, epic #4087).
///
/// The Best Value ranking needs a rough volume, and it already has one:
/// the median of the user's own fill-ups, which is personal from the
/// first few fills and needs no question asked. This sheet is for the
/// cases a measurement cannot reach — a driver who always puts in exactly
/// 20 litres, or one with no history yet who would rather say than wait
/// — and for making the assumption visible so it can be disagreed with.
///
/// ## What it deliberately does not ask
///
/// Tank capacity. The economics spec (§2) keeps capacity out of the
/// formula, and the app must work for a user who never enters one. Where
/// a capacity IS on file it appears as the "A full tank" shortcut and as
/// a silent ceiling on the chosen figure — a ceiling, never a
/// requirement.
class RefuelQuantitySheet extends ConsumerWidget {
  const RefuelQuantitySheet({super.key, this.tankCapacityL});

  /// The active vehicle's capacity, when it has one on file. Null simply
  /// means the "full tank" shortcut is not offered.
  final double? tankCapacityL;

  /// Open the sheet. Returns when it closes.
  static Future<void> show(BuildContext context, {double? tankCapacityL}) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => RefuelQuantitySheet(tankCapacityL: tankCapacityL),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final chosen = ref.watch(refuelQuantityProvider);
    final profile = ref.watch(refuelProfileProvider);
    final capacity = tankCapacityL;

    void choose(double? litres) {
      unawaited(ref.read(refuelQuantityProvider.notifier).set(litres));
      Navigator.of(context).pop();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Spacing.lg, 0, Spacing.lg, Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.refuelQuantityTitle, style: AppText.title(context)),
            const SizedBox(height: Spacing.md),
            Text(
              l10n.refuelQuantityExplainer,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: Spacing.lg),
            // The consumption side, shown as the assumption it is — and
            // as the reason Best Value is missing when there is none.
            Row(
              children: [
                Icon(Icons.local_gas_station_outlined,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Text(
                    profile.consumptionLPer100km == null
                        ? l10n.refuelConsumptionMissing
                        : l10n.refuelConsumptionMeasured(
                            UnitFormatter.formatConsumption(
                                profile.consumptionLPer100km!,
                                isEv: false),
                          ),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            Wrap(
              spacing: Spacing.md,
              runSpacing: Spacing.md,
              children: [
                // The measured default leads: it is the better answer
                // wherever a history exists, so it must not look like the
                // fallback.
                _Choice(
                  label: _measuredLabel(l10n, ref),
                  selected: chosen == null,
                  onTap: () => choose(null),
                ),
                for (final litres in RefuelQuantity.presets)
                  if (capacity == null || litres <= capacity)
                    _Choice(
                      label: UnitFormatter.formatVolume(litres),
                      selected: chosen == litres,
                      onTap: () => choose(litres),
                    ),
                if (capacity != null && capacity > 0)
                  _Choice(
                    label: '${l10n.refuelQuantityFullTank} · '
                        '${UnitFormatter.formatVolume(capacity)}',
                    selected: chosen == capacity,
                    onTap: () => choose(capacity),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// The measured option, carrying the value it currently resolves to —
  /// so choosing it is an informed choice and not a leap of faith.
  String _measuredLabel(AppLocalizations l10n, WidgetRef ref) {
    final chosen = ref.watch(refuelQuantityProvider);
    final resolved = ref.watch(refuelProfileProvider).litresIntended;
    // While an explicit choice is active the resolved figure IS that
    // choice, so the median cannot be read back off the profile; say the
    // plain thing instead of a number that would be wrong.
    if (chosen != null) return l10n.refuelQuantityMeasured;
    return l10n.refuelQuantityMeasuredValue(
        UnitFormatter.formatVolume(resolved));
  }
}

/// One selectable quantity.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

/// The default quantity when nothing is known at all — re-exported so the
/// sheet's tests can name it without reaching into the economics library.
const double kRefuelQuantityFallback = kDefaultRefuelLitres;
