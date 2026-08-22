// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/widgets/staged_progress_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/trip_start_stage.dart';

// #2274 concern 2 — the stage enum moved to the domain layer so the
// [TripRecordingState] can carry it without a provider→presentation
// import. Re-exported here so the ~existing callers that import this
// widget keep resolving `TripStartStage` unchanged.
export '../../domain/entities/trip_start_stage.dart' show TripStartStage;

/// Inline progress card shown on the Trips tab in place of the
/// "Start recording" button while the trip-start flow runs. The
/// animated chrome (rotating/pulsing icon + indeterminate bar) lives
/// in the shared [StagedProgressCard]; this file only maps
/// [TripStartStage] onto its icon + label.
class TripStartProgress extends StatelessWidget {
  final TripStartStage stage;

  /// #3335 — when non-null, a "Cancel" affordance is shown so the user can
  /// interrupt a stuck/slow OBD2 initialization and retry later without
  /// restarting the app. Null hides the button (e.g. legacy inline use).
  final VoidCallback? onCancel;

  const TripStartProgress({super.key, required this.stage, this.onCancel});

  IconData _iconFor(TripStartStage stage) {
    switch (stage) {
      case TripStartStage.connectingAdapter:
        return Icons.bluetooth_searching;
      case TripStartStage.readingVehicleData:
        return Icons.directions_car;
      case TripStartStage.startingRecording:
        return Icons.fiber_manual_record;
    }
  }

  String _labelFor(AppLocalizations l, TripStartStage stage) {
    switch (stage) {
      case TripStartStage.connectingAdapter:
        return l.tripStartProgressConnectingAdapter;
      case TripStartStage.readingVehicleData:
        return l.tripStartProgressReadingVehicleData;
      case TripStartStage.startingRecording:
        return l.tripStartProgressStartingRecording;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return StagedProgressCard(
      cardKey: const Key('trip_start_progress_card'),
      icon: _iconFor(stage),
      label: _labelFor(l, stage),
      stageKey: stage,
      onCancel: onCancel,
      cancelKey: const Key('trip_start_progress_cancel'),
    );
  }
}
