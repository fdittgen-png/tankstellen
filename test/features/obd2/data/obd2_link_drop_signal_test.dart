// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/obd2_link_drop_signal.dart';

void main() {
  group('Obd2LinkDropSignal (#3019 / Epic #3013 phase 3)', () {
    test('a subscriber receives the proactive drop event with transport + mac',
        () async {
      final events = <Obd2LinkDropEvent>[];
      final sub = Obd2LinkDropSignal.instance.drops.listen(events.add);

      Obd2LinkDropSignal.instance
          .notifyDrop(transportKind: 'classic', mac: 'AA:BB');
      // Broadcast stream delivers on the microtask queue.
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.single.transportKind, 'classic');
      expect(events.single.mac, 'AA:BB');
      await sub.cancel();
    });

    test('#3346 — the drop event carries the WHY (reason) when given',
        () async {
      final events = <Obd2LinkDropEvent>[];
      final sub = Obd2LinkDropSignal.instance.drops.listen(events.add);

      Obd2LinkDropSignal.instance.notifyDrop(
        transportKind: 'classic',
        mac: 'AA:BB',
        reason: 'classic-socket-error',
      );
      await Future<void>.delayed(Duration.zero);

      expect(events.single.reason, 'classic-socket-error');
      await sub.cancel();
    });

    test('#3346 — reason defaults to "unspecified" for older callers', () {
      const event = Obd2LinkDropEvent(transportKind: 'ble');
      expect(event.reason, 'unspecified');
    });

    test('multiple listeners both receive a drop (broadcast)', () async {
      var a = 0;
      var b = 0;
      final subA = Obd2LinkDropSignal.instance.drops.listen((_) => a++);
      final subB = Obd2LinkDropSignal.instance.drops.listen((_) => b++);

      Obd2LinkDropSignal.instance.notifyDrop(transportKind: 'ble');
      await Future<void>.delayed(Duration.zero);

      expect(a, 1);
      expect(b, 1);
      await subA.cancel();
      await subB.cancel();
    });

    test('notifyDrop never throws with no listeners attached', () {
      expect(
        () => Obd2LinkDropSignal.instance.notifyDrop(transportKind: 'ble'),
        returnsNormally,
      );
    });
  });
}
