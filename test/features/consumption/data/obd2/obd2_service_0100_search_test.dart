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

/// #3035/#3037 — the full connect path over the REAL [Obd2Service] +
/// transport + codec, driven by a channel that reproduces the ELM327 protocol
/// search.
///
/// #3037 GENEROUS-WINDOW rework: the first `0100` is sent ONCE with a generous
/// protocol-search read window (~15 s) and the in-progress search is RE-READ,
/// NOT re-sent (a re-send restarts the search). The slow-search case below
/// emits `SEARCHING...` then — several SIMULATED seconds later, still within
/// the window and ON THE SAME read — the real `41 00` bitmap, and asserts the
/// transport `write` for `0100` happened EXACTLY ONCE. A genuinely silent ECU
/// still resolves to `probedSilent` (regression guard); pure timeouts stay
/// `transient`.
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
      'SLOW-SEARCH (#3037): 0100 emits SEARCHING…, then ~7 s later (still in '
      'the generous window, SAME read) the real 41 00 bitmap → busAnswered, '
      'busProbe=answered, PIDs discovered — and 0100 is WRITTEN EXACTLY ONCE '
      '(never re-sent mid-search)', () {
    fakeAsync((async) {
      final channel = baseChannel()
        // Engine ON, ECU still searching: the adapter emits the SEARCHING
        // chatter chunk immediately, then ~7 s into the search — long past the
        // old 5 s ceiling but well within the 15 s generous window — the real
        // 41 00 frame terminated by the prompt, all on ONE read (one write).
        ..scriptDelayedChunks('0100\r', const [
          (Duration.zero, 'SEARCHING...\r'),
          (Duration(seconds: 7), '41 00 BE 3F A8 13\r>'),
        ]);

      final service = buildService(channel);
      final connected = connect(async, service);

      expect(connected, isTrue);
      expect(service.debugSupportedPids, isNotEmpty,
          reason: 'the generous window caught the late 41 00 SEARCHING hid');
      expect(service.busProbe, Obd2BusProbeResult.answered);
      expect(service.busAnswered, isTrue,
          reason: 'a slow-but-live car must NOT be told engine-off');
      // The CORE #3037 assertion: the search was RE-READ within one window,
      // never RE-SENT (a re-send would have restarted the protocol search).
      expect(channel.writeCountFor('0100\r'), 1,
          reason: '0100 must be sent ONCE — a mid-search re-send restarts the '
              'protocol search and loses the late 41 00 frame');
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
          reason: 'NO DATA IS the engine-off signature, detected in-window');
      expect(channel.writeCountFor('0100\r'), 1,
          reason: 'a definitive NO DATA settles in ONE send — no re-send');
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
      // #3037 — a read timeout means the search MAY still be in progress, so
      // 0100 is NOT re-sent (a re-send would restart the search).
      expect(channel.writeCountFor('0100\r'), 1,
          reason: 'a timed-out search is never re-sent (would restart search)');
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
  // #3037 — per-command timed CHUNK script: each (delay, chunk) is emitted
  // that many simulated seconds after the single write, all on ONE read.
  final Map<String, List<(Duration, String)>> _chunkScript = {};
  final Map<String, int> _cursor = {};
  final Map<String, int> _writeCount = {}; // #3037 — assert single-send.
  final Set<String> _silenced = {};
  final StreamController<List<int>> _controller =
      StreamController<List<int>>.broadcast();
  bool _open = false;

  void script(String command, List<String> replies) {
    _replies[command] = replies;
  }

  /// #3037 — script a SINGLE read answered by timed chunks: the channel emits
  /// each chunk `delay` after the write, so a late `41 00` lands within the
  /// generous window WITHOUT a re-send. The final chunk carries the `>`
  /// prompt that terminates the read.
  void scriptDelayedChunks(String command, List<(Duration, String)> chunks) {
    _chunkScript[command] = chunks;
  }

  /// #3037 — how many times [command] was WRITTEN to the channel. Lets a test
  /// assert `0100` was sent exactly once (re-read, not re-send mid-search).
  int writeCountFor(String command) => _writeCount[command] ?? 0;

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
    _writeCount[command] = (_writeCount[command] ?? 0) + 1;
    if (_silenced.contains(command)) return; // never reply → transport timeout
    final chunks = _chunkScript[command];
    if (chunks != null && chunks.isNotEmpty) {
      for (final (delay, chunk) in chunks) {
        Timer(delay, () {
          if (!_controller.isClosed) _controller.add(chunk.codeUnits);
        });
      }
      return;
    }
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
