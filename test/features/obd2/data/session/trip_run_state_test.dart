// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:tankstellen/features/obd2/data/session/trip_run_state.dart';

/// #4068 — the terminal transition clears EVERY pause. Two hand-rolled
/// finalisers (grace-window expiry, engine-off) used to write the flags
/// independently; neither cleared the user pause, so a paused trip that
/// auto-finalised reported "stopped AND paused" to the tile and the
/// notification through `isPaused`.
void main() {
  test('end() clears a user pause — a finished trip is never also paused',
      () {
    final run = TripRunState()..begin();
    expect(run.pauseByUser(), isTrue);
    expect(run.isPaused, isTrue);

    run.end();

    expect(run.stopped, isTrue);
    expect(run.started, isFalse);
    expect(run.isPaused, isFalse);
    expect(run.paused, isFalse);
    expect(run.pausedDueToDrop, isFalse);
    expect(run.degradedGpsOnly, isFalse);
  });

  test('end() also clears a drop pause and the GPS-only degrade', () {
    final run = TripRunState()
      ..begin()
      ..setPausedDueToDrop(true)
      ..setDegradedGpsOnly(true);
    run.end();
    expect(run.isPaused, isFalse);
    expect(run.degradedGpsOnly, isFalse);
  });
}
