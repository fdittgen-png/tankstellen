// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_disconnect_classifier.dart';
import 'ble_link_tuner.dart';
import 'connection_drop_debouncer.dart';
import 'elm_byte_channel.dart';
import 'obd2_comm_diagnostics.dart';
import 'obd2_connect_trace.dart';
import 'obd2_connect_trace_log.dart';
import 'obd2_connection_errors.dart';
import '../../../../core/logging/error_logger.dart';

/// Standard SPP-over-BLE UUIDs exposed by Vgate vLinker and most
/// ELM327 BLE clones (Nordic UART Service variant used by the
/// adapter firmware). If the adapter in front of you doesn't match
/// these, pass your own via [ble327ServiceUuid] / [writeCharUuid] /
/// [notifyCharUuid].
class Elm327BleUuids {
  final Guid service;
  final Guid writeChar;
  final Guid notifyChar;

  const Elm327BleUuids({
    required this.service,
    required this.writeChar,
    required this.notifyChar,
  });

  /// Defaults observed on real vLinker FS / FD / MC adapters + most
  /// BLE ELM327 clones.
  static final vgate = Elm327BleUuids(
    service: Guid('0000fff0-0000-1000-8000-00805f9b34fb'),
    writeChar: Guid('0000fff2-0000-1000-8000-00805f9b34fb'),
    notifyChar: Guid('0000fff1-0000-1000-8000-00805f9b34fb'),
  );
}

/// [ElmByteChannel] backed by flutter_blue_plus. Connects to a single
/// [BluetoothDevice], discovers the ELM327 service, enables notifies
/// on the incoming characteristic, and exposes write + notify as the
/// abstract channel contract.
///
/// This class is Android-oriented (vLinker FS is BLE on Android).
/// It is untested on iOS — flutter_blue_plus is cross-platform but
/// iOS BLE ELM adapters are rare; add iOS-specific handling when the
/// app starts supporting them.
class FlutterBluePlusElmChannel implements ElmByteChannel, Obd2LinkTuner {
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
  StreamSubscription<List<int>>? _subscription;
  StreamSubscription<BluetoothConnectionState>? _connStateSubscription;
  final StreamController<List<int>> _incoming =
      StreamController<List<int>>.broadcast();
  bool _open = false;

  /// #2261 concern 1 — debounces a raw `connectionState == disconnected` edge
  /// into a confirmed drop so a self-healing RF blip within the supervision
  /// timeout doesn't tear down a recoverable session, while a genuine
  /// disconnect still surfaces in ~1–2 s (not the ~15 s read timeout). On
  /// confirmation it pushes a typed [Obd2DisconnectedException] onto the byte
  /// stream, which the transport re-throws so [TripDropDetector] sees a drop.
  late final ConnectionDropDebouncer _dropDebouncer;

  FlutterBluePlusElmChannel(
    this._device, {
    Elm327BleUuids? uuids,
    Duration? connectTimeout,
    bool autoConnect = false,
    Duration dropDebounce = const Duration(milliseconds: 1500),
  })  : _uuids = uuids ?? Elm327BleUuids.vgate,
        _connectTimeout = connectTimeout,
        _autoConnect = autoConnect {
    _dropDebouncer = ConnectionDropDebouncer(
      debounce: dropDebounce,
      onConfirmed: _onDropConfirmed,
    );
  }

