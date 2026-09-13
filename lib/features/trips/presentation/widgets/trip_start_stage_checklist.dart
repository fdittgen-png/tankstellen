// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/trip_start_stage.dart';

/// The three trip-start steps, all of them, with the ones already behind
/// us ticked (#4126).
///
/// The start flow has always known its stage — `TripRecordingState`
/// carries it and the progress card renders its label — but only ever
/// showed ONE of the three at a time, as a line of text that was
/// replaced. On a screen that is otherwise empty for the 3-12 s a
/// connect normally takes (the field logs show holds far longer than
/// that), a single line gives the user nothing to read progress from: it
/// looks the same at second one and second ten, and the honest
/// conclusion is that the app has hung.
///
/// Showing all three turns the same information into progress. Nothing
/// new is measured, and nothing here talks to the OBD2 stack — the stage
/// arrives as a plain enum from the state that already owns it.
class TripStartStageChecklist extends StatelessWidget {
  const TripStartStageChecklist({super.key, required this.stage});

  /// The step currently running.
  final TripStartStage stage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = theme.colorScheme.onPrimaryContainer;
    final current = TripStartStage.values.indexOf(stage);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final step in TripStartStage.values)
          _StepRow(
            label: _stepLabel(l, step),
            // A step is done once the flow has moved past it. There is no
            // failure state to render: a step that fails ends the flow,
            // and the error surfaces on its own.
            done: TripStartStage.values.indexOf(step) < current,
            running: step == stage,
            ink: ink,
          ),
        const SizedBox(height: Spacing.sm),
        Text(
          l.tripStartSlowHint(l.obd2ResetConnection),
          style: theme.textTheme.bodySmall?.copyWith(
            color: ink.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  /// Short NOUN for a step — the progress card's own labels end in an
  /// ellipsis, which only reads correctly for the one step in flight.
  String _stepLabel(AppLocalizations l, TripStartStage step) => switch (step) {
        TripStartStage.connectingAdapter => l.tripStartStepAdapter,
        TripStartStage.readingVehicleData => l.tripStartStepVehicle,
        TripStartStage.startingRecording => l.tripStartStepRecording,
      };
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.label,
    required this.done,
    required this.running,
    required this.ink,
  });

  final String label;
  final bool done;
  final bool running;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A pending step is present but quiet: the reader needs to see that
    // there ARE two more steps without them competing with the one that
    // is running.
    final alpha = running || done ? 1.0 : 0.5;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle
                : running
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
            size: 16,
            color: ink.withValues(alpha: alpha),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: ink.withValues(alpha: alpha),
                fontWeight: running ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
