import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/obd2/obd2_service.dart';
import '../../data/obd2/trip_recording_controller.dart';
import '../../domain/trip_recorder.dart';

/// Result returned when the user saves a recorded trip as a fill-up
/// (#726). Null means the user cancelled or discarded.
class TripSaveResult {
  /// Latest odometer reading, in km. Populates the fill-up form's
  /// odometer field. Null when the car doesn't expose the odometer.
  final double? odometerKm;

  /// Estimated litres consumed during the trip. Populates the
  /// fill-up form's litres field. Null when the car doesn't expose
  /// a fuel-rate PID.
  final double? litersConsumed;

  final TripSummary summary;

  const TripSaveResult({
    required this.odometerKm,
    required this.litersConsumed,
    required this.summary,
  });
}

/// Full-screen trip recorder. Starts polling the already-connected
/// [Obd2Service] in [initState], streams live metrics, and on Stop
/// shows a summary with options to save as a fill-up or discard.
class TripRecordingScreen extends StatefulWidget {
  final Obd2Service service;

  const TripRecordingScreen({super.key, required this.service});

  @override
  State<TripRecordingScreen> createState() => _TripRecordingScreenState();
}

class _TripRecordingScreenState extends State<TripRecordingScreen> {
  late final TripRecordingController _controller;
  StreamSubscription<TripLiveReading>? _sub;
  TripLiveReading? _latest;
  TripSummary? _summary;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    _controller = TripRecordingController(service: widget.service);
    _sub = _controller.live.listen((r) {
      if (!mounted) return;
      setState(() => _latest = r);
    });
    _controller.start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    // If the user backs out without saving, make sure the polling
    // timer stops — the Obd2Service stays alive, owned by the caller.
    if (_controller.isRecording) {
      unawaited(_controller.stop());
    }
    super.dispose();
  }

  Future<void> _onStop() async {
    if (_stopping) return;
    setState(() => _stopping = true);
    await _controller.refreshOdometer();
    final summary = await _controller.stop();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _stopping = false;
    });
  }

  void _onSave() {
    final s = _summary!;
    final oStart = _controller.odometerStartKm;
    final oNow = _controller.odometerLatestKm;
    // End-of-trip km preference order:
    //   1. Latest odometer read from the ECU — ground truth.
    //   2. Start km + recorder-integrated distance — derived fallback
    //      when the car never answered the odometer PID a second
    //      time.
    //   3. Null — neither number is meaningful; the form stays blank.
    final endKm = oNow ??
        (oStart != null ? oStart + s.distanceKm : null);
    Navigator.of(context).pop(
      TripSaveResult(
        odometerKm: endKm,
        litersConsumed: s.fuelLitersConsumed,
        summary: s,
      ),
    );
  }

  void _onDiscard() {
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final summary = _summary;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          summary == null
              ? (l?.tripRecordingTitle ?? 'Recording trip')
              : (l?.tripSummaryTitle ?? 'Trip summary'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: summary == null
              ? _buildRecording(context, l)
              : _buildSummary(context, l, summary),
        ),
      ),
    );
  }

  Widget _buildRecording(BuildContext context, AppLocalizations? l) {
    final r = _latest;
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
          value: r == null ? '—' : _formatElapsed(r.elapsed),
        ),
        const Spacer(),
        FilledButton.icon(
          key: const Key('tripStopButton'),
          onPressed: _stopping ? null : _onStop,
          icon: _stopping
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.stop_circle_outlined),
          label: Text(l?.tripStop ?? 'Stop recording'),
        ),
      ],
    );
  }

  Widget _buildSummary(
    BuildContext context,
    AppLocalizations? l,
    TripSummary s,
  ) {
    final liters = s.fuelLitersConsumed;
    final endKm = _controller.odometerLatestKm ??
        ((_controller.odometerStartKm ?? 0) + s.distanceKm);
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
          value: '${endKm.toStringAsFixed(0)} km',
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

  static String _formatElapsed(Duration d) {
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
