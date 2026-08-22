// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/widgets/staged_progress_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/trip_save_stage.dart';

// #2548 — re-export the stage enum so callers that import this widget
// keep resolving `TripSaveStage` unchanged (mirrors [TripStartProgress]).
export '../../domain/entities/trip_save_stage.dart' show TripSaveStage;

/// Inline progress card shown on the recording screen in place of the
/// frozen live metrics while a stopped trip is being wrapped up (#2548).
/// The stop-side bookend to [TripStartProgress]; the animated chrome
/// lives in the shared [StagedProgressCard], this file only maps
/// [TripSaveStage] onto its icon + label.
///
/// Indeterminate by design — the save is a sub-second fixed await
/// sequence with no per-item counter, so there is NO determinate %.
/// The "Syncing" beat is worded "Syncing in background…" because the
/// TankSync upload is fire-and-forget (unawaited) and only surfaced
/// when cloud sync is enabled.
class TripSaveProgress extends StatelessWidget {
  final TripSaveStage stage;

  const TripSaveProgress({super.key, required this.stage});

  IconData _iconFor(TripSaveStage stage) {
    switch (stage) {
      case TripSaveStage.finalizingSummary:
        return Icons.checklist;
      case TripSaveStage.savingToHistory:
        return Icons.save_outlined;
      case TripSaveStage.syncingToCloud:
        return Icons.cloud_upload_outlined;
    }
  }

  String _labelFor(AppLocalizations l, TripSaveStage stage) {
    switch (stage) {
      case TripSaveStage.finalizingSummary:
        return l.tripSaveProgressFinalizingSummary;
      case TripSaveStage.savingToHistory:
        return l.tripSaveProgressSavingToHistory;
      case TripSaveStage.syncingToCloud:
        return l.tripSaveProgressSyncingToCloud;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return StagedProgressCard(
      cardKey: const Key('tripSaveProgress'),
      icon: _iconFor(stage),
      label: _labelFor(l, stage),
      stageKey: stage,
      // #2548 — announce each stage transition via TalkBack / VoiceOver.
      announceStages: true,
    );
  }
}
