// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The action row that closes a bottom-sheet form (#3993).
///
/// Three sheets had grown their own copy of the same Row — the zone
/// alert, the station alert and the loyalty card — differing only in
/// which ARB key they read the labels from. One primary action, dismiss
/// to its left, equal widths, and the primary is [FilledButton] so the
/// eye lands on the thing that commits.
///
/// A null [onConfirm] disables the primary action. Say WHY next to it
/// (the way the zone sheet names its first unmet requirement) — a
/// silently grey button is a dead end.
class SheetFormActions extends StatelessWidget {
  const SheetFormActions({
    super.key,
    required this.onCancel,
    required this.onConfirm,
    this.cancelLabel,
    this.confirmLabel,
    this.confirmKey,
  });

  final VoidCallback onCancel;

  /// `null` disables the primary action.
  final VoidCallback? onConfirm;

  /// Defaults to the shared "Cancel" / "Save" strings; a sheet whose
  /// verb is different (Create, Add) passes its own.
  final String? cancelLabel;
  final String? confirmLabel;

  /// Test handle on the primary action, so a sheet test can tap it
  /// without depending on the label.
  final Key? confirmKey;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            child: Text(cancelLabel ?? l.cancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            key: confirmKey,
            onPressed: onConfirm,
            child: Text(confirmLabel ?? l.save),
          ),
        ),
      ],
    );
  }
}
