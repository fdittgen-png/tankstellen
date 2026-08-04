// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;

import 'obd2_disconnect_quietly.dart';
import 'obd2_service.dart';

/// #3671 — default whole-attempt ceiling for one AUTOMATIC reconnect
/// dial. Generous: a legitimate Classic ladder (#3421, ≤23 s) + scan
/// window + ELM init retries fit comfortably; the field pathology it
/// exists for was a single liveReconnect attempt grinding 21 MINUTES
/// (connect trace t3, 2026-08-03) and pinning the main looper at ~95%
/// in the background until the OS killed the process for excessive CPU.
const Duration kDefaultDialBudget = Duration(seconds: 90);

/// Run [dial] under a whole-attempt [budget] (#3671).
///
/// `.timeout` cannot cancel the underlying dial (the connect stack has
/// no cancellation handle), so on overrun the zombie future is drained:
/// whatever service it eventually lands is released immediately via
/// [disconnectQuietly] — the single-link invariant holds, and the next
/// backoff-scheduled attempt finds the RFCOMM channel free once the
/// zombie dies on its own internal bounds. The thrown [TimeoutException]
/// reaches the supervisor's dial-fault path, where its stable runtime
/// type feeds the #3603 same-signature stand-down escalation.
///
/// Deliberately applied ONLY to the automatic reconnect dial policy —
/// interactive one-shot dials (picker, VIN reader, self-test) have a
/// user watching and their own UX timeouts, and a standing budget timer
/// under an in-flight interactive dial would break every
/// `pumpAndSettle` in their widget tests.
Future<Obd2Service?> dialWithBudget(
  Future<Obd2Service?> Function() dial, {
  Duration budget = kDefaultDialBudget,
}) {
  final pending = dial();
  return pending.timeout(budget, onTimeout: () {
    unawaited(pending.then<void>((late) async {
      if (late != null) await late.disconnectQuietly();
    }).catchError((Object e, StackTrace st) {
      // The zombie's own eventual failure is normal reconnect weather —
      // it was already accounted for as this attempt's budget miss.
      debugPrint('dialWithBudget: budget-overrun dial died on its own: $e');
    }));
    throw TimeoutException(
      'dial exceeded the ${budget.inSeconds}s whole-attempt budget (#3671)',
      budget,
    );
  });
}
