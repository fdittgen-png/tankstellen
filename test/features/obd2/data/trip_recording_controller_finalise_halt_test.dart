// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

/// #4329 — a trip the controller ends on its own (the #797 grace window,
/// the #3862 parked finalise) stops sampling at once, exactly as `stop()`
/// does. It used to end the run only, so the 250 ms emit loop went on
/// sampling a finished trip until someone pressed Stop.
///
/// fakeAsync owns the clock; no Hive box is open, so the finalise's
/// history write resolves to "no box" and the halt is what is under test.
library;

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/session/obd2_service.dart';
import 'package:tankstellen/features/obd2/data/session/trip_recording_controller.dart';
import 'package:tankstellen/features/obd2/data/transport/obd2_transport.dart';

import '../../../helpers/silence_error_logger.dart';

void main() {
  silenceErrorLoggerSpool();

  test('after a grace-window finalise the emit loop is gone: no emit in '
      '10 s', () {
    fakeAsync((async) {
      final transport = FakeObd2Transport(const {
        'ATZ': 'ELM327 v1.5>',
        'ATE0': 'OK>',
        'ATL0': 'OK>',
        'ATH0': 'OK>',
        'ATSP0': 'OK>',
      });
      final service = Obd2Service(transport);
      unawaited(service.connect());
      async.elapse(const Duration(seconds: 1));
      final ctl = TripRecordingController(
        service: service,
        pauseGraceWindow: const Duration(hours: 1),
        // #1904 — the drop is visible at once, so the grace window arms.
        silentReconnectWindow: Duration.zero,
      );
      unawaited(ctl.start());
      async.elapse(const Duration(seconds: 1));
      var emits = 0;
      final sub = ctl.live.listen((_) => emits++);
      async.elapse(const Duration(seconds: 1));
      expect(emits, greaterThan(0),
          reason: 'precondition: the loop emits while the trip records');

      ctl.debugTriggerDrop();
      unawaited(ctl.debugExpireGraceWindow());
      async.elapse(const Duration(milliseconds: 100));
      expect(ctl.currentState, TripRecordingControllerState.stopped);

      emits = 0;
      async.elapse(const Duration(seconds: 10));
      expect(emits, 0,
          reason: 'a finished trip must not be sampled — the 250 ms loop '
              'would have emitted 40 times');

      unawaited(sub.cancel());
      unawaited(ctl.stop());
      async.flushMicrotasks();
    });
  });
}
