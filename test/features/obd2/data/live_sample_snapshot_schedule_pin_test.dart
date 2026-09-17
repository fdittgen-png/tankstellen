// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/session/live_sample_snapshot.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';
import 'package:tankstellen/features/obd2/domain/pid_scheduler.dart';

/// #4159 — the RESOLVED schedule, pinned before the PID vocabulary moves.
///
/// `subscribeAllTiers` decides, per signal, whether it is subscribed at
/// all (which support gate it asks, strict or optimistic) and with what
/// cadence (hz, priority, tier). Moving the PID numbers out of the session
/// layer must not change a single row of that decision. The existing
/// subscription test only asserts set membership after a timed run; this
/// file pins the exact ORDERED table the scheduler receives and the exact
/// ordered gate calls the service answers, with no timers involved.
///
/// Literal command strings on purpose: the pin must not borrow the
/// vocabulary it guards.

class _StubTransport implements Obd2Transport {
  @override
  bool get isConnected => true;
  @override
  Future<void> connect() async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<String> sendCommand(String command) async => 'NO DATA';
}

/// A real [Obd2Service] (real resolver, real probation) that logs every
/// support-gate question it is asked, in order.
class _GateLogService extends Obd2Service {
  _GateLogService(Set<int>? supported) : super(_StubTransport()) {
    if (supported != null) debugSetSupportedPids(supported);
  }

  final List<String> gates = <String>[];
  bool logging = false;

  String _hex(int pid) =>
      '0x${pid.toRadixString(16).toUpperCase().padLeft(2, '0')}';

  @override
  bool isPidSupported(int pid) {
    final v = super.isPidSupported(pid);
    if (logging) gates.add('opt(${_hex(pid)})=$v');
    return v;
  }

  @override
  bool isPidKnownSupported(int pid) {
    final v = super.isPidKnownSupported(pid);
    if (logging) gates.add('strict(${_hex(pid)})=$v');
    return v;
  }
}

typedef _Row = (String command, double hz, PidPriority priority, PidTier tier);

/// Records every subscription in call order; never starts a timer.
class _Rec extends PidScheduler {
  _Rec() : super(transport: (_) async => 'NO DATA');

  final List<_Row> rows = <_Row>[];

  @override
  void subscribe(
    String command,
    ScheduledPid config,
    void Function(String response) onResult,
  ) {
    rows.add((command, config.hz, config.priority, config.tier));
  }
}

({List<_Row> rows, List<String> gates}) _resolve(_GateLogService service) {
  final scheduler = _Rec();
  final snapshot = LiveSampleSnapshot(
    service: service,
    onHighPriorityParse: (_) {},
    onSpeedSample: (_) {},
  );
  service.logging = true;
  snapshot.subscribeAllTiers(scheduler);
  service.logging = false;
  return (rows: scheduler.rows, gates: List.of(service.gates));
}

const _h = PidPriority.high;
const _m = PidPriority.medium;
const _l = PidPriority.low;
const _dyn = PidTier.dynamics;
const _mix = PidTier.mixture;
const _slow = PidTier.slowCorrection;
const _therm = PidTier.thermalContext;

/// The legacy table (everything before the precision families), each row
/// paired with the PID its optimistic gate asks about (null = core, no
/// gate).
const List<(_Row, int?)> _legacy = [
  (('010C\r', 5.0, _h, _dyn), null),
  (('010D\r', 5.0, _h, _dyn), null),
  (('0111\r', 5.0, _h, _dyn), null),
  (('0149\r', 5.0, _h, _dyn), 0x49),
  (('014A\r', 5.0, _h, _dyn), 0x4A),
  (('014B\r', 5.0, _h, _dyn), 0x4B),
  (('015E\r', 5.0, _h, _dyn), 0x5E),
  (('0110\r', 5.0, _h, _dyn), 0x10),
  (('010B\r', 5.0, _h, _dyn), 0x0B),
  (('0144\r', 2.0, _m, _mix), 0x44),
  (('0104\r', 2.0, _m, _mix), null),
  (('0143\r', 2.0, _m, _mix), 0x43),
  (('0106\r', 0.5, _m, _slow), null),
  (('0107\r', 0.5, _m, _slow), null),
  (('0108\r', 0.5, _m, _slow), 0x08),
  (('0109\r', 0.5, _m, _slow), 0x09),
  (('010F\r', 0.5, _m, _slow), null),
  (('010E\r', 0.5, _m, _slow), 0x0E),
  (('0133\r', 0.5, _m, _slow), 0x33),
  (('0105\r', 0.1, _l, _therm), null),
  (('012F\r', 0.1, _l, _therm), null),
  (('015C\r', 0.1, _l, _therm), 0x5C),
  (('0146\r', 0.1, _l, _therm), 0x46),
];

