import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/obd2/adapter_registry.dart';
import '../../data/obd2/obd2_connection_errors.dart';
import '../../data/obd2/obd2_connection_service.dart';
import '../../data/obd2/obd2_service.dart';

/// Modal bottom sheet that drives the full scan → pick → connect flow
/// (#743). Caller opens it with [showObd2AdapterPicker]; the future
/// resolves with a ready [Obd2Service] when the user connects to one
/// of the listed adapters, or `null` on cancel.
///
/// The sheet owns a simple state machine: scanning → selecting →
/// connecting → done/error. Every transition is driven by the
/// injected [Obd2ConnectionService], so widget tests swap it via a
/// Riverpod override of `obd2ConnectionProvider` and drive the full
/// flow without a BLE stack.
Future<Obd2Service?> showObd2AdapterPicker(BuildContext context) {
  return showModalBottomSheet<Obd2Service>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const Obd2AdapterPickerSheet(),
  );
}

class Obd2AdapterPickerSheet extends ConsumerStatefulWidget {
  const Obd2AdapterPickerSheet({super.key});

  @override
  ConsumerState<Obd2AdapterPickerSheet> createState() =>
      _Obd2AdapterPickerSheetState();
}

enum _Phase { scanning, selecting, connecting, error }

class _Obd2AdapterPickerSheetState
    extends ConsumerState<Obd2AdapterPickerSheet> {
  _Phase _phase = _Phase.scanning;
  StreamSubscription<List<ResolvedObd2Candidate>>? _sub;
  List<ResolvedObd2Candidate> _candidates = const [];
  Obd2ConnectionError? _error;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _phase = _Phase.scanning;
      _candidates = const [];
      _error = null;
    });
    final connection = ref.read(obd2ConnectionProvider);
    _sub?.cancel();
    _sub = connection.scan().listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _candidates = list;
          if (list.isNotEmpty) _phase = _Phase.selecting;
        });
      },
      onError: (e, _) {
        if (!mounted || e is! Obd2ConnectionError) return;
        setState(() {
          _error = e;
          _phase = _Phase.error;
        });
      },
    );
  }

  Future<void> _connect(ResolvedObd2Candidate candidate) async {
    setState(() => _phase = _Phase.connecting);
    try {
      final service = await ref
          .read(obd2ConnectionProvider)
          .connect(candidate);
      if (!mounted) return;
      Navigator.of(context).pop(service);
    } on Obd2ConnectionError catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _phase = _Phase.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l?.obdPickerTitle ?? 'Pick an OBD2 adapter',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildBody(l),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations? l) {
    switch (_phase) {
      case _Phase.scanning:
        return Column(
          key: const Key('obdPickerScanning'),
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l?.obdPickerScanning ?? 'Scanning for adapters…'),
          ],
        );
      case _Phase.selecting:
        return Column(
          key: const Key('obdPickerSelecting'),
          children: [
            for (final c in _candidates)
              ListTile(
                key: Key('obdPickerItem_${c.candidate.deviceId}'),
                leading: const Icon(Icons.bluetooth),
                title: Text(c.candidate.deviceName.isEmpty
                    ? c.profile.displayName
                    : c.candidate.deviceName),
                subtitle: Text(
                  '${c.profile.displayName} · ${c.candidate.rssi} dBm',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _connect(c),
              ),
          ],
        );
      case _Phase.connecting:
        return Column(
          key: const Key('obdPickerConnecting'),
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l?.obdPickerConnecting ?? 'Connecting…'),
          ],
        );
      case _Phase.error:
        return Column(
          key: const Key('obdPickerError'),
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error, size: 48),
            const SizedBox(height: 8),
            Text(
              _error?.message ?? 'Unknown error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('obdPickerRetry'),
              onPressed: _startScan,
              icon: const Icon(Icons.refresh),
              label: Text(l?.retry ?? 'Retry'),
            ),
          ],
        );
    }
  }
}
