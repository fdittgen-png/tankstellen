// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/sync/sync_provider.dart';
import '../../../../../core/widgets/section_card.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../providers/privacy_data_provider.dart';
import '../storage_bar.dart';
import 'privacy_status_text.dart';

/// The three-line summary at the top of Privacy & data (#3908, Epic
/// #3907): where the data lives, whether it syncs (and under which kind
/// of account), and how much the app stores on this device. Replaces the
/// former dashboard hero + config card + duplicate storage figures.
class PrivacySummaryCard extends ConsumerWidget {
  const PrivacySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sync = ref.watch(syncStateProvider);
    final inventory = ref.watch(deviceDataInventoryProvider);
    final lines = <(IconData, String, Key)>[
      (
        sync.isConfigured ? Icons.cloud_done_outlined : Icons.phone_android,
        PrivacyStatusText.dataLocationLine(l, sync),
        const Key('privacySummaryLocation'),
      ),
      (
        sync.isConfigured ? Icons.sync : Icons.sync_disabled,
        PrivacyStatusText.syncLine(l, sync),
        const Key('privacySummarySync'),
      ),
      (
        Icons.storage_outlined,
        l.privacyStorageLine(formatBytes(inventory.totalBytes)),
        const Key('privacySummaryStorage'),
      ),
    ];
    return SectionCard(
      key: const Key('privacySummaryCard'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (icon, text, key) in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(text,
                        key: key, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
