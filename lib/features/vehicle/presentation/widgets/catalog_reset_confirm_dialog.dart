// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../l10n/app_localizations.dart';

/// Confirmation dialog for the reset-from-vehicle-database action
/// (#3651). Mirrors [PumpGainResetConfirmDialog] (#3901): the caller decides
/// what to do with the returned bool — this widget only asks.
class CatalogResetConfirmDialog {
  CatalogResetConfirmDialog._();

  /// [vehicleLabel] names the matched catalog row (e.g.
  /// "Peugeot 107 I (2005-2014)") so the user can verify the reset
  /// source before confirming. Returns `true` only on the explicit
  /// reset action; cancel / barrier dismiss / back all return `null`.
  static Future<bool?> show(BuildContext context, String vehicleLabel) {
    final l = AppLocalizations.of(context);
    // #3682 — delegates to the ONE shared destructive-action dialog.
    return confirmDestructiveAction(
      context,
      title: l.catalogResetConfirmTitle,
      message: l.catalogResetConfirmBody(vehicleLabel),
      confirmLabel: l.catalogResetAction,
    );
  }
}
