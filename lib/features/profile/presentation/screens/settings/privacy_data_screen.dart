// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/app_routes.dart';
import '../../../../../core/providers/app_state_provider.dart';
import '../../../../../core/sync/sync_provider.dart';
import '../../../../../core/telemetry/storage/trace_storage.dart';
import '../../../../../core/widgets/settings_menu_tile.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/privacy_data_provider.dart';
import '../../widgets/privacy/privacy_status_text.dart';
import '../../widgets/privacy/privacy_summary_card.dart';
import '../../widgets/storage_bar.dart';
import 'privacy/privacy_choices_screen.dart';
import 'privacy/privacy_device_data_screen.dart';
import 'privacy/privacy_export_delete_screen.dart';
import 'settings_topic_scaffold.dart';

/// Settings → Privacy & data (#3908, Epic #3907): the ONE entry to the
/// privacy area — a three-line summary (where the data lives, sync,
/// storage) and four topic tiles with live status lines: Your choices,
/// Data on this device, Sync & account, Export or delete. Replaces the
/// former consent card + controls + Privacy Dashboard tile + storage
/// section stack, and the dashboard itself (its route now redirects
/// here).
class PrivacyDataScreen extends ConsumerWidget {
  const PrivacyDataScreen({super.key});

  /// Number of consents counted by the "Your choices" status line.
  static const int consentCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final consent = ref.watch(gdprConsentProvider);
    final sync = ref.watch(syncStateProvider);
    final inventory = ref.watch(deviceDataInventoryProvider);
    final errorLogCount = ref.watch(traceStorageProvider).count;
    final consentsOn = [
      consent.location,
      consent.errorReporting,
      consent.cloudSync,
      consent.vinOnlineDecode,
      consent.syncTrips,
    ].where((v) => v).length;

    return SettingsTopicScaffold(
      title: l.sectionPrivacyData,
      children: [
        const PrivacySummaryCard(),
        const SizedBox(height: 12),
        SettingsMenuTile(
          key: const Key('privacyTopic_choices'),
          icon: Icons.toggle_on_outlined,
          title: l.privacyTopicChoicesTitle,
          subtitle: l.privacyChoicesStatus(consentsOn, consentCount),
          onTap: () => _open(context, const PrivacyChoicesScreen()),
        ),
        const SizedBox(height: 8),
        SettingsMenuTile(
          key: const Key('privacyTopic_deviceData'),
          icon: Icons.phone_android,
          title: l.privacyLocalData,
          subtitle: l.privacyDeviceDataStatus(
            formatBytes(inventory.totalBytes),
            inventory.nonEmptyCount,
          ),
          onTap: () => _open(context, const PrivacyDeviceDataScreen()),
        ),
        const SizedBox(height: 8),
        SettingsMenuTile(
          key: const Key('privacyTopic_sync'),
          icon: Icons.cloud_outlined,
          title: l.settingsTopicSyncTitle,
          subtitle: PrivacyStatusText.syncLine(l, sync),
          // The Sync & account topic already has its route (#3884); the
          // tile here is a second door to the SAME screen.
          onTap: () => context.push(RoutePaths.settingsSync),
        ),
        const SizedBox(height: 8),
        SettingsMenuTile(
          key: const Key('privacyTopic_exportDelete'),
          icon: Icons.import_export,
          title: l.privacyTopicExportDeleteTitle,
          subtitle: l.privacyExportDeleteStatus(errorLogCount),
          onTap: () => _open(context, const PrivacyExportDeleteScreen()),
        ),
      ],
    );
  }

  /// The three privacy sub-screens are pushed on the shell branch's
  /// navigator (no deep-link contract of their own).
  static void _open(BuildContext context, Widget screen) {
    unawaited(Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    ));
  }
}
