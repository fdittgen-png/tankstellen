// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/fuel_type.dart';
import '../../domain/add_fill_up_warnings.dart';

/// Shows the "Check this fill-up" confirmation dialog (#2836) listing the
/// pending [warnings] and asking the user to fix or save anyway.
///
/// Returns `true` when the user chose **Save anyway**, `false` when they
/// chose **Go back and fix** or dismissed the dialog (the safe default —
/// a dismiss should not silently persist a flagged entry).
///
/// [chosenFuel] / [vehicleFuel] drive the mismatch line; [enteredOdoKm] /
/// [previousOdoKm] (both pre-formatted strings) drive the odometer line.
/// Fuel display names use [FuelType.displayName] to match the form's fuel
/// picker (language-neutral brand-style names like "Super E10" / "Diesel").
Future<bool> showFillUpWarningDialog({
  required BuildContext context,
  required List<FillUpWarning> warnings,
  required FuelType chosenFuel,
  required FuelType? vehicleFuel,
  required String enteredOdoKm,
  required String? previousOdoKm,
}) async {
  final l = AppLocalizations.of(context);
  final lines = <String>[
    for (final w in warnings)
      switch (w) {
        FillUpWarning.fuelEngineMismatch => l?.fillUpWarningFuelMismatch(
              chosenFuel.displayName,
              vehicleFuel?.displayName ?? chosenFuel.displayName,
            ) ??
            'You picked ${chosenFuel.displayName}, but this vehicle runs on '
                '${vehicleFuel?.displayName ?? chosenFuel.displayName}.',
        FillUpWarning.odometerBelowPrevious =>
          l?.fillUpWarningOdometerBelowPrevious(
                enteredOdoKm,
                previousOdoKm ?? enteredOdoKm,
              ) ??
              'Odometer $enteredOdoKm km is below the previous fill-up\'s '
                  '${previousOdoKm ?? enteredOdoKm} km — distance can\'t go '
                  'backwards.',
      },
  ];

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      title: Text(l?.fillUpWarningDialogTitle ?? 'Check this fill-up'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(line)),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l?.fillUpWarningGoBack ?? 'Go back and fix'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l?.fillUpWarningSaveAnyway ?? 'Save anyway'),
        ),
      ],
    ),
  );
  return result ?? false;
}
