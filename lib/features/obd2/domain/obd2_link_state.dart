// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// The link states one OBD2 adapter can be in, as seen by the ONE
/// reconnect owner (#3529, Epic #3527).
enum Obd2LinkState {
  /// No adapter configured / nothing to supervise.
  idle,

  /// A user- or policy-initiated dial is in flight.
  connecting,

  /// A live, initialized service is available via
  /// [Obd2LinkSupervisor.service].
  ready,

  /// The link dropped and the supervisor is running its backoff loop.
  /// It NEVER gives up on its own — the loop runs until success, a user
  /// disconnect, or an engine-off classification (the #3527 rewrite
  /// deliberately has no `terminalFailed` dead-end; the old six
  /// dead-end states are what stranded the 2026-07-08 trip).
  reconnecting,

  /// The user asked to disconnect. Nothing auto-reconnects until the
  /// next explicit [Obd2LinkSupervisor.connect] (research rule 7: ONE
  /// flag distinguishes intent from drop, checked in one place).
  userDisconnected,

  /// The bus was classified silent (engine off, #3035). The backoff
  /// loop parks — dialing a sleeping car burns adapter and phone
  /// battery — until [Obd2LinkSupervisor.wake] (movement, app resume)
  /// or an explicit connect.
  engineOff,
}
