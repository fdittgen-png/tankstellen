import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../driving/coach_event.dart';
import '../../../driving/providers/haptic_eco_coach_provider.dart';
import '../../domain/trip_recorder.dart';
import '../../providers/trip_recording_provider.dart';
import '../../providers/wakelock_facade.dart';
import '../widgets/trip_recording_pin_help_sheet.dart';

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

  /// #891 — ephemeral pin state. Enabling keeps the screen on + hides
  /// system bars so the live recording form stays readable at the
  /// pump / on a dashboard mount. Intentionally NOT persisted: the
  /// user opts back in each drive so battery-drain never lingers.
  bool _pinned = false;

  /// Cached facade handle so [dispose] can release the wake lock
  /// without touching `ref` (Riverpod forbids `ref.read` after the
  /// widget is deactivated). Populated the first time the user pins.
  WakelockFacade? _cachedFacade;

  @override
  void initState() {
    super.initState();
    // #1273 — subscribe to the coach-event stream as soon as the
    // screen mounts. The lifecycle provider gates emissions on the
    // toggle + active trip, so we don't need to branch here. We
    // schedule the listen for the next frame because `ref.listenManual`
    // can only be called after `build` has at least started for some
    // notifier deps; deferring keeps the API contract simple.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.listenManual<AsyncValue<CoachEvent>>(
        coachEventsProvider,
        (prev, next) {
          // We only care about *new* events, not error or loading
          // states — the SnackBar is purely a "the heuristic just
          // fired" surface, not a coach-status indicator.
          final value = next.value;
          if (value == null) return;
          // Suppress SnackBars on the post-stop summary view —
          // the coach heuristic can't fire there in practice (the
          // trip is no longer active so the lifecycle provider tore
          // its bridge down), but a stale tail-event during the
          // recording → finished transition is theoretically
          // possible. Cheap defence-in-depth.
          if (_stopped != null) return;
          _showCoachSnackBar(value);
        },
      );
    });
  }

  void _showCoachSnackBar(CoachEvent event) {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('coachSnackBar'),
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.eco, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l?.coachSnackBarMessage ??
                      'Easy on the throttle — coasting saves more',
                ),
              ),
            ],
          ),
        ),
      );
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
    super.dispose();
  }

  Future<void> _onStop() async {
    if (_stopping) return;
    setState(() => _stopping = true);
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
    setState(() {
      _stopped = result;
      _stopping = false;
      _pinned = false;
    });
  }

  Future<void> _togglePin() async {
    final facade = ref.read(wakelockFacadeProvider);
    // Cache so [dispose] can call `disable()` without reading `ref`
    // after the widget has been deactivated.
    _cachedFacade = facade;
    final nextPinned = !_pinned;
    // Flip UI state first so the icon reflects intent even if the
    // plugin call is slow — the facade swallows its own errors.
    setState(() => _pinned = nextPinned);
    if (nextPinned) {
      await facade.enable();
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await facade.disable();
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
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

  /// Handle the AppBar back tap. Mirrors the previous inline handler
  /// (pop if possible, otherwise route home) and additionally surfaces
  /// the one-time "recording continues in the background — tap the
  /// red banner to return" tip the FIRST time a user backs out while
  /// the trip is still active (#1273). The flag persists in the
  /// settings box so it never re-shows on this install.
  Future<void> _onBackPressed() async {
    final state = ref.read(tripRecordingProvider);
    final isMidTripBackOut = state.isActive && _stopped == null;
    if (isMidTripBackOut) {
      await _maybeShowResumeTip();
    }
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      GoRouter.of(context).go('/');
    }
  }

  /// Show the resume tip iff this is the first mid-trip back-out on
  /// this install. The flag is flipped BEFORE the SnackBar is shown
  /// so an immediate second back-out (e.g. user double-taps) doesn't
  /// double-fire the tip — the persisted bool is the single source
  /// of truth.
  Future<void> _maybeShowResumeTip() async {
    final settings = ref.read(settingsStorageProvider);
    final shown =
        settings.getSetting(StorageKeys.tripRecordingResumeTipShown);
    if (shown == true) return;
    await settings.putSetting(StorageKeys.tripRecordingResumeTipShown, true);
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          key: const Key('tripResumeTipSnackBar'),
          duration: const Duration(seconds: 6),
          content: Text(
            l?.tripRecordingResumeTip ??
                'Recording continues in the background. Tap the red '
                    'banner at the top of any screen to return.',
          ),
        ),
      );
  }

  /// Open the pin-help bottom sheet (#1273). Always-visible affordance
  /// — independent of the eco-coach toggle — because new users have
  /// no other clue what the pin button does.
  Future<void> _onPinHelpPressed() async {
    await TripRecordingPinHelpSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(tripRecordingProvider);
    final stopped = _stopped;

    final title = stopped != null
        ? (l?.tripSummaryTitle ?? 'Trip summary')
        : state.phase == TripRecordingPhase.paused
            ? (l?.tripBannerPaused ?? 'Trip paused')
            : (l?.tripRecordingTitle ?? 'Recording trip');

    // After stop: show the summary. Until then: live view.
    return PageScaffold(
      title: title,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l?.tooltipBack ?? 'Back',
        // Back from the recording screen DOES NOT stop the trip —
        // it stays alive via the provider. The banner is the
        // user's way back in.
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
              // #1273 — small help affordance next to the pin button
              // so first-time users discover what pinning does
              // (wakelock + immersive mode + auto-release on stop).
              // Always visible, independent of the eco-coach toggle.
              IconButton(
                key: const Key('tripPinHelpButton'),
                icon: const Icon(Icons.help_outline),
                tooltip: l?.tripRecordingPinHelpTooltip ??
                    'About the pin button',
                onPressed: _onPinHelpPressed,
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: stopped == null
              ? _buildRecording(context, l, state)
              : _buildSummary(context, l, stopped),
        ),
      ),
    );
  }

  Widget _buildRecording(
    BuildContext context,
    AppLocalizations? l,
    TripRecordingState state,
  ) {
    final r = state.live;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          value: r?.fuelLitersSoFar == null
              ? '—'
              : '${r!.fuelLitersSoFar!.toStringAsFixed(2)} L',
        ),
        const SizedBox(height: 8),
        _MetricCard(
          icon: Icons.eco,
          label: l?.tripMetricAvgConsumption ?? 'Avg',
          value: r?.liveAvgLPer100Km == null
              ? '—'
              : '${r!.liveAvgLPer100Km!.toStringAsFixed(1)} L/100 km',
        ),
        const SizedBox(height: 8),
        _MetricCard(
          icon: Icons.timer,
          label: l?.tripMetricElapsed ?? 'Elapsed',
          value: r == null ? '—' : _fmtElapsed(r.elapsed),
        ),
      ],
    );
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
              : '${s.avgLPer100Km!.toStringAsFixed(1)} L/100 km',
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
