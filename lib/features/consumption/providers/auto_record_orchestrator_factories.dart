// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/obd2/android_background_adapter_listener.dart';
import '../data/obd2/auto_trip_coordinator.dart';
import '../data/obd2/background_adapter_listener.dart';
import '../data/obd2/obd2_connection_service.dart';

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

/// Default factory: Android in production, an unimplemented stub
/// elsewhere. Tests override this provider to inject a
/// [FakeBackgroundAdapterListener] without touching platform-detection
/// code.
@Riverpod(keepAlive: true)
BackgroundAdapterListenerFactory autoRecordListenerFactory(Ref ref) {
  return () {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidBackgroundAdapterListener();
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
@Riverpod(keepAlive: true)
Obd2SessionOpener autoRecordSessionOpenerFactory(Ref ref) {
  return (String mac) async {
    return ref.read(obd2ConnectionProvider).connectByMac(mac);
  };
}

/// Foreground-active opener (#2282 concern 1): a DIRECT connect
/// ([Obd2ConnectionService.connectByMacDirect]) — `BluetoothDevice.fromId`
/// + `autoConnect`, NO active scan — so it wakes ELM327 clones that stop
/// advertising in standby. Used by the coordinator's
/// [AutoTripCoordinator.armForegroundActive] on every app resume to start
/// engine-detection while the app is in front, independent of the
/// disabled foreground service. `fallbackToScan: true` keeps behaviour no
/// worse than the scan opener when the direct attempt fails. Tests
/// override this provider to inject a fake direct opener.
@Riverpod(keepAlive: true)
Obd2ForegroundSessionOpener autoRecordForegroundSessionOpenerFactory(Ref ref) {
  return (String mac) async {
    return ref.read(obd2ConnectionProvider).connectByMacDirect(mac);
  };
}
