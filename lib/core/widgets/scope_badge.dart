// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_radius.dart';
import '../theme/spacing.dart';

/// Where a setting is stored — the answer to "if I change this, what
/// else changes?" (#3884, Epic #3881).
///
/// Most Settings rows are global; only rows whose scope is NOT global
/// carry a [ScopeBadge], so the badge is a signal, not noise.
enum SettingsScope {
  /// Persisted on the active `UserProfile` — switching profile switches
  /// the value (radar radius, widget colour, route planning, …).
  thisProfile,

  /// Persisted app-wide, independent of the active profile (radar
  /// auto-pin, feature flags, consents, …). Used where a neighbouring
  /// row is per-profile and the contrast would otherwise be ambiguous.
  allProfiles,

  /// Persisted on a `VehicleProfile` (OBD2 adapter, auto-record, …).
  thisVehicle,
}

/// Tiny tonal chip naming the [SettingsScope] of a tile or section.
///
/// Shown on the radar screen, the profile-scoped rows and the home-screen
/// widget section (#3884). Rendered as a `Semantics` label so screen
/// readers announce the scope together with the row.
class ScopeBadge extends StatelessWidget {
  final SettingsScope scope;

  const ScopeBadge(this.scope, {super.key});

  /// Localised label for [scope] — public so tests and tile subtitles
  /// can compose the same wording.
  static String labelOf(AppLocalizations l, SettingsScope scope) {
    switch (scope) {
      case SettingsScope.thisProfile:
        return l.scopeThisProfile;
      case SettingsScope.allProfiles:
        return l.scopeAllProfiles;
      case SettingsScope.thisVehicle:
        return l.scopeThisVehicle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = labelOf(AppLocalizations.of(context), scope);
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: AppRadius.sm,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
