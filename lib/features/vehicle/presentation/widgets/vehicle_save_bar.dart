// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Pinned bottom Save bar on the restyled edit-vehicle form
/// (#751 §3). Uses `bottomNavigationBar` so the CTA is always one
/// tap away regardless of scroll position, and respects the system
/// nav-bar inset (see `feedback_scaffold_inset_doubling.md`).
class VehicleSaveBar extends StatelessWidget {
  final VoidCallback onSave;
  const VehicleSaveBar({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      // #2117 — pinned save bars sit visibly above scroll content;
      // surfaceContainerHighest is the M3 tier for chrome surfaces
      // that need to lift off `surface`.
      color: theme.colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton.icon(
            onPressed: onSave,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.save),
            label: Text(l.save),
          ),
        ),
      ),
    );
  }
}
