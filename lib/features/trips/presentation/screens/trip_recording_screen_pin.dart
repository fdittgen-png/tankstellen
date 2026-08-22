// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'trip_recording_screen.dart';

/// #3762 — pin / wake-lock / auto-pin state and actions of
/// `_TripRecordingScreenState`, split out as a `part` mixin under the
/// #1680 file-length decomposition. Move-only: behaviour preserved,
/// every member verbatim from trip_recording_screen.dart. The mixin
/// owns the pin state (`_pinned`, `_cachedFacade`, `_autoPinEvaluated`);
/// the State and later mixins read it as inherited members.
mixin _TripRecordingPinControls on ConsumerState<TripRecordingScreen> {
  /// #891 — ephemeral pin state. Enabling keeps the screen on + hides
  /// system bars so the live recording form stays readable at the
  /// pump / on a dashboard mount. Intentionally NOT persisted: the
  /// user opts back in each drive so battery-drain never lingers.
  bool _pinned = false;

  /// Cached facade handle so [dispose] can release the wake lock
  /// without touching `ref` (Riverpod forbids `ref.read` after the
  /// widget is deactivated). Populated the first time the user pins.
  WakelockFacade? _cachedFacade;

  /// #2274 concern 1 — one-shot guard so the persisted auto-pin is
  /// evaluated at most once per screen mount. The screen may mount in
  /// the connecting phase (start-now-connect-later, concern 2) where no
  /// trip is active yet, so the evaluation is retried when the phase
  /// first flips to recording; this flag stops it firing twice.
  bool _autoPinEvaluated = false;

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
      final vehicleId = ref
          .read(tripRecordingProvider.notifier)
          .lastTripVehicleId;
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
      logFailure(e, st, where: 'TripRecordingScreen: auto-pin apply failed');
    }
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
    final autoPin = ref.watch(recordingProfileControllerProvider).autoPin;
    return SwitchListTile(
      key: const Key('tripRecordingAutoPinToggle'),
      contentPadding: EdgeInsets.zero,
      value: autoPin,
      onChanged: onChanged,
      title: Text(l.tripRecordingAutoPinTitle),
      subtitle: Text(l.tripRecordingAutoPinSubtitle),
    );
  }
}
