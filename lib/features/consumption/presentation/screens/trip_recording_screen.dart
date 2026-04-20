import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/trip_recorder.dart';
import '../../providers/trip_recording_provider.dart';

/// Result returned when the user saves a recorded trip as a fill-up
/// (#726). Null means the user cancelled or discarded.
class TripSaveResult {
  final double? odometerKm;
  final double? litersConsumed;
  final TripSummary summary;

  const TripSaveResult({
    required this.odometerKm,
    required this.litersConsumed,
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

  Future<void> _onStop() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    final result = await ref.read(tripRecordingProvider.notifier).stop();
    if (!mounted) return;
    setState(() {
      _stopped = result;
      _stopping = false;
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

  void _onSave() {
    final r = _stopped!;
    ref.read(tripRecordingProvider.notifier).reset();
    Navigator.of(context).pop(
      TripSaveResult(
        odometerKm: r.endOdometerKm,
        litersConsumed: r.summary.fuelLitersConsumed,
        summary: r.summary,
      ),
    );
  }

  void _onDiscard() {
    ref.read(tripRecordingProvider.notifier).reset();
    Navigator.of(context).pop(null);
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l?.tooltipBack ?? 'Back',
          // Back from the recording screen DOES NOT stop the trip —
          // it stays alive via the provider. The banner is the
          // user's way back in.
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              GoRouter.of(context).go('/');
            }
          },
        ),
        title: Text(title),
        actions: stopped != null
            ? null
            : [
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
                  onPressed:
                      _stopping || !state.isActive ? null : _onStop,
                ),
              ],
      ),
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
          label: Text(l?.tripSaveAsFillUp ?? 'Save as fill-up'),
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
