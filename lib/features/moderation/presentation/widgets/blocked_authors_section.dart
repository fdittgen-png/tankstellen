// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/moderation/content_moderation_providers.dart';
import '../../../../l10n/app_localizations.dart';

/// Privacy Dashboard card listing the community-content authors the
/// user blocked on this device, each with an Unblock action (#3871,
/// Epic #3865 GDPR — closes the "no UI surfaces unblock yet" gap left
/// by #3726).
///
/// Reads [blockedContentAuthorsProvider] (device-local, never synced);
/// Unblock calls [BlockedContentAuthors.unblock] so the author's shared
/// content shows again on every community surface. Renders an explicit
/// empty state rather than hiding, so the user can SEE the list is
/// empty — the dashboard is a transparency surface.
class BlockedAuthorsSection extends ConsumerWidget {
  const BlockedAuthorsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final blocked = ref.watch(blockedContentAuthorsProvider).toList()..sort();
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      key: const Key('blocked_authors_section'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.block_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l.blockedAuthorsTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l.blockedAuthorsDescription,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 12),
            if (blocked.isEmpty)
              Text(
                l.blockedAuthorsEmpty,
                key: const Key('blocked_authors_empty'),
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              )
            else
              for (final id in blocked)
                Row(
                  key: Key('blocked_author_row_$id'),
                  children: [
                    Icon(Icons.person_off_outlined, size: 18, color: muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        id,
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      key: Key('blocked_author_unblock_$id'),
                      onPressed: () => unawaited(
                        ref
                            .read(blockedContentAuthorsProvider.notifier)
                            .unblock(id),
                      ),
                      child: Text(l.blockedAuthorsUnblock),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
