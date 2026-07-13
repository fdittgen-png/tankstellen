// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #3575 — session-wide "no vehicle protocol" livelock detection for the
/// [PidScheduler].
///
/// When the adapter connects before the ignition is on, the ELM's first
/// auto protocol search fails and the chip answers every later command
/// instantly with `UNABLE TO CONNECT` / `STOPPED` — and the polling
/// cadence keeps interrupting any restarted search, so it can never
/// converge (field trip 2026-07-13: 21 minutes of 100% err at ~151 ms
/// per reply, 0% completeness). These replies arrive as SUCCESSFUL
/// transport round-trips, so the scheduler's per-PID failure streaks
/// never see them; this tracker classifies the CONTENT instead.
///
/// After [threshold] consecutive no-protocol replies it fires
/// [onEpisode] once and resets, so with the owner's throttle a
/// persistent condition re-signals rather than storms. The owner (the
/// recording controller) pauses polling and re-runs protocol discovery.
class PidNoProtocolEpisode {
  PidNoProtocolEpisode({required this.threshold, this.onEpisode});

  /// Consecutive no-protocol replies before [onEpisode] fires — ≈4–8 s
  /// at the 5–10 Hz effective cadence: fast enough to rescue a trip,
  /// slow enough to ignore a lone search hiccup.
  final int threshold;

  final void Function()? onEpisode;

  int _streak = 0;

  /// The ELM's "no vehicle protocol" reply family. NO DATA is
  /// deliberately NOT here — an alive bus NO-DATAs unsupported PIDs.
  static bool isNoProtocolReply(String response) {
    final u = response.toUpperCase();
    return u.contains('UNABLE TO CONNECT') ||
        u.contains('STOPPED') ||
        u.contains('BUS INIT');
  }

  /// Feed one successful reply's raw content.
  void note(String response) {
    if (isNoProtocolReply(response)) {
      if (++_streak >= threshold) {
        _streak = 0;
        onEpisode?.call();
      }
    } else {
      _streak = 0;
    }
  }
}
