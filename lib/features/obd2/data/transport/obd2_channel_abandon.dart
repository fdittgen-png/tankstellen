// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// #3244 — preempt-abandonment latch for a byte channel.
///
/// The #3179 channels are deliberately RE-openable: the transport's bounded
/// open-retry loop calls `close()` + `open()` on the SAME instance, so a
/// transient blip recovers on the next attempt. That very property turned a
/// supervisor PREEMPT into a zombie: the preempt teardown `close()`d the
/// passive holder's channel, the in-flight `open()` failed with a
/// *recoverable* disconnect, and the retry loop re-dialled — an UNBOUNDED
/// `autoConnect` GATT request racing the just-granted active requester on
/// the one adapter (the exact war #3185 exists to prevent).
///
/// [abandon] poisons the channel one-way: every later [throwIfAbandoned]
/// (production channels call it at the very top of `open()`) throws the
/// TERMINAL [Obd2ChannelAbandoned], which the transport's
/// `_isRecoverableOpenFailure` deliberately does NOT match — the retry loop
/// rethrows instead of re-dialling, and the preempted attempt unwinds.
mixin Obd2ChannelAbandonLatch {
  bool _abandoned = false;

  /// True once [abandon] poisoned this channel. A poisoned channel must
  /// never be (re)opened; the holder's attempt unwinds terminally.
  bool get isAbandoned => _abandoned;

  /// One-way poison, set by the supervisor's preempt teardown BEFORE the
  /// channel is closed, so the close-induced open failure cannot be retried
  /// into a re-dial. Idempotent.
  void abandon() => _abandoned = true;

  /// Throw the terminal [Obd2ChannelAbandoned] when poisoned. Channels call
  /// this at the very top of `open()` — before any trace stamping, so an
  /// abandoned zombie never writes into the NEW holder's live trace.
  void throwIfAbandoned() {
    if (_abandoned) throw const Obd2ChannelAbandoned();
  }
}

/// #3244 — terminal open failure of a preempt-abandoned channel.
///
/// Deliberately NOT an `Obd2ConnectionError` and NOT worded like a
/// disconnect: `_isRecoverableOpenFailure` (transport) and
/// `isBleAdapterDisconnect` must both classify it NON-recoverable so the
/// open-retry loop rethrows instead of re-dialling the poisoned channel.
class Obd2ChannelAbandoned implements Exception {
  const Obd2ChannelAbandoned();

  @override
  String toString() =>
      'Obd2ChannelAbandoned: channel was preempt-abandoned — '
      'terminal for this attempt (#3244)';
}
