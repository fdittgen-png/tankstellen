// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'classic_method_channel.dart';
import 'elm_byte_channel.dart';
import 'event_channel_cancel.dart';
import 'obd2_comm_diagnostics.dart';
import 'obd2_connection_errors.dart';
import '../../../../core/logging/error_logger.dart';

/// Standard Bluetooth Serial Port Profile UUID (#761). Every
/// Classic-SPP ELM327 adapter (vLinker FS, OBDLink LX, generic
/// Amazon dongles) uses this same Bluetooth-SIG assigned base.
const String sppServiceUuid = '00001101-0000-1000-8000-00805f9b34fb';

/// [ElmByteChannel] backed by the in-repo MethodChannel plugin
/// [Obd2ClassicMethodChannel] (#763).
///
/// The plugin owns the native [android.bluetooth.BluetoothSocket];
/// this Dart class just relays the two directions — `write` goes
/// down via MethodChannel, `incoming` comes up via EventChannel.
/// The existing [BluetoothObd2Transport] sits on top and handles
/// the ELM327 `>`-prompt framing.
class ClassicElmChannel implements ElmByteChannel {
  final String address;
  final String sppUuid;
  final Obd2ClassicMethodChannel _plugin;

  StreamSubscription<List<int>>? _subscription;
  final StreamController<List<int>> _incoming =
      StreamController<List<int>>.broadcast();
  bool _open = false;

  ClassicElmChannel({
    required this.address,
    Obd2ClassicMethodChannel? plugin,
    this.sppUuid = sppServiceUuid,
  }) : _plugin = plugin ?? const Obd2ClassicMethodChannel();

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  @override
  Future<void> open() async {
    if (_open) return;
    // #2466 — gated comm-diagnostics connect-lifecycle tee. A no-op
    // unless Feature.debugMode armed the collector; each call
    // early-returns on `!enabled`, so production pays one cached-bool
    // read per event.
    final diag = Obd2CommDiagnostics.instance;
    final connectSw = diag.enabled ? (Stopwatch()..start()) : null;
    if (diag.enabled) diag.noteConnectionEvent(attempt: true);

    final bool ok;
    try {
      ok = await _plugin.connect(address: address, uuid: sppUuid);
      // ignore: catch_no_st — rethrow-only: the original stack is preserved by rethrow
    } catch (e) {
      // A thrown platform error during the RFCOMM open (bonding,
      // permissions). Bin coarsely, then rethrow unchanged.
      if (diag.enabled) {
        diag.noteConnectionEvent(
          failureReason: _classifyClassicConnectFailure(e),
        );
      }
      rethrow;
    }
    if (!ok) {
      // The plugin reported a clean RFCOMM-open failure (false, not a
      // throw): the adapter is unbonded or out of range.
      if (diag.enabled) {
        diag.noteConnectionEvent(failureReason: 'rfcomm-open-fail');
      }
      throw StateError(
        'ClassicElmChannel: failed to open RFCOMM socket to $address '
        '(plugin returned false). Adapter may not be bonded or is out '
        'of range.',
      );
    }
    if (connectSw != null) {
      connectSw.stop();
      diag.noteConnectionEvent(
        success: true,
        timeToConnectMs: connectSw.elapsedMilliseconds,
      );
    }
    _subscription = _plugin.incoming.listen(
      (bytes) {
        // #2467 — tee the raw chunk into the gated comm-diagnostics
        // wire-framing counters. Double-gated (kReleaseMode +
        // collector.enabled), so production pays nothing.
        noteObd2Framing(bytes);
        _incoming.add(bytes);
      },
      onError: (Object e, StackTrace st) {
        // #2671 — a Classic-SPP drop raises a socket ERROR on the reader
        // stream (not stream `done`), so the `onDone` handler below never
        // runs. Mirror it here: clear `_open` the instant the link errors so
        // the very next `write()` short-circuits on the `!_open` guard
        // instead of dispatching into a dead socket and throwing the raw
        // `PlatformException(state, not connected)` the PidScheduler then
        // logged as an ERROR (4× in the field log).
        _open = false;
        // #2295 — forward the socket error onto the byte stream so the
        // transport's pending `sendCommand` completer fails IMMEDIATELY
        // (via `_failPending`) instead of waiting out the read timeout,
        // and log it so the drop is visible in release.
        if (!_incoming.isClosed) _incoming.addError(e, st);
        // #2466 — a Classic-SPP socket error is a RECOVERABLE OBD2/BT link
        // transient, not a local-storage fault. Tag it `other` to match
        // [FlutterBluePlusElmChannel]'s #2379 convention (the two channels
        // were inconsistent: BLE used `other`, Classic used `storage`).
        unawaited(errorLogger.log(ErrorLayer.other, e, st,
            context: const {'where': 'ClassicElmChannel notify error'}));
      },
      onDone: () {
        _open = false;
      },
    );
    _open = true;
  }

  @override
  Future<void> write(List<int> bytes) async {
    if (!_open) {
      // #2671 — the channel is not open: either never opened, or a drop
      // cleared `_open` (the `onError` / `onDone` handlers). Surface the
      // recoverable [Obd2DisconnectedException] so the drop detector's
      // `_isTypedDisconnect` routes a post-drop write through pause/reconnect
      // instead of letting a raw error reach the PidScheduler's error log.
      throw const Obd2DisconnectedException('ClassicElmChannel: not open');
    }
    // #2671 — a drop can land AFTER the `_open` guard passed but DURING the
    // native write (the in-flight-write race): the Kotlin side then throws
    // `PlatformException(state, not connected)`. Reclassify it as the
    // recoverable [Obd2DisconnectedException] — matching the #2524 precedent
    // in [BluetoothObd2Transport._sendRaw] — so the drop detector's
    // `_isTypedDisconnect` routes it through pause/reconnect instead of the
    // raw platform error being spooled as an ERROR trace. Also flip `_open`
    // so the next write short-circuits on the guard.
    try {
      await _plugin.write(bytes);
    } catch (e, st) {
      _open = false;
      debugPrint('ClassicElmChannel: write failed — reclassifying as a '
          'recoverable disconnect (#2671): $e\n$st');
      throw const Obd2DisconnectedException(
        'ClassicElmChannel: write failed — adapter not connected',
      );
    }
  }

  /// Bin a Classic-SPP `open()` throw into a stable, low-cardinality
  /// reason tag for the gated comm-diagnostics `failuresByReason` map
  /// (#2466). A clean `connect → false` is handled separately as
  /// `rfcomm-open-fail`; this covers the thrown-platform-error path
  /// (bonding / permission).
  static String _classifyClassicConnectFailure(Object e) {
    final msg = e.toString().toUpperCase();
    if (msg.contains('BOND') || msg.contains('PAIR')) return 'not-bonded';
    if (msg.contains('RFCOMM') || msg.contains('SOCKET')) {
      return 'rfcomm-open-fail';
    }
    return 'other';
  }

  @override
  Future<void> close() async {
    _open = false;
    await _subscription?.safeCancel();
    _subscription = null;
    try {
      await _plugin.disconnect();
    } catch (e, st) {
      // #2466 — recoverable OBD2/BT teardown, not local storage (#2379).
      // Was `storage`; now `other` to match [FlutterBluePlusElmChannel].
      unawaited(errorLogger.log(ErrorLayer.other, e, st, context: const {'where': 'ClassicElmChannel: disconnect error (ignored)'}));
    }
    await _incoming.close();
  }
}