  /// Push the typed disconnect onto the byte stream so the transport's
  /// in-flight `sendCommand` completer fails fast with a classified error
  /// instead of waiting out the read timeout (#2261 concern 1).
  void _onDropConfirmed() {
    // #2466 — a debounce-CONFIRMED drop is a real mid-session link loss; count
    // it (gated). Raw `disconnected` edges that self-heal inside the debounce
    // are binned separately below as `raw-edge-drop`.
    final diag = Obd2CommDiagnostics.instance;
    if (diag.enabled) diag.noteConnectionEvent(drop: true);
    if (_incoming.isClosed) return;
    _incoming.addError(const Obd2DisconnectedException());
  }

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> open() async {
    if (_open) return;
    // #2466 — gated comm-diagnostics connect-lifecycle tee. A no-op unless
    // `Feature.debugMode` armed the collector; each call early-returns on
    // `!enabled`, so production pays one cached-bool read per event.
    final diag = Obd2CommDiagnostics.instance;
    final connectSw = diag.enabled ? (Stopwatch()..start()) : null;
    if (diag.enabled) diag.noteConnectionEvent(attempt: true);
    try {
      await _connectAndDiscover();
      // ignore: catch_no_st — rethrow-only: the original stack is preserved by rethrow
    } catch (e) {
      if (diag.enabled) {
        diag.noteConnectionEvent(
          failureReason: classifyBleConnectFailure(e),
        );
      }
      // #2969 correction 3 — stamp the channel-open outcome on the active
      // connect trace HERE, where the REAL FBP/StateError is still in hand
      // (Obd2Service.connect swallows it into a generic Obd2AdapterUnresponsive
      // false return). FIRST-TERMINAL-WINS, so the wrong-transport gattTimeout
      // can never be overwritten by the scan fallback's scanEmpty. Ungated by
      // debugMode (the connect-trace ring is, deliberately).
      Obd2ConnectTraceLog.active
        ?..addStep(
          label: 'channel-open',
          status: Obd2ConnectStepStatus.fail,
          detail: e.toString(),
        )
        ..setOutcome(classifyBleOpenOutcome(e), failureDetail: e.toString());
      rethrow;
    }
    if (connectSw != null) {
      connectSw.stop();
      diag.noteConnectionEvent(
        success: true,
        timeToConnectMs: connectSw.elapsedMilliseconds,
      );
    }
  }

