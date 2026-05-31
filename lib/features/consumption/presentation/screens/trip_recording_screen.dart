// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../driving/haptic_eco_coach.dart';
import '../../../driving/providers/haptic_eco_coach_provider.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/obd2/broken_map_belief.dart';
import '../../data/pip_controller.dart';
import '../../domain/entities/consumption_stats.dart';
import '../../domain/trip_recorder.dart';
import '../../providers/broken_map_warned_vehicles_provider.dart';
import '../../providers/consumption_providers.dart';
import '../../providers/pip_mode_provider.dart';
import '../../providers/recording_profile_provider.dart';
import '../../providers/trip_recording_provider.dart';
import '../../providers/wakelock_facade.dart';
import '../widgets/broken_map_widgets.dart';
import '../widgets/minimal_drive_summary.dart';
import '../widgets/obd2_breadcrumb_overlay.dart';
import '../widgets/trip_avg_consumption_card.dart';
import '../widgets/trip_radar_card.dart';
import '../widgets/trip_start_progress.dart';
import '../../../../core/logging/error_logger.dart';

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

  const TripSaveResult({
    required this.entryId,
    required this.summary,
  });
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

class _TripRecordingScreenState extends ConsumerState<TripRecordingScreen> {
  StoppedTripResult? _stopped;
  bool _stopping = false;

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

  /// #891 — ephemeral pin state. Enabling keeps the screen on + hides
  /// system bars so the live recording form stays readable at the
  /// pump / on a dashboard mount. Intentionally NOT persisted: the
  /// user opts back in each drive so battery-drain never lingers.
  bool _pinned = false;

  /// #1458 phase 2 — sticky guard so the unpinned-recording GPS
  /// warning SnackBar fires AT MOST once per recording-screen mount.
  /// Pinning + unpinning + leaving + returning intentionally re-fires
  /// because it's a fresh mount each time; what we want to avoid is
  /// spamming on every rebuild that re-enters the post-frame check.
  bool _unpinnedWarningShown = false;

  /// #1458 phase 2 — deferred-show timer for the unpinned-recording
  /// warning. Cancelled on dispose so the SnackBar never fires after
  /// the screen has been popped (which would inject the warning into
  /// the next route's messenger, polluting unrelated screens).
  Timer? _unpinnedWarningTimer;

  /// Cached facade handle so [dispose] can release the wake lock
  /// without touching `ref` (Riverpod forbids `ref.read` after the
  /// widget is deactivated). Populated the first time the user pins.
  WakelockFacade? _cachedFacade;

  /// #1273 — subscription to [HapticEcoCoachLifecycle.coachEvents]. We
  /// open this in [initState] and cancel in [dispose] so the visual
  /// SnackBar surface is bound to THIS screen's lifecycle: navigating
  /// to the summary, history, or any other route silently stops the
  /// SnackBar even if the coach keeps firing in the background.
  StreamSubscription<CoachEvent>? _coachEventsSub;

  /// #1884 — the shared Picture-in-Picture bridge (`pipControllerProvider`,
  /// #1977). This screen drives the native auto-PiP opt-in — scoped to
  /// a foreground recording, cleared on [dispose] — and the minimise
  /// button; the PiP-mode rendering itself lives in `TripRecordingBanner`.
  late final PipController _pip;

  /// Last value pushed to [PipController.setAutoEnterEnabled], so the
  /// build method only crosses the channel when the opt-in changes.
  bool? _autoPipRequested;

  /// #2274 concern 1 — one-shot guard so the persisted auto-pin is
  /// evaluated at most once per screen mount. The screen may mount in
  /// the connecting phase (start-now-connect-later, concern 2) where no
  /// trip is active yet, so the evaluation is retried when the phase
  /// first flips to recording; this flag stops it firing twice.
  bool _autoPinEvaluated = false;

