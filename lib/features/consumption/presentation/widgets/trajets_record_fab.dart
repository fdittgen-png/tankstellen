// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/obd2/obd2_connection_errors.dart';
import '../../providers/trip_recording_provider.dart';
import '../obd2_connection_error_l10n.dart';
import '../screens/trip_recording_screen.dart';
import 'obd2_adapter_picker.dart';
import 'recording_start_coordinator.dart';

/// The "Start / Resume recording" FAB for the Trajets section (#2494).
///
/// Extracted out of [TrajetsTab] so the trajets list can route this FAB
/// through `PageScaffold.floatingActionButton` (the same Scaffold FAB slot
/// the Carburant tab already uses) rather than the old hand-rolled
/// `Stack + Positioned` overlay — which double-counted the system bottom
/// inset. This widget owns the #2274 recording-start orchestration (the
/// `RecordingStartCoordinator` pre-warm + start-now-connect-later flow);
/// the tab body is now a pure list.
class TrajetsRecordFab extends ConsumerStatefulWidget {
  const TrajetsRecordFab({super.key});

  @override
  ConsumerState<TrajetsRecordFab> createState() => _TrajetsRecordFabState();
}

class _TrajetsRecordFabState extends ConsumerState<TrajetsRecordFab> {
  /// #2274 — owns the pre-warm (concern 3) + start-now-connect-later
  /// (concern 2) orchestration.
  final RecordingStartCoordinator _starter = RecordingStartCoordinator();

  @override
  void initState() {
    super.initState();
    // #2274 concern 3 — kick the BLE pre-warm after the first frame so
    // it never competes with the tab's initial layout, and read
    // providers off a post-frame callback where `ref` is safe to use.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _starter.maybePrewarm(ref));
  }

  @override
  void dispose() {
    _starter.dispose();
    super.dispose();
  }

  Future<void> _onStartRecording() async {
    // #2274 concern 2 — re-entrancy guard. A connecting start is already
    // in flight (the recording screen is up in its connecting view), so
    // ignore a second CTA tap. The visible progress now lives on the
    // recording screen rather than an inline card on this tab.
    if (ref.read(tripRecordingProvider).isConnecting) return;
    final notifier = ref.read(tripRecordingProvider.notifier);
    // #2025 — when the user has disabled "Require OBD2 for trip
    // recording" in feature management, bypass the adapter picker
    // and start a GPS-only trajet immediately. The recording screen
    // displays distance + speed from Geolocator; engine fields stay
    // null and the persisted trip carries `kind: TripKind.gpsOnly`.
    final flags = ref.read(enabledFeaturesProvider);
    final obd2Required = flags.contains(Feature.obd2Optional);
    if (!obd2Required) {
      await notifier.startGpsOnly();
      if (!mounted) return;
      await Navigator.of(context).push<TripSaveResult?>(
        MaterialPageRoute(
          builder: (_) => const TripRecordingScreen(),
        ),
      );
      return;
    }
    // A trajet already running in the background — just jump back into
    // the live recording screen without re-connecting.
    if (ref.read(tripRecordingProvider).isActive) {
      await Navigator.of(context).push<TripSaveResult?>(
        MaterialPageRoute(
          builder: (_) => const TripRecordingScreen(),
        ),
      );
      return;
    }
    // #2274 concern 2 — start-now-connect-later. Enter the transient
    // connecting phase and push the recording screen IMMEDIATELY (just
    // like the GPS-only path above), then run the connect + prime in the
    // background with the inline TripStartProgress resolving in-place on
    // the recording screen. The user lands in the recording mode at once
    // and the activity is foreground+active before they can leave to
    // Maps (which makes the onUserLeaveHint auto-PiP — concern 4 — fire
    // reliably). Previously the connect blocked here and the screen only
    // pushed after connect+prime completed.
    notifier.enterConnecting();
    // Fire the connect concurrently — do NOT await before pushing, or
    // the screen wouldn't open until the connect finished (the old
    // behaviour). The coordinator owns its own error surfacing + teardown.
    unawaited(_starter.connectAndStart(
      ref,
      notifier: notifier,
      isMounted: () => mounted,
      openPicker: () {
        // #1188 — silent `connectByMac` fast path for a paired adapter;
        // the picker opens the modal sheet only when that fails. Plumbing
        // both the MAC + display name lets it surface a concrete fallback
        // snackbar ("Couldn't reach 'X' …") rather than a generic one.
        final activeVehicle = ref.read(activeVehicleProfileProvider);
        return showObd2AdapterPicker(
          context,
          pinnedMac: activeVehicle?.obd2AdapterMac,
          pinnedAdapterName: activeVehicle?.obd2AdapterName,
        );
      },
      onConnectionError: (error) {
        // Only an OBD2 connection error carries user-facing copy; other
        // failures are logged by the coordinator and stay silent.
        if (error is Obd2ConnectionError && mounted) {
          SnackBarHelper.showError(
              context, error.localizedMessage(AppLocalizations.of(context)));
        }
      },
    ));
    await Navigator.of(context).push<TripSaveResult?>(
      MaterialPageRoute(
        builder: (_) => const TripRecordingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // When a trip is already recording in the background (#1237), the
    // CTA changes shape: same `_onStartRecording` handler — which jumps
    // back into the live recording screen — but a different label + icon
    // so the user understands tapping returns them to the live trip
    // rather than starting a new one.
    final recordingState = ref.watch(tripRecordingProvider);
    final isRecordingActive = recordingState.isActive;
    // #2274 concern 2 — while a start is connecting, the recording
    // screen is already foreground showing the inline progress; reflect
    // that on the CTA too so a glance at the tab matches.
    final isConnecting = recordingState.isConnecting;
    return FloatingActionButton.extended(
      key: const Key('trajets_start_recording_button'),
      onPressed: isConnecting ? null : _onStartRecording,
      icon: Icon(
        isRecordingActive || isConnecting
            ? Icons.visibility
            : Icons.fiber_manual_record,
      ),
      label: Text(
        isConnecting
            ? (l?.tripStartProgressConnectingAdapter ??
                'Connecting to OBD2 adapter…')
            : isRecordingActive
                ? (l?.trajetsResumeRecordingButton ?? 'Resume recording')
                : (l?.trajetsStartRecordingButton ?? 'Start recording'),
      ),
    );
  }
}
