import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
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
///
/// When [pinnedMac] is non-null (#1188), the picker first tries a
/// silent direct connect via [Obd2ConnectionService.connectByMac].
/// On success the future resolves with the connected service and the
/// modal sheet is never shown — eliminating the 2-tap friction for
/// returning users with a paired adapter. On failure (adapter off,
/// out of range, init error) the sheet is shown with a snackbar built
/// from [pinnedAdapterName] so the user understands why the picker
/// reappeared.
Future<Obd2Service?> showObd2AdapterPicker(
  BuildContext context, {
  String? pinnedMac,
  String? pinnedAdapterName,
}) async {
  // Pinned-MAC fast path (#1188). When the active vehicle has an
  // adapter paired we want zero UI — connect silently and resolve
  // immediately, falling back to the sheet on any failure.
  if (pinnedMac != null && pinnedMac.isNotEmpty) {
    final container = ProviderScope.containerOf(context, listen: false);
    Obd2Service? service;
    try {
      service = await container.read(obd2ConnectionProvider).connectByMac(
            pinnedMac,
          );
    } on Obd2ConnectionError catch (e, st) {
      // Real connect failure (permission denied, init timeout). Drop
      // through to the sheet so the user can pick another adapter;
      // the snackbar surfaces the mishap.
      debugPrint('showObd2AdapterPicker pinned connect failed: $e\n$st');
    }
    if (service != null) {
      return service;
    }
    // Fall-through: open the sheet with a fallback snackbar. Schedule
    // the snackbar after the first frame so it lands on the surrounding
    // Scaffold and not on the modal route.
    if (!context.mounted) return null;
    return _showPickerSheet(
      context,
      fallbackAdapterName: pinnedAdapterName,
    );
  }
  return _showPickerSheet(context);
}

Future<Obd2Service?> _showPickerSheet(
  BuildContext context, {
  String? fallbackAdapterName,
}) {
  if (fallbackAdapterName != null && fallbackAdapterName.isNotEmpty) {
    // Surface the snackbar against the surrounding Scaffold (not the
    // modal route). Schedules after the current frame so the modal
    // is mounted by the time the snackbar slides in.
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = AppLocalizations.of(context);
    if (messenger != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              l?.obd2PickerPinnedFallback(fallbackAdapterName) ??
                  "Couldn't reach '$fallbackAdapterName' — pick another adapter",
            ),
          ),
        );
      });
    }
  }
  return showModalBottomSheet<Obd2Service>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const Obd2AdapterPickerSheet(),
  );
}

/// Pair-only variant of [showObd2AdapterPicker] (#779). Opens the
/// same scan sheet but pops with the user-picked
/// [ResolvedObd2Candidate] instead of connecting. Used by the vehicle
/// edit screen to persist the adapter's name+MAC on a vehicle without
/// initiating a full trip-recording session.
Future<ResolvedObd2Candidate?> showObd2AdapterPairer(BuildContext context) {
  return showModalBottomSheet<ResolvedObd2Candidate>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const Obd2AdapterPickerSheet(pairOnly: true),
  );
}

class Obd2AdapterPickerSheet extends ConsumerStatefulWidget {
  /// When true, tapping a candidate pops the sheet with the
  /// [ResolvedObd2Candidate] instead of opening a connection. Used
  /// by the vehicle-pairing flow (#779) where the user saves the
  /// adapter on the vehicle profile without starting a trip.
  final bool pairOnly;

  const Obd2AdapterPickerSheet({super.key, this.pairOnly = false});

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
    // #779 — pair-only flow: pop the candidate instead of opening a
    // connection. The caller persists it and closes.
    if (widget.pairOnly) {
      Navigator.of(context).pop(candidate);
      return;
    }
    setState(() => _phase = _Phase.connecting);
    try {
      final service = await ref
          .read(obd2ConnectionProvider)
          .connect(candidate);
      // #1188 — persist MAC + display name back onto the active
      // vehicle profile so the next session takes the pinned-MAC fast
      // path and skips the picker entirely. Best-effort: a missing
      // active vehicle, or a failed save, must not block the connect
      // path the user just completed.
      await _persistPickedAdapterToActiveVehicle(candidate);
      if (!mounted) return;
      Navigator.of(context).pop(service);
    } on Obd2ConnectionError catch (e, st) { // ignore: unused_catch_stack
      if (!mounted) return;
      setState(() {
        _error = e;
        _phase = _Phase.error;
      });
    }
  }

  /// Write the user's picked adapter MAC + display name onto the
  /// active vehicle profile when missing or different (#1188). Runs
  /// only when an active profile exists; no-op otherwise. Errors are
  /// swallowed (debug-printed) — the connect path the user is
  /// completing is the priority.
  Future<void> _persistPickedAdapterToActiveVehicle(
    ResolvedObd2Candidate candidate,
  ) async {
    try {
      final active = ref.read(activeVehicleProfileProvider);
      if (active == null) return;
      final mac = candidate.candidate.deviceId;
      final name = candidate.candidate.deviceName.isEmpty
          ? candidate.profile.displayName
          : candidate.candidate.deviceName;
      if (active.obd2AdapterMac == mac && active.obd2AdapterName == name) {
        return; // already persisted — skip the redundant write.
      }
      final updated = active.copyWith(
        obd2AdapterMac: mac,
        obd2AdapterName: name,
      );
      await ref.read(vehicleProfileListProvider.notifier).save(updated);
    } catch (e, st) {
      debugPrint(
        'Obd2AdapterPickerSheet._persistPickedAdapterToActiveVehicle: $e\n$st',
      );
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
