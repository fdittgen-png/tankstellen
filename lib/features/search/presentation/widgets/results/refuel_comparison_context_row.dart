// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The assumptions a comparison rests on, in one editable line (#4363).
///
/// Every row below it is only as honest as these three inputs: which
/// fuel, how much, and what the car burns. They are stated where the
/// figures are, not buried in settings — and the quantity is one tap
/// from being corrected, because it is the input a driver most often
/// knows better than the app (#4095).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/domain/data_value.dart';
import '../../../../../core/domain/tank_state_provider.dart';
import '../../../../../core/theme/app_text.dart';
import '../../../../../core/utils/localized_fuel_name.dart';
import '../../../../../core/utils/unit_formatter.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/refuel_comparison_provider.dart';
import '../../../providers/search_filters_provider.dart';
import 'refuel_quantity_sheet.dart';

/// The three assumptions every comparison row rests on — fuel, quantity,
/// consumption — stated where the figures are, with the quantity one tap
/// from correction.
class RefuelComparisonContextRow extends ConsumerWidget {
  const RefuelComparisonContextRow({super.key, required this.comparison});

  final RefuelComparison comparison;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fuel = ref.watch(selectedFuelTypeProvider);
    final tank = ref.watch(tankStateProvider);

    final consumption = switch (comparison.consumption) {
      Measured<double>(:final value) =>
        UnitFormatter.formatConsumption(value, isEv: false),
      Estimated<double>(:final value) =>
        l10n.refuelCompareConsumptionEstimated(
            UnitFormatter.formatConsumption(value, isEv: false)),
      Stale<double>(:final value) =>
        l10n.refuelCompareConsumptionEstimated(
            UnitFormatter.formatConsumption(value, isEv: false)),
      Unknown<double>() => l10n.refuelCompareConsumptionMissing,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            l10n.refuelCompareContextLine(
              localizedFuelName(l10n, fuel),
              UnitFormatter.formatVolume(comparison.quantityLitres),
              consumption,
            ),
            style: AppText.label(context)
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        IconButton(
          key: const Key('refuel_compare_edit_quantity'),
          icon: const Icon(Icons.tune),
          tooltip: l10n.refuelCompareQuantityEdit,
          onPressed: () => unawaited(RefuelQuantitySheet.show(
            context,
            tankCapacityL: tank.capacityL,
          )),
        ),
      ],
    );
  }
}
