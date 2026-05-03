import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'ios_state_restoration_service.dart';

part 'ios_state_restoration_provider.g.dart';

/// Singleton provider exposing the [IosStateRestorationService]
/// (#1295 phase 2).
///
/// `keepAlive: true` because the service holds a broadcast stream
/// controller that callers (Phase 3 — BLE listener) subscribe to
/// for the entire app lifetime. Letting Riverpod recreate it on
/// dependency churn would silently drop the controller and break
/// the listener wiring.
///
/// Production resolves to [FlutterBluePlusIosStateRestorationService]
/// — the only implementation. Tests override the provider with a
/// fake (or instantiate the service directly with
/// [FlutterBluePlusIosStateRestorationService.debugIsIOSOverride]
/// to drive both platform branches).
@Riverpod(keepAlive: true)
IosStateRestorationService iosStateRestorationService(Ref ref) {
  final service = FlutterBluePlusIosStateRestorationService();
  ref.onDispose(service.dispose);
  return service;
}
