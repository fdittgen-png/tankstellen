import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_service.dart';
import 'package:tankstellen/features/consumption/data/obd2/obd2_transport.dart';

/// Tests for [Obd2Service.canFrameStream] (#1418).
///
/// Wires the existing [FakeObd2Transport] (extended in #1418 with
/// listen-mode hooks) into the service and pins:
///   * setup commands (`ATCRA 0E6` + `STMA`) on first listen
///   * teardown command (`STMP`) on cancel
///   * STN listen-mode line parsing into the decoder's
///     `(id, payload)` record
///   * malformed-line resilience (no exception, no emission)

const _initResponses = {
  'ATZ': 'ELM327 v1.5>',
  'ATE0': 'OK>',
  'ATL0': 'OK>',
  'ATH0': 'OK>',
  'ATSP0': 'OK>',
  // Setup commands respond with OK + prompt — same pattern as the
  // rest of the init sequence.
  'ATCRA 0E6': 'OK>',
  'STMA': 'OK>',
};

Future<({Obd2Service service, FakeObd2Transport transport})> _connected({
  Map<String, String>? extra,
}) async {
  final transport = FakeObd2Transport({..._initResponses, ...?extra});
  final service = Obd2Service(transport);
  await service.connect();
  // The service captures init commands too; tests typically only care
  // about commands sent AFTER connect, so reset the recorder here.
  transport.sentCommands.clear();
  return (service: service, transport: transport);
}

