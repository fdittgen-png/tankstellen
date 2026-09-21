// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

part of 'trip_recording_screen.dart';

/// #3762 — recording event handlers of `_TripRecordingScreenState`
/// (stop / pause / delete / back-press / coach + broken-MAP SnackBars),
/// split out as a `part` mixin under the #1680 file-length
/// decomposition. Move-only: behaviour preserved, every member verbatim
/// from trip_recording_screen.dart.
///
/// #4037 — the pin state it used to inherit is now the State's owned
/// [TripRecordingPinController]; `_onStop` asks that collaborator to
/// release the lock instead of writing a field it shares with the
/// push-pin actions.
mixin _TripRecordingEventHandlers on ConsumerState<TripRecordingScreen> {
  bool _stopping = false;

  /// Owned by the State (abstract — the State's field satisfies it
  /// implicitly): the pin / wake-lock collaborator.
  TripRecordingPinController get _pin;

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

  /// #3963 — Stop SAVES and LEAVES. `stop()` already persisted the trip
  /// (#1185/#3582), so the summary screen that followed had one job: to be
  /// dismissed, by a driver. The screen pops instead and the trip is in the
  /// Trajets list; the delete that summary offered rides the confirmation
  /// snackbar, so a mis-stop is still one tap from gone.
  Future<void> _onStop() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    // #1458 phase 2 — hide the unpinned-recording warning if it is still
    // up: it is about an in-progress recording, and this one is over.
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
    final result = await ref.read(tripRecordingProvider.notifier).stop();
    if (!mounted) return;
    // #891 — auto-release the wake lock even if the user forgot to unpin.
    if (_pin.isPinned) {
      await _pin.disable();
      if (!mounted) return;
    }

    // Captured BEFORE the pop: the messenger and every string/handle the
    // snackbar needs must outlive this screen's context (SnackBarHelper
    // contract — the screen is about to be gone).
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final notifier = ref.read(tripRecordingProvider.notifier);
    final repo = ref.read(tripHistoryRepositoryProvider);
    final historyList = ref.read(tripHistoryListProvider.notifier);
    final retrySave = ref.read(pendingTripSaveRetryProvider); // #4378
    final entryId = result.entryId; // #4328 — null when nothing was saved

    setState(() {
      _stopping = false;
      _pin.clearPinned();
    });
    notifier.reset();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(
        entryId == null
            ? null
            : TripSaveResult(entryId: entryId, summary: result.summary),
      );
    }

    messenger?.hideCurrentSnackBar();
    // #2509 / #3582 / #4378 — what the stop tells the user about this
    // trip's persistence, in one place ([tripStopSnackBar]).
    messenger?.showSnackBar(tripStopSnackBar(
      l,
      result: result,
      repo: repo,
      onRetry: retrySave,
      onRetried: historyList.refresh,
    ));
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
