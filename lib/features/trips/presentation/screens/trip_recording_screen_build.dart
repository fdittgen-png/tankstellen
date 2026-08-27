// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_screen.dart';

/// #3762 — the `build` method of `_TripRecordingScreenState` plus the
/// PiP bridge state it owns, split out as a `part` mixin under the
/// #1680 file-length decomposition. Move-only: behaviour preserved,
/// every member verbatim from trip_recording_screen.dart.
mixin _TripRecordingBuild on _TripRecordingBodySections {
  /// #1884 — the shared Picture-in-Picture bridge (`pipControllerProvider`,
  /// #1977). This screen drives the native auto-PiP opt-in — scoped to
  /// a foreground recording, cleared on [dispose] — and the minimise
  /// button; the PiP-mode rendering itself lives in `TripRecordingBanner`.
  late final PipController _pip;

  /// Last value pushed to [PipController.setAutoEnterEnabled], so the
  /// build method only crosses the channel when the opt-in changes.
  bool? _autoPipRequested;

  // Owned by the State (abstract — the State's concrete methods
  // satisfy these implicitly): the hidden 5-tap debug gesture and the
  // pin-help sheet stay in trip_recording_screen.dart.
  void _bumpDebugTapCount();
  void _showPinHelp();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(tripRecordingProvider);
    final stopped = _stopped;

    // #2569 — keep the voice-announcement listener mounted while this
    // screen is up. It is keepAlive + self-gating (it subscribes to the
    // live approach stream only while `Feature.voiceAnnouncements` is on),
    // but its internal `ref.listen` fires only while the provider itself
    // has a live watcher — so we `watch` (not `read`) it here.
    ref.watch(voiceAnnouncementListenerProvider);

    // #2663 — keep the driving-coach voice listener mounted while this
    // screen is up. Like the announcement listener it is keepAlive +
    // self-gating (subscribes to the live harsh-event bus and coaching-hint
    // transitions only while the `voiceCoaching` toggle is on), and its
    // internal subscriptions fire only while the provider has a live
    // watcher — so we `watch` (not `read`) it here. This is the missing
    // event→coach→speak wire: before it, every driving cue was silent.
    ref.watch(drivingCoachVoiceListenerProvider);

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
      unawaited(_pip.setAutoEnterEnabled(wantAutoPip));
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
            final prev = previous?[vehicleId]?.pointEstimate ?? 0.0;
            final curr = next[vehicleId]?.pointEstimate ?? 0.0;
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
      debugPrint(
        'TripRecordingScreen broken-MAP listener wiring failed: '
        '$e\n$st',
      );
    }

    final title = stopped != null
        ? (l.tripSummaryTitle)
        // #2548 — the staged save view's title, the stop-side bookend to
        // the #2274 connecting title.
        : state.isSaving
        ? (l.tripRecordingSavingTitle)
        : state.isConnecting
        // #2274 concern 2 — the connecting view is up while the link
        // warms; title it accordingly rather than "Recording".
        ? (l.tripRecordingConnectingTitle)
        : state.phase == TripRecordingPhase.paused
        ? (l.tripBannerPaused)
        : (l.tripRecordingTitle);

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
        child: Semantics(header: true, child: Text(title)),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l.tooltipBack,
        // Back from the recording screen DOES NOT stop the trip —
        // it stays alive via the provider. The banner is the
        // user's way back in. #1273 — first back-out while
        // recording fires a one-time tooltip pointing at the banner.
        onPressed: _onBackPressed,
      ),
      // #2764 — the 5 inline IconButtons truncated the title to "Enr…".
      // Pause + Stop stay primary; Pin / Help / PiP fold into a single
      // overflow kebab (see [RecordingAppBarActions]).
      actions: stopped != null
          ? null
          : [
              RecordingAppBarActions(
                pinned: _pinned,
                pipSupported: _pip.isSupported,
                isActive: state.isActive,
                isPaused: state.phase == TripRecordingPhase.paused,
                stopping: _stopping,
                onTogglePin: _togglePin,
                onShowPinHelp: _showPinHelp,
                onEnterPip: () => _pip.enterPip(),
                onTogglePause: _togglePause,
                onStop: _onStop,
                // #3678 — shared reset run (guarded, honest snackbar).
                onResetConnection: () => runObd2ConnectionReset(context, ref),
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
}

/// #3762 — `initState` / `dispose` of `_TripRecordingScreenState` and
/// the subscriptions they own, split out as a `part` mixin under the
/// #1680 file-length decomposition. Move-only: behaviour preserved,
/// every member verbatim from trip_recording_screen.dart. Applied LAST
/// in the State's `with` chain (constrained `on _TripRecordingBuild`)
/// so `dispose` can drop the `_pip` auto-enter opt-in that mixin owns.
mixin _TripRecordingLifecycle on _TripRecordingBuild {
  /// #1273 — subscription to [HapticEcoCoachLifecycle.coachEvents]. We
  /// open this in [initState] and cancel in [dispose] so the visual
  /// SnackBar surface is bound to THIS screen's lifecycle: navigating
  /// to the summary, history, or any other route silently stops the
  /// SnackBar even if the coach keeps firing in the background.
  StreamSubscription<CoachEvent>? _coachEventsSub;

  /// #1458 phase 2 — deferred-show timer for the unpinned-recording
  /// warning. Cancelled on dispose so the SnackBar never fires after
  /// the screen has been popped (which would inject the warning into
  /// the next route's messenger, polluting unrelated screens).
  Timer? _unpinnedWarningTimer;

  // Owned by the State (abstract — the State's concrete method
  // satisfies this implicitly): the deferred unpinned-recording GPS
  // warning stays in trip_recording_screen.dart.
  void _maybeShowUnpinnedWarning();

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
    // #3834 — the wake lock is released only if we took it, but the system
    // UI is restored UNCONDITIONALLY. #3827 fixed WHAT the restore does and
    // left it behind this `_pinned` gate, so on any path that reaches
    // immersive without the flag surviving to dispose the bars stayed
    // immersive for the rest of the session — the black status bar users
    // kept reporting. restore() is idempotent and costs one platform call,
    // so running it needlessly is free; skipping it is not.
    if (_pinned) {
      final facade = _cachedFacade;
      if (facade != null) {
        unawaited(facade.disable());
      }
    }
    unawaited(EdgeToEdge.restore());
    unawaited(_coachEventsSub?.cancel());
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
}
