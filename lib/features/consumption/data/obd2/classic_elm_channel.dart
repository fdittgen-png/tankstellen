// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'classic_method_channel.dart';
import 'elm_byte_channel.dart';
import '../../../../core/utils/event_channel_cancel.dart';
import 'obd2_comm_diagnostics.dart';
import 'obd2_link_drop_signal.dart';
import 'obd2_connect_trace.dart';
import 'obd2_connect_trace_log.dart';
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

  /// #3179 — NOT final: [close] closes the broadcast controller, and the
  /// transport's open-retry loop (plus any reconnect) calls `close()` +
  /// `open()` on the SAME channel instance, so [open] must be able to
  /// recreate it. With a `final` controller the "recovered" link was a
  /// zombie: every socket byte hit the #2953 `isClosed` guard and was
  /// silently dropped, so every reply timed out.
  StreamController<List<int>> _incoming =
      StreamController<List<int>>.broadcast();
  bool _open = false;

  /// #3019 — set while a DELIBERATE [close] is tearing the channel down, so
  /// the resulting socket `done` / `error` edge is NOT misread as an
  /// unexpected drop (which would spuriously kick the reconnect loop after a
  /// normal disconnect).
  bool _closing = false;

  /// #3019 — fire the proactive link-drop signal exactly once per UNEXPECTED
  /// drop. Suppressed during a deliberate [close] (a normal teardown is not a
  /// drop).
  bool _dropSignalled = false;

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
    // #3179 — make the channel safely RE-openable. The transport's open-retry
    // loop (#2906) and the reconnect path call close() + open() on the SAME
    // instance; close() closed `_incoming` and latched `_closing`, and
    // neither was ever undone — so the "recovered" link was a zombie (bytes
    // silently dropped by the #2953 guard, the proactive drop signal
    // suppressed forever). Reset both latches and, when a prior close()
    // closed the controller, recreate it before connecting.
    _closing = false;
    _dropSignalled = false;
    if (_incoming.isClosed) {
      _incoming = StreamController<List<int>>.broadcast();
    }
    // #2466 — gated comm-diagnostics connect-lifecycle tee. A no-op
    // unless Feature.debugMode armed the collector; each call
    // early-returns on `!enabled`, so production pays one cached-bool
    // read per event.
    final diag = Obd2CommDiagnostics.instance;
    final connectSw = diag.enabled ? (Stopwatch()..start()) : null;
    if (diag.enabled) diag.noteConnectionEvent(attempt: true);

    final ClassicConnectResult connectResult;
    try {
      // #2969 — connectDetailed surfaces WHICH RFCOMM strategy won / the
      // terminal failure mode + the last native IOException, so the connect
      // trace carries the native cause (not just "rfcomm open returned false").
      connectResult = await _plugin.connectDetailed(
        address: address,
        uuid: sppUuid,
      );
      // ignore: catch_no_st — rethrow-only: the original stack is preserved by rethrow
    } catch (e) {
      // A thrown platform error during the RFCOMM open (bonding,
      // permissions). Bin coarsely, then rethrow unchanged.
      if (diag.enabled) {
        diag.noteConnectionEvent(
          failureReason: _classifyClassicConnectFailure(e),
        );
      }
      // #2969 — stamp the RFCOMM-open outcome on the active connect trace
      // (first-wins) so a thrown Classic-open failure is captured even with
      // developer mode off.
      Obd2ConnectTraceLog.stampOpenFailure(
          Obd2ConnectOutcome.rfcommOpenFail, e.toString());
      rethrow;
    }
    if (!connectResult.ok) {
      // The plugin reported a clean RFCOMM-open failure (false, not a
      // throw): the adapter is unbonded or out of range.
      if (diag.enabled) {
        diag.noteConnectionEvent(failureReason: 'rfcomm-open-fail');
      }
      // #2969 — the clean rfcomm-open failure is the dominant Classic mode;
      // stamp it on the trace (first-wins) so the user sees rfcommOpenFail, not
      // a generic ignition-off. The native strategy + last IOException
      // (correction 5 — the Kotlin Map return shape) land in [detail].
      final detail = 'rfcomm open failed '
          '(strategy: ${connectResult.strategy ?? 'unknown'}'
          '${connectResult.error != null ? ', error: ${connectResult.error}' : ''})';
      Obd2ConnectTraceLog.stampOpenFailure(
          Obd2ConnectOutcome.rfcommOpenFail, detail);
      // #2745 — this was a raw `StateError`, which the connect flow logged as
      // an `[unknown]` ERROR trace (field trace #6) even though it is an
      // EXPECTED, user-surfaced "adapter not reachable" condition (the dongle
      // is unbonded or out of range). Raise the TYPED [Obd2AdapterUnresponsive]
      // instead so the connect flow treats it as the breadcrumb-level user
      // condition it already handles for the BLE init path — not an ERROR.
      throw const Obd2AdapterUnresponsive(
        'Adapter did not answer — turn the ignition on and retry',
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
        // #2953 — guard the late add. A native Classic-SPP byte can land
        // on this EventChannel listener AFTER `close()` ran (`close()`
        // cancels `_subscription` then closes `_incoming`, but a chunk
        // already queued on the event loop still reaches this callback):
        // the field log #30 spooled `Bad state: Cannot add new events
        // after calling close` during the engine-off connect/disconnect
        // churn. The `addError` path below is already `isClosed`-guarded
        // (#2295); mirror it here. Per the #2295 contract we do NOT tear
        // the bridge early — late GOOD bytes still flow until `close()`,
        // and only a post-close stray is dropped silently.
        if (!_incoming.isClosed) _incoming.add(bytes);
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
        // #3019 / Epic #3013 phase 3 — PROACTIVE Classic-drop detection. The
        // socket error fires HERE the instant the link dies; emit the
        // transport-agnostic link-drop signal so the trip-INDEPENDENT
        // reconnect controller starts its bounded backoff loop immediately
        // rather than the drop being discovered only LAZILY on the next
        // `write()` (which never comes when idle / between trips). The in-trip
        // typed-disconnect handling below is unchanged.
        _signalDrop();
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
        // #3019 — a clean socket `done` is also a drop (some stacks close the
        // reader instead of erroring it). Same proactive signal.
        _signalDrop();
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
      // #3183 — the LAZY drop-discovery path: a drop noticed on write (no
      // reader error/done edge fired, or the native side never surfaced one)
      // must ALSO emit the #3019 proactive link-drop signal, or the
      // trip-independent reconnect controller stays asleep until the next
      // write that never comes. The reader onError/onDone paths already do.
      _signalDrop();
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

  /// #3019 — emit the proactive Classic link-drop signal once per unexpected
  /// drop. A deliberate [close] (the `_closing` guard) is a normal teardown,
  /// not a drop, so it never reaches here.
  void _signalDrop() {
    if (_closing || _dropSignalled) return;
    _dropSignalled = true;
    Obd2LinkDropSignal.instance
        .notifyDrop(transportKind: 'classic', mac: address);
  }

  @override
  Future<void> close() async {
    _closing = true;
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
