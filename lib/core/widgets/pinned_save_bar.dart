// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The ONE pinned bottom Save bar (#751 §3 / phase 2), promoted to
/// core after the vehicle and fill-up twins drifted apart only in
/// their icon glyph. Used via `bottomNavigationBar` so the CTA is
/// always one tap away regardless of scroll position, and respects
/// the system nav-bar inset so it never clips under gesture pills
/// (see `feedback_scaffold_inset_doubling.md`).
class PinnedSaveBar extends StatelessWidget {
  final VoidCallback onSave;

  /// Icon on the Save CTA — the vehicle form uses [Icons.save], the
  /// fill-up form [Icons.save_outlined].
  final IconData icon;

  const PinnedSaveBar({super.key, required this.onSave, this.icon = Icons.save});

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
            icon: Icon(icon),
            label: Text(l.save),
          ),
        ),
      ),
    );
  }
}
