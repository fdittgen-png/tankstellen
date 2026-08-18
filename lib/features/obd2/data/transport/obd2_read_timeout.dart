// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Per-command read-timeout classes for the ELM327 link (#2261 concern
/// 5).
///
/// A single fixed 5 s read timeout is both too slow (a trivial `ATE0`
/// echo that will never come back stalls the whole queue for 5 s) and,
/// for the protocol auto-search, occasionally too tight. These three
/// classes right-size the wait per command:
///
///   * [trivialAt] (~1 s) — AT configuration echoes (ATE0, ATL0, ATH0,
///     ATAT1, ATI, ATDPN, ATSP{n} with an explicit protocol). The
///     adapter answers `OK`/a short string in tens of milliseconds;
///     waiting 5 s for one that never comes is pure dead time.
///   * [wake] (~2.5 s) — the reset / wake commands (ATZ, ATWS) where a
///     slow clone re-enumerates, and the very first OBD request on a
///     fresh link (the ECU may still be waking).
///   * [protocolSearch] (~4.5 s) — `ATSP0` and the first OBD request
///     that triggers the ELM327's protocol auto-search across every bus
///     in turn. Starving this class would abort a search that was about
///     to succeed.
enum Obd2ReadTimeoutClass {
  trivialAt(Duration(milliseconds: 1000)),
  wake(Duration(milliseconds: 2500)),
  protocolSearch(Duration(milliseconds: 4500));

  const Obd2ReadTimeoutClass(this.timeout);
  final Duration timeout;
}

/// #2889 — how many AT commands at the very start of a fresh link get the
/// [Obd2ReadTimeoutClass.wake] grace instead of [Obd2ReadTimeoutClass
/// .trivialAt]. A slow Classic-SPP clone (observed: a vLinker FS answering
/// `ATE0` in 2276 ms) keeps echo/headers on while it finishes
/// re-enumerating after the `ATZ` reset; the old single-command grace had
/// already expired by `ATE0` (the SECOND command), so its 1000 ms
/// `trivialAt` budget fired BEFORE the device replied — and the late reply
/// then desynced every following command. Covering the first ~3 AT echoes
/// (ATE0/ATL0/ATH0 in the standard init) with the 2500 ms `wake` budget
/// accommodates the observed latency while still staying under the
/// transport's 5 s read ceiling. Every command past the early-init window
/// — and every real OBD query — keeps its original, tighter class.
const int earlyInitGraceCount = 3;

/// Classify [command] (a raw ELM327 command string, with or without its
/// trailing `\r`) into its read-timeout class (#2261 concern 5).
///
/// [firstCommandOnFreshLink] is true for the very first command sent
/// after the channel opened — the ECU may still be waking, so even a
/// trivial AT echo is given the [Obd2ReadTimeoutClass.wake] grace.
///
/// [atCommandsSinceOpen] (#2889) is the 0-based index of this AT command
/// within the fresh-link init burst (0 for the very first AT command, 1
/// for the second, …). While it is below [earlyInitGraceCount] a trivial
/// AT echo is upgraded to the [Obd2ReadTimeoutClass.wake] grace, so a slow
/// clone that keeps echo on for the first few commands still completes
/// before its read budget fires. Callers that don't track the counter may
/// omit it (defaults to a value past the window, preserving the legacy
/// single-command [firstCommandOnFreshLink] behaviour).
Obd2ReadTimeoutClass classifyReadTimeout(
  String command, {
  bool firstCommandOnFreshLink = false,
  int atCommandsSinceOpen = earlyInitGraceCount,
}) {
  final c = command.trim().toUpperCase();

  // Reset / wake — slow clones re-enumerate after a soft reset.
  if (c == 'ATZ' || c == 'ATWS') return Obd2ReadTimeoutClass.wake;

  // The ATSP0 auto-search walks every OBD protocol — the longest wait.
  if (c == 'ATSP0') return Obd2ReadTimeoutClass.protocolSearch;

  final isAt = c.startsWith('AT') || c.startsWith('ST');
  if (isAt) {
    // #2889 — a trivial AT echo gets the wake grace when it is the first
    // command on a fresh link OR still inside the early-init window (the
    // first [earlyInitGraceCount] AT commands), where a slow clone has not
    // yet finished re-enumerating. Otherwise it's a plain trivial echo.
    final inEarlyInitWindow = atCommandsSinceOpen < earlyInitGraceCount;
    return firstCommandOnFreshLink || inEarlyInitWindow
        ? Obd2ReadTimeoutClass.wake
        : Obd2ReadTimeoutClass.trivialAt;
  }

  // An OBD request (mode 01/09/22, raw hex). The first one on a fresh
  // link can still trigger / complete the protocol search, so it gets
  // the longest class; subsequent OBD reads get the wake grace (the ECU
  // can be momentarily busy) — still far tighter than the old flat 5 s.
  return firstCommandOnFreshLink
      ? Obd2ReadTimeoutClass.protocolSearch
      : Obd2ReadTimeoutClass.wake;
}
