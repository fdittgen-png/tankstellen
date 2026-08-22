// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_adapter_state_gate.dart';
import 'ble_disconnect_classifier.dart';
import 'ble_link_tuner.dart';
import 'connection_drop_debouncer.dart';
import 'elm_byte_channel.dart';
import 'elm_gatt_profiles.dart';
import 'obd2_channel_abandon.dart';
import '../obd2_comm_diagnostics.dart';
import '../../domain/obd2_connect_classifier.dart';
import '../obd2_connect_trace.dart';
import '../obd2_connect_trace_log.dart';
import '../../domain/obd2_connection_errors.dart';
import 'obd2_link_drop_signal.dart';
import 'obd2_pairing_mode.dart';
import 'obd2_platform_budgets.dart';
import '../../../../core/logging/error_logger.dart';

part 'flutter_blue_plus_elm_channel_connect.dart';
part 'flutter_blue_plus_elm_channel_gatt.dart';

/// [ElmByteChannel] backed by flutter_blue_plus. Connects to a single
/// [BluetoothDevice], discovers the ELM327 service, enables notifies
/// on the incoming characteristic, and exposes write + notify as the
/// abstract channel contract.
///
/// This class is Android-oriented (vLinker FS is BLE on Android).
/// It is untested on iOS — flutter_blue_plus is cross-platform but
/// iOS BLE ELM adapters are rare; add iOS-specific handling when the
/// app starts supporting them.
///
/// The connect / discovery / session-teardown bodies live in the
/// `flutter_blue_plus_elm_channel_connect.dart` and
/// `flutter_blue_plus_elm_channel_gatt.dart` parts (sanctioned #3760
/// decomposition — move-only, behaviour preserved); the thin instance
/// methods here stay virtually dispatchable for the test fakes.
class FlutterBluePlusElmChannel with Obd2ChannelAbandonLatch
    implements ElmByteChannel, Obd2LinkTuner, Obd2GattRecoverable {
  /// #2969 — bound the scan-path `connect()` (the `connectTimeout == null`
  /// branch) so FBP can't block ~35 s on a vanished candidate.
  static const Duration _scanPathConnectTimeout = Duration(seconds: 10);

  /// #3014 — bound `discoverServices` on its OWN short budget. FBP's default is
  /// 15 s; a hung discovery (a clone whose GATT table never resolves) used to
  /// freeze the whole open for 15 s and read as a hang. A miss now fails in
  /// ~5 s with a distinct `gattTimeout` outcome.
  /// #3182 — int SECONDS, passed to FBP's own `timeout:` parameter (see
  /// [discoverAndBind]) instead of an outer Dart `.timeout()`.
  /// #3172 — the iOS/Android values + the #3118 rationale live in the
  /// consolidated [Obd2PlatformBudgets] (same values, single audited home).
  static int get _discoverTimeoutSecs =>
      Obd2PlatformBudgets.resolved.discoverTimeoutSecs;

  /// #3014 — bound `setNotifyValue`, for the same reason: a clone that accepts
  /// the descriptor write but never ACKs would otherwise block 15 s.
  /// #3182 — int SECONDS, passed to FBP's own `timeout:` parameter.
  /// #3172 — the iOS/Android values + the #3118 OBDLink-CX rationale live in
  /// the consolidated [Obd2PlatformBudgets] (same values, single audited home).
  static int get _setNotifyTimeoutSecs =>
      Obd2PlatformBudgets.resolved.setNotifyTimeoutSecs;

  /// #3118 — test seams to lock the iOS-aware post-connect budgets. Kept as
  /// [Duration]s (built from the int-seconds FBP budgets) so the existing
  /// budget-pinning tests stay byte-identical.
  @visibleForTesting
  static Duration get debugDiscoverTimeout =>
      Duration(seconds: _discoverTimeoutSecs);
  @visibleForTesting
  static Duration get debugSetNotifyTimeout =>
      Duration(seconds: _setNotifyTimeoutSecs);

  /// #3014 — best-effort MTU asked for during the bounded-connect path. Clones
  /// often reject it; the post-discovery `requestMtu` in [tuneForRecording]
  /// stays the fallback. Skipped on the `autoConnect:true` passive path (FBP
  /// forbids `mtu` with autoConnect).
  static const int _preferredMtu = 247;

  final BluetoothDevice _device;
  final Elm327BleUuids _uuids;

  /// Optional bounded timeout passed to `device.connect` (#2242). When null,
  /// `connect` uses the legacy `mtu: null` form with no timeout (the scan-first
  /// path). When set — the direct-by-MAC path — `connect(autoConnect:false,
  /// timeout: …)` bounds the attempt and `open()` first tears down any stale
  /// GATT client to dodge Android GATT_ERROR 133.
  final Duration? _connectTimeout;

  /// #2261 concern 2 — passive autoConnect GATT wait. When true, `open()`
  /// connects with `autoConnect:true` and NO bounded timeout: the OS holds a
  /// low-power background connection request that resolves the instant the
  /// adapter (re)advertises. Used by the reconnect scanner past its active-scan
  /// miss ceiling so a parked car doesn't burn the radio. autoConnect:true
  /// forbids requestMtu, so the concern-4 MTU bump is skipped on this path.
  final bool _autoConnect;

  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;
  // Cancelled in the `flutter_blue_plus_elm_channel_gatt.dart` part's
  // close/teardown paths (the lint can't see across part files).
  // ignore: cancel_subscriptions
  StreamSubscription<List<int>>? _subscription;
  // ignore: cancel_subscriptions — cancelled in the same part teardown.
  StreamSubscription<BluetoothConnectionState>? _connStateSubscription;

  /// #3179 — NOT final: [close] closes the broadcast controller, and the
  /// transport's open-retry loop (plus any reconnect) calls `close()` +
  /// `open()` on the SAME channel instance, so [open] must be able to
  /// recreate it. With a `final` controller the "recovered" link was a
  /// zombie: every notify byte hit a closed controller and the reply timed
  /// out forever.
  StreamController<List<int>> _incoming =
      StreamController<List<int>>.broadcast();
  bool _open = false;

  /// #3019 — set while a DELIBERATE [close] tears the channel down, so the
  /// resulting disconnect edge is NOT misread as an unexpected drop (which
  /// would spuriously kick the reconnect loop after a normal disconnect).
  bool _closing = false;

  /// #3019 — fires the proactive link-drop signal at most once per UNEXPECTED
  /// drop (the debounce-confirmed edge), suppressed during a deliberate close.
  bool _dropSignalled = false;

  /// #2261 concern 1 — debounces a raw `connectionState == disconnected` edge
  /// into a confirmed drop so a self-healing RF blip within the supervision
  /// timeout doesn't tear down a recoverable session, while a genuine
  /// disconnect still surfaces in ~1–2 s (not the ~15 s read timeout). On
  /// confirmation it pushes a typed [Obd2DisconnectedException] onto the byte
  /// stream, which the transport re-throws so [TripDropDetector] sees a drop.
  /// #3179 — NOT `late final`: [close] disposes it, so a reopen rebuilds it
  /// (same debounce, same callback) instead of reviving a disposed one.
  late ConnectionDropDebouncer _dropDebouncer;

  /// #3179 — the configured debounce, kept so [open] can rebuild
  /// [_dropDebouncer] after a close() → open() cycle.
  final Duration _dropDebounce;

  /// #3014 — scan-before-connect seed (THE highest-leverage SmartOBD fix).
  /// Runs a brief TARGETED scan for this device's MAC before the cold
  /// `connect(autoConnect:false)` on the direct-by-MAC path, then `stopScan`s,
  /// so Android holds a FRESH scan-result handle for the peripheral. Connecting
  /// to a raw MAC the OS has no fresh handle for is the textbook GATT-133 / 15 s
  /// timeout trap (Punch Through / van Welie) — discovery is never reached.
  ///
  /// Returns `true` when the targeted scan SAW the MAC (a fresh handle exists,
  /// proceed to connect), `false` on a scan miss (the caller's bounded-passive
  /// fallback owns the recovery). Null on the scan-path / passive paths (no
  /// seed needed: the scan path already has a fresh handle from the picker
  /// scan, and the passive path is itself the OS-held background request).
  ///
  /// Injected by [PluginBluetoothFacade.channelForDirect] in production (a real
  /// FBP `withRemoteIds` scan); a fake in tests so scan-then-connect is driven
  /// with no BLE stack. fbp serializes BLE ops behind a global mutex, so the
  /// production seed MUST `stopScan` before returning or the subsequent connect
  /// deadlocks.
  final Future<bool> Function()? _scanSeed;

  FlutterBluePlusElmChannel(
    this._device, {
    Elm327BleUuids? uuids,
    Duration? connectTimeout,
    bool autoConnect = false,
    Future<bool> Function()? scanSeed,
    Duration dropDebounce = const Duration(milliseconds: 1500),
  })  : _uuids = uuids ?? Elm327BleUuids.vgate,
        _connectTimeout = connectTimeout,
        _autoConnect = autoConnect,
        _scanSeed = scanSeed,
        _dropDebounce = dropDebounce {
    _dropDebouncer = ConnectionDropDebouncer(
      debounce: dropDebounce,
      onConfirmed: _onDropConfirmed,
    );
  }

  /// Push the typed disconnect onto the byte stream so the transport's
  /// in-flight `sendCommand` completer fails fast with a classified error
  /// instead of waiting out the read timeout (#2261 concern 1). Body in
  /// [_onDropConfirmedImpl] (#3760 part).
  void _onDropConfirmed() => _onDropConfirmedImpl(this);

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  /// Connect + discover + subscribe, wrapped with the gated
  /// connect-lifecycle diagnostics tee (#2466) and the #2969 channel-open
  /// outcome stamping. Body in [_openChannel] (#3760 part).
  @override
  Future<void> open() => _openChannel(this);

  /// #3014 — the FBP connect dispatch, including the scan-before-connect seed
  /// on the cold direct path. `@protected @visibleForTesting` so a test can
  /// drive the scan-then-connect ordering (FBP `device.connect` is not fakeable
  /// otherwise). Body in [_connectDeviceImpl] (#3760 part).
  @protected
  @visibleForTesting
  Future<void> connectDevice() => _connectDeviceImpl(this);

  /// #3014 — the single raw FBP `device.connect` call, behind a `@protected`
  /// `@visibleForTesting` seam (the [writeRaw] precedent). A test overrides this
  /// to drive the scan-before-connect ORDERING and the GATT-133-on-cold-MAC
  /// contract without a real BLE stack (FBP `device.connect` is unfakeable
  /// otherwise). Production calls FBP exactly as before.
  @protected
  @visibleForTesting
  Future<void> rawConnect({
    required bool autoConnect,
    int? mtu,
    Duration? timeout,
  }) =>
      timeout == null
          ? _device.connect(autoConnect: autoConnect, mtu: mtu)
          : _device.connect(
              autoConnect: autoConnect, mtu: mtu, timeout: timeout);

  bool _debugScanSeedRan = false;
  bool _debugScanSeedSawMac = false;

  /// #3014 test seam — true once the scan-before-connect seed has run on the
  /// cold direct path.
  @visibleForTesting
  bool get debugScanSeedRan => _debugScanSeedRan;

  /// #3014 test seam — true when the seed saw the MAC (a fresh handle exists).
  @visibleForTesting
  bool get debugScanSeedSawMac => _debugScanSeedSawMac;

  /// #3014 — discover services, resolve the ELM write+notify pair by PROPERTY
  /// (registry UUIDs as a first-priority hint), bind the chars + enable notify.
  /// `@protected @visibleForTesting` so a test can stub it out when driving
  /// [connectDevice] in isolation (the real FBP discovery is not fakeable).
  /// Body in [_discoverAndBindImpl] (#3760 part).
  @protected
  @visibleForTesting
  Future<void> discoverAndBind() => _discoverAndBindImpl(this);

  /// #3181 — enable notifications on the resolved CCCD, with the
  /// FIRST-CONNECT pairing budget (the OBDLink CX pairs via this very
  /// subscribe). `@protected @visibleForTesting` so the budget selection +
  /// pairing classification are drivable without a BLE stack (via
  /// [rawSetNotify]). Body in [_enableNotifyImpl] (#3760 part).
  @protected
  @visibleForTesting
  Future<void> enableNotify() => _enableNotifyImpl(this);

  /// The raw CCCD subscribe behind a `@protected @visibleForTesting` seam
  /// (the [writeRaw] precedent) so [enableNotify]'s budget selection and
  /// pairing classification are testable — FBP's
  /// `BluetoothCharacteristic.setNotifyValue` hits the platform channel.
  @protected
  @visibleForTesting
  Future<void> rawSetNotify(int timeoutSecs) =>
      _notifyChar!.setNotifyValue(true, timeout: timeoutSecs);

  /// #3179 — the notify-stream DATA handler, extracted so a reopen test can
  /// drive the EXACT production byte path without a real BLE stack (FBP's
  /// `lastValueStream` is unfakeable). Tees the chunk into the gated
  /// comm-diagnostics framing counters (#2467) and feeds the live incoming
  /// controller. The `isClosed` guard mirrors [ClassicElmChannel]'s #2953
  /// late-byte guard: a chunk already queued on the event loop can land
  /// AFTER close() closed `_incoming` — drop it silently, never throw.
  @protected
  @visibleForTesting
  void handleNotifyBytes(List<int> bytes) {
    noteObd2Framing(bytes);
    if (!_incoming.isClosed) _incoming.add(bytes);
  }

  /// #3179 test seam — feed a raw connection-state edge into the drop
  /// debouncer exactly as the FBP `connectionState` listener does, so a test
  /// can prove drop detection still works after a close() → open() cycle
  /// (the real stream is unfakeable).
  @visibleForTesting
  void debugNoteConnectionState({required bool disconnected}) =>
      _dropDebouncer.noteConnectionState(disconnected: disconnected);

  /// #2261 concern 1 — subscribe to the connection-state stream so a real
  /// disconnect is noticed in ~1–2 s. The first emission is the current state
  /// (`connected`); the debouncer ignores `connected` edges, so this is a
  /// no-op until the link actually drops. (#3014 — extracted from the inlined
  /// discover/notify body + made a `@protected @visibleForTesting` seam so a
  /// test driving [open] doesn't hit the unfakeable FBP `connectionState`
  /// stream.)
  @protected
  @visibleForTesting
  void bindConnectionState() => _bindConnectionStateImpl(this);

  @override
  Future<void> tuneForRecording() =>
      const BleLinkTuner().tuneForRecording(_device, autoConnect: _autoConnect);

  @override
  Future<void> tuneForBackground() =>
      const BleLinkTuner().tuneForBackground(_device);

  /// #3014 — best-effort drop of the native Android GATT service cache between
  /// connect retries on a GATT_ERROR 133 (a cache-poisoned device). Never
  /// throws (#1103): the transport calls this on the failure path where any
  /// escape would mask the real connect error. Body in
  /// [_refreshGattCacheImpl] (#3760 part).
  @override
  Future<void> refreshGattCache() => _refreshGattCacheImpl(this);

  /// Write [bytes] to the resolved write characteristic, with the #2900
  /// drop reclassification. Body in [_writeChannel] (#3760 part).
  @override
  Future<void> write(List<int> bytes) => _writeChannel(this, bytes);

  /// The raw characteristic write, behind a [protected] [visibleForTesting]
  /// seam so a fault-injection test can drive [write]'s #2900 reclassification
  /// without a real BLE stack (a real [BluetoothCharacteristic] is not
  /// mockable).
  ///
  /// #3182 — write mode follows the RESOLVED characteristic's properties
  /// instead of a hardcoded `withoutResponse: true`: FBP fails loudly when
  /// asked for a write mode the characteristic doesn't advertise, so a clone
  /// whose write char only supports acknowledged writes could never receive a
  /// single command. `writeWithoutResponse` is still preferred whenever the
  /// adapter advertises it (fastest BLE write path).
  @protected
  @visibleForTesting
  Future<void> writeRaw(BluetoothCharacteristic char, List<int> bytes) =>
      char.write(bytes,
          withoutResponse: char.properties.writeWithoutResponse);

  /// #2900 test seam — prime an established session so a fault-injection test
  /// can drive [write] without the real connect path. #2907 — also wires
  /// `_notifyChar` + inert subscriptions so a test can prove a confirmed drop
  /// fully tears the session down (see [debugResidualSessionState]).
  @visibleForTesting
  void debugPrimeOpenSession(BluetoothCharacteristic writeChar) {
    _writeChar = writeChar;
    _notifyChar = writeChar;
    _open = true;
    _subscription ??= const Stream<List<int>>.empty().listen((_) {});
    _connStateSubscription ??=
        const Stream<BluetoothConnectionState>.empty().listen((_) {});
  }

  /// #2907 test seam — true while ANY per-session state survives a drop (the
  /// write/notify chars or either subscription); [_clearSessionOnDrop] clears
  /// them all.
  @visibleForTesting
  bool get debugResidualSessionState =>
      _notifyChar != null ||
      _writeChar != null ||
      _subscription != null ||
      _connStateSubscription != null;

  /// Deliberate teardown: cancel subscriptions, disconnect the GATT client
  /// and close the broadcast controller. Body in [_closeChannel] (#3760
  /// part).
  @override
  Future<void> close() => _closeChannel(this);
}
