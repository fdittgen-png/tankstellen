// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import 'obd2_comm_diagnostics.dart';
import 'obd2_response_class.dart';

/// ELM327 prompt byte (`>`). The adapter emits it once per reply to mark
/// "ready for the next command"; the transport accumulates incoming
/// bytes until it arrives.
const int _kPromptByte = 0x3E; // '>'

/// Tee one raw incoming byte [chunk] from an ELM327 channel into the
/// gated [Obd2CommDiagnostics] collector as cheap wire-framing counters
/// (#2467, Wave-1 of Epic #2463).
///
/// **Two short-circuits, cheapest first**, so production pays nothing:
///   1. `kReleaseMode` — the per-byte scan is the single most expensive
///      thing the comm-diagnostics subsystem does, so a release build
///      never even reads the collector flag (mirrors the
///      `Obd2BreadcrumbOverlay` release short-circuit). Tree-shaken to a
///      bare `return` in profile/release AOT.
///   2. `Obd2CommDiagnostics.instance.enabled` — off unless
///      `Feature.debugMode` armed the gate. A debug build with the gate
///      off pays one cached-bool read + branch-not-taken per chunk.
///
/// Past the gates it decodes the chunk and records, via the shared
/// [classifyObd2Response] vocabulary, exactly ONE framing observation
/// per chunk:
///   * any non-ASCII byte                       → garbage read (nonAscii)
///   * a chunk that is nothing but a `>` prompt  → stray/unexpected prompt
///   * `BUFFER FULL` / `CAN ERROR` / `UNABLE TO CONNECT` / `STOPPED` /
///     other unrecognised ASCII chatter          → garbage read
///   * a chunk with no terminating prompt        → partial frame
///   * a chunk carrying bytes *after* its prompt → leftover buffer (the
///     previous reply leaked into this read)
///
/// A clean, fully-terminated `…\r>` reply records nothing — only
/// anomalies are counted, so the collector's framing totals stay a tally
/// of wire trouble rather than of normal traffic.
void noteObd2Framing(List<int> chunk) {
  // (1) Heaviest guard first — never scan bytes in release.
  if (kReleaseMode) return;
  // (2) Gate: nothing unless developer mode armed the collector.
  if (!Obd2CommDiagnostics.instance.enabled) return;
  if (chunk.isEmpty) return;

  final diag = Obd2CommDiagnostics.instance;

  // (a) Non-ASCII byte ⇒ noisy wire / binary leak. Count once and stop —
  // a garbage chunk has nothing further worth framing.
  for (final b in chunk) {
    if (b < 0x20 || b > 0x7E) {
      // Tolerate the two ASCII line terminators the ELM frames replies
      // with — CR (0x0D) / LF (0x0A) are structure, not garbage.
      if (b == 0x0D || b == 0x0A) continue;
      diag.noteFraming(garbage: true);
      return;
    }
  }

  final text = String.fromCharCodes(chunk);
  final trimmed = text.trim();

  // (b) A chunk that is nothing but the ready prompt — a stray `>` with
  // no reply attached (a reset echo, a double-prompt from a clone).
  if (trimmed == '>') {
    diag.noteFraming(strayPrompt: true);
    return;
  }

  // (c) Route the ASCII content through the single classifier so the ELM
  // error vocabulary (BUFFER FULL / CAN ERROR / UNABLE TO CONNECT /
  // STOPPED) lands in the garbage bucket with the same vocabulary every
  // other comm-path layer uses. Only the EXPLICIT error vocab short-
  // circuits here — a `garbage` classification on its own is ambiguous
  // (an as-yet-incomplete hex frame like `41 0D` also classifies as
  // garbage), so unknown/partial content falls through to the
  // frame-boundary checks below where it is correctly a partial frame.
  switch (classifyObd2Response(text)) {
    case ResponseClass.bufferFull:
    case ResponseClass.canError:
    case ResponseClass.unrecognized:
      diag.noteFraming(garbage: true);
      return;
    case ResponseClass.ok:
    case ResponseClass.noData:
    case ResponseClass.garbage:
    case ResponseClass.timeout:
      break; // recognised reply OR ambiguous/partial — frame checks below
  }

  // (d) Frame-boundary health: where does the prompt sit?
  final promptAt = chunk.lastIndexOf(_kPromptByte);
  if (promptAt < 0) {
    // No terminating prompt in this chunk — a partial frame still being
    // accumulated by the transport.
    diag.noteFraming(partialFrame: true);
    return;
  }
  // Bytes after the prompt mean the previous reply leaked into this read
  // (the transport will carry them as leftover buffer into the next
  // command's accumulation).
  final hasTrailingPayload = chunk
      .skip(promptAt + 1)
      .any((b) => b != 0x0D && b != 0x0A && b != 0x20);
  if (hasTrailingPayload) {
    diag.noteFraming(leftoverBytes: true);
  }
}

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
