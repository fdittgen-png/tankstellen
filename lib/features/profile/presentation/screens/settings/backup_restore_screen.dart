// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/section_card.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../fill_ups/api.dart'
    show BackupExportFlow, BackupRestoreFlow;
import 'settings_topic_scaffold.dart';

/// Settings → Backup & restore (#3884): the full-backup export (#1317)
/// and restore (#2571) actions, previously reachable only from the
/// Consumption overflow menu. Both call the shared flows the menu uses,
/// so there is exactly one implementation of each.
class BackupRestoreScreen extends ConsumerWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return SettingsTopicScaffold(
      title: l.settingsTopicBackupTitle,
      children: [
        SectionCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            key: const Key('settingsExportBackupTile'),
            leading: const Icon(Icons.download_outlined),
            title: Text(l.exportBackupMenuLabel),
            subtitle: Text(l.settingsBackupExportSubtitle),
            onTap: () => unawaited(BackupExportFlow.run(
              context,
              ref,
              where: 'BackupRestoreScreen: export failed',
            )),
          ),
        ),
        const SizedBox(height: 8),
        SectionCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            key: const Key('settingsRestoreBackupTile'),
            leading: const Icon(Icons.restore_outlined),
            title: Text(l.restoreBackupMenuLabel),
            subtitle: Text(l.settingsBackupRestoreSubtitle),
            onTap: () => unawaited(BackupRestoreFlow.run(context, ref)),
          ),
        ),
      ],
    );
  }
}
