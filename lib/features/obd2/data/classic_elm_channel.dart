// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'classic_connect_cooldown.dart';
import 'classic_method_channel.dart';
import 'elm_byte_channel.dart';
import 'obd2_platform_budgets.dart';
import '../../../../core/utils/event_channel_cancel.dart';
import 'obd2_comm_diagnostics.dart';
import 'obd2_link_drop_signal.dart';
import 'obd2_connect_trace.dart';
import 'obd2_connect_trace_log.dart';
import 'obd2_connection_errors.dart';
import 'obd2_wedge_detector.dart';
import '../../../core/logging/error_logger.dart';
import '../../../core/telemetry/collectors/breadcrumb_collector.dart';

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

  /// #3421 — whole-ladder budget (ms) threaded to the native `connect` so
  /// the RFCOMM ladder as a WHOLE is bounded (the #3348 watchdog only bounds
  /// each rung). Reduced by any post-close cooldown waited in [open], so the
  /// cooldown is counted inside the budget.
  final int connectBudgetMs;

  /// #3421 — extra Dart-side slack on top of [connectBudgetMs] for the
  /// defense-in-depth `.timeout` around `connectDetailed` (a wedged platform
  /// thread never runs the native budget bookkeeping). Injectable so tests
  /// don't wait the production 3 s.
  final Duration deadlineGrace;

  /// #3421 — per-mac post-close cooldown (the #3404 micro-lever). Injectable
  /// for tests; production shares [ClassicConnectCooldown.instance] so the
  /// gap survives across the short-lived channel objects a reconnect
  /// episode creates.
  final ClassicConnectCooldown _cooldown;

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
    this.connectBudgetMs = Obd2PlatformBudgets.classicConnectLadderBudgetMs,
    this.deadlineGrace = Obd2PlatformBudgets.classicConnectDartGrace,
    ClassicConnectCooldown? cooldown,
  })  : _plugin = plugin ?? const Obd2ClassicMethodChannel(),
        _cooldown = cooldown ?? ClassicConnectCooldown.instance;

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
    // #3421 — post-close cooldown (the #3404 micro-lever): a connect dialled
    // back-to-back after a close/drop lands on the adapter's still-held SPP
    // channel and burns a doomed ladder rung (or hangs, #3346). Wait out the
    // remainder of the 1.5 s gap since the last close/drop of THIS mac, and
    // count the wait INSIDE the whole-ladder budget by reducing what the
    // native side gets. Floor at 1 ms so a pathological budget/gap combo
    // still dispatches one bounded native attempt.
    final cooldownWaitedMs =
        (await _cooldown.awaitReadyToConnect(address)).inMilliseconds;
    final nativeBudgetMs = connectBudgetMs - cooldownWaitedMs < 1
        ? 1
        : connectBudgetMs - cooldownWaitedMs;
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
      // #3421 — the whole-ladder budget is threaded down natively AND
      // enforced here as defense-in-depth: even a WEDGED platform thread
      // (whose native budget bookkeeping never runs because the blocking
      // `BluetoothSocket.connect()` refuses to return — field traces t5/t8,
      // 4.7/16.8 min) can no longer hold this Dart caller past
      // budget + [deadlineGrace]. The TimeoutException takes the existing
      // thrown-failure classification below.
      final deadline = Duration(milliseconds: nativeBudgetMs) + deadlineGrace;
      connectResult = await _plugin
          .connectDetailed(
            address: address,
            uuid: sppUuid,
            budgetMs: nativeBudgetMs,
          )
          .timeout(
            deadline,
            onTimeout: () => throw TimeoutException(
              'classic connect exceeded the whole-ladder budget '
              '(${nativeBudgetMs}ms) + grace — platform thread wedged (#3421)',
              deadline,
            ),
          );
      // ignore: catch_no_st — rethrow-only: the original stack is preserved by rethrow
    } catch (e) {
      // #3422 — the Dart-side deadline (wedged platform thread) carries the
      // wedge signature; other throws (bonding/permissions) break the streak.
      noteClassicLadderOutcome(address,
          ok: false,
          strategy: e is TimeoutException ? 'connect-budget-timeout' : null);
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
      // #3422 — an `exhausted` / `budget-exhausted` ladder outcome feeds the
      // wedge streak (N=3 consecutive → LinkWedged, the bounded storm).
      noteClassicLadderOutcome(address,
          ok: false, strategy: connectResult.strategy);
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
    // #3422 — a successful connect resets the wedge streak / clears a wedge.
    noteClassicLadderOutcome(address,
        ok: true, strategy: connectResult.strategy);
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
        _signalDrop(reason: 'classic-socket-error'); // #3346
        // #2295 — forward the socket error onto the byte stream so the
        // transport's pending `sendCommand` completer fails IMMEDIATELY
        // (via `_failPending`) instead of waiting out the read timeout,
        // and log it so the drop is visible in release.
        if (!_incoming.isClosed) _incoming.addError(e, st);
        // #2466 — a Classic-SPP socket error is a RECOVERABLE OBD2/BT link
        // transient, not a local-storage fault. Tag it `other` to match
        // [FlutterBluePlusElmChannel]'s #2379 convention (the two channels
        // were inconsistent: BLE used `other`, Classic used `storage`).
        //
        // #3379 — but the COMMON case here is the EXPECTED end-of-session drop:
        // an RFCOMM reader surfaces a closed link as `bt socket closed,
        // read return: -1` on engine-off / drive-away / navigate-away. That is
        // not a fault — `_signalDrop` above already kicked the reconnect
        // controller (visible as the `obd2-reconnect: drop-received`
        // breadcrumb). ERROR-logging it on every session end buried real faults
        // (it was the SOLE trace in field log 064a9d4c). Breadcrumb the benign
        // drop; only an UNEXPECTED socket error still ERROR-logs.
        if (isBenignClassicLinkDrop(e)) {
          BreadcrumbCollector.add(
            'obd2: classic link dropped',
            detail: e.toString(),
          );
        } else {
          unawaited(errorLogger.log(ErrorLayer.other, e, st,
              context: const {'where': 'ClassicElmChannel notify error'}));
        }
      },
      onDone: () {
        _open = false;
        // #3019 — a clean socket `done` is also a drop (some stacks close the
        // reader instead of erroring it). Same proactive signal.
        _signalDrop(reason: 'classic-socket-done'); // #3346
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
      _signalDrop(reason: 'classic-write-failed'); // #3346
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
    // #3421 — the Dart-side whole-ladder deadline fired (wedged platform
    // thread). Its own bin, so the field export tells a budget overrun
    // apart from a clean rfcomm-open failure.
    if (e is TimeoutException) return 'connect-budget-timeout';
    final msg = e.toString().toUpperCase();
    if (msg.contains('BOND') || msg.contains('PAIR')) return 'not-bonded';
    if (msg.contains('RFCOMM') || msg.contains('SOCKET')) {
      return 'rfcomm-open-fail';
    }
    return 'other';
  }

  /// #3019 — emit the proactive Classic link-drop signal once per unexpected
  /// drop. A deliberate [close] (the `_closing` guard) is a normal teardown,
  /// not a drop, so it never reaches here. #3346 — [reason] tags WHICH edge
  /// noticed the drop (socket error / socket done / lazy write failure) so the
  /// reconnect-episode breadcrumb records it.
  void _signalDrop({required String reason}) {
    if (_closing || _dropSignalled) return;
    _dropSignalled = true;
    // #3421 — an unexpected drop counts as a socket close for the post-close
    // cooldown: the adapter's SPP channel is exactly as busy after a drop as
    // after a deliberate close, so the next connect must respect the gap.
    _cooldown.noteClosed(address);
    Obd2LinkDropSignal.instance
        .notifyDrop(transportKind: 'classic', mac: address, reason: reason);
  }

  @override
  Future<void> close() async {
    // #3421 — stamp the cooldown only when a LINK was actually torn down
    // (live, or dropped and signalled): a close() after a FAILED open has
    // nothing to cool down, and stamping it would needlessly delay the
    // transport's #2906 open-retry rungs.
    if (_open || _dropSignalled) _cooldown.noteClosed(address);
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

/// #3379 — whether [e] is the EXPECTED Classic-SPP link-drop signature, as
/// opposed to an unexpected fault worth an ERROR trace.
///
/// An RFCOMM reader stream surfaces a closed link as `bt socket closed,
/// read return: -1` (or `… not connected`) on every normal session end —
/// engine off, drive away, navigate off the trip screen, adapter unplugged.
/// That drop is already handled (the channel `_signalDrop`s it to the
/// reconnect controller), so it is breadcrumbed rather than ERROR-logged;
/// only a NON-matching socket error keeps the full error trace.
///
/// Pure + case-insensitive substring match — the message text is the only
/// stable signal the platform layer carries across OEM BT stacks.
bool isBenignClassicLinkDrop(Object e) {
  final m = e.toString().toLowerCase();
  return m.contains('socket closed') ||
      m.contains('read ret') || // "read ret: -1" and "read return: -1"
      m.contains('not connected');
}
