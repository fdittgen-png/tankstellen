// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/protocol/adapter_registry.dart';
import '../../data/session/obd2_adapter_identity.dart';
import '../../domain/obd2_connection_errors.dart';
import '../../data/session/obd2_connection_service.dart';
import '../../data/transport/obd2_pairing_mode.dart';
import '../../data/transport/obd2_scan_readiness.dart';
import '../../data/session/obd2_service.dart';
import 'obd2_picker_supervised_dial.dart';
import 'obd2_scan_empty_state.dart';
import 'obd2_scan_error_state.dart';
import '../obd2_connection_error_l10n.dart';
import '../obd2_connect_telemetry.dart';
import '../../../../core/logging/error_logger.dart';

part 'obd2_adapter_picker_body.dart';
part 'obd2_adapter_picker_flow.dart';

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
      // #3527 — supervised one-shot dial: no reuse-live for a user-chosen
      // device — see [obd2PickerSupervisedDial].
      service = await obd2PickerSupervisedDial(
          container,
          () => container.read(obd2ConnectionProvider).connectByMacTransportAware(pinnedMac, adapterName: pinnedAdapterName));
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
        : l.obd2PickerPinnedFallback(fallbackAdapterName!);
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

enum _Phase { scanning, selecting, connecting, error, blocked }

class _Obd2AdapterPickerSheetState
    extends ConsumerState<Obd2AdapterPickerSheet>
    with _Obd2AdapterPickerFlow, _Obd2AdapterPickerBody {
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
}
