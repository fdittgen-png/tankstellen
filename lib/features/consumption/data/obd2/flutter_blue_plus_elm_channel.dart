// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'connection_drop_debouncer.dart';
import 'elm_byte_channel.dart';
import 'obd2_comm_diagnostics.dart';
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

  /// #2261 concern 4 — best-effort MTU to request on a high-throughput
  /// (recording) link. 247 is the practical ATT payload ceiling on most
  /// Android BLE stacks; the actual negotiated value is whatever the
  /// peripheral grants. Skipped entirely on the autoConnect passive
  /// path (FBP forbids requestMtu there).
  static const int _recordingMtu = 247;

  /// Optional bounded timeout passed to `device.connect` (#2242). When
  /// null, `connect` is called with the legacy `mtu: null` form and no
  /// explicit timeout (the scan-first path, where the device was just
  /// seen advertising so a long connect block is unlikely). When set —
  /// the direct-by-MAC path — `connect(autoConnect:false,
  /// timeout: …)` bounds the attempt and `open()` first tears down any
  /// stale GATT client to dodge Android GATT_ERROR 133.
  final Duration? _connectTimeout;

  /// #2261 concern 2 — passive autoConnect GATT wait. When true, `open()`
  /// connects with `autoConnect:true` and NO bounded timeout: the OS
  /// holds a low-power background GATT connection request that resolves
  /// the instant the adapter (re)advertises. Used by the reconnect
  /// scanner once its active-scan miss ceiling is reached, so a parked
  /// car doesn't burn the radio on repeated active scans. autoConnect:true
  /// forbids requestMtu (FBP throws), so the concern-4 MTU bump is
  /// skipped entirely on this path.
  final bool _autoConnect;

  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;
  StreamSubscription<List<int>>? _subscription;
  StreamSubscription<BluetoothConnectionState>? _connStateSubscription;
  final StreamController<List<int>> _incoming =
      StreamController<List<int>>.broadcast();
  bool _open = false;

  /// #2261 concern 1 — debounces a raw `connectionState == disconnected`
  /// edge into a confirmed drop so a self-healing RF blip within the BLE
  /// supervision timeout doesn't tear down a recoverable session, while
  /// a genuine disconnect still surfaces in ~1–2 s (not the ~15 s read
  /// timeout). On confirmation it pushes a typed [Obd2DisconnectedException]
  /// onto the byte stream, which the transport's pending-command completer
  /// re-throws so [TripDropDetector] classifies it as a typed drop.
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
  /// in-flight `sendCommand` completer fails fast with a classified
  /// error instead of waiting out the read timeout (#2261 concern 1).
  void _onDropConfirmed() {
    // #2466 — a debounce-CONFIRMED drop is a real mid-session link loss.
    // Count it as a drop (gated; no-op unless Feature.debugMode is on).
    // Raw `disconnected` edges that self-heal inside the debounce are
    // binned separately below as `raw-edge-drop` so the confirmed-drop
    // total stays a tally of genuine losses.
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
    // #2466 — gated comm-diagnostics connect-lifecycle tee. The whole
    // block is a no-op unless `Feature.debugMode` armed the collector
    // (the gate provider flips `enabled`); each call early-returns on
    // `!enabled`, so production pays one cached-bool read per event.
    final diag = Obd2CommDiagnostics.instance;
    final connectSw = diag.enabled ? (Stopwatch()..start()) : null;
    if (diag.enabled) diag.noteConnectionEvent(attempt: true);
    try {
      await _connectAndDiscover();
    } catch (e) {
      if (diag.enabled) {
        diag.noteConnectionEvent(
          failureReason: _classifyBleConnectFailure(e),
        );
      }
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
  /// diagnostics tee (#2466) without interleaving counters through the
  /// platform calls.
  Future<void> _connectAndDiscover() async {
    final timeout = _connectTimeout;
    if (_autoConnect) {
      // #2261 concern 2 — passive autoConnect GATT wait. No bounded
      // timeout: the OS keeps a low-power background connection request
      // that resolves the moment the adapter advertises again.
      // requestMtu is forbidden with autoConnect:true, so `mtu: null`.
      await _device.connect(autoConnect: true, mtu: null);
    } else if (timeout == null) {
      await _device.connect(autoConnect: false, mtu: null);
    } else {
      // Direct-by-MAC path (#2242). Tear down any stale GATT client for
      // this device FIRST — Android returns GATT_ERROR 133 if a prior
      // (dropped-but-not-closed) GATT connection is still open, which
      // would silently force a fall back to the scan path. disconnect()
      // is idempotent and a no-op when nothing is connected.
      try {
        await _device.disconnect();
      } catch (e, _) {
        // Best-effort pre-connect teardown of a stale GATT client. The
        // connect below proceeds (and recovers) regardless — a failure
        // here is RECOVERABLE and routine, never an error trace (#2379).
        // Debug-only.
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
        // wire-framing counters. Double-gated (kReleaseMode +
        // collector.enabled), so production pays nothing.
        noteObd2Framing(bytes);
        _incoming.add(bytes);
      },
      onError: (e, st) {
        // #2295 — forward the GATT/ATT error onto the byte stream so the
        // transport's pending `sendCommand` completer fails IMMEDIATELY
        // (via `_failPending`) instead of sitting until the 5 s read
        // timeout, and log it so the drop is visible in release.
        if (!_incoming.isClosed) _incoming.addError(e, st);
        // OBD2/BLE GATT/ATT error, not local storage — `other` ("not yet
        // classified") is the correct layer (#2379). Kept logged: this is
        // a real link drop worth seeing in release triage.
        unawaited(errorLogger.log(ErrorLayer.other, e, st,
            context: const {'where': 'FlutterBluePlusElmChannel notify error'}));
      },
    );
    // #2261 concern 1 — subscribe to the device's connection-state
    // stream so a real disconnect is noticed in ~1–2 s. The first
    // emission is the current state (`connected`, since we just
    // connected); the debouncer ignores `connected` edges, so this is a
    // no-op until the link actually drops.
    _dropDebouncer.reset();
    _connStateSubscription = _device.connectionState.listen(
      (state) {
        final disconnected =
            state == BluetoothConnectionState.disconnected;
        // #2466 — a raw `disconnected` EDGE (before the debouncer
        // confirms it) is binned as a recoverable transient, not a
        // confirmed drop: most edges self-heal inside the supervision
        // window. Only count it while the debouncer is idle, so a
        // single drop episode contributes one raw-edge tally, not one
        // per repeated edge. Gated; no-op unless Feature.debugMode is on.
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
    // #2261 concern 4 — a freshly-opened ACTIVE link is a recording
    // link: ask for high throughput (high priority + best-effort MTU).
    // Skipped on the passive autoConnect path — FBP forbids requestMtu
    // with autoConnect:true, and a parked-car passive wait wants low
    // power, not high duty. Best-effort: any rejection is swallowed.
    if (!_autoConnect) {
      await tuneForRecording();
    }
  }

  @override
  Future<void> tuneForRecording() async {
    await _setConnectionPriority(ConnectionPriority.high);
    // requestMtu is forbidden with autoConnect:true (FBP throws); the
    // passive path never calls this, but guard anyway.
    if (_autoConnect) return;
    try {
      final granted = await _device.requestMtu(_recordingMtu);
      // #2466 — record the negotiated ATT MTU into the gated comm-health
      // session (no-op unless Feature.debugMode armed the collector). The
      // peripheral may grant less than requested; the granted value is the
      // diagnostic one.
      final diag = Obd2CommDiagnostics.instance;
      if (diag.enabled) diag.recordAdapterIdentity(mtu: granted);
    } catch (e, st) {
      // Many clones reject a non-default MTU — harmless, the default
      // 23-byte MTU still works. PHY (2M) is deliberately NOT requested:
      // it is a trap on BLE 4.0/4.1 clones.
      debugPrint('FlutterBluePlusElmChannel requestMtu skipped: $e\n$st');
    }
  }

  @override
  Future<void> tuneForBackground() async {
    await _setConnectionPriority(ConnectionPriority.balanced);
  }

  /// Bin a BLE `open()` failure into a stable, low-cardinality reason tag
  /// for the gated comm-diagnostics `failuresByReason` map (#2466). Kept
  /// coarse + platform-derived so an exported error-log shows *why* a
  /// connect failed (GATT timeout vs missing ELM service vs other) without
  /// leaking a high-cardinality raw message.
  static String _classifyBleConnectFailure(Object e) {
    final msg = e.toString().toUpperCase();
    if (msg.contains('TIMEOUT') || msg.contains('GATT_CONNECTION_TIMEOUT')) {
      return 'gatt-connection-timeout';
    }
    // Android GATT_ERROR 133 — the catch-all "stack gave up" code, most
    // often a stale GATT client or an out-of-range adapter.
    if (msg.contains('133') || msg.contains('GATT_ERROR')) {
      return 'gatt-error-133';
    }
    // The service / characteristic discovery `StateError`s thrown above.
    if (e is StateError &&
        (msg.contains('ELM327 SERVICE') ||
            msg.contains('WRITE CHARACTERISTIC') ||
            msg.contains('NOTIFY CHARACTERISTIC'))) {
      return 'service-not-found';
    }
    return 'other';
  }

  /// Best-effort connection-priority request (#2261 concern 4). Android
  /// only — FBP throws `androidOnly` elsewhere — so the try/catch keeps
  /// iOS / a rejecting clone from ever breaking a session.
  Future<void> _setConnectionPriority(ConnectionPriority priority) async {
    try {
      await _device.requestConnectionPriority(
        connectionPriorityRequest: priority,
      );
    } catch (e, st) {
      debugPrint('FlutterBluePlusElmChannel requestConnectionPriority '
          'skipped: $e\n$st');
    }
  }

  @override
  Future<void> write(List<int> bytes) async {
    final char = _writeChar;
    if (char == null) {
      throw StateError('Channel not open — call open() first');
    }
    // withoutResponse lets the adapter write as fast as BLE allows;
    // the ELM327 replies via notify anyway.
    try {
      await char.write(bytes, withoutResponse: true);
      // ignore: catch_no_st
    } catch (e) {
      // #2261 concern 1 — a write failing WHILE a disconnect edge is
      // pending confirms the drop immediately rather than waiting out
      // the rest of the debounce: the link has proven unusable. A lone
      // write failure on an otherwise-connected link is a no-op for the
      // debouncer and falls through to the caller as before. Rethrow-only
      // (the caller / transport classifies it) — no stack trace needed.
      // #2466 — bin the write failure as a recoverable transient reason
      // (gated; no-op unless Feature.debugMode is on). It is distinct
      // from a confirmed drop: a write can fail on a link that recovers.
      final diag = Obd2CommDiagnostics.instance;
      if (diag.enabled) diag.noteConnectionEvent(failureReason: 'write-fail');
      _dropDebouncer.noteCommandFailure();
      rethrow;
    }
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
    // #2295 — close the broadcast controller on dispose (symmetry with
    // ClassicElmChannel.close()) so it doesn't leak across a reconnect.
    if (!_incoming.isClosed) await _incoming.close();
    _writeChar = null;
    _notifyChar = null;
  }
}
