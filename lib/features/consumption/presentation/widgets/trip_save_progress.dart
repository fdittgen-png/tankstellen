// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/trip_save_stage.dart';

// #2548 — re-export the stage enum so callers that import this widget
// keep resolving `TripSaveStage` unchanged (mirrors [TripStartProgress]).
export '../../domain/entities/trip_save_stage.dart' show TripSaveStage;

/// Inline progress card shown on the recording screen in place of the
/// frozen live metrics while a stopped trip is being wrapped up (#2548).
/// The stop-side bookend to [TripStartProgress]: a slowly-rotating /
/// pulsing stage icon + an indeterminate [LinearProgressIndicator] +
/// a stage-driven status label so the user sees the save happening
/// instead of an abrupt swap to the summary.
///
/// Indeterminate by design — the save is a sub-second fixed await
/// sequence with no per-item counter, so there is NO determinate %.
/// The "Syncing" beat is worded "Syncing in background…" because the
/// TankSync upload is fire-and-forget (unawaited) and only surfaced
/// when cloud sync is enabled.
class TripSaveProgress extends StatefulWidget {
  final TripSaveStage stage;

  const TripSaveProgress({super.key, required this.stage});

  @override
  State<TripSaveProgress> createState() => _TripSaveProgressState();
}

class _TripSaveProgressState extends State<TripSaveProgress>
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

  String _labelFor(AppLocalizations? l, TripSaveStage stage) {
    switch (stage) {
      case TripSaveStage.finalizingSummary:
        return l?.tripSaveProgressFinalizingSummary ?? 'Finalizing summary…';
      case TripSaveStage.savingToHistory:
        return l?.tripSaveProgressSavingToHistory ?? 'Saving to history…';
      case TripSaveStage.syncingToCloud:
        return l?.tripSaveProgressSyncingToCloud ?? 'Syncing in background…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = _labelFor(l, widget.stage);
    return Card(
      key: const Key('tripSaveProgress'),
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
                  // #2548 — a liveRegion so TalkBack / VoiceOver announce
                  // each stage transition as the save progresses.
                  child: Semantics(
                    liveRegion: true,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        label,
                        key: ValueKey(widget.stage),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: AppRadius.md,
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