void main() {
  group('Obd2Service.canFrameStream — setup + teardown commands (#1418)', () {
    test(
        'first listen sends ATCRA 0E6 then STMA in that order — '
        'capability-gated by the provider, not enforced here',
        () async {
      final (:service, :transport) = await _connected();

      final stream = service.canFrameStream();
      // No listener attached yet → no commands sent. The broadcast
      // controller's onListen fires only after `listen` runs.
      expect(transport.sentCommands, isEmpty);

      final sub = stream.listen((_) {});
      // onListen runs setup() asynchronously — wait for the two
      // sendCommand awaits to land.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        transport.sentCommands,
        equals(['ATCRA 0E6', 'STMA']),
        reason: 'filter must be set BEFORE listen-mode start so the '
            'first emitted frame is already filtered to 0x0E6',
      );

      await sub.cancel();
    });

    test('cancel sends STMP via sendListenModeStop — never via sendCommand '
        '(the prompt is not coming back until listen-mode exits)',
        () async {
      final (:service, :transport) = await _connected();
      final sub = service.canFrameStream().listen((_) {});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();

      expect(transport.listenStopCommands, equals(['STMP']));
      // Critically: the regular sendCommand log should NOT also see
      // STMP — using sendCommand for STMP would deadlock on real
      // hardware because the adapter's listen-mode swallows `>`.
      expect(transport.sentCommands, isNot(contains('STMP')));
    });

    test(
        'broadcast stream — second listener does NOT re-send setup; '
        'first cancel does NOT send STMP while a second listener is '
        'still attached', () async {
      final (:service, :transport) = await _connected();
      final stream = service.canFrameStream();

      final s1 = stream.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      transport.sentCommands.clear();

      final s2 = stream.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      // No re-setup — the controller's onListen fires once.
      expect(transport.sentCommands, isEmpty);

      await s1.cancel();
      // Still one listener active → broadcast controller's onCancel
      // does NOT fire yet → no STMP.
      expect(transport.listenStopCommands, isEmpty);

      await s2.cancel();
      // Now last listener is gone → STMP fires.
      expect(transport.listenStopCommands, equals(['STMP']));
    });
  });

  group('Obd2Service.canFrameStream — line parsing (#1418)', () {
    test(
        'well-formed STN line "0E6 D 8 12 34 56 78 9A BC DE F0" parses '
        'into (0x0E6, [0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0])',
        () async {
      final (:service, :transport) = await _connected();
      final stream = service.canFrameStream();
      final received = <({int id, List<int> payload})>[];
      final sub = stream.listen(received.add);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      transport.pushListenLine('0E6 D 8 12 34 56 78 9A BC DE F0');
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.first.id, 0x0E6);
      expect(
        received.first.payload,
        equals([0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0]),
      );

      await sub.cancel();
    });

    test('canonical PSA fuel-level line "0E6 D 6 00 00 00 00 00 5A" '
        'parses to a 6-byte payload', () async {
      // 6-byte payload — the smallest length the decoder accepts
      // (bytes 4-5 must be readable). Pins the length-vs-byte-count
      // check.
      final (:service, :transport) = await _connected();
      final received = <({int id, List<int> payload})>[];
      final sub = service.canFrameStream().listen(received.add);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      transport.pushListenLine('0E6 D 6 00 00 00 00 00 5A');
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.first.payload, equals([0, 0, 0, 0, 0, 0x5A]));

      await sub.cancel();
    });

    test('multiple frames in sequence emit in order', () async {
      final (:service, :transport) = await _connected();
      final received = <List<int>>[];
      final sub = service.canFrameStream().listen(
            (frame) => received.add(frame.payload),
          );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      transport.pushListenLine('0E6 D 6 00 00 00 00 00 5A');
      transport.pushListenLine('0E6 D 6 00 00 00 00 00 64');
      transport.pushListenLine('0E6 D 6 00 00 00 00 00 00');
      await Future<void>.delayed(Duration.zero);

      expect(received, [
        [0, 0, 0, 0, 0, 0x5A],
        [0, 0, 0, 0, 0, 0x64],
        [0, 0, 0, 0, 0, 0x00],
      ]);

      await sub.cancel();
    });

    test('case-insensitive: lowercase hex tokens parse identically',
        () async {
      // Some STN firmwares emit lowercase hex; the parser must not
      // reject them.
      final (:service, :transport) = await _connected();
      final received = <int>[];
      final sub = service.canFrameStream().listen(
            (frame) => received.add(frame.payload.last),
          );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      transport.pushListenLine('0e6 d 6 00 00 00 00 00 5a');
      await Future<void>.delayed(Duration.zero);

      expect(received, [0x5A]);
      await sub.cancel();
    });
  });

  group('Obd2Service.canFrameStream — malformed input is silently dropped '
      '(#1418)', () {
    test('wrong frame id ("0B6 D 6 ...") drops without emission', () async {
      // Adjacent broadcast on a real PSA bus — must not match.
      final (:service, :transport) = await _connected();
      final received = <({int id, List<int> payload})>[];
      final sub = service.canFrameStream().listen(received.add);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      transport.pushListenLine('0B6 D 6 11 22 33 44 55 66');
      transport.pushListenLine('0E6 D 6 00 00 00 00 00 5A');
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.first.id, 0x0E6);
      await sub.cancel();
    });

    test('short payload (length=8 but only 4 byte tokens) drops; subsequent '
        'good frame still emits — the stream survives', () async {
      final (:service, :transport) = await _connected();
      final received = <int>[];
      final sub = service.canFrameStream().listen(
            (frame) => received.add(frame.payload.length),
          );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      transport.pushListenLine('0E6 D 8 12 34 56 78');
      transport.pushListenLine('0E6 D 6 00 00 00 00 00 5A');
      await Future<void>.delayed(Duration.zero);

      expect(received, [6]);
      await sub.cancel();
    });

    test('non-hex byte token ("0E6 D 6 00 00 00 00 00 ZZ") drops without '
        'crashing', () async {
      // ZZ is not parseable as hex → tryParse returns null → frame
      // dropped. The stream must not surface the error.
      final (:service, :transport) = await _connected();
      final received = <({int id, List<int> payload})>[];
      Object? streamError;
      final sub = service.canFrameStream().listen(
            received.add,
            onError: (Object e, StackTrace _) => streamError = e,
          );
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      transport.pushListenLine('0E6 D 6 00 00 00 00 00 ZZ');
      transport.pushListenLine('0E6 D 6 00 00 00 00 00 5A');
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.first.payload.last, 0x5A);
      expect(streamError, isNull);
      await sub.cancel();
    });

    test('empty / whitespace-only line drops silently', () async {
      final (:service, :transport) = await _connected();
      final received = <({int id, List<int> payload})>[];
      final sub = service.canFrameStream().listen(received.add);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      transport.pushListenLine('');
      transport.pushListenLine('   ');
      transport.pushListenLine('0E6 D 6 00 00 00 00 00 5A');
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      await sub.cancel();
    });

    test('missing "D" indicator ("0E6 X 6 ...") drops', () async {
      // Some adapter modes emit `T` (tx) or other indicators on the
      // same line; only `D` (data) is wanted.
      final (:service, :transport) = await _connected();
      final received = <({int id, List<int> payload})>[];
      final sub = service.canFrameStream().listen(received.add);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      transport.pushListenLine('0E6 X 6 00 00 00 00 00 5A');
      await Future<void>.delayed(Duration.zero);

      expect(received, isEmpty);
      await sub.cancel();
    });
  });
}
