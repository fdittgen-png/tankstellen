// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../theme/dark_mode_colors.dart';
import 'confirm_delete_dialog.dart';

/// Reusable swipe-to-delete wrapper with red background and delete icon.
///
/// Replaces the once-identical Dismissible implementations across the
/// list surfaces (alerts, favorites, itineraries, fill-ups, charging
/// logs). The `confirm_delete_lint_test` allowlists raw `Dismissible`
/// usages, so every delete-swipe in the app goes through here.
///
/// #3682 — every swipe now asks the shared [confirmDestructiveAction]
/// warning BEFORE dismissing, so an accidental flick can't destroy
/// data; the surfaces' existing 10-second undo (#3664) stays as the
/// second net for a confirmed-but-regretted delete. [confirmMessage]
/// lets a list name the item ("Delete the alert for Total Sète?");
/// null keeps the generic localized body.
class SwipeToDelete extends StatelessWidget {
  final Key dismissKey;
  final VoidCallback onDismissed;
  final Widget child;

  /// Optional item-specific message for the confirmation dialog.
  final String? confirmMessage;

  const SwipeToDelete({
    super.key,
    required this.dismissKey,
    required this.onDismissed,
    required this.child,
    this.confirmMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: dismissKey,
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) =>
          confirmDestructiveAction(context, message: confirmMessage),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: DarkModeColors.error(context),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismissed(),
      child: child,
    );
  }
}
