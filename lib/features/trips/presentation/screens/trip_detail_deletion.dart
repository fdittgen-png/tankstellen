// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/confirm_delete_dialog.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../core/error/guarded.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/trip_history_provider.dart';

/// Serializes delete admission and retains complete telemetry for Undo.
class TripDetailDeletion {
  bool _pending = false;

  Future<void> run(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    String tripId,
  ) async {
    if (_pending) return;
    _pending = true;
    try {
      final confirmed = await confirmDestructiveAction(
        context,
        title: l.trajetDetailDeleteConfirmTitle,
        message: l.trajetDetailDeleteConfirmBody,
        confirmLabel: l.trajetDetailDeleteConfirmConfirm,
        confirmKey: const Key('trip_detail_delete_confirm'),
      );
      if (confirmed != true || !context.mounted) return;
      final notifier = ref.read(tripHistoryListProvider.notifier);
      final repo = ref.read(tripHistoryRepositoryProvider);
      final messenger = ScaffoldMessenger.maybeOf(context);
      final undoLabel = l.undo;
      final message = l.trajetDeletedUndoSnackbar;
      // A loader can restart while confirmation is open. Its summary fallback
      // is never an Undo payload: obtain the full canonical record first.
      final deleted = repo == null
          ? ref.read(tripHistoryDetailProvider(tripId))
          : await repo.loadByIdAsync(tripId);
      if (!context.mounted) return;
      if (repo != null && deleted == null) {
        SnackBarHelper.showError(context, l.errorUnknown);
        return;
      }
      await notifier.delete(tripId);
      if (!context.mounted) return;
      context.pop();
      if (deleted == null || messenger == null) return;
      messenger.showSnackBar(
        SnackBarHelper.undoSnackBar(
          message,
          undoLabel: undoLabel,
          onUndo: () => unawaited(notifier.save(deleted)),
        ),
      );
    } catch (e, st) {
      logFailure(e, st, where: 'Trip detail deletion');
      if (context.mounted) SnackBarHelper.showError(context, l.errorUnknown);
    } finally {
      _pending = false;
    }
  }
}
