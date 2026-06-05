// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'adapters/smart_obd_adapter.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'bluetooth_obd2_transport.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm_byte_channel.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'negotiated_protocol_cache.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/'
    'supported_pids_cache.dart';
import '../../../../helpers/silence_error_logger.dart';

/// #2892 — a HEALTHY ELM chip on a SILENT bus (ignition off / ECU asleep).
///
/// Every AT command succeeds (ATZ → ATAT1 all OK, the chip itself is fine),
/// but the vehicle bus never answers: `ATDPN` → NO DATA (no protocol to
/// cache) and `0100` → NO DATA (PID discovery returns EMPTY). `connect()`
/// still returns `true` — protocol-resolve and PID discovery are best-effort
/// and swallow the no-answer — so the status chip shows green "connected" and
/// a trip would start GPS-only with zero telemetry and no explanation.
///
/// `busAnswered` is the cheap signal the coordinator gates on to surface the
/// existing localized "turn the ignition on" condition instead of silently
/// starting. It must be `false` HERE (protocol null AND zero PIDs) and `true`
/// the moment EITHER a protocol cached or a PID was discovered.
void main() {
  silenceErrorLoggerSpool();

  /// Build a service over the scripted channel, run its connect to completion
  /// under the virtual clock, and return whether connect() reported success.
  bool connect(FakeAsync async, _ScriptedChannel channel, Obd2Service service) {
    bool? connected;
    unawaited(
      service.connect(adapter: const SmartObdAdapter()).then((ok) {
        connected = ok;
      }),
    );
    async
      ..elapse(const Duration(seconds: 30))
      ..flushMicrotasks();
    return connected ?? false;
  }

  Obd2Service buildService(_ScriptedChannel channel) {
    final transport = BluetoothObd2Transport(channel);
    const fallbackKey = 'AA:BB:CC:DD:EE:FF';
    return Obd2Service(
      transport,
      protocolCache: NegotiatedProtocolCache(_InMemoryBox()),
      protocolCacheKey: fallbackKey,
      pidsCache: SupportedPidsCache(_InMemoryBox()),
      vehicleFallbackKey: fallbackKey,
    );
  }

  group('busAnswered reflects whether the vehicle bus replied (#2892)', () {
    test(
        'connect succeeds but busAnswered is FALSE when the bus is silent '
        '(ATDPN + 0100 both NO DATA, zero PIDs, no protocol)', () {
      fakeAsync((async) {
        // Every AT init command answers OK — the chip is healthy. Only the
        // BUS is dead: ATDPN + the VIN + 0100 all return NO DATA.
        final channel = _ScriptedChannel()
          ..script('ATZ\r', 'ELM327 v1.5\r>')
          ..script('ATE0\r', 'ATE0\rOK\r>')
          ..script('ATL0\r', 'OK\r>')
          ..script('ATH0\r', 'OK\r>')
          ..script('ATSP0\r', 'OK\r>')
          ..script('ATAT1\r', 'OK\r>')
          ..script('ATI\r', 'ELM327 v1.5\r>')
          // Bus silent: protocol can't be described → null → nothing cached.
          ..script('ATDPN\r', 'NO DATA\r>')
          ..script('0902\r', 'NO DATA\r>')
          // Bus silent: 0100 returns no bitmap → discovery finds zero PIDs.
          ..script('0100\r', 'NO DATA\r>');

        final service = buildService(channel);
        final connected = connect(async, channel, service);

        // #2891 invariant — connect() itself still SUCCEEDS (best-effort
        // resolve/discovery swallow the no-answer). We do not regress that.
        expect(connected, isTrue,
            reason: 'connect() must still succeed (best-effort resolve)');

        // The two no-answer signals the bug left silent.
        expect(service.debugSupportedPids, isEmpty,
            reason: '0100 NO DATA → zero supported PIDs');

        // The new signal: the bus never answered, so this trip would be a
        // degraded GPS-only recording → busAnswered must be FALSE.
        expect(service.busAnswered, isFalse,
            reason: 'protocol null AND zero PIDs → bus did not answer');
      });
    });

    test('busAnswered is TRUE when 0100 discovers at least one PID', () {
      fakeAsync((async) {
        final channel = _ScriptedChannel()
          ..script('ATZ\r', 'ELM327 v1.5\r>')
          ..script('ATE0\r', 'ATE0\rOK\r>')
          ..script('ATL0\r', 'OK\r>')
          ..script('ATH0\r', 'OK\r>')
          ..script('ATSP0\r', 'OK\r>')
          ..script('ATAT1\r', 'OK\r>')
          ..script('ATI\r', 'ELM327 v1.5\r>')
          // Protocol still unknown — but the bus DID answer 0100, so a real
          // trip is possible: busAnswered must trip on the PID set alone.
          ..script('ATDPN\r', 'NO DATA\r>')
          ..script('0902\r', 'NO DATA\r>')
          // 0100 bitmap: 0x0D (speed) set, no next-range flag → discovery stops.
          ..script('0100\r', '41 00 00 08 00 00\r>');

        final service = buildService(channel);
        final connected = connect(async, channel, service);

        expect(connected, isTrue);
        expect(service.debugSupportedPids, isNotEmpty,
            reason: '0100 answered a real bitmap');
        expect(service.busAnswered, isTrue,
            reason: 'a non-empty PID set means the bus answered');
      });
    });

    test('busAnswered is TRUE when ATDPN cached a protocol even with 0 PIDs',
        () {
      fakeAsync((async) {
        final channel = _ScriptedChannel()
          ..script('ATZ\r', 'ELM327 v1.5\r>')
          ..script('ATE0\r', 'ATE0\rOK\r>')
          ..script('ATL0\r', 'OK\r>')
          ..script('ATH0\r', 'OK\r>')
          ..script('ATSP0\r', 'OK\r>')
          ..script('ATAT1\r', 'OK\r>')
          ..script('ATI\r', 'ELM327 v1.5\r>')
          // Protocol negotiated + cached (bus answered ATDPN) even though
          // 0100 then went quiet → busAnswered must trip on the protocol.
          ..script('ATDPN\r', '6\r>')
          ..script('0902\r', 'NO DATA\r>')
          ..script('0100\r', 'NO DATA\r>');

        final service = buildService(channel);
        final connected = connect(async, channel, service);

        expect(connected, isTrue);
        expect(service.debugSupportedPids, isEmpty);
        expect(service.busAnswered, isTrue,
            reason: 'a cached protocol digit means the bus answered ATDPN');
      });
    });
  });
}

// ---------------------------------------------------------------------------
// Prompt scripted channel — each command answers immediately on a fresh timer
// so it composes with fakeAsync's virtual clock. Mirrors the transport test's
// _ScriptedChannel (#2889 harness), minus per-command delays we don't need.
// ---------------------------------------------------------------------------

class _ScriptedChannel implements ElmByteChannel {
  final Map<String, String> _replyByCommand = {};
  final StreamController<List<int>> _controller =
      StreamController<List<int>>.broadcast();
  final List<List<int>> _writes = [];
  bool _open = false;

  void script(String command, String reply) {
    _replyByCommand[command] = reply;
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
    final reply = _replyByCommand[command] ?? 'NO DATA\r>';
    // Emit on a fresh zero-delay timer so the reply lands inside the
    // fakeAsync clock without a real wall-clock wait.
    Timer(Duration.zero, () {
      if (!_controller.isClosed) _controller.add(reply.codeUnits);
    });
  }
}

// ---------------------------------------------------------------------------
// Tiny in-memory Box<String> — caches only call get/put/delete/clear.
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