const _wideband = [
  0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, //
  0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B,
];

String _hex(int pid) =>
    '0x${pid.toRadixString(16).toUpperCase().padLeft(2, '0')}';

/// Every legacy optional gate call in order, answering true except for
/// the PIDs in [parked].
List<String> _legacyGates({Set<int> parked = const {}}) => [
      for (final (_, pid) in _legacy)
        if (pid != null) 'opt(${_hex(pid)})=${!parked.contains(pid)}',
    ];

/// The precision gate calls in their fixed order, answering true exactly
/// for [claimed].
List<String> _precisionGates(Set<int> claimed) => [
      for (final pid in [..._wideband, 0x66, 0x9D, 0xA2, 0x52])
        'strict(${_hex(pid)})=${claimed.contains(pid)}',
    ];

List<_Row> _legacyRows({Set<String> without = const {}}) => [
      for (final (row, _) in _legacy)
        if (!without.contains(row.$1)) row,
    ];

void main() {
  test('unresolved clone: full legacy table, zero precision rows', () {
    final r = _resolve(_GateLogService(null));
    expect(r.rows, _legacyRows());
    expect(r.gates, [..._legacyGates(), ..._precisionGates(const {})]);
  });

  test('basic car {0C,0D,04,11}: full legacy table (optimistic), '
      'zero precision rows', () {
    final r = _resolve(_GateLogService({0x0C, 0x0D, 0x04, 0x11}));
    expect(r.rows, _legacyRows());
    expect(r.gates, [..._legacyGates(), ..._precisionGates(const {})]);
  });

  test('fully-capable car: legacy table then the precision rows in '
      'wideband → 0x66 → 0x9D → 0xA2 → 0x52 order', () {
    const claimed = {0x24, 0x2A, 0x34, 0x66, 0x9D, 0xA2, 0x52};
    final r = _resolve(_GateLogService({
      0x0C, 0x0D, 0x11, 0x04, 0x0F, 0x05, 0x06, 0x07, 0x2F, //
      0x10, 0x0B, 0x5E, 0x44, 0x33, 0x49, 0x4A, 0x4B, 0x43, 0x08, 0x09,
      0x5C, 0x46, 0x0E, ...claimed,
    }));
    expect(r.rows, [
      ..._legacyRows(),
      ('0124\r', 2.0, _m, _mix),
      ('012A\r', 2.0, _m, _mix),
      ('0134\r', 2.0, _m, _mix),
      ('0166\r', 5.0, _h, _dyn),
      ('019D\r', 5.0, _h, _dyn),
      ('01A2\r', 5.0, _h, _dyn),
      ('0152\r', 0.5, _m, _slow),
    ]);
    expect(r.gates, [..._legacyGates(), ..._precisionGates(claimed)]);
  });

  test('0x10 parked by runtime probation (3× real NO DATA) drops only '
      'the MAF row', () async {
    final service = _GateLogService({0x0C, 0x0D, 0x04, 0x11});
    for (var i = 0; i < 3; i++) {
      expect(await service.readMafGramsPerSecond(), isNull);
    }
    final r = _resolve(service);
    expect(r.rows, _legacyRows(without: {'0110\r'}));
    expect(r.gates, [
      ..._legacyGates(parked: {0x10}),
      ..._precisionGates(const {}),
    ]);
  });
}
