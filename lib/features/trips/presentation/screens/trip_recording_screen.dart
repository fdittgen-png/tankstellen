// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_routes.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../driving/haptic_eco_coach.dart';
import '../../../driving/providers/driving_coach_voice_listener_provider.dart';
import '../../../driving/providers/haptic_eco_coach_provider.dart';
import '../../../driving/providers/voice_announcement_listener_provider.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../../obd2/api.dart';
import '../../data/pip_controller.dart';
import '../../../fill_ups/api.dart';
import '../../domain/trip_recorder.dart';
import '../../providers/broken_map_warned_vehicles_provider.dart';
import '../../providers/pip_mode_provider.dart';
import '../../providers/recording_profile_provider.dart';
import '../../providers/trip_recording_provider.dart';
import '../../providers/wakelock_facade.dart';
import '../widgets/broken_map_widgets.dart';
import '../../../driving_score/api.dart';
import '../widgets/minimal_drive_summary.dart';
import '../widgets/recording_app_bar_actions.dart';
import '../widgets/trip_avg_consumption_card.dart';
import '../widgets/trip_radar_card.dart';
import '../widgets/trip_recording_landscape_body.dart';
import '../widgets/trip_save_progress.dart';
import '../widgets/trip_start_progress.dart';
import '../../../../core/error/guarded.dart';
import '../../../../core/utils/edge_to_edge.dart';

part 'trip_recording_screen_body.dart';
part 'trip_recording_screen_build.dart';
part 'trip_recording_screen_handlers.dart';
part 'trip_recording_screen_pin.dart';

/// Result returned when the user confirms saving a recorded trip
/// from the summary screen (#726, #1185).
///
/// The trip itself is already persisted to [TripHistoryRepository] by
/// the time the summary screen renders — `TripRecording.stop()` writes
/// the [TripHistoryEntry] before this screen flips to the summary
/// view. The id is exposed here so the caller can refresh its trip
/// list / scroll to the new row, but the save action itself NEVER
/// creates a fill-up. Null means the user cancelled or discarded.
class TripSaveResult {
  /// Id of the persisted [TripHistoryEntry] for this trip. Matches
  /// the id used by [TripHistoryRepository.save] (ISO start timestamp
  /// when available, otherwise the save-time fallback).
  final String entryId;
  final TripSummary summary;

  const TripSaveResult({required this.entryId, required this.summary});
}

/// Live view of the app-wide trip recording. The trip itself lives
/// in [tripRecordingProvider] (keepAlive), so this screen can come
/// and go without losing state.
///
/// App bar exposes Pause/Resume and Stop; the user can also back
/// out of the screen entirely while driving — the recording
/// continues via the provider, surfaced by [TripRecordingBanner] on
/// every subsequent screen.
class TripRecordingScreen extends ConsumerStatefulWidget {
  const TripRecordingScreen({super.key});

  @override
  ConsumerState<TripRecordingScreen> createState() =>
      _TripRecordingScreenState();
}

