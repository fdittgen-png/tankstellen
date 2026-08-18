// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #3558 — phrase the whole-ladder connect timeout by HOW it fired.
///
/// A timer that fires within a small jitter of its [deadline] is the
/// genuine #3421 wedge signature (the platform never answered inside the
/// budget). One that fires far past it means the ISOLATE was not running —
/// Android froze the backgrounded process (no FGS, #3417) and the dial
/// simply stretched over the frozen window. The two need different words,
/// or a field trace reads like a native fault that never happened.
String classicConnectTimeoutMessage({
  required int budgetMs,
  required Duration deadline,
  required Duration actualElapsed,
}) {
  final overrun = actualElapsed - deadline;
  if (overrun > const Duration(seconds: 5)) {
    return 'classic connect timer fired ${overrun.inSeconds}s late '
        '(${actualElapsed.inSeconds}s wall for a ${deadline.inSeconds}s '
        'deadline) — app was suspended in background mid-dial (#3558), '
        'not a platform wedge';
  }
  return 'classic connect exceeded the whole-ladder budget '
      '(${budgetMs}ms) + grace — platform thread wedged (#3421)';
}
