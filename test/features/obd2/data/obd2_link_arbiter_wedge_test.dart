// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_arbiter.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_drop_signal.dart';
import 'package:tankstellen/features/obd2/data/obd2_wedge_detector.dart';

import '../../../helpers/silence_error_logger.dart';

void main() {
  silenceErrorLoggerSpool();

  final arbiter = Obd2LinkArbiter.instance;
  final detector = Obd2WedgeDetector.instance;

  setUp(() {
    arbiter.resetForTest();
    detector.resetForTest();
  });

  tearDown(() {
    arbiter.resetForTest();
    detector.resetForTest();
  });

  void wedge() {
    for (var i = 0; i < 3; i++) {
      detector.noteClassicConnectOutcome(
          mac: 'AA:BB', ok: false, strategy: 'exhausted');
    }
    expect(detector.isWedged, isTrue);
  }

  Future<void> pumpDrop() async {
    Obd2LinkDropSignal.instance.notifyDrop(
      transportKind: 'classic',
      mac: 'AA:BB',
      reason: 'classic-socket-error',
    );
    // The drop signal is an async broadcast stream — let it deliver.
    await Future<void>.delayed(Duration.zero);
  }

  group('Obd2LinkArbiter × LinkWedged stand-down (#3422)', () {
    test('while wedged, a drop is NOT routed to the idle policy '
        '(no reconnect loop restart — the storm stays bounded)', () async {
      final drops = <Obd2LinkDropEvent>[];
      final reg = arbiter.registerIdlePolicy(
        onDrop: drops.add,
        onStandDown: () {},
      );
      addTearDown(reg.dispose);

      wedge();
      await pumpDrop();
      expect(drops, isEmpty);

      // Wedge cleared (a recovery rung / the adapter reappeared) → drops
      // flow to the idle policy again.
      detector.noteRecovered('rung-sdp-refresh');
      await pumpDrop();
      expect(drops, hasLength(1));
    });

    test('the wedge latching fires standDown on the idle policy, stopping '
        'an in-flight idle loop', () {
      var standDowns = 0;
      final reg = arbiter.registerIdlePolicy(
        onDrop: (_) {},
        onStandDown: () => standDowns++,
      );
      addTearDown(reg.dispose);

      wedge();
      expect(standDowns, 1);
    });

    test('while wedged, an autoRecord lease is refused (the loop stands '
        'down) but user-driven claims still pass', () {
      wedge();

      expect(
        arbiter.tryAcquire('auto-record', Obd2LinkPriority.autoRecord),
        isNull,
        reason: 'the auto-record loop must not keep dialling a wedged link',
      );

      final interactive =
          arbiter.tryAcquire('picker', Obd2LinkPriority.interactive);
      expect(interactive, isNotNull,
          reason: 'a user gesture is a sanctioned wedge escape hatch');
      interactive!.release();

      final recording =
          arbiter.tryAcquire('recording', Obd2LinkPriority.recording);
      expect(recording, isNotNull);
      recording!.release();
    });

    test('autoRecord leases are granted again once the wedge clears', () {
      wedge();
      detector.noteRecovered('rung-bt-cycle');
      final lease =
          arbiter.tryAcquire('auto-record', Obd2LinkPriority.autoRecord);
      expect(lease, isNotNull);
      lease!.release();
    });

    test('a lease HOLDER still receives its drop while wedged (its own '
        'transport-level recovery decides — only the idle fan-out is gated)',
        () async {
      wedge();
      final holderDrops = <Obd2LinkDropEvent>[];
      final lease = arbiter.tryAcquire(
        'recording',
        Obd2LinkPriority.recording,
        onDrop: holderDrops.add,
      );
      expect(lease, isNotNull);
      addTearDown(lease!.release);

      await pumpDrop();
      expect(holderDrops, hasLength(1));
    });
  });
}