  @override
  void initState() {
    super.initState();
    // #1977 — the single app-wide PiP controller; PiP-mode observation
    // is centralised in `pipModeProvider` / `TripRecordingBanner`.
    _pip = ref.read(pipControllerProvider);
    // #2274 concern 1 — apply the persisted RecordingProfile's auto-pin
    // the moment the screen appears, so a user who opted in once gets the
    // wake lock + immersive bars without re-tapping the push-pin every
    // drive. Default OFF preserves the deliberate opt-in-each-drive
    // design of #891. Done here (not via a synthetic _togglePin tap) so
    // the pin state is correct on the first frame.
    _maybeApplyAutoPin();
    // Subscribe to the long-lived coach-events broadcast. The
    // lifecycle provider's stream is filter-empty when the toggle is
    // off — no event will be emitted until the user has opted in,
    // so a `setState`-light listener is fine here.
    final lifecycle = ref.read(hapticEcoCoachLifecycleProvider.notifier);
    _coachEventsSub = lifecycle.coachEvents.listen(_onCoachEvent);
    // #1458 phase 2 — schedule the unpinned-recording GPS warning
    // shortly after the screen has settled. We defer rather than fire
    // in the immediate post-frame callback for two reasons:
    //   1. Other on-mount SnackBars (broken-MAP belief crossings,
    //      eco-coach live events) win the race and own the messenger
    //      slot during the first frame; queueing ours behind theirs
    //      would let them clobber each other.
    //   2. Production users see the warning ~0.6 s after landing —
    //      late enough that it doesn't compete with other initial
    //      animations, early enough that they read it before the
    //      first GPS sample interval.
    _unpinnedWarningTimer = Timer(const Duration(milliseconds: 600), () {
      _maybeShowUnpinnedWarning();
    });
  }

