// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT


import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/telemetry/collectors/breadcrumb_collector.dart';
import '../../../core/time/app_clock.dart';
import '../data/android_background_adapter_listener.dart';
// The wake() action lives in the supervisor library's part extension —
// importing the library brings it into scope.
import '../data/obd2_link_supervisor.dart';
import 'obd2_reconnect_provider.dart';

part 'obd2_engine_start_hint_provider.g.dart';

/// #3699 — turn Bluetooth ACL connects into reconnect wakes.
///
/// The stand-down escalation is correct while the car is parked (the
/// adapter sleeps; every probe is a doomed 23 s timeout), but before
/// this wiring NOTHING broke the hold at engine start with the phone
/// pocketed: `wake()` fired only on app resume and on GPS movement
/// during an already-running recording. Field shape (2026-08-11):
/// overnight misses escalated the hold past an hour and the morning
/// drive got no hands-free connect until the app was opened.
///
/// The phone linking to ANY Bluetooth device — in the car, the audio
/// system, at exactly ignition-on when the vLinker wakes from its 3 mA
/// sleep — is the cheapest engine-start signal Android offers without
/// new permissions. The native receiver already rate-limits to one hint
/// per 5 min; here we drop hints older than [staleness] (the native
/// ring can replay buffered hints on resubscribe) and nudge `wake()`,
/// which is a no-op in every state where waking is meaningless and an
/// immediate dial in `engineOff` / held-`reconnecting`.
@Riverpod(keepAlive: true)
void engineStartHintWake(Ref ref) {
  const staleness = Duration(minutes: 2);
  final sub = AndroidBackgroundAdapterListener.engineStartHints.listen((at) {
    final now = ref.read(appClockProvider).now();
    if (now.difference(at) > staleness) return;
    BreadcrumbCollector.add(
      'OBD2 engine-start hint',
      detail: 'BT ACL connect — waking reconnect',
    );
    ref.read(obd2ReconnectProvider.notifier).supervisor.wake();
  });
  ref.onDispose(sub.cancel);
}
