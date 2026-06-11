// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/obd2/adapter_registry.dart';
import '../../data/obd2/obd2_adapter_identity.dart';
import '../../data/obd2/obd2_connection_errors.dart';
import '../../data/obd2/obd2_connection_service.dart';
import '../../data/obd2/obd2_pairing_mode.dart';
import '../../data/obd2/obd2_service.dart';
import '../obd2_connection_error_l10n.dart';
import '../obd2_connect_telemetry.dart';
import '../../../../core/logging/error_logger.dart';

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
    Obd2PairingRequired? pairingError;
    try {
      // #3025 — TRANSPORT-AWARE pinned connect. The old call hard-wired the
      // scan-based `connectByMac`, but coming off the (now transport-aware,
      // #3025) pre-warm — or as the sole entry — the transport-aware direct
      // path routes a Classic adapter (vLinker BM-Android) straight to RFCOMM
      // and NEVER opens the BLE GATT that 4 s-times-out + poisons the socket. It
      // still falls back to the merged BLE+Classic scan via `connectByMac`
      // internally for a direct miss, so the existing behaviour is preserved.
      service = await container.read(obd2ConnectionProvider).connectByMacTransportAware(
            pinnedMac,
            adapterName: pinnedAdapterName,
          );
    } on Obd2ConnectionError catch (e, st) {
      // Drop through to the sheet so the user can pick another adapter; the
      // fall-through snackbar surfaces it. #2745 — an expected, user-surfaced
      // condition is a breadcrumb, a genuine fault still ERROR-logs.
      // #3181 — a pairing failure carries ACTIONABLE guidance (power-cycle
      // the adapter, retry within 5 minutes), so it overrides the generic
      // "couldn't reach X" fall-through snackbar below.
      if (e is Obd2PairingRequired) pairingError = e;
      recordObd2ConnectFailure(e, st, where: 'pinned connect failed');
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
      pairingError: pairingError,
    );
  }
  return _showPickerSheet(context);
}

