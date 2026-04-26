import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Pinned bottom Save bar (#751 phase 2). Sits below the scroll view
/// so the CTA is always one tap away regardless of how many cards
/// the user has scrolled past. Respects the system nav-bar inset so
/// it never clips under gesture pills (see
/// `feedback_scaffold_inset_doubling.md`).
///
/// Pulled out of `add_fill_up_screen.dart` (#563 extraction) so the
/// screen file drops well below 300 LOC.
class FillUpPinnedSaveBar extends StatelessWidget {
  final VoidCallback onSave;

  const FillUpPinnedSaveBar({super.key, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton.icon(
            onPressed: onSave,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.save_outlined),
            label: Text(l?.save ?? 'Save'),
          ),
        ),
      ),
    );
  }
}
