// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../providers/shared_trips_provider.dart';
import 'trajet_row.dart';

/// "Shared with me" section on the Trajets tab (#2240).
///
/// Renders the trips other accounts have shared with the current user
/// as read-only [TrajetRow]s carrying a distinct "Shared" badge. Hidden
/// entirely when there's nothing shared (or sharing is unavailable —
/// the [sharedTripsProvider] returns an empty list in that case), so
/// owned-trip-only users never see an empty header.
///
/// These rows are NOT mixed into the owned-trip list: keeping them in a
/// clearly-labelled section underneath preserves the "these aren't
/// yours, you can't delete them" affordance the issue asked for.
class SharedTripsSection extends ConsumerWidget {
  const SharedTripsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sharedAsync = ref.watch(sharedTripsProvider);

    final shared = sharedAsync.value ?? const [];
    if (shared.isEmpty) return const SizedBox.shrink();

    return Column(
      key: const Key('trajets_shared_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Icon(Icons.group_outlined,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                l?.trajetsSharedSectionTitle ?? 'Shared with me',
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
        ),
        ...shared.map(
          (entry) => TrajetRow(
            entry: entry,
            vehicle: null,
            l: l,
            theme: theme,
            shared: true,
            onTap: () => context.push('/trip/${entry.id}'),
          ),
        ),
      ],
    );
  }
}