  /// The connect → service-discovery → notify-subscribe body of [open],
  /// extracted so [open] can wrap it with the gated connect-lifecycle
  /// diagnostics tee (#2466) without interleaving counters through the calls.
  Future<void> _connectAndDiscover() async {
    final timeout = _connectTimeout;
    if (_autoConnect) {
      // #2261 concern 2 — passive autoConnect GATT wait. No bounded timeout:
      // the OS keeps a low-power background connection request that resolves
      // the moment the adapter advertises again. requestMtu forbidden with
      // autoConnect:true, so `mtu: null`.
      await _device.connect(autoConnect: true, mtu: null);
    } else if (timeout == null) {
      await _device.connect(autoConnect: false, mtu: null);
    } else {
      // Direct-by-MAC path (#2242). Tear down any stale GATT client FIRST —
      // Android returns GATT_ERROR 133 if a prior (dropped-but-not-closed)
      // connection is still open, silently forcing a fall back to the scan
      // path. disconnect() is idempotent (no-op when nothing is connected).
      try {
        await _device.disconnect();
      } catch (e, _) {
        // Best-effort pre-connect teardown of a stale GATT client. The connect
        // below proceeds regardless — a failure here is RECOVERABLE and
        // routine, never an error trace (#2379). Debug-only.
        assert(() {
          debugPrint(
              'FlutterBluePlusElmChannel: pre-connect dead-GATT teardown '
              'failed (proceeding): $e');
          return true;
        }());
      }
      // The explicit ~4 s timeout is LOAD-BEARING: FBP's
      // autoConnect:false connect can otherwise block ~35 s.
      await _device.connect(autoConnect: false, timeout: timeout);
    }
    final services = await _device.discoverServices();
    final service = services.firstWhere(
      (s) => s.uuid == _uuids.service,
      orElse: () => throw StateError(
        'BLE device ${_device.remoteId.str} has no ELM327 service '
        '${_uuids.service}',
      ),
    );
    _writeChar = service.characteristics.firstWhere(
      (c) => c.uuid == _uuids.writeChar,
      orElse: () => throw StateError(
        'BLE device has no write characteristic ${_uuids.writeChar}',
      ),
    );
    _notifyChar = service.characteristics.firstWhere(
      (c) => c.uuid == _uuids.notifyChar,
      orElse: () => throw StateError(
        'BLE device has no notify characteristic ${_uuids.notifyChar}',
      ),
    );
    await _notifyChar!.setNotifyValue(true);
    _subscription = _notifyChar!.lastValueStream.listen(
      (bytes) {
        // #2467 — tee the raw chunk into the gated comm-diagnostics
        // wire-framing counters (double-gated, so production pays nothing).
        noteObd2Framing(bytes);
        _incoming.add(bytes);
      },
      onError: (e, st) {
        // #2900 — a mid-session disconnect can surface here too (the GATT/ATT
        // stack errors the notify stream when the adapter drops). Clear the
        // session and forward the RECLASSIFIED recoverable disconnect (not the
        // raw FBP/GATT error) so the transport's completer fails fast AND the
        // drop detector sees a typed disconnect — never an ERROR trace. A
        // genuine non-disconnect error keeps its #2295 behaviour (below).
        if (isBleAdapterDisconnect(e)) {
          // #2907 — FULL session teardown on a confirmed drop (was clearing
          // only `_open`/`_writeChar`, leaving stale notify state behind).
          _clearSessionOnDrop();
          if (!_incoming.isClosed) {
            _incoming.addError(
              const Obd2DisconnectedException(
                'FlutterBluePlusElmChannel: notify stream dropped — '
                'adapter not connected',
              ),
              st,
            );
          }
          return;
        }
        // #2295 — forward the error so the transport's pending `sendCommand`
        // completer fails IMMEDIATELY instead of waiting out the read timeout.
        if (!_incoming.isClosed) _incoming.addError(e, st);
        // OBD2/BLE GATT/ATT error → `other` ("not yet classified", #2379).
        // Kept logged: a real link drop worth seeing in release triage.
        unawaited(errorLogger.log(ErrorLayer.other, e, st,
            context: const {'where': 'FlutterBluePlusElmChannel notify error'}));
      },
    );
    // #2261 concern 1 — subscribe to the connection-state stream so a real
    // disconnect is noticed in ~1–2 s. The first emission is the current state
    // (`connected`); the debouncer ignores `connected` edges, so this is a
    // no-op until the link actually drops.
    _dropDebouncer.reset();
    _connStateSubscription = _device.connectionState.listen(
      (state) {
        final disconnected =
            state == BluetoothConnectionState.disconnected;
        // #2466 — a raw `disconnected` EDGE (before the debouncer confirms it)
        // is binned as a recoverable transient: most edges self-heal inside the
        // supervision window. Counted only while the debouncer is idle so one
        // drop episode is one tally. Gated; no-op unless Feature.debugMode.
        if (disconnected) {
          final diag = Obd2CommDiagnostics.instance;
          if (diag.enabled && !_dropDebouncer.isPending) {
            diag.noteConnectionEvent(failureReason: 'raw-edge-drop');
          }
        }
        _dropDebouncer.noteConnectionState(disconnected: disconnected);
      },
      onError: (e, st) {
        debugPrint('FlutterBluePlusElmChannel connectionState error: $e');
      },
    );
    _open = true;
    // #2261 concern 4 — a freshly-opened ACTIVE link is a recording link: ask
    // for high throughput (priority + best-effort MTU). Skipped on the passive
    // autoConnect path (FBP forbids requestMtu; a parked-car wait wants low
    // power). Best-effort: any rejection is swallowed.
    if (!_autoConnect) {
      await tuneForRecording();
    }
  }

  @override
  Future<void> tuneForRecording() =>
      const BleLinkTuner().tuneForRecording(_device, autoConnect: _autoConnect);

  @override
  Future<void> tuneForBackground() =>
      const BleLinkTuner().tuneForBackground(_device);

