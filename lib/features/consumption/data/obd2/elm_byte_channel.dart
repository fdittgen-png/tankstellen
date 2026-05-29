// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

/// Raw byte pipe to an ELM327-compatible adapter.
///
/// Abstracted so [BluetoothObd2Transport] can be unit-tested with a
/// fake channel — the real Bluetooth implementation lives in
/// [FlutterBluePlusElmChannel] (step 1 of #716).
abstract class ElmByteChannel {
  /// Open the channel — e.g. connect BLE, discover services, enable
  /// notifications. Throws on failure. Idempotent: opening an already
  /// open channel is a no-op.
  Future<void> open();

  /// Write raw [bytes] to the adapter. The ELM327 expects ASCII
  /// command strings terminated by `\r`.
  Future<void> write(List<int> bytes);

  /// Stream of bytes coming back from the adapter. Consumers
  /// accumulate until the ELM prompt character `>` (0x3E) arrives.
  Stream<List<int>> get incoming;

  /// Close the channel and release resources. Idempotent.
  Future<void> close();

  bool get isOpen;
}

/// Optional capability mixin (#2261 concern 4) — channels backed by a
/// BLE GATT link can tune the connection for throughput vs power. The
/// trip recorder asks for high throughput while actively polling and
/// drops to balanced when only the 1 Hz auto-record stream is live, so
/// a parked-but-connected adapter doesn't hold the radio at high duty.
///
/// A separate opt-in interface (rather than methods on [ElmByteChannel])
/// keeps every existing test fake free of boilerplate — only the BLE
/// channel implements it; callers type-check before tuning.
///
/// Implementations MUST be best-effort: every call is wrapped in
/// try/catch so a clone that rejects the platform call never breaks a
/// recording session, and the calls are no-ops off Android / on the
/// passive autoConnect path (FBP forbids requestMtu with autoConnect).
abstract class Obd2LinkTuner {
  /// Request a high-throughput link: `ConnectionPriority.high` plus a
  /// best-effort MTU bump. Used while the trip recorder is actively
  /// polling PIDs.
  Future<void> tuneForRecording();

  /// Drop back to `ConnectionPriority.balanced` — used when only the
  /// 1 Hz auto-record movement-detection stream is live, so a connected
  /// idle adapter stops holding the radio at high duty.
  Future<void> tuneForBackground();
}