// #3762 — decomposed under the #1680 file-length cap: the State's
// members are split move-only across four `part` mixins (pin controls,
// event handlers, body sections, build + lifecycle), applied in
// dependency order below. Private state stays shared; zero behaviour
// change. This file keeps the members pinned here by the lint
// baselines (wall-clock call sites, `Card(` / `titleLarge` allowlists).
class _TripRecordingScreenState extends ConsumerState<TripRecordingScreen>
    with
        _TripRecordingPinControls,
        _TripRecordingEventHandlers,
        _TripRecordingBodySections,
        _TripRecordingBuild,
        _TripRecordingLifecycle {
  /// #1395 — hidden 5-tap gesture state for the OBD2 diagnostic
  /// overlay toggle. Mirrors the [MapScreen] gesture (PR #1378) bit-
  /// for-bit so the two debug toggles can be reasoned about as a
  /// single pattern.
  ///
  /// Five taps within [_debugGestureWindow] flips
  /// [obd2DebugOverlayProvider]; a stray double-tap during normal
  /// use cannot accidentally enable the overlay because the count
  /// resets after a 2-second pause.
  static const Duration _debugGestureWindow = Duration(seconds: 2);
  static const int _debugGestureTapThreshold = 5;
  int _debugTapCount = 0;
  DateTime? _lastDebugTapAt;

  /// #1458 phase 2 — sticky guard so the unpinned-recording GPS
  /// warning SnackBar fires AT MOST once per recording-screen mount.
  /// Pinning + unpinning + leaving + returning intentionally re-fires
  /// because it's a fresh mount each time; what we want to avoid is
  /// spamming on every rebuild that re-enters the post-frame check.
  bool _unpinnedWarningShown = false;

  /// #1458 phase 2 — surface a one-shot SnackBar warning when the user
  /// arrives at the recording screen with the pin toggle OFF AND a
  /// trip is currently active. Pinning keeps the screen on + hides
  /// system bars; without it, Android may throttle GPS during sleep
  /// and the trip path heatmap will show gaps. Production telemetry
  /// (issue #1458 phase 2) feeds the persisted [GpsSampleDiagnostic]
  /// list so a future iteration can quantify the throttle rate per
  /// device — the warning is the upfront mitigation while we
  /// instrument the live behaviour.
  ///
  /// Suppressed when [_pinned] is true because pinning is the actual
  /// fix; nagging the user who already opted in would be noise. The
  /// [_unpinnedWarningShown] guard prevents re-firing within a single
  /// screen mount even if the post-frame callback runs multiple
  /// times (it fires once per [WidgetsBinding.instance] schedule —
  /// the guard is a defence against the observed case where a parent
  /// rebuild re-enters initState during pumpAndSettle in widget
  /// tests).
  @override
  void _maybeShowUnpinnedWarning() {
    if (!mounted) return;
    if (_unpinnedWarningShown) return;
    if (_pinned) return;
    final notifier = ref.read(tripRecordingProvider.notifier);
    final recordingState = ref.read(tripRecordingProvider);
    if (!recordingState.isActive) return;
    // Only fire on a FRESH recording mount — i.e. the user just tapped
    // Start Recording in the trajets tab and was navigated here. When
    // they return to the screen later via the banner (after backing
    // out mid-trip), `lastTripStartedAt` is well in the past and the
    // warning would just be noise. We use a 10 s window so the
    // 600 ms post-mount delay + any test-pump + any production
    // initState→post-frame race comfortably falls inside.
    final startedAt = notifier.lastTripStartedAt;
    if (startedAt == null) return;
    final age = DateTime.now().difference(startedAt);
    if (age > const Duration(seconds: 10)) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final l = AppLocalizations.of(context);
    _unpinnedWarningShown = true;
    messenger.showSnackBar(
      SnackBarHelper.iconatedInfoSnackBar(
        Icons.gps_off,
        l.tripRecordingUnpinnedWarning,
        key: const Key('tripRecordingUnpinnedWarningSnackBar'),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  /// Hidden gesture handler — counts trip-recording-screen title taps
  /// inside [_debugGestureWindow] and toggles
  /// [obd2DebugOverlayProvider] on reaching [_debugGestureTapThreshold]
  /// (#1395). Sibling to `_bumpDebugTapCount` in [MapScreen]
  /// (PR #1378).
  @override
  void _bumpDebugTapCount() {
    final now = DateTime.now();
    final last = _lastDebugTapAt;
    if (last == null || now.difference(last) > _debugGestureWindow) {
      _debugTapCount = 1;
    } else {
      _debugTapCount++;
    }
    _lastDebugTapAt = now;

    if (_debugTapCount >= _debugGestureTapThreshold) {
      _debugTapCount = 0;
      _lastDebugTapAt = null;
      final wasEnabled = ref.read(obd2DebugOverlayProvider);
      unawaited(
        ref.read(obd2DebugOverlayProvider.notifier).toggle().then((_) {
          if (!mounted) return;
          final l10n = AppLocalizations.of(context);
          final msg = wasEnabled
              ? (l10n.obd2DebugOverlayDisabledSnack)
              : (l10n.obd2DebugOverlayEnabledSnack);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBarHelper.infoSnackBar(msg));
        }),
      );
    }
  }

  @override
  void _onSave() {
    // #1185 — the trip is ALREADY persisted to the rolling
    // [TripHistoryRepository] by `TripRecording.stop()` before this
    // summary screen renders, so this handler is a confirm-and-pop
    // affordance, not a write site. We DELIBERATELY do not push
    // `AddFillUpScreen` from here: a trip is a consumption record,
    // a fill-up is a refuel event at a pump — the two must not be
    // conflated (see issue #1185 for the wrong-semantics report).
    final r = _stopped!;
    // Match the id derivation in `TripRecording._saveToHistory` so
    // the popped id resolves to the entry that was just written.
    final entryId =
        r.summary.startedAt?.toIso8601String() ??
        DateTime.now().toIso8601String();
    ref.read(tripRecordingProvider.notifier).reset();
    Navigator.of(
      context,
    ).pop(TripSaveResult(entryId: entryId, summary: r.summary));
  }

  /// #1273 — show a bottom sheet explaining what the pin button does.
  /// Always visible (NOT gated by any toggle); first-launch users
  /// need this regardless of opt-ins.
  ///
  /// #2274 concern 1 — the sheet also hosts the persisted "always pin
  /// when recording starts" opt-in. Off by default (the deliberate
  /// opt-in-each-drive design); flipping it on persists to the global
  /// [RecordingProfile] and pins THIS live screen immediately so the
  /// effect is visible without waiting for the next drive.
  @override
  void _showPinHelp() {
    final l = AppLocalizations.of(context);
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.push_pin, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.tripRecordingPinHelpTitle,
                          style: Theme.of(ctx).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(l.tripRecordingPinHelpBody),
                  const SizedBox(height: 8),
                  _AutoPinToggle(
                    onChanged: (value) async {
                      await ref
                          .read(recordingProfileControllerProvider.notifier)
                          .setAutoPin(value);
                      // Reflect the opt-in on THIS live screen at once.
                      if (value && !_pinned) {
                        if (mounted) setState(() => _pinned = true);
                        await _enablePin();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(l.tooltipBack),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      // #2764 — explicit Row over a ListTile title/trailing split: the
      // label gets the flexible space and ellipsizes, the value keeps
      // its intrinsic width (mirrors TripAvgConsumptionCard's fix).
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
