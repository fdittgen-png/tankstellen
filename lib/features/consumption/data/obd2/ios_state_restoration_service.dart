import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../../../core/logging/error_logger.dart';
import 'ios_restoration_event.dart';

/// Dart-side facade over Core Bluetooth state preservation +
/// restoration on iOS (#1295 phase 2).
///
/// ## What this is for
///
/// On iOS, the only way to keep an OBD2 BLE connection alive across
/// app termination — so the app can be relaunched in the background
/// when the user enters their car — is Core Bluetooth's State
/// Preservation and Restoration. The flow is:
///
/// 1. Cold-start: call `FlutterBluePlus.setOptions(restoreState: true)`
///    BEFORE any scan/connect. Under the hood the plugin passes
///    `CBCentralManagerOptionRestoreIdentifierKey` to the native
///    `CBCentralManager`, opting us into state restoration.
/// 2. After first-run pairing: connect to the paired ELM327 BLE
///    peripheral with no timeout. iOS retains this pending connect
///    across termination as long as the user has not force-quit.
/// 3. When the ELM327 powers up later (driver enters the car), iOS
///    sees the advertisement, completes the connection, and
///    relaunches the app into the background. The native plugin
///    receives `centralManager:willRestoreState:` and rehydrates
///    the peripheral; we surface that event to Dart via [events].
///
/// See `docs/guides/ios-auto-record.md` for the platform-side
/// changes (Info.plist, background modes, usage strings) the
/// developer must apply on a Mac before the iOS path can be
/// verified end-to-end.
///
/// ## Platform safety
///
/// EVERY public method is safe to call on Android (and on Linux /
/// macOS-desktop test runners). Non-iOS platforms get no-op
/// implementations:
///
/// * [initialize] returns immediately.
/// * [registerPersistedAdapter] returns immediately.
/// * [events] emits a single [IosRestorationNotSupported] then
///   closes.
///
/// This means callers can wire the service unconditionally during
/// app initialization and let the platform gate handle dispatch —
/// no `if (Platform.isIOS)` sprinkled across the call sites.
///
/// ## Phase boundary
///
/// This service is Phase 2 of the iOS hands-free auto-record port
/// per #1295. Phase 1 (the on-device spike that proves
/// `willRestoreState` actually fires on real hardware) requires a
/// Mac + iPhone + ELM327 BLE adapter and is NOT autonomous-worker
/// territory. Phase 3 (BLE listener + speed source + trip
/// lifecycle) consumes the [events] stream to resume trip
/// recording after a background relaunch.
abstract class IosStateRestorationService {
  /// Configure flutter_blue_plus for state restoration. Idempotent:
  /// safe to call more than once. Must be called BEFORE any scan
  /// or connect on a cold start, otherwise iOS will not register
  /// our central manager for state restoration on this launch.
  ///
  /// On non-iOS platforms this is a no-op.
  Future<void> initialize();

  /// Issue a flutter_blue_plus connect to the paired ELM327 with
  /// a long-lived pending semantics. iOS retains this pending
  /// connect across app termination via state restoration as
  /// long as the user has not force-quit the app.
  ///
  /// [peripheralUuid] is the `CBPeripheral.identifier.uuidString`
  /// captured during first-run pairing. iOS does NOT expose the
  /// hardware MAC; the UUID is the stable identifier we persist
  /// in `VehicleProfile.pairedAdapterUuidIos` (Phase 3).
  ///
  /// On non-iOS platforms this is a no-op.
  Future<void> registerPersistedAdapter(String peripheralUuid);

  /// Stream of state-restoration events surfaced from the native
  /// side. On iOS, emits [IosRestorationWillRestore] each time
  /// the OS relaunches us via `centralManager:willRestoreState:`.
  /// On non-iOS platforms, emits a single
  /// [IosRestorationNotSupported] then closes.
  ///
  /// Single-broadcast: multiple listeners are supported.
  Stream<IosRestorationEvent> get events;

  /// Release resources held by the service. Closes the [events]
  /// stream. Safe to call more than once.
  Future<void> dispose();
}

