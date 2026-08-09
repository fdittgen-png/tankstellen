// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// #3682 — THE one destructive-action confirmation for the whole app.
///
/// Every delete (and delete-like reset) routes through this function so
/// the warning look, the button order, the barrier semantics and the
/// error styling exist exactly once. Before it, the same AlertDialog
/// scaffolding was copy-pasted six times and five swipe surfaces plus
/// two sheet deletes had no confirmation at all.
///
/// Contract:
///  * returns `true` ONLY on an explicit tap of the destructive action;
///  * Cancel, barrier dismiss and system back all return `false` — a
///    destructive action must never happen by accident;
///  * [title] / [message] / [confirmLabel] default to the generic
///    localized strings; sites with richer copy (the η_v reset's
///    explainer, the vehicle delete naming the vehicle) pass their own;
///  * [confirmKey] gives a surface a stable per-site test handle
///    without duplicating the dialog.
///
/// The confirm button is error-styled AND icon-carrying so the
/// destructive choice is signalled by more than colour (the same
/// non-colour-alone rule the snackbars follow, #1692).
Future<bool> confirmDestructiveAction(
  BuildContext context, {
  String? title,
  String? message,
  String? confirmLabel,
  Key? confirmKey,
}) async {
  if (!context.mounted) return false;
  final l = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: scheme.error),
        title: Text(title ?? l.confirmDeleteTitle),
        content: Text(message ?? l.confirmDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton.tonalIcon(
            key: confirmKey,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.errorContainer,
              foregroundColor: scheme.onErrorContainer,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(confirmLabel ?? l.delete),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
