import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../driving/haptic_eco_coach.dart';
import '../../../driving/providers/haptic_eco_coach_provider.dart';
import '../../domain/trip_recorder.dart';
import '../../providers/trip_recording_provider.dart';
import '../../providers/wakelock_facade.dart';
import '../widgets/obd2_breadcrumb_overlay.dart';

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

  @override
  void initState() {
    super.initState();
    // Subscribe to the long-lived coach-events broadcast. The
    // lifecycle provider's stream is filter-empty when the toggle is
    // off — no event will be emitted until the user has opted in,
    // so a `setState`-light listener is fine here.
    final lifecycle = ref.read(hapticEcoCoachLifecycleProvider.notifier);
    _coachEventsSub = lifecycle.coachEvents.listen(_onCoachEvent);
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
    messenger.showSnackBar(
      SnackBar(
        key: const Key('hapticEcoCoachSnackBar'),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.eco, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l?.hapticEcoCoachSnackBarMessage ??
                    'Easy on the throttle — coasting saves more',
              ),
            ),
          ],
        ),
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
            ..showSnackBar(SnackBar(content: Text(msg)));
        }),
      );
    }
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

  /// #1273 — show a bottom sheet explaining what the pin button does.
  /// Always visible (NOT gated by any toggle); first-launch users
  /// need this regardless of opt-ins.
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
        messenger.showSnackBar(
          SnackBar(
            key: const Key('tripRecordingResumeHintSnackBar'),
            duration: const Duration(seconds: 5),
            content: Text(
              l?.tripRecordingResumeHintMessage ??
                  'Recording continues in the background. Tap the red '
                      'banner at the top of any screen to return.',
            ),
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
              child: stopped == null
                  ? _buildRecording(context, l, state)
                  : _buildSummary(context, l, stopped),
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
