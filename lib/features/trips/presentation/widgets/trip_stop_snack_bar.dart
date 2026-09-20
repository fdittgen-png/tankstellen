// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/trip_history_repository.dart';
import '../../providers/recording_pipeline.dart';

/// What a Stop tells the user about the trip it just ended (#3582 — the UI
/// never lies about persistence), built away from the recording screen so
/// the three outcomes read as one decision:
///
/// * a stationary discard says nothing was saved (#2509);
/// * a failed history write says the trip is KEPT and offers a retry
///   (#4378) — [onRetry] is the same confirmed save, run now instead of at
///   the next launch, after which [onRetried] refreshes what the user sees;
/// * a save offers the honest delete of the row it wrote (#3582).
SnackBar tripStopSnackBar(
  AppLocalizations l, {
  required StoppedTripResult result,
  required TripHistoryRepository? repo,
  required Future<int> Function() onRetry,
  required VoidCallback onRetried,
}) {
  if (result.discardedNoMovement) {
    return SnackBarHelper.infoSnackBar(l.tripRecordingDiscardedNoMovement);
  }
  if (result.saveFailed) {
    return SnackBarHelper.infoSnackBar(
      l.tripSaveFailedKept,
      key: const Key('tripSaveFailedSnackBar'),
      duration: SnackBarHelper.undoDuration,
      action: SnackBarAction(
        label: l.tripSaveRetryAction,
        onPressed: () => unawaited(onRetry().then((_) => onRetried())),
      ),
    );
  }
  final entryId = result.entryId;
  return SnackBarHelper.infoSnackBar(
    l.tripSummaryAutoSaved,
    key: const Key('tripSavedSnackBar'),
    duration: SnackBarHelper.undoDuration,
    action: (entryId == null || repo == null)
        ? null
        : SnackBarAction(
            label: l.tripSummaryDelete,
            onPressed: () => unawaited(repo.delete(entryId)),
          ),
  );
}
