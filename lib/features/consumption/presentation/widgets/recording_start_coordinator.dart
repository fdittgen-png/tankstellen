// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/logging/error_logger.dart';
import '../../../feature_management/application/feature_flags_provider.dart';
import '../../../feature_management/domain/feature.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../../obd2/api.dart';
import '../../providers/trip_recording_provider.dart';

/// Owns the #2274 recording-start orchestration that the trajets tab
/// delegates to: the concern-3 BLE pre-warm and the concern-2
/// start-now-connect-later picker → connect → `start` sequence.
///
/// Extracted out of `TrajetsTab` so the tab widget stays under the
/// 400-line cap (#1680) and so the start logic is unit-testable without
/// pumping the whole tab. The coordinator is a plain object held by the
/// tab's `State`; it captures the [WidgetRef] per call (never stored)
/// and signals its host through narrow callbacks so it owns no widget
/// concerns of its own.
class RecordingStartCoordinator {
  /// #2274 concern 3 — pre-warm BLE connect. For a pinned/bonded
  /// adapter, a direct GATT connect is kicked the moment the tab opens
  /// so the link is already warm by the time the user taps Start. The
  /// in-flight future and its resolved service are held here; the start
  /// flow consumes the service when ready (skipping the picker's own
  /// connect), and [dispose] tears down an unconsumed warm link cleanly
  /// when the user backs out without starting a trip.
  Future<Obd2Service?>? _prewarm;
  Obd2Service? _prewarmedService;
  bool _prewarmConsumed = false;

  /// Set false once the host's `State` is disposed so the
  /// post-connect callbacks stop touching a dead widget.
  bool _alive = true;

  /// #2274 concern 3 — begin a direct-connect-by-MAC for the active
  /// vehicle's pinned adapter when the tab opens. No-op when OBD2 is not
  /// required (GPS-only mode), when no adapter is pinned, when a trip is
  /// already active/connecting, or when a pre-warm is already running.
  void maybePrewarm(WidgetRef ref) {
    if (!_alive) return;
    if (_prewarm != null) return;
    // GPS-only mode never touches BLE — nothing to warm.
    final flags = ref.read(enabledFeaturesProvider);
    if (!flags.contains(Feature.obd2Optional)) return;
    final recordingState = ref.read(tripRecordingProvider);
    if (recordingState.isActive || recordingState.isConnecting) return;
    final activeVehicle = ref.read(activeVehicleProfileProvider);
    final mac = activeVehicle?.obd2AdapterMac;
    if (mac == null || mac.isEmpty) return;
    final Obd2ConnectionService connection;
    try {
      connection = ref.read(obd2ConnectionProvider);
    } catch (_) {
      // No connection graph (widget tests that don't override it) —
      // pre-warm is a best-effort optimisation, so skip silently.
      return;
    }
    // #3025 — TRANSPORT-AWARE pre-warm. The old call hard-wired the BLE
    // `connectByMacDirect`, so a Classic-SPP adapter (vLinker BM-Android) could
    // only 4 s-timeout AND the doomed BLE GATT to its MAC then poisoned the
    // RFCOMM socket the start flow's Classic fallback used (`read ret: -1`),
    // breaking firstConnect entirely. Routing through the transport-aware entry
    // (transport inferred from the paired adapter NAME via the registry) takes
    // the RFCOMM path for a Classic adapter and never opens the poisoning BLE
    // GATT. `fallbackToScan: false` — the pre-warm is a fast best-effort warm,
    // not a guaranteed connect; a miss just means the start flow connects
    // normally. A successful warm is held for the start flow to consume.
    final future = connection.connectByMacTransportAware(
      mac,
      adapterName: activeVehicle?.obd2AdapterName,
      fallbackToScan: false,
    );
    _prewarm = future;
    unawaited(future.then((svc) {
      if (!_alive) {
        // Backed out while the warm was in flight — disconnect it so we
        // don't leak an open GATT link.
        unawaited(svc?.disconnect());
        return;
      }
      _prewarmedService = svc;
    }).catchError((Object e, StackTrace st) {
      unawaited(errorLogger.log(ErrorLayer.ui, e, st,
          context: const {'where': 'RecordingStart pre-warm connect failed'}));
    }));
  }

