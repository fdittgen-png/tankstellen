// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import '../../../../../core/sync/sync_config.dart';
import '../../../../../l10n/app_localizations.dart';

/// The plain-language status lines the Privacy & data entry shares
/// between its summary card and its topic tiles (#3908, Epic #3907) —
/// ONE wording per fact, so the card and the tile can never disagree.
abstract final class PrivacyStatusText {
  /// "Sync: on · anonymous account" / "… · email account" / "Sync: off".
  static String syncLine(AppLocalizations l, SyncConfig config) {
    if (!config.isConfigured) return l.privacySyncLineDisabled;
    return config.hasEmail
        ? l.privacySyncLineEnabledEmail
        : l.privacySyncLineEnabledAnonymous;
  }

  /// Where the data lives: on this device only, or also on TankSync.
  static String dataLocationLine(AppLocalizations l, SyncConfig config) =>
      config.isConfigured
          ? l.privacyDataLocationSynced
          : l.privacyDataLocationLocal;

  /// The localised sync-mode explanation ("Sparkilo Community — the
  /// developer's EU server", …) for the Sync & account screen (#3911).
  static String modeLine(AppLocalizations l, SyncMode mode) => switch (mode) {
        SyncMode.community => l.privacySyncModeCommunity,
        SyncMode.joinExisting => l.privacySyncModeSharedGroup,
        SyncMode.private => l.privacySyncModeSelfHosted,
        SyncMode.none => l.privacySyncLineDisabled,
      };

  /// Host part of the Supabase URL — no scheme, no path — or the raw
  /// value when it does not parse.
  static String databaseHost(String url) {
    final host = Uri.tryParse(url)?.host;
    return (host == null || host.isEmpty) ? url : host;
  }
}
