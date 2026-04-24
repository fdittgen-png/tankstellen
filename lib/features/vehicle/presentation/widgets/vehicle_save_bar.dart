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
            icon: const Icon(Icons.save),
            label: Text(l?.save ?? 'Save'),
          ),
        ),
      ),
    );
  }
}