  /// #2274 concern 2 — run the picker → connect → `start` sequence while
  /// the recording screen is already foreground in its connecting state.
  /// Advances the provider's [TripStartStage] so the inline progress
  /// card on the recording screen tracks the beat, and on any failure /
  /// cancellation rolls the connecting phase back to idle so the user
  /// isn't stranded on a spinner.
  ///
  /// [openPicker] surfaces the adapter picker (the host passes a closure
  /// that calls `showObd2AdapterPicker` with the screen context).
  /// [onConnectionError] surfaces a localized snackbar; [isMounted] lets
  /// the coordinator bail when the host context is gone.
  Future<void> connectAndStart(
    WidgetRef ref, {
    required TripRecording notifier,
    required Future<Obd2Service?> Function() openPicker,
    required void Function(Object error) onConnectionError,
    required bool Function() isMounted,
  }) async {
    try {
      // #2274 concern 3 — consume the pre-warmed link if one is ready.
      // Awaiting the in-flight warm here is cheap: if it has already
      // resolved we get the service immediately; if it's still
      // connecting we let it finish rather than firing a second connect.
      Obd2Service? service;
      final warm = _prewarm;
      if (warm != null) {
        service = _prewarmedService ?? await warm;
      }
      if (service != null) {
        // Pre-warm hit — skip the picker entirely; the link is already
        // up. Mark it consumed so [dispose] doesn't disconnect the
        // service the live recording now owns.
        _prewarmConsumed = true;
      } else {
        // #1188 — pre-warm missed (no pinned adapter, out of range, or a
        // failed direct connect): fall back to the picker, which takes a
        // silent `connectByMac` fast path for a paired adapter.
        if (!isMounted()) {
          notifier.cancelConnecting();
          return;
        }
        service = await openPicker();
      }
      if (service == null) {
        // User dismissed the picker without connecting — leave the
        // recording screen's connecting view and revert to idle.
        notifier.cancelConnecting();
        return;
      }
      // #2892 — the ELM chip can connect cleanly (every AT OK) while the
      // vehicle bus is silent (ignition off / ECU asleep): ATDPN→NO DATA
      // caches no protocol and 0100→NO DATA leaves zero supported PIDs, yet
      // `connect()` still returned true. Starting here would yield a degraded
      // GPS-only trip with no telemetry and no explanation.
      //
      // #3009 — surface the ENGINE-OFF condition with an accurate
      // "start the engine" message ([Obd2EngineOff]), NOT the old
      // adapter-blaming [Obd2AdapterUnresponsive] ("the adapter did not
      // respond" — but it DID respond; only the engine is off). Roll the
      // connecting phase back and tear down the dead link.
      //
      // #3101 — gate on the FINER [Obd2Service.busProbe] tri-state, NOT the
      // coarse `busAnswered`. #3035 fixed this same false-engine-off in the
      // CONNECTION layer but this start gate was never migrated: on a
      // cache-miss first connect (post reset / reinstall) to a LIVE-but-slow
      // car, the `0100` probe merely TIMES OUT during the ELM protocol search
      // → no protocol digit, no PIDs → `busAnswered == false` though the
      // engine is ON. The old gate then bailed with engine-off and the trip
      // "won't start at all". Block ONLY a confirmed engine-off
      // ([Obd2BusProbeResult.probedSilent] — the ECU stayed silent through
      // EVERY retry); a `transient` / `answered` / `notProbed` (warm
      // cache-hit) connect starts and lets the scheduler pick up PIDs once the
      // protocol search converges.
      if (service.busProbe == Obd2BusProbeResult.probedSilent) {
        notifier.cancelConnecting();
        onConnectionError(const Obd2EngineOff());
        unawaited(service.disconnect());
        return;
      }
      // #3335 — the user may have hit Cancel on the connecting card while
      // the BLE connect was in flight. If the session is no longer
      // connecting, tear the freshly-linked service down and do NOT start a
      // trip they backed out of.
      if (!ref.read(tripRecordingProvider).isConnecting) {
        unawaited(service.disconnect());
        return;
      }
      notifier.setConnectStage(TripStartStage.readingVehicleData);
      await notifier.start(service);
      notifier.setConnectStage(TripStartStage.startingRecording);
    } catch (e, st) {
      notifier.cancelConnecting();
      onConnectionError(e);
      // #2745 — the `onConnectionError` snackbar already surfaced this, so an
      // EXPECTED OBD2 connect condition is a breadcrumb, not an ERROR trace
      // (field trace #5); a genuine fault still ERROR-logs.
      recordObd2ConnectFailure(e, st, where: 'RecordingStart connectAndStart');
    }
  }

  /// Tear down a pre-warmed link the user never consumed (backed out
  /// without starting a trip). Best-effort + fire-and-forget — the
  /// host's `dispose` must stay synchronous.
  void dispose() {
    _alive = false;
    if (_prewarmConsumed) return;
    final svc = _prewarmedService;
    if (svc != null) {
      unawaited(svc.disconnect());
    } else {
      // The warm may still be in flight — disconnect whatever it
      // resolves to, since this tab is gone.
      unawaited(_prewarm?.then((s) => s?.disconnect()));
    }
  }
}
