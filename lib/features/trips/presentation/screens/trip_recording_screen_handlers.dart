// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_screen.dart';

/// #3762 — recording event handlers of `_TripRecordingScreenState`
/// (stop / pause / delete / back-press / coach + broken-MAP SnackBars),
/// split out as a `part` mixin under the #1680 file-length
/// decomposition. Move-only: behaviour preserved, every member verbatim
/// from trip_recording_screen.dart. Constrained `on
/// _TripRecordingPinControls` so `_onStop` can release the pin state it
/// shares with the manual push-pin actions.
mixin _TripRecordingEventHandlers on _TripRecordingPinControls {
  StoppedTripResult? _stopped;
  bool _stopping = false;

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
        l.hapticEcoCoachSnackBarMessage,
        key: const Key('hapticEcoCoachSnackBar'),
        duration: const Duration(seconds: 4),
      ),
    );
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
      await EdgeToEdge.restore();
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
        ..showSnackBar(
          SnackBarHelper.infoSnackBar(l.tripRecordingDiscardedNoMovement),
        );
    }
    setState(() {
      _stopped = result;
      _stopping = false;
      _pinned = false;
    });
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

  /// #3582 — the trip was auto-saved at stop, so "delete" must actually
  /// remove the persisted entry, not just reset the UI (the old
  /// "Discard" silently kept the trip in history).
  void _onDeleteSavedTrip() {
    final r = _stopped;
    if (r != null) {
      final entryId = r.summary.startedAt?.toIso8601String();
      final repo = ref.read(tripHistoryRepositoryProvider);
      if (entryId != null && repo != null) {
        unawaited(repo.delete(entryId));
      }
    }
    ref.read(tripRecordingProvider.notifier).reset();
    Navigator.of(context).pop(null);
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
            l.tripRecordingResumeHintMessage,
            key: const Key('tripRecordingResumeHintSnackBar'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
      // Persist the dismissal so the hint never fires twice. Awaited
      // so the test that asserts post-state can read it back without
      // racing the pop.
      await settings.putSetting(StorageKeys.tripRecordingResumeHintShown, true);
    }
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      GoRouter.of(context).go(RoutePaths.search);
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
    final warned = ref.read(brokenMapWarnedVehiclesProvider.notifier);
    if (!warned.markIfFirst(vehicleId)) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final l = AppLocalizations.of(context);
    // #2173 — plain info through SnackBarHelper (Key + duration kept).
    messenger.showSnackBar(
      SnackBarHelper.infoSnackBar(
        l.brokenMapSnackbarUnreliable,
        key: const Key('brokenMapWarningSnackBar'),
        duration: const Duration(seconds: 8),
      ),
    );
  }
}