/// Production implementation. Dispatches every method to a private
/// platform-specific handler so the dispatcher itself is testable
/// on the Dart VM (no iOS runtime needed).
///
/// The iOS path uses `flutter_blue_plus` 1.35+ which exposes
/// `setOptions(restoreState: true)` and forwards
/// `CBCentralManagerOptionRestoreIdentifierKey` under the hood.
/// The plugin currently has no Dart-side stream for the
/// `willRestoreState` callback; Phase 3 will add a thin
/// MethodChannel listener (or upstream a PR to FBP) to surface
/// the peripheral list. For Phase 2 we publish a single
/// [IosRestorationNotSupported] event on cold start as a
/// breadcrumb that the listener wired up correctly — Phase 3
/// will replace the placeholder with real `willRestore` events.
class FlutterBluePlusIosStateRestorationService
    implements IosStateRestorationService {
  /// Test seam: when set, overrides `Platform.isIOS` for the
  /// dispatcher branch. Production code leaves it null and the
  /// real platform check is used.
  @visibleForTesting
  final bool? debugIsIOSOverride;

  final StreamController<IosRestorationEvent> _eventsController =
      StreamController<IosRestorationEvent>.broadcast();

  bool _initialized = false;
  bool _disposed = false;

  FlutterBluePlusIosStateRestorationService({this.debugIsIOSOverride});

  /// Resolved platform check. Production reads [Platform.isIOS];
  /// tests pass [debugIsIOSOverride] to drive both branches.
  bool get _isIOS => debugIsIOSOverride ?? Platform.isIOS;

  @override
  Future<void> initialize() async {
    if (_disposed) return;
    if (_initialized) return;
    _initialized = true;
    if (_isIOS) {
      await _initializeIOS();
    } else {
      _initializeNonIOS();
    }
  }

  /// iOS path: opt the central manager into state restoration so
  /// `CBCentralManagerOptionRestoreIdentifierKey` is set on the
  /// native side. Must run before any scan/connect.
  Future<void> _initializeIOS() async {
    try {
      await FlutterBluePlus.setOptions(restoreState: true);
      debugPrint(
        'IosStateRestorationService: setOptions(restoreState: true) ok',
      );
    } catch (e, st) {
      await errorLogger.log(
        ErrorLayer.services,
        e,
        st,
        context: const {
          'where': 'IosStateRestorationService.initialize',
        },
      );
      rethrow;
    }
  }

  /// Non-iOS path: emit the "not supported" sentinel so listeners
  /// can switch exhaustively without a Platform check.
  void _initializeNonIOS() {
    if (_eventsController.isClosed) return;
    _eventsController.add(const IosRestorationEvent.notSupported());
  }

  @override
  Future<void> registerPersistedAdapter(String peripheralUuid) async {
    if (_disposed) return;
    if (!_isIOS) {
      // Android keeps its paired ELM327 alive via the foreground
      // service (#1004) — there is nothing to register here.
      return;
    }
    await _registerPersistedAdapterIOS(peripheralUuid);
  }

  /// iOS path: issue a flutter_blue_plus connect with a long
  /// timeout (effectively "no timeout"). iOS retains the pending
  /// connect across app termination via state restoration. We do
  /// NOT await the future — the call returns once the connect is
  /// queued, not once the peripheral is reached.
  Future<void> _registerPersistedAdapterIOS(String peripheralUuid) async {
    try {
      final device = BluetoothDevice.fromId(peripheralUuid);
      // Fire-and-forget: the connect future completes on the next
      // BLE state change (which may be hours away when the car is
      // parked). We purposefully drop the returned Future on the
      // floor — the consumer in Phase 3 listens to
      // `device.connectionState` for the actual connect signal.
      // `unawaited` is intentional, not a bug.
      // ignore: unawaited_futures
      device.connect(
        autoConnect: true,
        // `mtu` must be null when `autoConnect: true` — see the
        // FBP source: `assert((mtu == null) || !autoConnect)`.
        mtu: null,
        // 365 days is the longest reasonable "no timeout" — the
        // FBP API doesn't accept Duration.zero as "infinite".
        timeout: const Duration(days: 365),
      );
      debugPrint(
        'IosStateRestorationService: registerPersistedAdapter queued '
        'connect for $peripheralUuid',
      );
    } catch (e, st) {
      await errorLogger.log(
        ErrorLayer.services,
        e,
        st,
        context: {
          'where': 'IosStateRestorationService.registerPersistedAdapter',
          'peripheralUuid': peripheralUuid,
        },
      );
      rethrow;
    }
  }

  @override
  Stream<IosRestorationEvent> get events => _eventsController.stream;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (!_eventsController.isClosed) {
      await _eventsController.close();
    }
  }
}
