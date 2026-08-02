// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_clock.g.dart';

/// #3660 — the injectable clock seam (llmwiki page 26).
///
/// `DateTime.now()` in app code is untestable in the only way that
/// matters: it agrees with the calendar of the machine that runs it.
/// The sibling project's CI was green on the 28th and red on the 1st
/// with no commits in between — a test asserting the current month
/// name against a fake seeded in the month the test was written.
///
/// New code reads time through this seam (`ref.watch(appClockProvider)`
/// or an injected [AppClock]); tests override the provider with a
/// [FixedClock] pinned to a mid-month Wednesday so nothing lands on a
/// weekend, month boundary or DST change by accident.
///
/// The 242 pre-existing raw `DateTime.now()` call sites are
/// grandfathered by `test/lint/wall_clock_test.dart`, whose per-file
/// baseline may only ever shrink — migrating a file reduces its count;
/// new raw reads fail CI.
abstract interface class AppClock {
  DateTime now();
}

/// The production clock — the ONE place the app reads the wall clock
/// on purpose. Its single raw read is the seam's own exemption in the
/// wall-clock ratchet.
class SystemClock implements AppClock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// A clock frozen at [instant] — the test-side implementation. Prefer
/// a mid-month Wednesday (e.g. `DateTime(2026, 3, 11, 14, 30)`) so a
/// pinned test never sits on a weekend, month boundary or DST change
/// by accident.
class FixedClock implements AppClock {
  const FixedClock(this.instant);

  final DateTime instant;

  @override
  DateTime now() => instant;
}

/// App-wide clock. keepAlive — the clock has no state to dispose and
/// every layer may read it.
@Riverpod(keepAlive: true)
AppClock appClock(Ref ref) => const SystemClock();
