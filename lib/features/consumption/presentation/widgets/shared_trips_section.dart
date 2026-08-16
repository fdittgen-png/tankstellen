// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/moderation/content_moderation_providers.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/sync/content_reports_sync.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/shared_trips_provider.dart';
import 'trajet_row.dart';

/// "Shared with me" section on the Trajets tab (#2240).
///
/// Renders the trips other accounts have shared with the current user
/// as read-only [TrajetRow]s carrying a distinct "Shared" badge. Hidden
/// entirely when there's nothing shared (or sharing is unavailable —
/// the [visibleSharedTripsProvider] returns an empty result in that
/// case), so owned-trip-only users never see an empty header.
///
/// These rows are NOT mixed into the owned-trip list: keeping them in a
/// clearly-labelled section underneath preserves the "these aren't
/// yours, you can't delete them" affordance the issue asked for.
///
/// #3726 — long-pressing a shared row opens the moderation sheet
/// (Report content / Block author), the in-app UGC report/block flow
/// Play's UGC policy requires. Reported items hide immediately and a
/// `content_reports` row reaches the user's TankSync server; blocked
/// authors are filtered from every community surface on this device.
class SharedTripsSection extends ConsumerWidget {
  const SharedTripsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fetch = ref.watch(visibleSharedTripsProvider);

    final shared = fetch.entries;
    if (shared.isEmpty) return const SizedBox.shrink();

    return Column(
      key: const Key('trajets_shared_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Icon(
                Icons.group_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                l.trajetsSharedSectionTitle,
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
            onTap: () => TripDetailRoute(entry.id).push<void>(context),
            onLongPress: () => _showModerationSheet(
              context,
              ref,
              tripId: entry.id,
              authorId: fetch.ownerByTripId[entry.id],
            ),
          ),
        ),
      ],
    );
  }

  /// The report/block bottom sheet for one shared trip (#3726).
  void _showModerationSheet(
    BuildContext context,
    WidgetRef ref, {
    required String tripId,
    required String? authorId,
  }) {
    final l = AppLocalizations.of(context);
    unawaited(showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('shared_trip_report_action'),
              leading: const Icon(Icons.flag_outlined),
              title: Text(l.contentModerationReportAction),
              onTap: () {
                Navigator.of(sheetContext).pop();
                unawaited(_confirmAndReport(context, ref, tripId: tripId));
              },
            ),
            if (authorId != null)
              ListTile(
                key: const Key('shared_trip_block_action'),
                leading: const Icon(Icons.block_outlined),
                title: Text(l.contentModerationBlockAction),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  unawaited(
                      _confirmAndBlock(context, ref, authorId: authorId));
                },
              ),
          ],
        ),
      ),
    ));
  }

  /// Confirmation dialog → `content_reports` row → hide + snackbar.
  Future<void> _confirmAndReport(
    BuildContext context,
    WidgetRef ref, {
    required String tripId,
  }) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.contentModerationReportDialogTitle),
        content: Text(l.contentModerationReportDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            key: const Key('shared_trip_report_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.contentModerationReportConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final submit = ref.read(contentReportSubmitProvider);
    final sent = await submit(
      targetKind: ContentReportsSync.kindSharedTrip,
      targetId: tripId,
    );
    if (!sent) {
      messenger.showSnackBar(
          SnackBar(content: Text(l.contentModerationReportFailedSnack)));
      return;
    }
    await ref.read(reportedContentTargetsProvider.notifier).hide(tripId);
    messenger.showSnackBar(
        SnackBar(content: Text(l.contentModerationReportedSnack)));
  }

  /// Confirmation dialog → local block-list add → snackbar.
  Future<void> _confirmAndBlock(
    BuildContext context,
    WidgetRef ref, {
    required String authorId,
  }) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.contentModerationBlockDialogTitle),
        content: Text(l.contentModerationBlockDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            key: const Key('shared_trip_block_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.contentModerationBlockConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(blockedContentAuthorsProvider.notifier).block(authorId);
    messenger.showSnackBar(
        SnackBar(content: Text(l.contentModerationBlockedSnack)));
  }
}
