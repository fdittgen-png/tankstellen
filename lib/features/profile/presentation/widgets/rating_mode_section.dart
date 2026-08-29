// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/storage_providers.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/ugc_public_notice_dialog.dart';
import '../../../../l10n/app_localizations.dart';

/// Segmented button for the station-rating sharing mode
/// (`local` / `private` / `shared`) plus a live description below.
///
/// Extracted from the profile-edit sheet parts in #3871 (Epic #3865,
/// GDPR): switching to `shared` is the user's first PUBLIC contribution
/// (ratings become readable by every user of the database), so the
/// one-time "Shared with other users" notice gates that transition —
/// Cancel leaves the previous mode selected. Takes primitives so it is
/// testable without the DraggableScrollableSheet host.
class RatingModeSection extends ConsumerWidget {
  final String ratingMode;
  final ValueChanged<String> onChanged;

  const RatingModeSection({
    super.key,
    required this.ratingMode,
    required this.onChanged,
  });

  Future<void> _select(BuildContext context, WidgetRef ref, String mode) async {
    if (mode == 'shared' && ratingMode != 'shared') {
      final accepted = await ensureUgcPublicNoticeAccepted(
        context,
        settings: ref.read(settingsStorageProvider),
      );
      if (!accepted) return;
    }
    onChanged(mode);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'local',
              label: Text(l10n.ratingModeLocal),
              icon: const Icon(Icons.phone_android, size: 16),
            ),
            ButtonSegment(
              value: 'private',
              label: Text(l10n.ratingModePrivate),
              icon: const Icon(Icons.lock, size: 16),
            ),
            ButtonSegment(
              value: 'shared',
              label: Text(l10n.ratingModeShared),
              icon: const Icon(Icons.people, size: 16),
            ),
          ],
          selected: {ratingMode},
          onSelectionChanged: (s) => _select(context, ref, s.first),
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          ratingMode == 'local'
              ? (l10n.ratingDescLocal)
              : ratingMode == 'private'
              ? (l10n.ratingDescPrivate)
              : (l10n.ratingDescShared),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
