// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

part of 'auto_trip_coordinator.dart';

/// Adapter-event + speed-sample handlers for [AutoTripCoordinator],
/// extracted as a `part` (#3760 decomposition — move-only, behaviour
/// preserved) so the coordinator file stays under the #1680 file-length
/// cap. Free functions (the `obd2_connect_by_mac.dart` precedent) keep
/// library-level access to the coordinator's private state-machine flags;
/// the public API on [AutoTripCoordinator] is untouched.

/// Body of the coordinator's adapter-event subscription (#3760 —
/// move-only).
void _onAdapterEvent(AutoTripCoordinator c, BackgroundAdapterEvent event) {
  // MAC filter — multi-vehicle support. A second paired car sharing
  // the same listener (phase 2b may centralise the bridge) would
  // emit events for an unrelated MAC; we drop them silently rather
  // than risk auto-recording the wrong car's drive.
  if (event.mac != c.config.mac) {
    AutoRecordTraceLog.add(
      switch (event) {
        AdapterConnected() =>
          AutoRecordEventKind.adapterConnectIgnoredOtherMac,
        AdapterDisconnected() =>
          AutoRecordEventKind.adapterDisconnectIgnoredOtherMac,
      },
      mac: event.mac,
    );
    return;
  }

  switch (event) {
    case AdapterConnected():
      AutoRecordTraceLog.add(
        AutoRecordEventKind.adapterConnected,
        mac: event.mac,
      );
      // Fire-and-forget — opening the OBD2 session is async (BLE
      // scan + ELM327 init can take seconds) but the caller of
      // `_onAdapterEvent` is a stream callback that must return
      // synchronously. Errors are funnelled through `errorLogger`
      // inside `_onConnected` so the subscription stays alive.
      unawaited(_onConnected(c));
    case AdapterDisconnected():
      AutoRecordTraceLog.add(
        AutoRecordEventKind.adapterDisconnected,
        mac: event.mac,
      );
      unawaited(_onDisconnected(c));
  }
}

Future<void> _onConnected(AutoTripCoordinator c) async {
  // Reconnect within the disconnect-save window: cancel the timer
  // and let the existing trip continue. We still re-open the OBD2
  // session because the previous one died with the disconnect.
  c._debouncer.cancelIfPending();
  c._consecutiveSupraThreshold = 0;
  await c._watch.stopWatching();
  // Close any orphan session from a prior connect cycle defensively
  // — under normal flow the held session is null here because the
  // disconnect path either handed it off (trip active) or closed
  // it (no trip). Double-close is cheap on a disconnected service.
  await c._watch.closeSessionIfHeld();

  // If a trip is already active (hand-off happened on a previous
  // connect), the recorder owns the session and we don't need to
  // open a new one — speed sampling is the recorder's job now.
  if (c._tripActive) return;

  await c._watch.openAndWatch(c.sessionOpener);
}

Future<void> _onDisconnected(AutoTripCoordinator c) async {
  // Stop counting movement samples — the OBD2 session is gone, no
  // more speed will arrive until the adapter reappears.
  c._consecutiveSupraThreshold = 0;
  await c._watch.stopWatching();
  // Close any orphan session if no trip is active. When a trip IS
  // active the recorder owns the session, so we leave its
  // pause-on-drop logic to handle teardown.
  if (!c._tripActive) {
    await c._watch.closeSessionIfHeld();
  } else {
    // A trip is active: ownership has already moved to the recorder
    // on the threshold-cross hand-off, so the held session should
    // already be null here. Defensive null-out covers the edge case
    // where a test bypasses the hand-off.
    c._watch.takeSession();
  }
  c._debouncer.arm();
}

void _onSpeedSample(AutoTripCoordinator c, double kmh) {
  if (c._tripActive) return;
  if (kmh > c.config.movementStartThresholdKmh) {
    c._consecutiveSupraThreshold++;
    AutoRecordTraceLog.add(
      AutoRecordEventKind.speedSampleSupraThreshold,
      mac: c.config.mac,
      detail:
          'speed=${kmh.toStringAsFixed(1)} kmh, '
          'count=${c._consecutiveSupraThreshold}/${c.consecutiveSamplesWindow}',
    );
  } else {
    c._consecutiveSupraThreshold = 0;
    AutoRecordTraceLog.add(
      AutoRecordEventKind.speedSampleSubThreshold,
      mac: c.config.mac,
      detail: 'speed=${kmh.toStringAsFixed(1)} kmh',
    );
  }
  if (c._consecutiveSupraThreshold >= c.consecutiveSamplesWindow) {
    AutoRecordTraceLog.add(
      AutoRecordEventKind.thresholdCrossed,
      mac: c.config.mac,
      detail: 'speed=${kmh.toStringAsFixed(1)} kmh',
    );
    c._tripActive = true;
    c._consecutiveSupraThreshold = 0;
    // Fire-and-forget — the coordinator's contract is "we observed
    // movement, the provider knows what to do". Errors are logged
    // through `errorLogger` rather than re-thrown into the speed
    // stream, where they'd kill the subscription.
    unawaited(c._watch.handOffAndStartTrip(kmh));
  }
}
