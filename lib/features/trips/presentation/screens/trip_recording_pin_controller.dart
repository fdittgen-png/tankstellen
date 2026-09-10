// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/guarded.dart';
import '../../../../core/utils/edge_to_edge.dart';
import '../../providers/recording_profile_provider.dart';
import '../../providers/trip_recording_provider.dart';
import '../../providers/wakelock_facade.dart';

/// The recording screen's pin (wake-lock) state, as a collaborator the
/// screen OWNS rather than a mixin sharing its private scope (#4037,
/// epic #4032).
///
/// #891 — pinning is ephemeral: enabling keeps the screen on so the live
/// recording form stays readable at the pump / on a dashboard mount, and
/// it is intentionally NOT persisted, so the user opts back in each drive
/// and battery drain never lingers. #2274 concern 1 adds the persisted
/// per-vehicle `autoPin` opt-in, applied at most once per mount.
///
/// The three pieces of state that used to be spread across the screen's
/// `part` mixins — the pin flag, the cached facade `dispose` releases
/// through, and the one-shot auto-pin guard — are private fields of this
/// class now, so nothing else can invalidate them. The screen reads
/// [isPinned] and calls [onChanged] to rebuild.
class TripRecordingPinController {
  TripRecordingPinController({required this.ref, required this.onChanged});

  /// The screen's own ref. Never read after the screen is deactivated —
  /// [releaseOnDispose] deliberately goes through [_cachedFacade].
  final WidgetRef ref;

  /// Called after any change to [isPinned] so the screen can `setState`.
  final VoidCallback onChanged;

  bool _pinned = false;

  /// Cached facade handle so [releaseOnDispose] can drop the wake lock
  /// without touching `ref` (Riverpod forbids `ref.read` after the widget
  /// is deactivated). Populated the first time the user pins.
  WakelockFacade? _cachedFacade;

  /// #2274 concern 1 — one-shot guard so the persisted auto-pin is
  /// evaluated at most once per screen mount. The screen may mount in
  /// the connecting phase (start-now-connect-later, concern 2) where no
  /// trip is active yet, so the evaluation is retried when the phase
  /// first flips to recording; this flag stops it firing twice.
  bool _autoPinEvaluated = false;

  /// Whether the screen currently holds the wake lock.
  bool get isPinned => _pinned;

  /// Whether the persisted auto-pin has already been evaluated for this
  /// mount — the screen's build-time retry listener checks it before
  /// calling [maybeApplyAutoPin] again.
  bool get autoPinEvaluated => _autoPinEvaluated;

  Future<void> toggle() async {
    final nextPinned = !_pinned;
    // Flip UI state first so the icon reflects intent even if the
    // plugin call is slow — the facade swallows its own errors.
    _pinned = nextPinned;
    onChanged();
    if (nextPinned) {
      await enable();
    } else {
      await disable();
    }
  }

  /// Acquire the wake lock. Shared by the manual push-pin tap ([toggle])
  /// and the #2274 auto-pin path ([maybeApplyAutoPin]) so both produce an
  /// identical pinned state.
  Future<void> enable() async {
    final facade = ref.read(wakelockFacadeProvider);
    // Cache so [releaseOnDispose] can call `disable()` without reading
    // `ref` after the widget has been deactivated.
    _cachedFacade = facade;
    await facade.enable();
    // #3843 — the pin no longer hides the system bars. immersiveSticky is
    // designed to RE-hide them, so it actively fights being exited, and four
    // fixes trying to reverse it reliably all failed in the field. The wake
    // lock is the feature; hiding the clock on a live-driving screen was
    // polish. With nothing entering immersive there is nothing to restore.
  }

  Future<void> disable() async {
    final facade = ref.read(wakelockFacadeProvider);
    _cachedFacade = facade;
    await facade.disable();
    await EdgeToEdge.restore();
  }

  /// Pin now: flip the flag, tell the screen, and take the wake lock.
  /// Used by the pin-help sheet's auto-pin opt-in, which must reflect on
  /// THIS live screen the moment it is switched on.
  Future<void> pin() async {
    if (_pinned) return;
    _pinned = true;
    onChanged();
    await enable();
  }

  /// Drop the pinned flag WITHOUT touching the platform — the caller has
  /// already released the wake lock (the stop path releases it before it
  /// rebuilds, so the icon and the lock can never disagree).
  void clearPinned() => _pinned = false;

  /// #2274 concern 1 — on a FRESH recording mount, honour the persisted
  /// [RecordingProfile.autoPin] for the active vehicle by pinning the
  /// form straight away. No-op when the effective profile has `autoPin`
  /// off — the conservative default — or when no trip is active (the user
  /// reached the screen for the summary view, not a live drive).
  void maybeApplyAutoPin() {
    if (_autoPinEvaluated) return;
    try {
      final recordingState = ref.read(tripRecordingProvider);
      // Wait for a live trip — the screen may have mounted in the
      // connecting phase (concern 2) where no trip exists yet. The
      // build-time listener retries this the moment it goes active.
      if (!recordingState.isActive) return;
      _autoPinEvaluated = true;
      final vehicleId = ref
          .read(tripRecordingProvider.notifier)
          .lastTripVehicleId;
      final profile = ref
          .read(recordingProfileControllerProvider.notifier)
          .effectiveFor(vehicleId);
      if (!profile.autoPin) return;
      _pinned = true;
      onChanged();
      unawaited(enable());
    } catch (e, st) {
      _autoPinEvaluated = true;
      // A missing Riverpod override in a widget test that pumps this
      // screen without the profile graph must not crash the mount — the
      // safe fallback is "not auto-pinned", matching the default.
      logFailure(e, st, where: 'TripRecordingScreen: auto-pin apply failed');
    }
  }

  /// Auto-release the wake lock + restore system UI if the user exits the
  /// screen without unpinning. Best-effort and synchronous, because
  /// `State.dispose` is: the facade swallows plugin errors on unsupported
  /// platforms.
  ///
  /// #3834 — the wake lock is released only if we took it, but the system
  /// UI is restored UNCONDITIONALLY. #3827 fixed WHAT the restore does and
  /// left it behind the pinned gate, so on any path that reached immersive
  /// without the flag surviving to dispose the bars stayed immersive for
  /// the rest of the session — the black status bar users kept reporting.
  /// `restore()` is idempotent and costs one platform call, so running it
  /// needlessly is free; skipping it is not.
  void releaseOnDispose() {
    if (_pinned) {
      final facade = _cachedFacade;
      if (facade != null) {
        unawaited(facade.disable());
      }
    }
    unawaited(EdgeToEdge.restore());
  }
}