  @override
  void dispose() {
    // Auto-release the wake lock + restore system UI if the user
    // exits the screen without unpinning. Best-effort; the facade
    // swallows plugin errors on unsupported platforms. Fire-and-
    // forget — `dispose` must stay synchronous.
    if (_pinned) {
      final facade = _cachedFacade;
      if (facade != null) {
        unawaited(facade.disable());
      }
      unawaited(
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        ),
      );
    }
    _coachEventsSub?.cancel();
    _coachEventsSub = null;
    // #1458 phase 2 — cancel any pending unpinned-warning fire so the
    // SnackBar never lands in the next route's messenger after the
    // user has popped this screen.
    _unpinnedWarningTimer?.cancel();
    _unpinnedWarningTimer = null;
    // #1884 — drop the native auto-PiP opt-in so leaving the app from
    // an unrelated screen never shrinks the wrong UI into a tile.
    // Fire-and-forget — `dispose` must stay synchronous. The controller
    // itself is owned by `pipControllerProvider`, not disposed here.
    unawaited(_pip.setAutoEnterEnabled(false));
    super.dispose();
  }

  /// Show the visual eco-coach SnackBar. Lifecycle-gated: this is
  /// only called while the recording screen is mounted because the
  /// stream subscription only exists between initState and dispose.
  /// The provider gates EMISSION on the haptic-eco-coach toggle, so
  /// no event reaches us when the toggle is off — no need to
  /// double-gate here.
  void _onCoachEvent(CoachEvent _) {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    // #2173 — iconated info row through the centralized helper (adds the
    // liveRegion announce; same icon/text/Key/duration as before).
    messenger.showSnackBar(
      SnackBarHelper.iconatedInfoSnackBar(
        Icons.eco,
        l?.hapticEcoCoachSnackBarMessage ??
            'Easy on the throttle — coasting saves more',
        key: const Key('hapticEcoCoachSnackBar'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

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
        l?.tripRecordingUnpinnedWarning ??
            'Pin the screen to keep GPS active during the trip '
                '— Android may throttle GPS during sleep.',
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
              ? (l10n?.obd2DebugOverlayDisabledSnack ??
                  'OBD2 diagnostic overlay disabled')
              : (l10n?.obd2DebugOverlayEnabledSnack ??
                  'OBD2 diagnostic overlay enabled');
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBarHelper.infoSnackBar(msg));
        }),
      );
    }
  }

  Future<void> _onStop() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    // #1458 phase 2 — hide the unpinned-recording warning if it's still
    // visible. The warning is about an in-progress recording; once the
    // user has tapped Stop, the recording is over and the SnackBar
    // would just be sitting on top of the summary view's discard /
    // save buttons until its auto-dismiss timer elapsed.
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    final result = await ref.read(tripRecordingProvider.notifier).stop();
    if (!mounted) return;
    // #891 — when the recording ends, auto-release the wake lock
    // even if the user forgot to unpin. The form will still be
    // visible (summary screen) but there's no longer any reason
    // to keep the device awake at the user's expense.
    if (_pinned) {
      await ref.read(wakelockFacadeProvider).disable();
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      if (!mounted) return;
    }
    // #2509 — surface a "no movement detected" notice when the trip was
    // discarded as genuinely stationary (no distance, no usable signal),
    // so a Stop tap that saves nothing is never silent data loss. NEVER
    // shown when the trip was actually saved (`discardedNoMovement` is
    // false then) — the user lands on the normal summary view instead.
    if (result.discardedNoMovement) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBarHelper.infoSnackBar(
          l?.tripRecordingDiscardedNoMovement ??
              'Recording discarded — no movement detected',
        ));
    }
    setState(() {
      _stopped = result;
      _stopping = false;
      _pinned = false;
    });
  }

  Future<void> _togglePin() async {
    final nextPinned = !_pinned;
    // Flip UI state first so the icon reflects intent even if the
    // plugin call is slow — the facade swallows its own errors.
    setState(() => _pinned = nextPinned);
    if (nextPinned) {
      await _enablePin();
    } else {
      await _disablePin();
    }
  }

  /// Acquire the wake lock + hide system bars. Shared by the manual
  /// push-pin tap ([_togglePin]) and the #2274 auto-pin path
  /// ([_maybeApplyAutoPin]) so both produce an identical pinned state.
  Future<void> _enablePin() async {
    final facade = ref.read(wakelockFacadeProvider);
    // Cache so [dispose] can call `disable()` without reading `ref`
    // after the widget has been deactivated.
    _cachedFacade = facade;
    await facade.enable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _disablePin() async {
    final facade = ref.read(wakelockFacadeProvider);
    _cachedFacade = facade;
    await facade.disable();
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  /// #2274 concern 1 — on a FRESH recording mount, honour the persisted
  /// [RecordingProfile.autoPin] for the active vehicle by pinning the
  /// form straight away (wake lock + immersive bars). No-op when the
  /// effective profile has `autoPin` off — the conservative default —
  /// or when no trip is active (the user reached the screen for the
  /// summary view, not a live drive).
  void _maybeApplyAutoPin() {
    if (_autoPinEvaluated) return;
    try {
      final recordingState = ref.read(tripRecordingProvider);
      // Wait for a live trip — the screen may have mounted in the
      // connecting phase (concern 2) where no trip exists yet. The
      // build-time listener retries this the moment it goes active.
      if (!recordingState.isActive) return;
      _autoPinEvaluated = true;
      final vehicleId =
          ref.read(tripRecordingProvider.notifier).lastTripVehicleId;
      final profile = ref
          .read(recordingProfileControllerProvider.notifier)
          .effectiveFor(vehicleId);
      if (!profile.autoPin) return;
      setState(() => _pinned = true);
      unawaited(_enablePin());
    } catch (e, st) {
      _autoPinEvaluated = true;
      // A missing Riverpod override in a widget test that pumps this
      // screen without the profile graph must not crash the mount — the
      // safe fallback is "not auto-pinned", matching the default.
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': 'TripRecordingScreen: auto-pin apply failed',
      }));
    }
  }

  void _togglePause() {
    final state = ref.read(tripRecordingProvider);
    final notifier = ref.read(tripRecordingProvider.notifier);
    if (state.phase == TripRecordingPhase.paused) {
      notifier.resume();
    } else {
      notifier.pause();
    }
  }

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
    final entryId = r.summary.startedAt?.toIso8601String() ??
        DateTime.now().toIso8601String();
    ref.read(tripRecordingProvider.notifier).reset();
    Navigator.of(context).pop(
      TripSaveResult(
        entryId: entryId,
        summary: r.summary,
      ),
    );
  }

  void _onDiscard() {
    ref.read(tripRecordingProvider.notifier).reset();
    Navigator.of(context).pop(null);
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
  void _showPinHelp() {
    final l = AppLocalizations.of(context);
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
                        l?.tripRecordingPinHelpTitle ?? 'About pin',
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l?.tripRecordingPinHelpBody ??
                      'Pin keeps the screen on and hides system bars '
                          'so the form stays readable on a dashboard '
                          'mount. Tap again to release. Auto-releases '
                          'when the trip stops.',
                ),
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
                    child: Text(l?.tooltipBack ?? 'Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// #1273 — handle the back-press. If the trip is still recording
  /// AND the user has never seen the resume hint, show a SnackBar
  /// with the resume copy, persist the dismissal, then pop. Once the
  /// flag is set (in Hive) future back-outs pop immediately.
  Future<void> _onBackPressed() async {
    final state = ref.read(tripRecordingProvider);
    final settings = ref.read(settingsStorageProvider);
    final shown =
        settings.getSetting(StorageKeys.tripRecordingResumeHintShown) == true;
    if (state.isActive && !shown) {
      final l = AppLocalizations.of(context);
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger != null) {
        messenger.hideCurrentSnackBar();
        // #2173 — plain info through SnackBarHelper (adds liveRegion
        // announce; Key + duration preserved, no visual change).
        messenger.showSnackBar(
          SnackBarHelper.infoSnackBar(
            l?.tripRecordingResumeHintMessage ??
                'Recording continues in the background. Tap the red '
                    'banner at the top of any screen to return.',
            key: const Key('tripRecordingResumeHintSnackBar'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      // Persist the dismissal so the hint never fires twice. Awaited
      // so the test that asserts post-state can read it back without
      // racing the pop.
      await settings.putSetting(
        StorageKeys.tripRecordingResumeHintShown,
        true,
      );
    }
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      GoRouter.of(context).go('/');
    }
  }

  /// #1423 phase 5 — fire the broken-MAP snackbar exactly once per
  /// session per vehicle when its belief crosses into the warning band
  /// (0.7-0.9). The crossing is detected via [ref.listen]: only fires
  /// when the previous belief was BELOW the warning threshold AND the
  /// new belief is at or above it. The hard-disable band (>=0.9) does
  /// NOT re-fire — the persistent banner takes over for that level.
  ///
  /// Uses [BrokenMapWarnedVehicles.markIfFirst] as the per-session
  /// guard so a vehicle that crosses, decays back below 0.7, and
  /// crosses again only warns once.
  void _maybeFireBrokenMapSnackbar(
    String vehicleId,
    BrokenMapBand previousBand,
    BrokenMapBand currentBand,
  ) {
    if (currentBand != BrokenMapBand.warning) return;
    if (previousBand == BrokenMapBand.warning ||
        previousBand == BrokenMapBand.hardDisable) {
      return;
    }
    final warned =
        ref.read(brokenMapWarnedVehiclesProvider.notifier);
    if (!warned.markIfFirst(vehicleId)) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final l = AppLocalizations.of(context);
    // #2173 — plain info through SnackBarHelper (Key + duration kept).
    messenger.showSnackBar(
      SnackBarHelper.infoSnackBar(
        l?.brokenMapSnackbarUnreliable ??
            'MAP sensor reads incorrectly — fuel readings may be '
                '50–80% too low. Try a different adapter.',
        key: const Key('brokenMapWarningSnackBar'),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(tripRecordingProvider);
    final stopped = _stopped;

    // #2274 concern 1 — the screen may have mounted in the connecting
    // phase (concern 2) before any trip was active, so the initState
    // auto-pin evaluation was deferred. Retry it the instant the phase
    // first flips to a live trip. The `_autoPinEvaluated` one-shot guard
    // keeps it from firing twice.
    ref.listen<TripRecordingPhase>(
      tripRecordingProvider.select((s) => s.phase),
      (previous, next) {
        if (!_autoPinEvaluated && next == TripRecordingPhase.recording) {
          _maybeApplyAutoPin();
        }
      },
    );

    // #1884 + #2274 concern 4 — foreground-then-PiP auto-enter (Android).
    // Keep the native auto-PiP opt-in in sync with the recording state:
    // the app shrinks into a PiP tile when the user leaves (onUserLeaveHint
    // on MainActivity) only while a trip is actively recording on this
    // FOREGROUND screen. The opt-in is armed the instant the phase flips
    // to recording — and because concern 2 now pushes this screen
    // IMMEDIATELY (the connect runs underneath while the screen is already
    // foreground+active), the activity is reliably foreground before the
    // user can switch to Maps, so the system's auto-enter fires.
    //
    // Android-only: `PipController.isSupported` is false elsewhere and
    // every call is an inert no-op (iOS PiP is video-only and cannot host
    // app UI). The persisted [RecordingProfile.autoEnterReducedOnStart]
    // is an additive opt-in hint — it never SUPPRESSES the existing
    // always-armed behaviour, so the default is unchanged.
    final wantAutoPip = stopped == null && state.isActive;
    if (wantAutoPip != _autoPipRequested) {
      _autoPipRequested = wantAutoPip;
      _pip.setAutoEnterEnabled(wantAutoPip);
    }

    // #1977 — when the OS shrinks the app into a PiP tile, the compact
    // glanceable view is rendered app-wide by `TripRecordingBanner`
    // (which wraps every screen), so this screen needs no PiP branch of
    // its own — the recording keeps running underneath regardless.

    // #1423 phase 5 — listen for the active vehicle's broken-MAP
    // belief crossing into the 0.7-0.9 warning band. The listener
    // is wired here (not in initState) so it picks up the scaffold
    // messenger for the current build context. `ref.listen` only
    // fires on actual state changes, so the no-op default belief
    // doesn't trigger anything.
    //
    // Both reads are wrapped in a try/catch so widget tests that
    // pump this screen without bootstrapping Hive (a long-standing
    // pattern — see `Obd2BreadcrumbOverlay` for the same defence)
    // don't fail with a `HiveError: Box not found` when the active-
    // vehicle / belief providers walk down to `settingsStorage`.
    try {
      final activeVehicle = ref.watch(activeVehicleProfileProvider);
      if (activeVehicle != null) {
        ref.listen<Map<String, BrokenMapBelief>>(
          brokenMapBeliefByVehicleProvider,
          (previous, next) {
            final vehicleId = activeVehicle.id;
            final prev =
                previous?[vehicleId]?.pointEstimate ?? 0.0;
            final curr =
                next[vehicleId]?.pointEstimate ?? 0.0;
            if (prev == curr) return;
            _maybeFireBrokenMapSnackbar(
              vehicleId,
              brokenMapBandFor(prev),
              brokenMapBandFor(curr),
            );
          },
        );
      }
    } catch (e, st) {
      debugPrint('TripRecordingScreen broken-MAP listener wiring failed: '
          '$e\n$st');
    }

    final title = stopped != null
        ? (l?.tripSummaryTitle ?? 'Trip summary')
        : state.isConnecting
            // #2274 concern 2 — the connecting view is up while the
            // link warms; title it accordingly rather than "Recording".
            ? (l?.tripRecordingConnectingTitle ?? 'Starting recording…')
            : state.phase == TripRecordingPhase.paused
                ? (l?.tripBannerPaused ?? 'Trip paused')
                : (l?.tripRecordingTitle ?? 'Recording trip');

    // After stop: show the summary. Until then: live view.
    // #1395 — wrap the title in a GestureDetector so the hidden
    // 5-tap gesture can flip [obd2DebugOverlayProvider]. `behavior:
    // opaque` ensures the tap is captured even when the title's
    // intrinsic size leaves empty space inside the AppBar's title
    // slot. `excludeFromSemantics: true` keeps the title out of the
    // accessibility tap-target audit (it's a developer-only hidden
    // gesture; the title was always a non-tappable header).
    return PageScaffold(
      titleWidget: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: _bumpDebugTapCount,
        child: Semantics(
          header: true,
          child: Text(title),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l?.tooltipBack ?? 'Back',
        // Back from the recording screen DOES NOT stop the trip —
        // it stays alive via the provider. The banner is the
        // user's way back in. #1273 — first back-out while
        // recording fires a one-time tooltip pointing at the banner.
        onPressed: _onBackPressed,
      ),
      actions: stopped != null
          ? null
          : [
              // #891 — wrap in Semantics so TalkBack announces the
              // *next* action (Pin / Unpin) in addition to the
              // tooltip's battery-cost hint. `container: true`
              // merges the IconButton's tap semantics into the label.
              Semantics(
                container: true,
                button: true,
                toggled: _pinned,
                label: _pinned
                    ? (l?.tripRecordingPinSemanticOn ??
                        'Unpin recording form')
                    : (l?.tripRecordingPinSemanticOff ??
                        'Pin recording form'),
                child: IconButton(
                  key: const Key('tripPinButton'),
                  icon: Icon(
                    _pinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: _pinned
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  tooltip: l?.tripRecordingPinTooltip ??
                      'Pinning keeps the screen on — uses more battery',
                  isSelected: _pinned,
                  onPressed: _togglePin,
                ),
              ),
              // #1273 — `?` icon adjacent to the pin button. Always
              // visible (no toggle gating); first-launch users need
              // a path to "what does this button do" without leaving
              // the recording screen.
              IconButton(
                key: const Key('tripPinHelpButton'),
                icon: const Icon(Icons.help_outline),
                tooltip: l?.tripRecordingPinHelpTooltip ??
                    'What does pin do?',
                onPressed: _showPinHelp,
              ),
              // #1884 — minimise the recording into a floating
              // Picture-in-Picture tile. Android-only; the button is
              // absent where PiP can't host app UI.
              if (_pip.isSupported)
                IconButton(
                  key: const Key('tripMinimiseButton'),
                  icon: const Icon(Icons.picture_in_picture_alt),
                  tooltip: l?.tripRecordingMinimiseTooltip ??
                      'Minimise to a floating tile',
                  onPressed: () => _pip.enterPip(),
                ),
              IconButton(
                key: const Key('tripPauseButton'),
                icon: Icon(state.phase == TripRecordingPhase.paused
                    ? Icons.play_arrow
                    : Icons.pause),
                tooltip: state.phase == TripRecordingPhase.paused
                    ? (l?.tripResume ?? 'Resume')
                    : (l?.tripPause ?? 'Pause'),
                onPressed: state.isActive ? _togglePause : null,
              ),
              IconButton(
                key: const Key('tripStopButton'),
                icon: const Icon(Icons.stop_circle_outlined),
                tooltip: l?.tripStop ?? 'Stop recording',
                onPressed: _stopping || !state.isActive ? null : _onStop,
              ),
            ],
      bodyPadding: EdgeInsets.zero,
      // #1395 — wrap the body in a Stack so the diagnostic overlay
      // can float above the live recording / summary content. The
      // overlay self-hides as a [SizedBox.shrink] when neither
      // `kDebugMode` nor [obd2DebugOverlayProvider] is set, so the
      // wrap is zero-cost in production builds where the flag is off.
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // #1423 phase 5 — persistent banner shown only when
                  // the active vehicle's broken-MAP belief is at or
                  // above 0.9. Self-hides as [SizedBox.shrink] for
                  // every other band so the layout pays nothing in
                  // the common case.
                  const BrokenMapBanner(),
                  Expanded(
                    child: stopped == null
                        ? _buildRecording(context, l, state)
                        : _buildSummary(context, l, stopped),
                  ),
                ],
              ),
            ),
          ),
          const Obd2BreadcrumbOverlay(),
        ],
      ),
    );
  }

  Widget _buildRecording(
    BuildContext context,
    AppLocalizations? l,
    TripRecordingState state,
  ) {
    // #2274 concern 2 — start-now-connect-later: the screen is pushed
    // immediately in the connecting phase while the BLE connect + prime
    // run underneath. Render the inline progress card (the same one the
    // trajets tab used to show) until the first live sample flips the
    // phase to recording. Centred so it reads as a "warming up" state
    // rather than an empty metrics column.
    if (state.isConnecting) {
      return Center(
        child: TripStartProgress(
          key: const Key('tripRecordingConnectingProgress'),
          stage: state.connectStage ?? TripStartStage.connectingAdapter,
        ),
      );
    }

    final r = state.live;

    // #1423 phase 5 — when the active vehicle's broken-MAP belief is
    // at or above 0.9, hard-disable the live L/100 km derived from
    // MAP-fallback fuel-rate and fall back to the receipt-derived
    // average for that vehicle. The chip below the value surfaces in
    // the 0.7-0.9 band as a disclaimer.
    final belief = readActiveVehicleBelief(ref);
    final band = belief == null
        ? BrokenMapBand.silent
        : brokenMapBandFor(belief.pointEstimate);
    // #2391 — the Avg card owns the measured-vs-GPS-estimate decision
    // (`~` prefix + maturity badge for GPS-only) itself; the screen only
    // resolves the broken-MAP hard-disable override (receipt-derived
    // per-vehicle average) and hands it through.
    final brokenMapOverride = band == BrokenMapBand.hardDisable
        ? (_receiptDerivedLPer100Km(ref) ?? '—')
        : null;

    // #2380 — the radar card + five metric cards + coaching card can
    // exceed a short viewport, so the recording column scrolls rather
    // than overflowing on small phones / large text scales.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        // #2380 — closest-station radar leads the column; coaching card
        // moved to the bottom. See [TripRadarCard] for the data sources.
        const TripRadarCard(),
        const SizedBox(height: 8),
        _MetricCard(
          icon: Icons.route,
          label: l?.tripMetricDistance ?? 'Distance',
          value: r == null
              ? '—'
              : '${r.distanceKmSoFar.toStringAsFixed(2)} km',
        ),
        const SizedBox(height: 8),
        _MetricCard(
          icon: Icons.speed,
          label: l?.tripMetricSpeed ?? 'Speed',
          value: r?.speedKmh == null
              ? '—'
              : '${r!.speedKmh!.toStringAsFixed(0)} km/h',
        ),
        const SizedBox(height: 8),
        _MetricCard(
          icon: Icons.local_gas_station,
          label: l?.tripMetricFuelUsed ?? 'Fuel used',
          // #2391 — measured litres, else the GPS estimator's running
          // integral with `~` (GPS-only trips no longer show `—` all
          // drive), else `—`.
          value: r?.fuelLitersSoFar != null
              ? '${r!.fuelLitersSoFar!.toStringAsFixed(2)} L'
              : r?.gpsEstimatedFuelLitersSoFar != null
                  ? '~${r!.gpsEstimatedFuelLitersSoFar!.toStringAsFixed(2)} L'
                  : '—',
        ),
        const SizedBox(height: 8),
        // #2391 — Avg card: measured (OBD2, no `~`) vs GPS-only estimate
        // (`~X.X L/100 km` + calibration-maturity badge + info tooltip).
        TripAvgConsumptionCard(
          live: r,
          brokenMapOverride: brokenMapOverride,
        ),
        const BrokenMapDisclaimerChip(),
        const SizedBox(height: 8),
        _MetricCard(
          icon: Icons.timer,
          label: l?.tripMetricElapsed ?? 'Elapsed',
          value: r == null ? '—' : _fmtElapsed(r.elapsed),
        ),
        const SizedBox(height: 8),
        // #2380 — instant L/100 km + coaching symbols; moved from the
        // top to the bottom so the radar card leads the screen.
        const MinimalDriveSummary(),
      ],
      ),
    );
  }

  /// #1423 phase 5 — receipt-derived L/100 km for the active vehicle,
  /// formatted to one decimal. Returns null when there isn't enough
  /// fill-up history to compute one (single tank or no closed plein-
  /// to-plein window). Used to fill the live-Avg metric while the
  /// broken-MAP belief is in the hard-disable band.
  String? _receiptDerivedLPer100Km(WidgetRef ref) {
    try {
      final active = ref.watch(activeVehicleProfileProvider);
      if (active == null) return null;
      final fills = ref
          .watch(fillUpListProvider)
          .where((f) => f.vehicleId == active.id)
          .toList();
      if (fills.length < 2) return null;
      final stats = ConsumptionStats.fromFillUps(fills);
      final avg = stats.avgConsumptionL100km;
      if (avg == null) return null;
      return UnitFormatter.formatConsumption(avg, isEv: false);
    } catch (e, st) {
      // A malformed fill-up set must not crash the summary card —
      // but log the cause rather than hiding it silently (#1682).
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {'where': 'TripRecordingScreen: consumption summary calc failed'}));
      return null;
    }
  }

  Widget _buildSummary(
    BuildContext context,
    AppLocalizations? l,
    StoppedTripResult r,
  ) {
    final s = r.summary;
    final liters = s.fuelLitersConsumed;
    final endKm = r.endOdometerKm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricCard(
          icon: Icons.route,
          label: l?.tripMetricDistance ?? 'Distance',
          value: '${s.distanceKm.toStringAsFixed(2)} km',
        ),
        const SizedBox(height: 8),
        _MetricCard(
          icon: Icons.local_gas_station,
          label: l?.tripMetricFuelUsed ?? 'Fuel used',
          value: liters == null ? '—' : '${liters.toStringAsFixed(2)} L',
        ),
        const SizedBox(height: 8),
        _MetricCard(
          icon: Icons.eco,
          label: l?.tripMetricAvgConsumption ?? 'Avg',
          value: s.avgLPer100Km == null
              ? '—'
              : UnitFormatter.formatConsumption(s.avgLPer100Km!, isEv: false),
        ),
        const SizedBox(height: 8),
        _MetricCard(
          icon: Icons.speed,
          label: l?.tripMetricOdometer ?? 'Odometer',
          value: endKm == null ? '—' : '${endKm.toStringAsFixed(0)} km',
        ),
        const Spacer(),
        FilledButton.icon(
          key: const Key('tripSaveButton'),
          onPressed: _onSave,
          icon: const Icon(Icons.save),
          label: Text(l?.tripSaveRecording ?? 'Save trip'),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('tripDiscardButton'),
          onPressed: _onDiscard,
          child: Text(l?.tripDiscard ?? 'Discard'),
        ),
      ],
    );
  }

  static String _fmtElapsed(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString()}:${s.toString().padLeft(2, '0')}';
  }
}

/// #2274 concern 1 — the "always pin when recording starts" opt-in in
/// the pin-help bottom sheet. Watches the global [RecordingProfile] so
/// the switch reflects the persisted preference and updates live when
/// flipped. Off by default — preserving the opt-in-each-drive design.
class _AutoPinToggle extends ConsumerWidget {
  const _AutoPinToggle({required this.onChanged});

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final autoPin =
        ref.watch(recordingProfileControllerProvider).autoPin;
    return SwitchListTile(
      key: const Key('tripRecordingAutoPinToggle'),
      contentPadding: EdgeInsets.zero,
      value: autoPin,
      onChanged: onChanged,
      title: Text(
        l?.tripRecordingAutoPinTitle ?? 'Always pin when recording starts',
      ),
      subtitle: Text(
        l?.tripRecordingAutoPinSubtitle ??
            'Pin the form automatically every drive instead of tapping '
                'each time. Uses more battery.',
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
      child: ListTile(
        leading: Icon(icon, size: 28),
        title: Text(label, style: theme.textTheme.bodySmall),
        trailing: Text(
          value,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ),
    );
  }
}