  @override
  Future<void> write(List<int> bytes) async {
    final char = _writeChar;
    if (char == null) {
      // #2900 — the session was cleared by a confirmed drop (the catch below,
      // or a notify-stream error). Surface the recoverable typed disconnect —
      // NOT a raw StateError — so `_isTypedDisconnect` routes a post-drop write
      // through pause/reconnect and `recordObd2ReadFailure` de-noises it to a
      // breadcrumb, mirroring [ClassicElmChannel.write]'s `!_open` guard.
      throw const Obd2DisconnectedException(
        'FlutterBluePlusElmChannel: not open',
      );
    }
    // withoutResponse lets the adapter write as fast as BLE allows.
    try {
      await writeRaw(char, bytes);
    } catch (e, st) {
      // #2261 concern 1 — a write failure WHILE a disconnect edge is pending
      // confirms the drop immediately; a lone failure on a live link is a
      // debouncer no-op. #2466 — bin it as a recoverable transient (gated).
      final diag = Obd2CommDiagnostics.instance;
      if (diag.enabled) diag.noteConnectionEvent(failureReason: 'write-fail');
      _dropDebouncer.noteCommandFailure();
      // #2900 — a drop landing DURING the BLE write makes FBP throw a raw
      // disconnect exception ([isBleAdapterDisconnect]) that, left unwrapped,
      // [TripDropDetector] didn't recognise — so the ~1 Hz speed poller re-wrote
      // every cycle and each failure spooled an ERROR trace (error-log #23, 25×).
      // Reclassify into the recoverable [Obd2DisconnectedException] (the #2671
      // [ClassicElmChannel] + #2524 [BluetoothObd2Transport] precedents) and
      // clear the session so the next write short-circuits on the open-guard.
      if (isBleAdapterDisconnect(e)) {
        // #2907 — full session teardown on a write-time drop (was clearing
        // only `_open`/`_writeChar`), so a reconnect's open() starts clean.
        _clearSessionOnDrop();
        debugPrint('FlutterBluePlusElmChannel: write failed — reclassifying '
            'as a recoverable disconnect (#2900): $e\n$st');
        throw const Obd2DisconnectedException(
          'FlutterBluePlusElmChannel: write failed — adapter not connected',
        );
      }
      // A genuine non-disconnect BLE error still surfaces unchanged.
      // ignore: use_rethrow_when_possible
      throw e;
    }
  }

  /// The raw characteristic write, behind a [protected] [visibleForTesting]
  /// seam so a fault-injection test can drive [write]'s #2900 reclassification
  /// without a real BLE stack (a real [BluetoothCharacteristic] is not
  /// mockable). Production writes exactly as before.
  @protected
  @visibleForTesting
  Future<void> writeRaw(BluetoothCharacteristic char, List<int> bytes) =>
      char.write(bytes, withoutResponse: true);

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

  /// #2907 — fully clear per-session BLE state the instant a drop is confirmed
  /// (notify-stream error / write failure) so a subsequent [open] starts
  /// clean. Used to clear only `_open`/`_writeChar`, leaving `_notifyChar` +
  /// both subscriptions dangling for the next open to double-wire. Cancels
  /// fire-and-forget: it can run INSIDE the notify subscription's own
  /// `onError`, where awaiting its own cancellation would deadlock. `_incoming`
  /// is NOT closed here — [close] owns that.
  void _clearSessionOnDrop() {
    _open = false;
    _writeChar = null;
    _notifyChar = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_connStateSubscription?.cancel());
    _connStateSubscription = null;
  }

  @override
  Future<void> close() async {
    _open = false;
    _dropDebouncer.dispose();
    await _connStateSubscription?.cancel();
    _connStateSubscription = null;
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _device.disconnect();
    } catch (e, st) {
      // OBD2/BLE layer, not local storage (#2379).
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'FlutterBluePlusElmChannel: disconnect failed'}));
    }
    // #2295 — close the broadcast controller (symmetry with
    // ClassicElmChannel.close()) so it doesn't leak across a reconnect.
    if (!_incoming.isClosed) await _incoming.close();
    _writeChar = null;
    _notifyChar = null;
  }
}
