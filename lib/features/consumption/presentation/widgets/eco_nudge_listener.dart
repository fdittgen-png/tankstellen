// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/eco_nudge_engine.dart';
import '../../providers/trip_recording_provider.dart';

/// Zero-size listener that surfaces live eco-coaching nudges as
/// dismissible SnackBars while the recording screen is mounted
/// (#3432, epic #3416 task 7).
///
/// Mirrors the #1273 haptic-eco-coach SnackBar pattern: because this
/// widget lives INSIDE the recording screen's tree, the subscription
/// exists only between the screen's mount and dispose — navigating away
/// (or the app backgrounding the UI) tears the listener down, so nudges
/// are structurally OFF when the recording is not in the foreground.
///
/// All decision logic (episode detection, ≥ 60 s spacing, max 3 per
/// trip) lives in the pure [EcoNudgeEngine]; this widget only bridges
/// provider state changes into `onReading` and renders the verdict.
/// The SnackBar uses the standard swipe-to-dismiss + auto-timeout —
/// same dismissal affordance as the eco-coach hint.
class EcoNudgeListener extends ConsumerStatefulWidget {
  const EcoNudgeListener({super.key});

  @override
  ConsumerState<EcoNudgeListener> createState() => _EcoNudgeListenerState();
}

class _EcoNudgeListenerState extends ConsumerState<EcoNudgeListener> {
  final EcoNudgeEngine _engine = EcoNudgeEngine();
  bool _wasActive = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(tripRecordingProvider, (prev, next) {
      // A fresh trip start (inactive → active) resets the per-trip
      // nudge budget; a stop clears the episode state for the next one.
      if (next.isActive && !_wasActive) _engine.reset();
      _wasActive = next.isActive;

      // Only nudge during the live recording phase — paused / dropped /
      // saving states must never coach.
      if (next.phase != TripRecordingPhase.recording) return;
      final reading = next.live;
      if (reading == null) return;
      final nudge = _engine.onReading(reading, DateTime.now());
      if (nudge != null) _show(nudge);
    });
    return const SizedBox.shrink();
  }

  void _show(EcoNudgeType nudge) {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final (icon, message) = switch (nudge) {
      EcoNudgeType.idleWaste => (Icons.hourglass_bottom, l.ecoNudgeIdle),
      EcoNudgeType.harshAccel => (Icons.flash_on, l.ecoNudgeHarshAccel),
      EcoNudgeType.highRpmCruise => (
          Icons.keyboard_double_arrow_up,
          l.ecoNudgeHighRpm
        ),
    };
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBarHelper.iconatedInfoSnackBar(
        icon,
        message,
        key: const Key('ecoNudgeSnackBar'),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
