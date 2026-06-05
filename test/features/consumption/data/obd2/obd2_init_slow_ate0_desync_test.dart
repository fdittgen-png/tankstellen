// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'adapters/v_linker_fs_adapter.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'bluetooth_obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'negotiated_protocol_cache.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'supported_pids_cache.dart';
import '../../../../helpers/silence_error_logger.dart';

/// #2889 — a slow Classic-SPP clone (vLinker FS) answers `ATE0` in ~2.3 s.
/// `ATE0` is the SECOND init command, so the old single-command grace had
/// expired and it fell to the 1 s `trivialAt` budget → it TIMED OUT before
/// the reply landed. `_withConnectRetry` then re-sent `ATE0`; the device's
/// slow ORIGINAL reply arrived during that window and was matched to the
/// FOLLOWING command's completer → a permanent one-command desync. ATDPN
/// then parsed null (protocol unknown) and `0100` mis-framed, so PID
/// discovery returned EMPTY (0 PIDs) — the trip silently logged
/// "estimated" fuel.
///
/// These tests inject that exact fault (a delayed `ATE0` reply) and assert
/// the connect still reaches PID discovery with the correct protocol and
/// exactly ONE `ATE0` write. They FAIL on the pre-#2889 code and PASS after
/// the two-part fix (early-init timeout grace + post-timeout resync).
///
/// `fake_async` drives virtual time so the 2.3 s ATE0 latency costs no
/// wall-clock; the cache Boxes are tiny in-memory fakes (no Hive disk I/O,
/// which would not compose with the fake clock).
void main() {
  silenceErrorLoggerSpool();

  // Trim the connect-retry settle so the (legacy) retry path that the bug
  // depended on plays out promptly under the fake clock.
  setUp(() {
    Obd2Service.connectRetryDelay = const Duration(milliseconds: 50);
  });
  tearDown(() {
    Obd2Service.connectRetryDelay = const Duration(milliseconds: 150);
  });

  group('slow-ATE0 clone reaches PID discovery without desync (#2889)', () {
    test(
        'connect resolves protocol 6 + non-empty PIDs with a SINGLE ATE0 '
        'write, despite a 2.3 s ATE0 reply', () {
      fakeAsync((async) {
        final channel = _DelayedScriptedChannel()
          // ATZ is the first command → it already had the 2.5 s `wake`
          // grace pre-#2889, so 1.5 s passes on both old and new code.
          ..scriptDelayed('ATZ\r', 'ELM327 v2.3\r>',
              const Duration(milliseconds: 1483))
          // ATE0 is the SECOND command. Echo is STILL ON (the clone hasn't
          // applied it yet) and the reply lands at 2276 ms — past the old
          // 1 s `trivialAt` budget but inside the new 2.5 s early-init wake
          // grace. This single delayed reply is the whole bug.
          ..scriptDelayed('ATE0\r', 'ATE0\rOK\r>',
              const Duration(milliseconds: 2276))
          ..scriptDelayed('ATL0\r', 'OK\r>', Duration.zero)
          ..scriptDelayed('ATH0\r', 'OK\r>', Duration.zero)
          ..scriptDelayed('ATSP0\r', 'OK\r>', Duration.zero)
          ..scriptDelayed('ATAT1\r', 'OK\r>', Duration.zero)
          ..scriptDelayed('ATI\r', 'ELM327 v2.3\r>', Duration.zero)
          // ATDPN — negotiated protocol 6 (ISO 15765-4 CAN 11/500). Only
          // reads correctly if the link is still aligned at this point.
          ..scriptDelayed('ATDPN\r', '6\r>', Duration.zero)
          // VIN (0902) — this clone returns none, so prime() falls back to
          // the vehicleFallbackKey and runs the 01XX supported-PID scan.
          ..scriptDelayed('0902\r', 'NO DATA\r>', Duration.zero)
          // 0100 bitmap: BE 3F A8 13 → sets PID 0x0D (speed) + the
          // next-range flag (PID 0x20), so discovery walks on to 0120.
          ..scriptDelayed('0100\r', '41 00 BE 3F A8 13\r>', Duration.zero)
          // 0120 bitmap: all-zero → next-range flag clear → discovery stops.
          ..scriptDelayed('0120\r', '41 20 00 00 00 00\r>', Duration.zero);

        final transport = BluetoothObd2Transport(channel);
        final protocolBox = _InMemoryBox();
        final pidsBox = _InMemoryBox();
        const fallbackKey = 'AA:BB:CC:DD:EE:FF';
        final service = Obd2Service(
          transport,
          protocolCache: NegotiatedProtocolCache(protocolBox),
          protocolCacheKey: fallbackKey,
          pidsCache: SupportedPidsCache(pidsBox),
          vehicleFallbackKey: fallbackKey,
        );

        bool? connected;
        unawaited(
          service.connect(adapter: const VLinkerFsAdapter()).then((ok) {
            connected = ok;
          }),
        );

        // Advance virtual time well past every scripted delay + the
        // protocol search + retry settle.
        async.elapse(const Duration(seconds: 30));
        async.flushMicrotasks();

        expect(connected, isTrue, reason: 'connect must succeed');

        // The desync's downstream symptom was 0 PIDs / protocol unknown.
        expect(service.debugSupportedPids, isNotEmpty,
            reason: 'PID discovery must not return empty');
        expect(service.isPidSupported(0x0D), isTrue,
            reason: 'PID 0x0D (speed) is set in the 0100 bitmap');

        // Protocol resolved + cached as 6 — only possible if ATDPN matched
        // its own reply (alignment held through the init burst).
        expect(protocolBox.store[fallbackKey], '6',
            reason: 'ATDPN must resolve + cache protocol 6');

        // The root assertion: no retry → exactly ONE ATE0 write. On the
        // pre-#2889 code the trivialAt timeout fired and `_withConnectRetry`
        // re-sent ATE0, so this was 2.
        final ate0Writes = channel.writesAsStrings
            .where((w) => w.trim() == 'ATE0')
            .length;
        expect(ate0Writes, 1,
            reason: 'ATE0 must not time out → no retry → exactly one write');
      });
    });
  });

  group('transport drops a stale late reply instead of desyncing (#2889)', () {
    test(
        'a reply that lands after its command times out is NOT matched to '
        'the next command', () {
      fakeAsync((async) {
        // Drive the transport directly with a tiny read ceiling so the
        // first command times out fast, then its late reply lands.
        final channel = _DelayedScriptedChannel()
          // First AT echo: reply lands AFTER the (clamped) read budget.
          ..scriptDelayed('ATE0\r', 'ATE0\rOK\r>',
              const Duration(milliseconds: 400))
          // Second AT echo: a prompt, correct reply.
          ..scriptDelayed('ATL0\r', 'OK\r>',
              const Duration(milliseconds: 10));

        // Clamp the read ceiling to 200 ms so EVERY class (incl. the
        // early-init wake grace) is capped below the 400 ms ATE0 delay —
        // this isolates the resync latch, independent of the timeout class.
        final transport = BluetoothObd2Transport(
          channel,
          readTimeout: const Duration(milliseconds: 200),
        );

        unawaited(transport.connect());
        async.flushMicrotasks();

        // First command times out (reply only at 400 ms > 200 ms ceiling).
        Object? firstError;
        unawaited(
          transport.sendCommand('ATE0\r').catchError((Object e) {
            firstError = e;
            return '';
          }),
        );
        async.elapse(const Duration(milliseconds: 250));
        expect(firstError, isA<TimeoutException>(),
            reason: 'ATE0 must time out at the 200 ms ceiling');

        // The stale ATE0 reply lands at 400 ms — it must be SWALLOWED, not
        // handed to the next command.
        String? secondReply;
        unawaited(
          transport.sendCommand('ATL0\r').then((r) => secondReply = r),
        );
        // Push past both the stale ATE0 reply (400 ms total) and the fresh
        // ATL0 reply (10 ms after its write).
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        expect(secondReply, isNotNull,
            reason: 'ATL0 must receive a reply');
        expect(secondReply!.trim(), 'OK',
            reason: 'ATL0 must get ITS OWN reply (OK), not the stale '
                'ATE0 reply — the desync the latch prevents');
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Delayed scripted channel — like the transport test's _ScriptedChannel, but
// each scripted reply is emitted after a per-command Duration so a slow clone
// can be faithfully reproduced (#2889).
// ---------------------------------------------------------------------------

class _DelayedScriptedChannel implements ElmByteChannel {
  final Map<String, String> _replyByCommand = {};
  final Map<String, Duration> _delayByCommand = {};
  final StreamController<List<int>> _controller =
      StreamController<List<int>>.broadcast();
  final List<List<int>> _writes = [];
  bool _open = false;

  void scriptDelayed(String command, String reply, Duration delay) {
    _replyByCommand[command] = reply;
    _delayByCommand[command] = delay;
  }

  List<String> get writesAsStrings =>
      _writes.map((w) => String.fromCharCodes(w)).toList();

  @override
  Future<void> open() async => _open = true;

  @override
  Future<void> close() async => _open = false;

  @override
  bool get isOpen => _open;

  @override
  Stream<List<int>> get incoming => _controller.stream;

  @override
  Future<void> write(List<int> bytes) async {
    _writes.add(bytes);
    final command = String.fromCharCodes(bytes);
    final reply = _replyByCommand[command];
    if (reply == null) {
      // Unknown command — answer NO DATA promptly so nothing hangs.
      _controller.add('NO DATA>'.codeUnits);
      return;
    }
    final delay = _delayByCommand[command] ?? Duration.zero;
    // Emit after the scripted delay on a fresh timer so it composes with
    // fakeAsync's virtual clock (no real wall-clock wait).
    Timer(delay, () {
      if (!_controller.isClosed) _controller.add(reply.codeUnits);
    });
  }
}

// ---------------------------------------------------------------------------
// Tiny in-memory Box<String> — the caches only call get/put/delete/clear, so
// this avoids Hive's real-disk async (which would not compose with the fake
// clock) while behaving exactly like a Box for those four operations.
// ---------------------------------------------------------------------------

class _InMemoryBox extends Fake implements Box<String> {
  final Map<String, String> store = {};

  @override
  String? get(dynamic key, {String? defaultValue}) =>
      store[key as String] ?? defaultValue;

  @override
  Future<void> put(dynamic key, String value) async {
    store[key as String] = value;
  }

  @override
  Future<void> delete(dynamic key) async {
    store.remove(key as String);
  }

  @override
  Future<int> clear() async {
    final n = store.length;
    store.clear();
    return n;
  }
}
