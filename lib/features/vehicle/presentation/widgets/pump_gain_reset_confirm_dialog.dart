// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';

import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../l10n/app_localizations.dart';

/// Destructive-action confirmation dialog for the pump-calibration
/// reset (#3901, Epic #3886): discards the learned pump gain so the
/// next full-to-full tank window re-anchors the estimate from scratch.
/// The caller decides what to do with the returned bool — this widget
/// only asks the user.
class PumpGainResetConfirmDialog {
  PumpGainResetConfirmDialog._();

  /// Returns `true` only when the user explicitly taps the reset
  /// action. Cancel / barrier dismiss / back-button all return
  /// `false`, which callers should treat as "do nothing".
  static Future<bool?> show(BuildContext context) {
    final l = AppLocalizations.of(context);
    // #3682 — delegates to the ONE shared destructive-action dialog;
    // this class stays as the call-site-stable named entry point.
    return confirmDestructiveAction(
      context,
      title: l.pumpGainResetConfirmTitle,
      message: l.pumpGainResetConfirmBody,
      confirmLabel: l.pumpGainResetAction,
    );
  }
}
