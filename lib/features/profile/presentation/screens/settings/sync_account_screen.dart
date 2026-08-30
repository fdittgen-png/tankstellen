// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../widgets/tank_sync_section.dart';
import 'settings_topic_scaffold.dart';

/// Settings → Sync & account (#3884): the TankSync section expanded —
/// connection status, account (anonymous ↔ email), data management and
/// the danger zone. The root tile is gated on `Feature.tankSync`
/// (#1447 phase 3); stored TankSync config survives the gate.
class SyncAccountScreen extends StatelessWidget {
  const SyncAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SettingsTopicScaffold(
      title: l.settingsTopicSyncTitle,
      children: [
        SettingsGroupHeader(
          icon: Icons.cloud_outlined,
          title: 'TankSync', // i18n-ignore: brand name
          // #1696 — a localized descriptive subtitle so the brand-named
          // section isn't an unexplained label.
          subtitle: l.tankSyncSectionSubtitle,
        ),
        const TankSyncSection(),
      ],
    );
  }
}
