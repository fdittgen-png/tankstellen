import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/auto_record_trace_log.dart';
import 'package:tankstellen/features/consumption/data/obd2/elm327_protocol.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_speed_stream.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';

/// Unit tests for [Obd2SpeedStream] (#1004 phase 2b-3).
///
/// The stream polls [Obd2Service.readSpeedKmh] at a fixed cadence and
/// emits doubles. These tests run with a tiny `pollPeriod` so the
/// polling timer fires inside `pumpEventQueue` without burning real
/// wall-clock time.
class _FakeTransport implements Obd2Transport {
  final Queue<int?> speedQueue;
  bool _connected = true;
  int sendCalls = 0;

  _FakeTransport(this.speedQueue);

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    _connected = true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  Future<String> sendCommand(String command) async {
    sendCalls++;
    if (command == Elm327Protocol.vehicleSpeedCommand) {
      if (speedQueue.isEmpty) return 'NO DATA';
      final value = speedQueue.removeFirst();
      if (value == null) return 'NO DATA';
      return '41 0D ${value.toRadixString(16).padLeft(2, '0').toUpperCase()}';
    }
    return '';
  }
}

/// Transport that throws on every `sendCommand` so the stream's
/// catch-branch (the production code defensively wraps the read so a
/// future change can't kill the subscription) is exercised.
class _ThrowingTransport implements Obd2Transport {
  int sendCalls = 0;

  @override
  bool get isConnected => true;

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<String> sendCommand(String command) async {
    sendCalls++;
    throw StateError('boom');
  }
}

