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
import 'package:tankstellen/features/consumption/data/obd2/'
    'supported_pids_probe.dart';
import '../../../../helpers/silence_error_logger.dart';

/// #3035 — the full connect path over the REAL [Obd2Service] + transport +
/// codec, driven by a channel that reproduces the ELM327 protocol search.
///
/// This is the end-to-end RED→GREEN: on master the first `0100` returning
/// `SEARCHING...` (then the real bitmap on the retry) left `busAnswered=false`
/// and `busProbe` had no notion of a transient — so the connect was wrongly
/// classified engine-off. With the resilient probe the bus is ANSWERED, PIDs
/// are discovered, and `busAnswered` is true. A genuinely silent ECU still
/// resolves to `probedSilent` (regression guard).
void main() {
  silenceErrorLoggerSpool();

  setUp(() => obd2ProbeBackoffScale = 0.0);
  tearDown(() => obd2ProbeBackoffScale = 1.0);

  bool connect(FakeAsync async, Obd2Service service) {
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

  Obd2Service buildService(_SeqChannel channel) {
    final transport = BluetoothObd2Transport(channel);
    const key = 'AA:BB:CC:DD:EE:FF';
    return Obd2Service(
      transport,
      protocolCache: NegotiatedProtocolCache(_InMemoryBox()),
      protocolCacheKey: key,
      pidsCache: SupportedPidsCache(_InMemoryBox()),
      vehicleFallbackKey: key,
    );
  }

  _SeqChannel baseChannel() => _SeqChannel()
    ..script('ATZ\r', ['ELM327 v1.5\r>'])
    ..script('ATE0\r', ['ATE0\rOK\r>'])
    ..script('ATL0\r', ['OK\r>'])
    ..script('ATH0\r', ['OK\r>'])
    ..script('ATSP0\r', ['OK\r>'])
    ..script('ATAT1\r', ['OK\r>'])
    ..script('ATI\r', ['ELM327 v1.5\r>'])
    ..script('ATDPN\r', ['NO DATA\r>'])
    ..script('0902\r', ['NO DATA\r>']);

  test(
      'SEARCHING-then-data: 0100 first replies SEARCHING…, the retry returns '
      'the bitmap → busAnswered=true, busProbe=answered, PIDs discovered',
      () {
    fakeAsync((async) {
      final channel = baseChannel()
        // Engine ON, ECU still searching: first read is SEARCHING chatter,
        // the second read delivers the real 41 00 bitmap.
        ..script('0100\r', ['SEARCHING...\r>', '41 00 BE 3F A8 13\r>']);

      final service = buildService(channel);
      final connected = connect(async, service);

      expect(connected, isTrue);
      expect(service.debugSupportedPids, isNotEmpty,
          reason: 'the retry discovered the PIDs SEARCHING first hid');
      expect(service.busProbe, Obd2BusProbeResult.answered);
      expect(service.busAnswered, isTrue,
          reason: 'a slow-but-live car must NOT be told engine-off');
    });
  });

  test(
      'genuine engine-off: every 0100 returns NO DATA → busAnswered=false, '
      'busProbe=probedSilent (real engine-off still detected)', () {
    fakeAsync((async) {
      final channel = baseChannel()..script('0100\r', ['NO DATA\r>']);

      final service = buildService(channel);
      final connected = connect(async, service);

      expect(connected, isTrue, reason: 'connect is best-effort, still true');
      expect(service.debugSupportedPids, isEmpty);
      expect(service.busAnswered, isFalse);
      expect(service.busProbe, Obd2BusProbeResult.probedSilent,
          reason: 'NO DATA through every retry IS the engine-off signature');
    });
  });

  test(
      'transient: every 0100 read elapses its budget → busProbe=transient, '
      'NOT probedSilent (a flaky link is never told engine-off)', () {
    fakeAsync((async) {
      // No 0100 script → the channel never replies → the transport read budget
      // elapses every attempt (TimeoutException), with no definitive-silent.
      final channel = baseChannel()..silenceCommand('0100\r');

      final service = buildService(channel);
      final connected = connect(async, service);

      expect(connected, isTrue);
      expect(service.busProbe, Obd2BusProbeResult.transient,
          reason: 'pure timeouts are indeterminate, not a confirmed silence');
    });
  });
}

// ---------------------------------------------------------------------------
// Sequenced scripted channel — each command can answer a DIFFERENT reply on
// successive sends (the ELM327 protocol-search behaviour the bug missed).
// A command with no script (or explicitly silenced) NEVER replies, so the
// transport's read budget elapses (a real TimeoutException). Composes with
// fakeAsync via a fresh zero-delay timer per reply.
// ---------------------------------------------------------------------------

class _SeqChannel implements ElmByteChannel {
  final Map<String, List<String>> _replies = {};
  final Map<String, int> _cursor = {};
  final Set<String> _silenced = {};
  final StreamController<List<int>> _controller =
      StreamController<List<int>>.broadcast();
  bool _open = false;

  void script(String command, List<String> replies) {
    _replies[command] = replies;
  }

  /// Mark a command as never-replying (the read budget elapses on every send).
  void silenceCommand(String command) => _silenced.add(command);

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
    final command = String.fromCharCodes(bytes);
    if (_silenced.contains(command)) return; // never reply → transport timeout
    final replies = _replies[command];
    if (replies == null || replies.isEmpty) return; // unknown → silent
    final i = _cursor[command] ?? 0;
    final reply = replies[i < replies.length ? i : replies.length - 1];
    _cursor[command] = i + 1;
    Timer(Duration.zero, () {
      if (!_controller.isClosed) _controller.add(reply.codeUnits);
    });
  }
}

class _InMemoryBox extends Fake implements Box<String> {
  final Map<String, String> store = {};

  @override
  String? get(dynamic key, {String? defaultValue}) =>
      store[key as String] ?? defaultValue;

  @override
  Future<void> put(dynamic key, String value) async => store[key as String] = value;

  @override
  Future<void> delete(dynamic key) async => store.remove(key as String);

  @override
  Future<int> clear() async {
    final n = store.length;
    store.clear();
    return n;
  }
}
