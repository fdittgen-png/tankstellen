// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Overflow targets the recording kebab dispatches via its single
/// `onSelected` path (#2764). Each item maps to a callback the host
/// [TripRecordingScreen] already owns (pin / help / PiP).
enum _RecordingOverflowAction { pin, help, pip }

/// Trailing app-bar actions for the active trip-recording screen (#2764).
///
/// Material 3 caps a top app bar at ~3 trailing actions before the title
/// starts truncating; the old inline layout emitted 5 (Pin + Help + PiP +
/// Pause + Stop) which clipped the title to "Enr…". This widget keeps the
/// two primary controls — **Pause + Stop** — as visible [IconButton]s and
/// folds **Pin, Help, PiP** into a single `more_vert` overflow kebab so the
/// title always has room. Mirrors the #2761 consumption-screen pattern.
///
/// All behaviour + keys are preserved: the pin item reflects [pinned] (icon
/// + label flip + a `Semantics(toggled:)` wrapper for TalkBack), the PiP
/// item only renders when [pipSupported] is true, and Help opens the same
/// target via [onShowPinHelp].
class RecordingAppBarActions extends StatelessWidget {
  const RecordingAppBarActions({
    super.key,
    required this.pinned,
    required this.pipSupported,
    required this.isActive,
    required this.isPaused,
    required this.stopping,
    required this.onTogglePin,
    required this.onShowPinHelp,
    required this.onEnterPip,
    required this.onTogglePause,
    required this.onStop,
  });

  /// Whether the recording form is currently pinned (wake lock held).
  final bool pinned;

  /// Whether Picture-in-Picture can host app UI on this platform
  /// (Android-only; the PiP item is absent elsewhere).
  final bool pipSupported;

  /// Whether the trip is actively recording (gates Pause / Stop).
  final bool isActive;

  /// Whether the trip is currently paused (drives the Pause↔Resume icon).
  final bool isPaused;

  /// Whether a stop is already in flight (disables Stop to avoid re-entry).
  final bool stopping;

  final VoidCallback onTogglePin;
  final VoidCallback onShowPinHelp;
  final VoidCallback onEnterPip;
  final VoidCallback onTogglePause;
  final VoidCallback onStop;

  void _onSelected(_RecordingOverflowAction action) {
    switch (action) {
      case _RecordingOverflowAction.pin:
        onTogglePin();
      case _RecordingOverflowAction.help:
        onShowPinHelp();
      case _RecordingOverflowAction.pip:
        onEnterPip();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pause + Stop stay primary (visible) — the two controls a
        // driver reaches for mid-trip.
        IconButton(
          key: const Key('tripPauseButton'),
          icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
          tooltip: isPaused ? (l?.tripResume ?? 'Resume') : (l?.tripPause ?? 'Pause'),
          onPressed: isActive ? onTogglePause : null,
        ),
        IconButton(
          key: const Key('tripStopButton'),
          icon: const Icon(Icons.stop_circle_outlined),
          tooltip: l?.tripStop ?? 'Stop recording',
          onPressed: stopping || !isActive ? null : onStop,
        ),
        // Pin / Help / PiP collapse into one kebab so the title keeps room.
        PopupMenuButton<_RecordingOverflowAction>(
          key: const Key('recording_overflow_menu'),
          icon: const Icon(Icons.more_vert),
          tooltip: l?.moreActionsTooltip ?? 'More',
          onSelected: _onSelected,
          itemBuilder: (_) => [
            // #891 — the pin item reflects + toggles `_pinned`. Its
            // visible label IS the Pin / Unpin action string (so the
            // menu reads like the action it performs), and a
            // `Semantics(toggled:)` wrapper keeps the TalkBack on/off
            // state the old icon-only IconButton exposed. The label is
            // not duplicated on the wrapper so the merged semantics
            // stays exactly "Pin recording form" / "Unpin recording
            // form" (#2764).
            PopupMenuItem<_RecordingOverflowAction>(
              key: const Key('tripPinButton'),
              value: _RecordingOverflowAction.pin,
              child: Semantics(
                toggled: pinned,
                child: _MenuRow(
                  icon: pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  iconColor:
                      pinned ? Theme.of(context).colorScheme.primary : null,
                  label: pinned
                      ? (l?.tripRecordingPinSemanticOn ?? 'Unpin recording form')
                      : (l?.tripRecordingPinSemanticOff ??
                          'Pin recording form'),
                ),
              ),
            ),
            // #1273 — "what does pin do?" help, always present.
            PopupMenuItem<_RecordingOverflowAction>(
              key: const Key('tripPinHelpButton'),
              value: _RecordingOverflowAction.help,
              child: _MenuRow(
                icon: Icons.help_outline,
                label: l?.tripRecordingPinHelpTooltip ?? 'What does pin do?',
              ),
            ),
            // #1884 — minimise to PiP; Android-only.
            if (pipSupported)
              PopupMenuItem<_RecordingOverflowAction>(
                key: const Key('tripMinimiseButton'),
                value: _RecordingOverflowAction.pip,
                child: _MenuRow(
                  icon: Icons.picture_in_picture_alt,
                  label: l?.tripRecordingMinimiseTooltip ??
                      'Minimise to a floating tile',
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A leading-icon + label row for an overflow [PopupMenuItem] (mirrors the
/// consumption-screen kebab's `_MenuRow`). The label shrinks + ellipsizes
/// so a long translation (German / the en_XA pseudo-locale) never overflows
/// the PopupMenuItem's ~256 dp bound.
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;

  const _MenuRow({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
