// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/trip_start_stage.dart';

// #2274 concern 2 — the stage enum moved to the domain layer so the
// [TripRecordingState] can carry it without a provider→presentation
// import. Re-exported here so the ~existing callers that import this
// widget keep resolving `TripStartStage` unchanged.
export '../../domain/entities/trip_start_stage.dart' show TripStartStage;

/// Inline progress card shown on the Trips tab in place of the
/// "Start recording" button while the trip-start flow runs. Combines
/// a slowly-rotating Bluetooth/route icon (the "entertainment"
/// affordance) with a [LinearProgressIndicator] and a stage-driven
/// status label so the user can see the app is doing something.
class TripStartProgress extends StatefulWidget {
  final TripStartStage stage;

  const TripStartProgress({super.key, required this.stage});

  @override
  State<TripStartProgress> createState() => _TripStartProgressState();
}

class _TripStartProgressState extends State<TripStartProgress>
    with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

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
    final theme = Theme.of(context);
    return Card(
      key: const Key('trip_start_progress_card'),
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1.1).animate(
                    CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
                  ),
                  child: RotationTransition(
                    turns: _spin,
                    child: Icon(
                      _iconFor(widget.stage),
                      size: 28,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      _labelFor(l, widget.stage),
                      key: ValueKey(widget.stage),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 6,
                backgroundColor: theme.colorScheme.onPrimaryContainer
                    .withValues(alpha: 0.15),
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
