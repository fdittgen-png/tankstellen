// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../vehicle/providers/vehicle_providers.dart';
import '../../obd2/api.dart';

part 'auto_record_orchestrator_factories.g.dart';

/// Listener + session-opener factory providers the [AutoRecordOrchestrator]
/// reads when building a coordinator. Extracted from the orchestrator file
/// so the orchestrator class stays under the 400-line guard (#1680); tests
/// override these providers to inject fakes without touching the
/// orchestrator's diff logic.

/// Factory that returns a fresh [BackgroundAdapterListener] per
/// coordinator. Each coordinator owns its own listener so a MAC change
/// (drop + recreate) cannot leak the previous listener's
/// `MethodChannel.start` into the new arm.
typedef BackgroundAdapterListenerFactory = BackgroundAdapterListener
    Function();

/// Default factory: Android's foreground-service bridge, iOS's Core
/// Bluetooth state-restoration listener (#3167), an unimplemented stub
/// elsewhere. Tests override this provider to inject a
/// [FakeBackgroundAdapterListener] without touching platform-detection
/// code.
@Riverpod(keepAlive: true)
BackgroundAdapterListenerFactory autoRecordListenerFactory(Ref ref) {
  return () {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidBackgroundAdapterListener();
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // #3167 — hands-free auto-record Phase 3. The keepAlive singleton
      // restoration service is shared across coordinators on purpose:
      // `setOptions(restoreState: true)` and the launch-relaunch tag are
      // process-wide, while each listener arms its own peripheral UUID.
      return IosBackgroundAdapterListener(
        restoration: ref.read(iosStateRestorationServiceProvider),
      );
    }
    return const UnimplementedBackgroundAdapterListener();
  };
}

/// Default opener: opens a fresh [Obd2Service] for the configured MAC
/// via [Obd2ConnectionService.connectByMac] (#1004 phase 2b-3).
/// Returns null when the adapter is out of range or the scan times
/// out — the coordinator stays idle for that connect cycle and waits
/// for the next `AdapterConnected`. Tests override this provider to
/// inject a fake opener that returns a stub service.
///
/// #3167 — wrapped in [wrapStateRestorationOrigin] so the FIRST
/// auto-record connect after a Core Bluetooth background relaunch is
/// trace-stamped `Obd2ConnectOrigin.stateRestoration`. A no-op on a
/// normal launch and on Android (the tag is never set there).
@Riverpod(keepAlive: true)
Obd2SessionOpener autoRecordSessionOpenerFactory(Ref ref) {
  return wrapStateRestorationOrigin(
    inner: (String mac) async {
      return ref.read(obd2ConnectionProvider).connectByMac(mac);
    },
    restoration: ref.read(iosStateRestorationServiceProvider),
  );
}

/// #3167 — decorate [inner] so the one-shot launch-restoration tag
/// (set when iOS relaunched the app via Core Bluetooth state
/// restoration) stamps `Obd2ConnectOrigin.stateRestoration` on the
/// connect trace of the FIRST auto-record session open of that launch.
/// Later opens — and every open on a normal launch — run [inner]
/// untagged, so the service's own default origin applies.
///
/// The origin override scopes the supervisor-admitted connect the
/// opener performs ([Obd2ConnectionService.connectByMac] →
/// `supervisor.admit`), so the restoration path enters single-flight
/// admission like every other requester — only its trace label differs.
///
/// Exposed (not private) so the unit test can drive it with a fake
/// restoration service + a fake inner opener without standing up the
/// whole connection service.
@visibleForTesting
Obd2SessionOpener wrapStateRestorationOrigin({
  required Obd2SessionOpener inner,
  required IosStateRestorationService restoration,
}) {
  return (String mac) {
    if (restoration.consumeLaunchRestorationTag()) {
      return Obd2ConnectTraceLog.runWithOrigin(
        Obd2ConnectOrigin.stateRestoration,
        () => inner(mac),
      );
    }
    return inner(mac);
  };
}

/// Foreground-active opener (#2282 concern 1): a DIRECT connect — NO active
/// scan — so it wakes ELM327 clones that stop advertising in standby. Used by
/// the coordinator's [AutoTripCoordinator.armForegroundActive] on every app
/// resume to start engine-detection while the app is in front, independent of
/// the disabled foreground service.
///
/// #3025 — now TRANSPORT-AWARE via
/// [Obd2ConnectionService.connectByMacTransportAware]. The old call hard-wired
/// the BLE [Obd2ConnectionService.connectByMacDirect], so a Classic-SPP adapter
/// (vLinker BM-Android) could only 4 s-timeout AND the doomed BLE GATT to its
/// MAC poisoned the RFCOMM socket — the same firstConnect defect this opener
/// shared. Transport is inferred from the paired adapter NAME (read defensively
/// off the active vehicle so a provider hiccup never makes the connect throw).
/// `fallbackToScan: true` keeps behaviour no worse than the scan opener when the
/// direct attempt fails. Tests override this provider to inject a fake opener.
@Riverpod(keepAlive: true)
Obd2ForegroundSessionOpener autoRecordForegroundSessionOpenerFactory(Ref ref) {
  return (String mac) async {
    String? adapterName;
    try {
      adapterName = ref.read(activeVehicleProfileProvider)?.obd2AdapterName;
    } catch (_) {
      // The vehicle provider must never make an auto-record connect throw —
      // fall back to a name-less (unknown-transport) connect.
      adapterName = null;
    }
    return ref
        .read(obd2ConnectionProvider)
        .connectByMacTransportAware(mac, adapterName: adapterName);
  };
}