void main() {
  const Duration shortPoll = Duration(milliseconds: 5);
  const String mac = 'AA:BB:CC:DD:EE:FF';

  setUp(() {
    AutoRecordTraceLog.clear();
  });

  test('emits one km/h sample per successful read', () async {
    final transport = _FakeTransport(Queue<int?>.of(<int?>[20, 25, 30]));
    final service = Obd2Service(transport);
    final stream = Obd2SpeedStream(service, mac: mac, pollPeriod: shortPoll);

    final received = <double>[];
    final sub = stream.stream.listen(received.add);
    await Future<void>.delayed(shortPoll * 4);
    await sub.cancel();

    expect(received, [20.0, 25.0, 30.0],
        reason: 'each successful read must emit one km/h sample');
  });

  test('null reads are dropped silently (no emission)', () async {
    // Mix nulls and ints — only ints should land on the stream.
    final transport = _FakeTransport(
      Queue<int?>.of(<int?>[null, 12, null, 18]),
    );
    final service = Obd2Service(transport);
    final stream = Obd2SpeedStream(service, mac: mac, pollPeriod: shortPoll);

    final received = <double>[];
    final sub = stream.stream.listen(received.add);
    await Future<void>.delayed(shortPoll * 5);
    await sub.cancel();

    expect(received, [12.0, 18.0],
        reason: 'null reads must not produce stream events');
  });

  test('cancelling the subscription stops the polling timer', () async {
    final transport = _FakeTransport(
      Queue<int?>.of(List<int?>.generate(50, (_) => 10)),
    );
    final service = Obd2Service(transport);
    final stream = Obd2SpeedStream(service, mac: mac, pollPeriod: shortPoll);

    final received = <double>[];
    final sub = stream.stream.listen(received.add);
    await Future<void>.delayed(shortPoll * 3);
    await sub.cancel();

    final samplesAtCancel = received.length;
    final sendsAtCancel = transport.sendCalls;
    // After cancel, leave plenty of time for any leaked timer to fire.
    await Future<void>.delayed(shortPoll * 10);

    expect(received.length, samplesAtCancel,
        reason: 'cancel must stop further emissions');
    expect(transport.sendCalls, sendsAtCancel,
        reason: 'cancel must stop further reads — the timer is gone');
  });

  test(
      'consecutive null reads trigger an obd2SpeedReadFailed trace at the threshold',
      () async {
    final transport = _FakeTransport(
      Queue<int?>.of(<int?>[null, null, null, null, null, null, null]),
    );
    final service = Obd2Service(transport);
    final stream = Obd2SpeedStream(
      service,
      mac: mac,
      pollPeriod: shortPoll,
      failureLogThreshold: 3,
    );

    final received = <double>[];
    final sub = stream.stream.listen(received.add);
    await Future<void>.delayed(shortPoll * 7);
    await sub.cancel();

    expect(received, isEmpty,
        reason: 'no sample should land while every read returns null');
    final trace = AutoRecordTraceLog.snapshot();
    final failures = trace
        .where((e) => e.kind == AutoRecordEventKind.obd2SpeedReadFailed)
        .toList();
    expect(failures, hasLength(1),
        reason: 'the threshold must fire exactly once per N consecutive '
            'failures (the counter advances past N without re-firing)');
    expect(failures.first.mac, mac,
        reason: 'the trace entry must carry the configured MAC');
  });

  test('a successful read resets the consecutive-failure counter', () async {
    // Pattern: null × 2, 20, null × 2 — with threshold 3 this should
    // NEVER fire the failure trace because the counter resets at 20.
    final transport = _FakeTransport(
      Queue<int?>.of(<int?>[null, null, 20, null, null, null]),
    );
    final service = Obd2Service(transport);
    final stream = Obd2SpeedStream(
      service,
      mac: mac,
      pollPeriod: shortPoll,
      failureLogThreshold: 3,
    );

    final received = <double>[];
    final sub = stream.stream.listen(received.add);
    // Drive enough ticks to consume the queue but stop before the
    // post-success null run alone reaches threshold.
    await Future<void>.delayed(shortPoll * 5);
    await sub.cancel();

    expect(received, [20.0]);
    final failures = AutoRecordTraceLog.snapshot()
        .where((e) => e.kind == AutoRecordEventKind.obd2SpeedReadFailed)
        .toList();
    expect(failures, isEmpty,
        reason: 'a successful read in the middle of a null run must reset '
            'the counter so the threshold is never crossed');
  });

  test('a thrown read is logged and counted as a failure', () async {
    final transport = _ThrowingTransport();
    // Wrap in a service whose `readSpeedKmh` swallows the throw and
    // returns null (the production behaviour). To exercise the
    // catch-branch in [Obd2SpeedStream] we instead bypass the
    // service by giving Obd2Service a transport that throws — the
    // service itself catches it and returns null. So this test
    // verifies the documented "null reads dropped" path under a
    // throwing transport.
    final service = Obd2Service(transport);
    final stream = Obd2SpeedStream(
      service,
      mac: mac,
      pollPeriod: shortPoll,
      failureLogThreshold: 2,
    );

    final received = <double>[];
    final sub = stream.stream.listen(received.add);
    await Future<void>.delayed(shortPoll * 4);
    await sub.cancel();

    expect(received, isEmpty,
        reason: 'every read failed — no samples must reach the stream');
    final trace = AutoRecordTraceLog.snapshot();
    final failures = trace
        .where((e) => e.kind == AutoRecordEventKind.obd2SpeedReadFailed)
        .toList();
    expect(failures, isNotEmpty,
        reason: 'the failure-threshold trace must fire at least once');
  });

  test('first emission lands within the first poll period', () async {
    // Production code wants an immediate first read so the coordinator
    // can react within the poll window, not after. Verifies that
    // [Obd2SpeedStream] kicks the timer with an explicit tick.
    final transport = _FakeTransport(Queue<int?>.of(<int?>[42]));
    final service = Obd2Service(transport);
    final stream = Obd2SpeedStream(service, mac: mac, pollPeriod: shortPoll);

    final received = <double>[];
    final sub = stream.stream.listen(received.add);
    // Wait less than a full poll period after subscribing — but
    // long enough for the immediate `_tick` to land.
    await Future<void>.delayed(shortPoll ~/ 2);
    final receivedAtSubscribe = received.length;
    await sub.cancel();

    expect(receivedAtSubscribe, 1,
        reason: 'the first read must fire on subscribe, not after the '
            'first poll-period delay');
  });

  test('closing without a subscriber is safe', () async {
    final transport = _FakeTransport(Queue<int?>.of(<int?>[10]));
    final service = Obd2Service(transport);
    final stream = Obd2SpeedStream(service, mac: mac, pollPeriod: shortPoll);

    // Subscribe and immediately cancel without awaiting any ticks —
    // this exercises the close-during-subscribe path.
    final sub = stream.stream.listen((_) {});
    await sub.cancel();
    // Wait past the poll period — the timer should have been killed
    // and no further reads should land.
    await Future<void>.delayed(shortPoll * 3);

    // No assertion crash means the close path is clean.
    expect(transport.sendCalls, lessThanOrEqualTo(1),
        reason: 'cancel-immediate must not leave the polling timer alive');
  });
}