Future<Obd2Service?> _showPickerSheet(
  BuildContext context, {
  String? fallbackAdapterName,
  Obd2PairingRequired? pairingError,
}) {
  final hasFallbackName =
      fallbackAdapterName != null && fallbackAdapterName.isNotEmpty;
  if (pairingError != null || hasFallbackName) {
    // Surface the snackbar against the surrounding Scaffold (not the
    // modal route). Schedules after the current frame so the modal
    // is mounted by the time the snackbar slides in.
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = AppLocalizations.of(context);
    // #3181 — the pairing guidance wins over the generic fall-through.
    final text = pairingError != null
        ? pairingError.localizedMessage(l)
        : l?.obd2PickerPinnedFallback(fallbackAdapterName!) ??
            "Couldn't reach '$fallbackAdapterName' — pick another adapter";
    if (messenger != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        messenger.showSnackBar(SnackBarHelper.infoSnackBar(text));
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

/// Bundle of the live OBD2 service plus the MAC of the adapter the
/// user picked in the sheet (#1310). Surfaces the MAC at the same
/// boundary the existing [showObd2AdapterPicker] returns so the OBD2
/// onboarding step can persist [VehicleProfile.obd2AdapterMac] on a
/// freshly-saved profile — without this the orchestrator silently
/// dropped users who finished onboarding (auto-record gate requires
/// `obd2AdapterMac` to be non-empty).
class PickedObd2Connection {
  /// Live OBD2 connection ready for VIN + PID reads.
  final Obd2Service service;

  /// Stable BLE/Classic identifier for the picked adapter.
  final String mac;

  /// Friendly label for the adapter (advertised name, falling back
  /// to the registry's display name).
  final String name;

  const PickedObd2Connection({
    required this.service,
    required this.mac,
    required this.name,
  });
}

/// Connect-and-pick variant of [showObd2AdapterPicker] used by the
/// OBD2 onboarding step (#1310). Returns both the live service AND
/// the picked adapter's MAC so the caller can persist it onto the
/// vehicle profile they're about to save. Pops with `null` on cancel
/// or failure, matching [showObd2AdapterPicker]'s contract.
Future<PickedObd2Connection?> showObd2AdapterPickerWithMac(
  BuildContext context,
) {
  return showModalBottomSheet<PickedObd2Connection>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const Obd2AdapterPickerSheet(returnPickedConnection: true),
  );
}

class Obd2AdapterPickerSheet extends ConsumerStatefulWidget {
  /// When true, tapping a candidate pops the sheet with the
  /// [ResolvedObd2Candidate] instead of opening a connection. Used
  /// by the vehicle-pairing flow (#779) where the user saves the
  /// adapter on the vehicle profile without starting a trip.
  final bool pairOnly;

  /// When true, after a successful connect the sheet pops with a
  /// [PickedObd2Connection] (service + MAC + name) instead of just
  /// the [Obd2Service] (#1310). Used by the OBD2 onboarding step so
  /// it can write `obd2AdapterMac` onto the freshly-saved profile.
  /// Mutually exclusive with [pairOnly] in practice — onboarding
  /// always wants to also connect.
  final bool returnPickedConnection;

  const Obd2AdapterPickerSheet({
    super.key,
    this.pairOnly = false,
    this.returnPickedConnection = false,
  });

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

  /// #3103 — false on iOS (no Classic facade wired): the picker then explains
  /// that iPhone can only use Bluetooth-LE adapters, instead of silently
  /// showing nothing when the user has a Classic-only adapter.
  bool _supportsClassicDiscovery = true;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _phase = _Phase.scanning;
      _candidates = const [];
      _error = null;
    });
    final connection = ref.read(obd2ConnectionProvider);
    _supportsClassicDiscovery = connection.supportsClassicDiscovery;
    unawaited(_sub?.cancel());
    _sub = connection.scan().listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _candidates = list;
          if (list.isNotEmpty) _phase = _Phase.selecting;
        });
      },
      onError: (Object e, _) {
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
    // errorlog_30 — capture the post-connect persist's provider reads BEFORE
    // the first `await`. `connect()` is async and the sheet can be dismissed/
    // unmounted while it runs; reading `ref` AFTER unmount throws `Bad state:
    // Using "ref" when a widget is about to or has been unmounted is unsafe`.
    // Both providers are `keepAlive: true`, so the captures stay valid and the
    // best-effort persist still completes on the unmounted path (the connect
    // succeeded — the pinned MAC must be written either way).
    final activeProfile = ref.read(activeVehicleProfileProvider);
    final vehicleListNotifier = ref.read(vehicleProfileListProvider.notifier);
    final connection = ref.read(obd2ConnectionProvider);
    // #3184(f) — end the scan stream before the connect begins. NOT
    // awaited: a cancel future can take extra event-loop turns (and never
    // completes under widget-test fake-async) and must delay neither the
    // spinner nor the connect. Trace separation does not depend on this
    // ordering — `Obd2ConnectTraceLog.beginTrace` SUPERSEDES a live
    // picker-scan trace, so the connect always opens its own root. The
    // connect path stops the radio itself (stopScanBeforeConnect); this
    // cancels the Dart side.
    unawaited(_sub?.cancel());
    _sub = null;
    try {
      final service = await connection.connect(candidate);
      // #1188 — persist MAC + display name back onto the active vehicle
      // profile so the next session takes the pinned-MAC fast path and skips
      // the picker. Best-effort; uses the pre-await captures (errorlog_30) so
      // it never touches `ref` after unmount.
      await _persistPickedAdapterToActiveVehicle(
        candidate,
        activeProfile,
        vehicleListNotifier,
      );
      if (!mounted) return;
      if (widget.returnPickedConnection) {
        // #1310 — onboarding flow needs the MAC alongside the service
        // so it can persist `obd2AdapterMac` on the freshly-saved
        // profile (no `active` vehicle exists yet during onboarding,
        // so [_persistPickedAdapterToActiveVehicle] no-ops).
        final mac = candidate.candidate.deviceId;
        final name = candidate.candidate.deviceName.isEmpty
            ? candidate.profile.displayName
            : candidate.candidate.deviceName;
        Navigator.of(context).pop(
          PickedObd2Connection(service: service, mac: mac, name: name),
        );
      } else {
        Navigator.of(context).pop(service);
      }
    } on Obd2ConnectionError catch (e, st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': '_Obd2AdapterPicker._connect: adapter connect failed'
      }));
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
  ///
  /// Persists [VehicleProfile.obd2AdapterMac] (#1310) so the auto-record
  /// orchestrator's gate (`obd2AdapterMac != null &&
  /// backgroundLocationConsent`) flips to ready as soon as the user
  /// successfully pairs — without this, the auto-record toggle silently
  /// dropped users who picked an adapter outside the OBD2 onboarding
  /// wizard.
  ///
  /// [active] and [listNotifier] are captured by the caller BEFORE its first
  /// `await` (errorlog_30): this runs post-connect, when the sheet may already
  /// be unmounted, so reading them off `ref` here would throw the "ref used
  /// after unmount" [StateError]. Both source providers are `keepAlive: true`.
  Future<void> _persistPickedAdapterToActiveVehicle(
    ResolvedObd2Candidate candidate,
    VehicleProfile? active,
    VehicleProfileList listNotifier,
  ) async {
    try {
      if (active == null) return;
      // #2282 concern 3 / #3168 — identity capture lives at the data-layer
      // [Obd2AdapterIdentity] seam: it stores the iOS CBPeripheral UUID
      // reconnection key when the deviceId is UUID-shaped (and null for an
      // Android MAC), so this widget no longer branches on the platform
      // (#2350 ratchet).
      final identity = Obd2AdapterIdentity.fromCandidate(candidate);
      if (active.obd2AdapterMac == identity.deviceId &&
          active.obd2AdapterName == identity.name &&
          active.pairedAdapterUuidIos == identity.uuidIos) {
        return; // already persisted — skip the redundant write.
      }
      final updated = active.copyWith(
        obd2AdapterMac: identity.deviceId,
        obd2AdapterName: identity.name,
        pairedAdapterUuidIos: identity.uuidIos,
      );
      await listNotifier.save(updated);
    } catch (e, st) {
      // #2308 — this write is the ONLY path that pre-populates the
      // pinned-MAC fast-connect; a HiveError here silently drops the
      // adapter MAC and breaks auto-connect on every later session, so
      // it must leave a release-visible breadcrumb (not just debugPrint).
      unawaited(errorLogger.log(ErrorLayer.ui, e, st, context: const {
        'where': '_persistPickedAdapterToActiveVehicle',
      }));
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

  /// #3103 — one tile shape for both sections. A recognized candidate shows
  /// its matched profile name; an unrecognized one (empty placeholder profile)
  /// shows the device's own advertised name + a muted "tap to try" hint.
  Widget _candidateTile(ResolvedObd2Candidate c, AppLocalizations? l) {
    final subtitle = c.recognized
        ? '${c.profile.displayName} · ${c.candidate.rssi} dBm'
        : '${l?.obd2PickerTapToTry ?? 'Unrecognized — tap to try'} · '
            '${c.candidate.rssi} dBm';
    return ListTile(
      key: Key('obdPickerItem_${c.candidate.deviceId}'),
      leading: Icon(
        c.recognized ? Icons.bluetooth : Icons.bluetooth_searching,
      ),
      title: Text(c.candidate.deviceName.isEmpty
          ? c.profile.displayName
          : c.candidate.deviceName),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _connect(c),
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
        // #3103 — recognized adapters first, then NAMED-but-unrecognized
        // devices under an "other devices" header so discovery surfaces ALL
        // adapters, not just catalog-known ones.
        final recognized = [for (final c in _candidates) if (c.recognized) c];
        final unrecognized = [
          for (final c in _candidates)
            if (!c.recognized) c,
        ];
        return Column(
          key: const Key('obdPickerSelecting'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in recognized) _candidateTile(c, l),
            if (unrecognized.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  l?.obd2PickerOtherDevices ?? 'Other Bluetooth devices',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              for (final c in unrecognized) _candidateTile(c, l),
            ],
            if (!_supportsClassicDiscovery)
              Padding(
                key: const Key('obdPickerBleOnlyNotice'),
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                child: Text(
                  l?.obd2PickerBleOnlyNotice ??
                      'iPhone works with Bluetooth-LE adapters only. A '
                          'Classic-only adapter (e.g. vLinker BM, Konnwei '
                          'KW902) must be used on Android.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
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
            // #3181 — while a FIRST-connect setNotify is in flight the OS
            // pairing dialog may be waiting for the user; tell them to
            // confirm it instead of letting the spinner look hung.
            ValueListenableBuilder<bool>(
              valueListenable: Obd2PairingMode.pairingWaitPending,
              builder: (context, pending, _) {
                if (!pending || l == null) return const SizedBox.shrink();
                return Padding(
                  key: const Key('obdPickerPairingHint'),
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l.obd2PairingConfirmHint,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ],
        );
      case _Phase.error:
        // When the underlying error is a permission denial we surface
        // a second CTA — "Open Settings" — alongside the existing
        // Retry. This unblocks users who have already tapped "Don't
        // Allow" on the iOS Bluetooth prompt (the system stops
        // re-prompting and Retry alone never reaches a granted state).
        // Tapping the button calls permission_handler's
        // [openAppSettings], which deep-links into the app's row in
        // iOS Settings (or the Apps page on Android). On a successful
        // grant, the user comes back to the picker and Retry now
        // succeeds.
        final isPermissionError = _error is Obd2PermissionDenied;
        return Column(
          key: const Key('obdPickerError'),
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error, size: 48),
            const SizedBox(height: 8),
            Text(
              _error?.localizedMessage(l) ??
                  l?.errorUnknown ??
                  'Unknown error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('obdPickerRetry'),
              onPressed: _startScan,
              icon: const Icon(Icons.refresh),
              label: Text(l?.retry ?? 'Retry'),
            ),
            if (isPermissionError) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('obdPickerOpenSettings'),
                onPressed: () {
                  // Fire-and-forget — the OS handles the deep link, we
                  // don't need the resolved bool. Best-effort: if the
                  // platform reports failure we still leave the picker
                  // in its error state so Retry stays accessible.
                  unawaited(openAppSettings());
                },
                icon: const Icon(Icons.settings),
                label: Text(
                  l?.obdPermissionDenied ??
                      'Grant Bluetooth permission in system settings',
                ),
              ),
            ],
          ],
        );
    }
  }
}
