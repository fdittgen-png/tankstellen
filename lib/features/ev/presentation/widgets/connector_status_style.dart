// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/dark_mode_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/ev/charging_station.dart';

/// Locale-safe presentation for a [ConnectorStatus] (#2493).
///
/// Colour and icon switch on the canonical enum — never on the upstream
/// free-form status string — so the operational scale renders identically
/// in all 23 locales. Only the human-readable [label] is localised.
///
/// This is the single source of truth shared by the search-side
/// `EVConnectorTile` and the EV station-detail screen, so the two surfaces
/// can never drift apart on what "available" looks like again.
extension ConnectorStatusStyle on ConnectorStatus {
  /// Semantic status colour, adapting to light/dark for WCAG AA.
  Color color(BuildContext context) => switch (this) {
    ConnectorStatus.available => DarkModeColors.success(context),
    ConnectorStatus.occupied => DarkModeColors.warning(context),
    ConnectorStatus.partial => DarkModeColors.warning(context),
    ConnectorStatus.outOfOrder => DarkModeColors.error(context),
    ConnectorStatus.unknown => Theme.of(context).colorScheme.outline,
  };

  /// Status glyph, switched on the enum (not the upstream string).
  IconData get icon => switch (this) {
    ConnectorStatus.available => Icons.check_circle,
    ConnectorStatus.occupied => Icons.access_time,
    ConnectorStatus.partial => Icons.warning,
    ConnectorStatus.outOfOrder => Icons.cancel,
    ConnectorStatus.unknown => Icons.help_outline,
  };

  /// Localised display label. Falls back to English when no [l10n] is in
  /// scope (e.g. tests pumped without localisations).
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      ConnectorStatus.available => l10n.evStatusAvailable,
      ConnectorStatus.occupied => l10n.evStatusOccupied,
      ConnectorStatus.partial => l10n.evStatusPartial,
      ConnectorStatus.outOfOrder => l10n.evStatusOutOfOrder,
      ConnectorStatus.unknown => l10n.evStatusUnknown,
    };
  }
}
